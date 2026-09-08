// pages/mine/mine.js —— 我的：一体主卡（孩子主区 + 家长副区）+ 统计卡 + iOS 风格功能列表
const app = getApp();
const db = require('../../utils/db');
const auth = require('../../utils/auth');
const dateUtil = require('../../utils/date');

// 家长角色映射：value → 称谓后缀（用于派生 parentLabel）
const ROLE_SUFFIX = {
  dad: '爸爸',
  mom: '妈妈',
  grandpa: '爷爷',
  grandma: '奶奶',
  grandpa_m: '姥爷',
  grandma_m: '姥姥',
  other: '家长',
};
// 角色选择 ActionSheet 顺序（与 itemList 索引一一对应）
const ROLE_OPTIONS = [
  { value: 'dad', label: '爸爸' },
  { value: 'mom', label: '妈妈' },
  { value: 'grandpa', label: '爷爷' },
  { value: 'grandma', label: '奶奶' },
  { value: 'grandpa_m', label: '姥爷' },
  { value: 'grandma_m', label: '姥姥' },
  { value: 'other', label: '其他' },
];

Page({
  data: {
    // 登录/用户
    isLoggedIn: false,
    currentUser: null,
    // 孩子
    children: [],
    activeChildId: '',
    activeChild: null,
    // 统计（仅统计卡展示，主卡不再展示）
    stats: { records: 0, books: 0 },
    // 家长副区派生文案
    parentLabel: '',       // 「小云朵的爸爸」/「我是 Ta 的...」
    parentLabelSet: false, // currentUser.role != null 时为 true
    phoneTail: '',         // 已绑定手机号时展示的末四位

    // 添加/编辑孩子弹层
    showChildSheet: false,
    editingChildUuid: '',
    childForm: { name: '', birthDate: '', gender: 'unknown', gradeOverride: '', avatarFileId: '', _avatarTempPath: '' },
    formAvatarUrl: '',

    // 绑定手机号弹层（getPhoneNumber 必须由 button 触发，故用轻量弹层承接）
    showPhoneSheet: false,

    // 年级确认 / 手动选择弹层
    showGradeConfirm: false,
    gradeConfirmText: '',
    pendingGradeChildUuid: '',
    showGradePicker: false,
    gradePickerRange: [
      '幼儿园小班', '幼儿园中班', '幼儿园大班',
      '小学1年级', '小学2年级', '小学3年级', '小学4年级', '小学5年级', '小学6年级',
      '初中1年级', '初中2年级', '初中3年级',
      '高中1年级', '高中2年级', '高中3年级',
    ],
    gradePickerIndex: 0,
  },

  // ==================== 生命周期 ====================
  onLoad() {
    // 订阅全局事件：用户/当前孩子变化时刷新
    this._onUser = (u) => {
      this.setData({ currentUser: u, isLoggedIn: !!u });
      this._deriveParentLabel();
    };
    app.on && app.on('userChanged', this._onUser);
    this._onActiveChild = (id) => {
      this.setData({ activeChildId: id });
      this.refresh();
    };
    app.on && app.on('activeChildChanged', this._onActiveChild);
  },

  onShow() {
    // B（时序）：app.js 登录为异步，onShow 早于 ensureLogin 完成时 auth.currentUser() 仍为 null，
    // 会误判未登录 → 家长副区点击走 doLogin 分支。优先读全局已登录态，再 fallback。
    const u = app.globalData.currentUser || auth.currentUser();
    this.setData({
      currentUser: u,
      isLoggedIn: !!u,
      activeChildId: app.globalData.activeChildId,
    });
    this.refresh();
    // 异步保底：缓存没有用户但云已就绪，静默补一次登录（解决冷启动时序问题）
    if (!u && app.globalData.cloudReady) {
      auth.ensureLogin().then((user) => {
        app.globalData.currentUser = user;
        this.setData({ currentUser: user, isLoggedIn: true });
        this._deriveParentLabel();
        this.refresh();
      }).catch(() => { /* ignore，用户可手动触发登录 */ });
    }
  },

  onUnload() {
    app.off && app.off('userChanged', this._onUser);
    app.off && app.off('activeChildChanged', this._onActiveChild);
  },

  // ==================== 数据加载 ====================
  async refresh() {
    const children = await db.children.listAll();
    let activeChildId = app.globalData.activeChildId;
    // 无选中孩子时默认选第一个
    if ((!activeChildId || !children.find((c) => c.uuid === activeChildId)) && children.length) {
      activeChildId = children[0].uuid;
      app.setActiveChild(activeChildId);
    }
    // 批量解析所有孩子的头像临时 URL
    const fileIds = children.filter((c) => c.avatarFileId).map((c) => c.avatarFileId);
    let urlMap = {};
    if (fileIds.length) {
      try { urlMap = await db.getTempUrls(fileIds); } catch (e) { /* ignore */ }
    }
    this._parseChildren(children, urlMap);
    this.setData({ children, activeChildId });
    // 先定位当前孩子，再刷新统计，最后派生家长称谓（依赖 activeChild 名字）
    this._loadActiveChild();
    this._loadStats();
    this._deriveParentLabel();
  },

  // 解析孩子派生字段（_displayName / _ageText / _grade / _ageRange / _avatarEmoji / _avatarUrl）
  _parseChildren(children, urlMap) {
    urlMap = urlMap || {};
    (children || []).forEach((c) => {
      c._displayName = c.name || '宝贝';
      c._ageText = dateUtil.ageText(c.birthDate);
      c._grade = dateUtil.gradeOf(c.birthDate, c.gradeOverride);
      c._ageRange = dateUtil.ageRangeOf(c.birthDate);
      c._avatarEmoji = c.gender === 'boy' ? '👦' : c.gender === 'girl' ? '👧' : '👶';
      c._avatarUrl = c.avatarFileId ? (urlMap[c.avatarFileId] || '') : '';
    });
    return children;
  },

  // 从已解析的 children 中定位当前 activeChildId 对应孩子
  _loadActiveChild() {
    const { children, activeChildId } = this.data;
    const activeChild = (children || []).find((c) => c.uuid === activeChildId) || null;
    this.setData({ activeChild });
  },

  // 统计：records / books 均在 db 层经 scope().childId 自动按当前孩子过滤
  //（scope 读取 app.globalData.activeChildId，与本页 activeChildId 保持一致），无需再手动加 childId。
  async _loadStats() {
    const childId = this.data.activeChildId;
    const [records, allBooks] = await Promise.all([
      db.records.listAll(999),
      childId ? db.books.listAll() : Promise.resolve([]),
    ]);
    // 共读绘本仅统计「已读完」，不含加入书架但未读完的
    const finishedBooks = allBooks.filter((b) => b.status === 'finished');
    this.setData({ stats: { records: records.length, books: finishedBooks.length } });
  },

  // 派生家长副区文案：currentUser.role + 当前孩子名 → 称谓
  _deriveParentLabel() {
    const user = this.data.currentUser;
    const child = this.data.activeChild;
    const name = (child && child._displayName) || 'Ta';
    const loggedIn = this.data.isLoggedIn;
    const roleSet = !!(user && user.role != null && ROLE_SUFFIX[user.role]);
    let label;
    if (!loggedIn) {
      // 未登录：家长副区不再显示空状态文案，而是明确的「选角色/绑定」入口
      label = '登录后绑定家长角色';
    } else if (roleSet) {
      label = `${name}的${ROLE_SUFFIX[user.role]}`;
    } else {
      label = '我是 Ta 的...';
    }
    this.setData({ parentLabel: label, parentLabelSet: roleSet });
    // 派生手机号末四位（仅已绑定时展示）
    const phone = user && user.phone ? String(user.phone) : '';
    this.setData({ phoneTail: phone ? phone.slice(-4) : '' });
  },

  // ==================== 家长副区交互 ====================
  // 点击家长副区称谓行：未登录先登录；已登录「直接」弹角色选择 ActionSheet。
  // 废弃原两级 ActionSheet 嵌套：微信不允许在上一个 ActionSheet 的 success 回调里
  // 再调起 ActionSheet，第二个会被系统静默丢弃 → 表现为「点了没反应」。
  onParentRowTap() {
    console.log('[mine] onParentRowTap triggered, isLoggedIn=', this.data.isLoggedIn, 'currentUser=', JSON.stringify(this.data.currentUser));
    if (!this.data.isLoggedIn) {
      this.doLogin();
      return;
    }
    this.onRoleSelect();
  },

  // 直接弹角色选择 ActionSheet（爸爸/妈妈/爷爷/奶奶/姥爷/姥姥/其他 + 取消），选完写库并重新派生
  onRoleSelect() {
    if (!this.data.isLoggedIn) {
      this.doLogin();
      return;
    }
    wx.showActionSheet({
      itemList: ROLE_OPTIONS.map((r) => r.label), // 7 项角色；ActionSheet 自带「取消」
      success: async (res) => {
        const opt = ROLE_OPTIONS[res.tapIndex];
        if (!opt) return; // 取消或越界不落库
        try {
          const updated = await auth.updateUserRole(opt.value);
          // 同步本页与全局，再重新派生称谓
          app.globalData.currentUser = updated;
          this.setData({ currentUser: updated, isLoggedIn: true });
          this._deriveParentLabel();
          wx.showToast({ title: '已设置', icon: 'success' });
        } catch (e) {
          console.error('[mine] updateUserRole 失败', e);
          wx.showToast({ title: '保存失败', icon: 'none' });
        }
      },
      fail: () => { /* 取消，忽略 */ },
    });
  },

  // 绑定/更换手机号：由独立按钮（bindtap）触发，不再走 ActionSheet。
  // 弹轻量弹层（内含 getPhoneNumber 按钮，微信规定该授权必须由按钮触发）。
  onBindPhone() {
    if (!this.data.isLoggedIn) {
      this.doLogin();
      return;
    }
    this.setData({ showPhoneSheet: true });
  },
  closePhoneSheet() {
    this.setData({ showPhoneSheet: false });
  },

  // ==================== 切换孩子 ====================
  onSwitchChild() {
    const children = this.data.children || [];
    if (!children.length) {
      this.openAddChild();
      return;
    }
    const itemList = children.map((c) => {
      const name = c._displayName || c.name || '宝贝';
      return c._ageText ? `${name} · ${c._ageText}` : name;
    });
    itemList.push('+ 添加新孩子');
    wx.showActionSheet({
      itemList,
      success: (res) => {
        const idx = res.tapIndex;
        if (idx === children.length) {
          this.openAddChild();
          return;
        }
        const child = children[idx];
        if (child) app.setActiveChild(child.uuid); // 触发 activeChildChanged → refresh（含统计刷新 + 重新派生 parentLabel）
      },
      fail: () => { /* 取消 */ },
    });
  },

  // ==================== 登录 / 手机号 ====================
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
        this.setData({ currentUser: u, isLoggedIn: true });
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
    if (d.errMsg && d.errMsg.indexOf('ok') === -1) {
      this.closePhoneSheet();
      return;
    }
    const payload = d.code ? { code: d.code } : d.cloudID ? { cloudID: d.cloudID } : null;
    if (!payload) {
      this.closePhoneSheet();
      return;
    }
    auth
      .bindPhone(payload)
      .then(() => {
        this.closePhoneSheet();
        wx.showToast({ title: '已绑定手机号', icon: 'success' });
        const u = auth.currentUser();
        this.setData({ currentUser: u, isLoggedIn: !!u });
        this.refresh();
      })
      .catch(() => {
        this.closePhoneSheet();
        wx.showToast({ title: '绑定失败', icon: 'none' });
      });
  },

  // ==================== 添加 / 编辑孩子 ====================
  openAddChild() {
    this.setData({
      showChildSheet: true,
      editingChildUuid: '',
      childForm: { name: '', birthDate: '', gender: 'unknown', gradeOverride: '', avatarFileId: '', _avatarTempPath: '' },
      formAvatarUrl: '',
    });
  },

  async onEditChild(e) {
    // 主卡「✏️ 编辑」无 dataset 时编辑当前 activeChild；列表场景可带 data-uuid
    const uuid = (e && e.currentTarget && e.currentTarget.dataset.uuid) || this.data.activeChildId;
    const child = this.data.children.find((c) => c.uuid === uuid);
    if (!child) return;
    const birthDateStr = child.birthDate ? dateUtil.ymd(new Date(child.birthDate)) : '';
    // B1：打开编辑弹层时必须回填 name（否则编辑时名字空白）及其余字段
    this.setData({
      showChildSheet: true,
      editingChildUuid: uuid,
      childForm: {
        name: child.name || '',
        birthDate: birthDateStr,
        gender: child.gender || 'unknown',
        gradeOverride: child.gradeOverride || '',
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
      showChildSheet: false,
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
        this.setData({ showChildSheet: false, editingChildUuid: '', formAvatarUrl: '' });
        await this.refresh();
        wx.showToast({ title: '已保存', icon: 'success' });
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
        this.setData({ showChildSheet: false, editingChildUuid: '', formAvatarUrl: '' });
        app.setActiveChild(child.uuid);
        await this.refresh();
        wx.showToast({ title: '已添加', icon: 'success' });
        this._maybeConfirmGrade(child.uuid);
      }
    } catch (err) {
      wx.hideLoading();
      console.error('[mine] saveChild 失败', err);
      wx.showToast({ title: '保存失败', icon: 'none' });
    }
  },

  // ==================== 年级确认弹层 ====================
  _maybeConfirmGrade(childUuid) {
    const child = this.data.children.find((c) => c.uuid === childUuid);
    if (!child || !child.birthDate) return;
    if (child.gradeOverride) return; // 已手动覆盖则跳过
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

  // ==================== 功能菜单 ====================
  goArchive() {
    wx.showToast({ title: '成长档案敬请期待', icon: 'none' });
  },
  goReport() {
    wx.navigateTo({ url: '/pages/report/report' });
  },
  goCloudSync() {
    wx.showToast({ title: '云同步敬请期待', icon: 'none' });
  },
  goSettings() {
    wx.showToast({ title: '设置敬请期待', icon: 'none' });
  },

  // ==================== 退出登录 ====================
  onLogout() {
    wx.showModal({
      title: '退出登录',
      content: '退出后本地缓存将清除，需要重新登录才能使用云同步功能',
      confirmText: '退出',
      confirmColor: '#FF4D4F',
      success: (res) => {
        if (res.confirm) {
          auth.logout();
          // 同时清空孩子相关数据，避免退出后页面还显示孩子信息
          this.setData({
            isLoggedIn: false,
            currentUser: null,
            children: [],
            activeChildId: '',
            activeChild: null,
            stats: { records: 0, books: 0 },
            parentLabel: '登录后绑定家长角色',
            parentLabelSet: false,
            phoneTail: '',
          });
        }
      },
    });
  },
});
