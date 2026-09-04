// pages/records/add/add.js —— 添加记录：文字输入 + 图片上传 + 分类/心情
const db = require('../../../utils/db');
const auth = require('../../../utils/auth');
const dateUtil = require('../../../utils/date');
const { CATEGORIES, MOODS } = require('../../../utils/constants');

Page({
  data: {
    title: '',
    note: '',
    categories: CATEGORIES,
    moods: MOODS,
    category: '日常',
    mood: '',
    eventDate: '', // 'YYYY-MM-DD'
    localImages: [], // 本地临时路径
    submitting: false,
    // 编辑模式
    recordId: '', // 非空表示编辑已有记录
    isEdit: false,
    existingImageIds: [], // 编辑模式下保留的云端图片 fileID
    existingImageUrls: [], // 与 existingImageIds 一一对应的临时预览链接
    loading: false,
  },

  onLoad(query) {
    const recordId = query.recordId || '';
    if (recordId) {
      // 编辑模式：加载已有记录填入表单
      this.setData({ recordId, isEdit: true, loading: true });
      wx.setNavigationBarTitle({ title: '编辑记录' });
      this._loadRecord(recordId);
    } else {
      const date = query.date || dateUtil.ymd(new Date());
      this.setData({ eventDate: date });
    }
  },

  async _loadRecord(recordId) {
    wx.showLoading({ title: '加载中...', mask: true });
    try {
      const rec = await db.getByUuid(db.COLLECTIONS.dailyRecords, recordId);
      if (!rec) {
        wx.hideLoading();
        wx.showToast({ title: '记录不存在', icon: 'none' });
        this.setData({ loading: false });
        return;
      }
      const existingImageIds = rec.imageFileIds || [];
      this.setData({
        title: rec.title || '',
        note: rec.note || '',
        category: rec.category || '日常',
        mood: rec.mood || '',
        eventDate: dateUtil.ymd(rec.eventDate ? new Date(rec.eventDate) : new Date()),
        existingImageIds,
        loading: false,
      });
      wx.hideLoading();
      // 换取云端图片临时预览链接
      if (existingImageIds.length) {
        const map = await db.getTempUrls(existingImageIds);
        this.setData({
          existingImageUrls: existingImageIds.map((f) => map[f]).filter(Boolean),
        });
      }
    } catch (err) {
      wx.hideLoading();
      console.error('[add] 加载记录失败', err);
      wx.showToast({ title: '加载失败', icon: 'none' });
      this.setData({ loading: false });
    }
  },

  // 移除一张已存在的云端图片（仅从本次保存的列表中剔除）
  removeExistingImage(e) {
    const idx = e.currentTarget.dataset.idx;
    const existingImageIds = this.data.existingImageIds.slice();
    const existingImageUrls = this.data.existingImageUrls.slice();
    existingImageIds.splice(idx, 1);
    existingImageUrls.splice(idx, 1);
    this.setData({ existingImageIds, existingImageUrls });
  },

  previewExisting(e) {
    const url = e.currentTarget.dataset.url;
    wx.previewImage({ urls: this.data.existingImageUrls, current: url });
  },

  onTitleInput(e) {
    this.setData({ title: e.detail.value });
  },
  onNoteInput(e) {
    this.setData({ note: e.detail.value });
  },
  onDateChange(e) {
    this.setData({ eventDate: e.detail.value });
  },
  selectCategory(e) {
    this.setData({ category: e.currentTarget.dataset.cat });
  },
  selectMood(e) {
    const key = e.currentTarget.dataset.mood;
    this.setData({ mood: this.data.mood === key ? '' : key });
  },

  // 选择图片（最多 9 张）
  chooseImage() {
    const remain = 9 - this.data.localImages.length;
    if (remain <= 0) {
      wx.showToast({ title: '最多 9 张', icon: 'none' });
      return;
    }
    wx.chooseMedia({
      count: remain,
      mediaType: ['image'],
      sizeType: ['compressed'],
      sourceType: ['album', 'camera'],
      success: (res) => {
        const paths = res.tempFiles.map((f) => f.tempFilePath);
        this.setData({ localImages: this.data.localImages.concat(paths) });
      },
    });
  },

  removeImage(e) {
    const idx = e.currentTarget.dataset.idx;
    const localImages = this.data.localImages.slice();
    localImages.splice(idx, 1);
    this.setData({ localImages });
  },

  previewLocal(e) {
    const url = e.currentTarget.dataset.url;
    wx.previewImage({ urls: this.data.localImages, current: url });
  },

  async onSubmit() {
    const {
      title, note, category, mood, eventDate, localImages, submitting,
      isEdit, recordId, existingImageIds,
    } = this.data;
    if (submitting) return;
    if (!title.trim()) {
      wx.showToast({ title: '请填写标题', icon: 'none' });
      return;
    }
    // 预检登录态：ownerId 为空说明未登录（通常是 login 云函数未部署导致），
    // 提前拦截并给出明确指引，避免走到写库时抛「未登录，无法写入」的模糊错误。
    if (!auth.ownerId()) {
      wx.showToast({ title: '请先到「我的」登录后再保存', icon: 'none' });
      console.warn('[add] 未登录（ownerId 为空），无法保存。请确认 login 云函数已部署并登录成功');
      return;
    }
    this.setData({ submitting: true });
    wx.showLoading({ title: '保存中...', mask: true });
    try {
      let newImageIds = [];
      if (localImages.length) {
        newImageIds = await db.uploadFiles(localImages);
      }
      const eventTs = dateUtil.startOfDay(new Date(eventDate.replace(/-/g, '/')));
      if (isEdit) {
        // 编辑模式：保留未删除的云端图片 + 新上传图片，调用 update
        const imageFileIds = (existingImageIds || []).concat(newImageIds);
        await db.records.update(recordId, {
          title: title.trim(),
          note: note.trim() || null,
          tags: category ? [category] : [],
          category: category || null,
          mood: mood || null,
          imageFileIds,
          eventDate: eventTs,
        });
      } else {
        await db.records.create({
          title: title.trim(),
          note: note.trim() || null,
          tags: category ? [category] : [],
          category: category || null,
          mood: mood || null,
          imageFileIds: newImageIds,
          eventDate: eventTs,
          source: 'manual',
        });
      }
      wx.hideLoading();
      wx.showToast({ title: '已保存', icon: 'success' });
      setTimeout(() => wx.navigateBack(), 600);
    } catch (err) {
      wx.hideLoading();
      // 打印完整错误对象，便于定位（如上传失败、写库权限、集合不存在等）
      console.error('[add] 保存失败，详细错误：', err, JSON.stringify(err && (err.errMsg || err.message) || err));
      const msg = `${(err && (err.errMsg || err.message)) || err}`;
      let title = '保存失败，请重试';
      if (/未登录/.test(msg)) {
        title = '未登录，请先到「我的」登录';
      } else if (/upload|uploadFile|存储/i.test(msg)) {
        title = '图片上传失败，请重试';
      } else if (/permission|denied|权限/i.test(msg)) {
        title = '无写入权限，请检查数据库权限设置';
      }
      wx.showToast({ title, icon: 'none' });
      this.setData({ submitting: false });
    }
  },
});
