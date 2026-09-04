// pages/records/add/add.js —— 添加记录：文字输入 + 图片上传 + 分类/心情
const db = require('../../../utils/db');
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
  },

  onLoad(query) {
    const date = query.date || dateUtil.ymd(new Date());
    this.setData({ eventDate: date });
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
    const { title, note, category, mood, eventDate, localImages, submitting } = this.data;
    if (submitting) return;
    if (!title.trim()) {
      wx.showToast({ title: '请填写标题', icon: 'none' });
      return;
    }
    this.setData({ submitting: true });
    wx.showLoading({ title: '保存中...', mask: true });
    try {
      let imageFileIds = [];
      if (localImages.length) {
        imageFileIds = await db.uploadFiles(localImages);
      }
      const eventTs = dateUtil.startOfDay(new Date(eventDate.replace(/-/g, '/')));
      await db.records.create({
        title: title.trim(),
        note: note.trim() || null,
        tags: category ? [category] : [],
        category: category || null,
        mood: mood || null,
        imageFileIds,
        eventDate: eventTs,
        source: 'manual',
      });
      wx.hideLoading();
      wx.showToast({ title: '已保存', icon: 'success' });
      setTimeout(() => wx.navigateBack(), 600);
    } catch (err) {
      wx.hideLoading();
      console.error('[add] 保存失败', err);
      wx.showToast({ title: '保存失败，请重试', icon: 'none' });
      this.setData({ submitting: false });
    }
  },
});
