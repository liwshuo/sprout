// pages/mine/mine.js —— 我的：孩子信息 + 多孩子切换 + 周报入口 + 登录/绑手机
const app = getApp();
const db = require('../../utils/db');
const auth = require('../../utils/auth');
const dateUtil = require('../../utils/date');

Page({
  data: {
    user: null,
    children: [],
    activeChildId: '',
    activeChild: null,
    stats: { records: 0, books: 0 },
    // 添加孩子弹层
    showAddChild: false,
    editingChildUuid: '',
    childForm: { name: '', birthDate: '', gender: 'unknown', avatarFileId: '', _avatarTempPath: '' },
    formAvatarUrl: '',
    // 年级确认弹层
    showGradeConfirm: false,
    gradeConfirmText: '',
    pendingGradeChildUuid: '',
    showGradePicker: false,
    gradePickerRange: [
      '幼儿园小班','幼儿园中班','幼儿园大班',
      '小学1年级','小学2年级','小学3年级','小学4年级','小学5年级','小学6年级',
      '初中1年级','初中2年级','初中3年级',
      '高中1年级','高中2年级','高中3年级',
    ],
    gradePickerIndex: 0,
  },

  onLoad() {
    this._onUser = (u) => this.setData({ user: u });
    app.on && app.on('userChanged', this._onUser);
    this._onActiveChild = (id) => {
      this.setData({ activeChildId: id });
      this.refresh();
    };
    app.on && app.on('activeChildChanged', this._onActiveChild);
  },
  onShow() {
    this.setData({ user: auth.currentUser(), activeChildId: app.globalData.activeChildId });
    this.refresh();
  },
  onUnload() {
    app.off && app.off('userChanged', this._onUser);
    app.off && app.off('activeChildChanged', this._onActiveChild);
  },

  async refresh() {
    const children = await db.children.listAll();
    let activeChildId = app.globalData.activeChildId;
    // 无选中孩子时默认选第一个
    if ((!activeChildId || !children.find((c) => c.uuid === activeChildId)) && children.length) {
      activeChildId = children[0].uuid;
      app.setActiveChild(activeChildId);
    }
    const activeChild = children.find((c) => c.uuid === activeChildId) || null;
    if (activeChild) {
      activeChild._displayName = activeChild.name || '宝贝';
      activeChild._ageText = dateUtil.ageText(activeChild.birthDate);
      activeChild._grade = dateUtil.gradeOf(activeChild.birthDate, activeChild.gradeOverride);
      activeChild._ageRange = dateUtil.ageRangeOf(activeChild.birthDate);
      activeChild._avatarEmoji = activeChild.gender === 'boy' ? '👦' : activeChild.gender === 'girl' ? '👧' : '👶';
    }
    // 批量解析所有孩子的头像临时 URL
    const fileIds = children.filter((c) => c.avatarFileId).map((c) => c.avatarFileId);
    let urlMap = {};
    if (fileIds.length) {
      try { urlMap = await db.getTempUrls(fileIds); } catch (e) { /* ignore */ }
    }
    children.forEach((c) => {
      c._displayName = c.name || '宝贝';
      c._ageText = dateUtil.ageText(c.birthDate);
      c._avatarEmoji = c.gender === 'boy' ? '👦' : c.gender === 'girl' ? '👧' : '👶';
      c._avatarUrl = c.avatarFileId ? (urlMap[c.avatarFileId] || '') : '';
    });
    // activeChild 直接从已处理的 children 里取
    const updatedActiveChild = children.find((c) => c.uuid === activeChildId) || null;
    if (updatedActiveChild && activeChild) {
      // 把派生字段同步到 activeChild（activeChild 已在上方单独处理了 _grade / _ageRange）
      activeChild._avatarUrl = updatedActiveChild._avatarUrl;
      activeChild._avatarEmoji = updatedActiveChild._avatarEmoji;
    }
    this.setData({ children, activeChildId, activeChild });
    this._loadStats();
  },

  async _loadStats() {
    const childId = this.data.activeChildId;
    const [records, books] = await Promise.all([
      db.records.listAll(999),
      childId ? db.books.listAll() : Promise.resolve([]),
    ]);
    // books 已在 listAllPaged 通过 scope().childId 自动过滤当前孩子，不需要额外 filter
    this.setData({ stats: { records: records.length, books: books.length } });
  },

  switchChild(e) {
    const uuid = e.currentTarget.dataset.uuid;
    app.setActiveChild(uuid);
    const child = this.data.children.find((c) => c.uuid === uuid) || null;
    if (child) {
      child._displayName = child.name || '宝贝';
      child._ageText = dateUtil.ageText(child.birthDate);
      child._grade = dateUtil.gradeOf(child.birthDate, child.gradeOverride);
      child._ageRange = dateUtil.ageRangeOf(child.birthDate);
      child._avatarEmoji = child.gender === 'boy' ? '👦' : child.gender === 'girl' ? '👧' : '👶';
    }
    this.setData({ activeChildId: uuid, activeChild: child });
    this._loadStats();
    wx.showToast({ title: '已切换', icon: 'none' });
  },

  // ---- 登录 ----
  doLogin() {
    if (!app.globalData.cloudReady) {
      wx.showToast({ title: '云环境未配置', icon: 'none' });
      return;
    }
    wx.showLoading({ title: '登录中...', mask: true });
    auth
      .ensureLogin()
      .then((u) => {
        app.globalData.currentUser = u;
        wx.hideLoading();
        this.setData({ user: u });
        this.refresh();
        wx.showToast({ title: '登录成功', icon: 'success' });
      })
      .catch((err) => {
        wx.hideLoading();
        console.error('[mine] 登录失败', err);
        const tip = auth.isCloudFunctionMissing(err)
          ? '登录失败：请先在开发者工具部署 login 云函数'
          : '登录失败，请稍后重试';
        wx.showToast({ title: tip, icon: 'none' });
      });
  },

  // 手机号快速验证按钮回调（新版返回 code，旧版返回 cloudID）
  onGetPhone(e) {
    const d = e.detail || {};
    // 用户拒绝授权
    if (d.errMsg && d.errMsg.indexOf('ok') === -1) return;
    const payload = d.code ? { code: d.code } : d.cloudID ? { cloudID: d.cloudID } : null;
    if (!payload) return;
    auth
      .bindPhone(payload)
      .then(() => {
        wx.showToast({ title: '已绑定手机号', icon: 'success' });
        this.setData({ user: auth.currentUser() });
        this.refresh();
      })
      .catch(() => wx.showToast({ title: '绑定失败', icon: 'none' }));
  },

  // ---- 添加孩子 ----
  openAddChild() {
    this.setData({
      showAddChild: true,
      editingChildUuid: '',
      childForm: { name: '', birthDate: '', gender: 'unknown', avatarFileId: '', _avatarTempPath: '' },
      formAvatarUrl: '',
    });
  },
  async openEditChild(e) {
    const uuid = e.currentTarget.dataset.uuid;
    const child = this.data.children.find((c) => c.uuid === uuid);
    if (!child) return;
    const birthDateStr = child.birthDate ? dateUtil.ymd(new Date(child.birthDate)) : '';
    this.setData({
      showAddChild: true,
      editingChildUuid: uuid,
      childForm: {
        name: child.name || '',
        birthDate: birthDateStr,
        gender: child.gender || 'unknown',
        avatarFileId: child.avatarFileId || '',
        _avatarTempPath: '',
      },
      formAvatarUrl: '',
    });
    // 有 avatarFileId 时解析旧头像临时 URL 展示
    if (child.avatarFileId) {
      try {
        const urlMap = await db.getTempUrls([child.avatarFileId]);
        this.setData({ formAvatarUrl: urlMap[child.avatarFileId] || '' });
      } catch (err) { /* ignore */ }
    }
  },
  closeAddChild() {
    this.setData({
      showAddChild: false,
      'childForm.avatarFileId': '',
      'childForm._avatarTempPath': '',
      formAvatarUrl: '',
    });
  },
  onChildInput(e) {
    this.setData({ 'childForm.name': e.detail.value });
  },
  onGenderSelect(e) {
    const gender = e.currentTarget.dataset.gender;
    this.setData({ 'childForm.gender': gender });
  },
  onBirthChange(e) {
    this.setData({ 'childForm.birthDate': e.detail.value });
  },
  // 弹层内选头像（仅暂存临时路径，保存时统一上传）
  async onFormAvatarTap() {
    const res = await wx.chooseMedia({
      count: 1,
      mediaType: ['image'],
      sizeType: ['compressed'],
      sourceType: ['album', 'camera'],
    });
    if (!res.tempFiles || !res.tempFiles.length) return;
    const tempPath = res.tempFiles[0].tempFilePath;
    this.setData({ 'childForm._avatarTempPath': tempPath });
  },
  async saveChild() {
    const { name, birthDate, gender } = this.data.childForm;
    const editingUuid = this.data.editingChildUuid;
    if (!name.trim()) {
      wx.showToast({ title: '请填写宝宝名字', icon: 'none' });
      return;
    }
    if (!auth.ownerId()) {
      wx.showToast({ title: '请先登录', icon: 'none' });
      return;
    }
    // 处理头像：有新选择的临时图片则先上传
    let avatarFileId = this.data.childForm.avatarFileId || '';
    if (this.data.childForm._avatarTempPath) {
      wx.showLoading({ title: '上传头像...', mask: true });
      try {
        avatarFileId = await db.uploadFile(this.data.childForm._avatarTempPath);
      } catch (e) {
        console.error('头像上传失败', e);
      }
      wx.hideLoading();
    }
    wx.showLoading({ title: '保存中...', mask: true });
    try {
      const birthTs = birthDate
        ? dateUtil.startOfDay(new Date(birthDate.replace(/-/g, '/')))
        : null;
      if (editingUuid) {
        // 编辑模式
        await db.children.update(editingUuid, {
          name: name.trim(),
          birthDate: birthTs || null,
          gender: gender || 'unknown',
          avatarFileId: avatarFileId || null,
        });
        wx.hideLoading();
        this.setData({ showAddChild: false, editingChildUuid: '', formAvatarUrl: '' });
        await this.refresh();
        wx.showToast({ title: '已保存', icon: 'success' });
        // 编辑完也触发年级确认（如果有生日）
        this._maybeConfirmGrade(editingUuid);
      } else {
        // 新增模式
        const child = await db.children.create({
          name: name.trim(),
          birthDate: birthTs || null,
          gender: gender || 'unknown',
          avatarFileId: avatarFileId || null,
          gradeOverride: null,
          sortOrder: this.data.children.length,
        });
        wx.hideLoading();
        this.setData({ showAddChild: false, editingChildUuid: '', formAvatarUrl: '' });
        app.setActiveChild(child.uuid);
        await this.refresh();
        wx.showToast({ title: '已添加', icon: 'success' });
        // 新增完触发年级确认
        this._maybeConfirmGrade(child.uuid);
      }
    } catch (err) {
      wx.hideLoading();
      console.error('[mine] saveChild 失败', err);
      wx.showToast({ title: '保存失败', icon: 'none' });
    }
  },

  // ---- 年级确认弹层 ----
  _maybeConfirmGrade(childUuid) {
    const child = this.data.children.find((c) => c.uuid === childUuid);
    if (!child || !child.birthDate) return;
    // 已有手动覆盖则跳过确认
    if (child.gradeOverride) return;
    const grade = dateUtil.gradeOf(child.birthDate, null);
    if (!grade) return; // 幼儿园/大学阶段不弹
    this.setData({
      showGradeConfirm: true,
      gradeConfirmText: grade,
      pendingGradeChildUuid: childUuid,
    });
  },

  onGradeConfirmOk() {
    this.setData({ showGradeConfirm: false, pendingGradeChildUuid: '' });
  },

  onGradeConfirmEdit() {
    // 关闭确认弹层，打开年级 picker
    const grade = this.data.gradeConfirmText;
    const idx = this.data.gradePickerRange.indexOf(grade);
    this.setData({
      showGradeConfirm: false,
      showGradePicker: true,
      gradePickerIndex: idx >= 0 ? idx : 0,
    });
  },

  onGradePickerChange(e) {
    this.setData({ gradePickerIndex: Number(e.detail.value) });
  },

  async onGradePickerConfirm() {
    const grade = this.data.gradePickerRange[this.data.gradePickerIndex];
    const uuid = this.data.pendingGradeChildUuid;
    if (!uuid || !grade) {
      this.setData({ showGradePicker: false });
      return;
    }
    try {
      await db.children.update(uuid, { gradeOverride: grade });
      this.setData({ showGradePicker: false, pendingGradeChildUuid: '' });
      this.refresh();
      wx.showToast({ title: '年级已更新', icon: 'success' });
    } catch (err) {
      wx.showToast({ title: '更新失败', icon: 'none' });
    }
  },

  onGradePickerCancel() {
    this.setData({ showGradePicker: false, pendingGradeChildUuid: '' });
  },

  // ---- 头像上传（已移入添加/编辑孩子弹层，见 onFormAvatarTap / saveChild）----

  goReport() {
    wx.navigateTo({ url: '/pages/report/report' });
  },
});
