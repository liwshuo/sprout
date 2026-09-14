const app = getApp();
const db = require('../../utils/db');

Component({
  data: {
    children: [],
    activeChild: null,
  },

  lifetimes: {
    attached() {
      this._onActiveChild = () => this._syncFromGlobal();
      this._onUser = (user) => {
        if (user) this._loadChildren();
        else this.setData({ children: [], activeChild: null });
      };
      app.on && app.on('activeChildChanged', this._onActiveChild);
      app.on && app.on('userChanged', this._onUser);
      this._syncFromGlobal();
      this._loadChildren();
    },
    detached() {
      app.off && app.off('activeChildChanged', this._onActiveChild);
      app.off && app.off('userChanged', this._onUser);
    },
  },

  pageLifetimes: {
    show() {
      this._syncFromGlobal();
      this._loadChildren();
    },
  },

  methods: {
    _syncFromGlobal() {
      const children = app.globalData.children || [];
      const activeId = app.globalData.activeChildId;
      const activeChild = children.find((child) => child.uuid === activeId) || children[0] || null;
      this.setData({ children, activeChild });
    },

    async _loadChildren() {
      if (!app.globalData.loginVerified || this._loadingChildren) return;
      this._loadingChildren = true;
      try {
        const children = await db.children.listAll();
        app.globalData.children = children;
        let activeId = app.globalData.activeChildId;
        if (children.length && !children.some((child) => child.uuid === activeId)) {
          activeId = children[0].uuid;
          app.setActiveChild(activeId);
        }
        this._syncFromGlobal();
      } catch (err) {
        console.warn('[child-switcher] 加载孩子列表失败', err);
      } finally {
        this._loadingChildren = false;
      }
    },

    onTap() {
      const children = this.data.children || [];
      if (children.length <= 1) return;
      wx.showActionSheet({
        itemList: children.map((child) => child._displayName || child.name || '宝贝'),
        success: (res) => {
          const child = children[res.tapIndex];
          if (child && child.uuid !== app.globalData.activeChildId) {
            app.setActiveChild(child.uuid);
          }
        },
      });
    },
  },
});
