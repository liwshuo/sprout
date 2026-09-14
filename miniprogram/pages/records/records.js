// pages/records/records.js —— 记录列表：文字 + 图片卡片
const app = getApp();
const db = require('../../utils/db');
const auth = require('../../utils/auth');
const dateUtil = require('../../utils/date');
const { categoryColor, moodEmoji } = require('../../utils/constants');

Page({
  data: {
    records: [],
    loading: false,
  },

  onLoad() {
    this._onChild = () => this.refresh();
    app.on && app.on('activeChildChanged', this._onChild);
  },

  onShow() {
    this.refresh();
  },

  onUnload() {
    app.off && app.off('activeChildChanged', this._onChild);
  },

  onPullDownRefresh() {
    this.refresh()
      .then(() => wx.stopPullDownRefresh())
      .catch(() => wx.stopPullDownRefresh());
  },

  async refresh() {
    this.setData({ loading: true });
    const childId = app.globalData.activeChildId;
    if (!childId) {
      this.setData({ records: [], loading: false });
      return;
    }
    const list = await db.records.listAll(100);
    const records = list.map((r) => ({
      ...r,
      color: categoryColor(r.category),
      moodIcon: moodEmoji(r.mood),
      dateLabel: dateUtil.mdCn(r.eventDate),
      images: r.imageFileIds || [],
      imageUrls: [],
    }));
    this.setData({ records, loading: false });
    this._hydrateImages(records);
  },

  async _hydrateImages(records) {
    const ids = [];
    records.forEach((r) => (r.images || []).forEach((f) => ids.push(f)));
    if (!ids.length) return;
    const map = await db.getTempUrls(ids);
    const withUrls = this.data.records.map((r) => ({
      ...r,
      imageUrls: (r.images || []).map((f) => map[f]).filter(Boolean),
    }));
    this.setData({ records: withUrls });
  },

  previewImage(e) {
    const { urls, current } = e.currentTarget.dataset;
    if (urls && urls.length) wx.previewImage({ urls, current });
  },

  goAdd() {
    wx.navigateTo({ url: '/pages/records/add/add' });
  },

  onEdit(e) {
    const uuid = e.currentTarget.dataset.uuid;
    wx.navigateTo({ url: `/pages/records/add/add?recordId=${uuid}` });
  },

  onDelete(e) {
    if (!auth.ownerId()) {
      wx.showToast({ title: '请先登录', icon: 'none' });
      return;
    }
    const uuid = e.currentTarget.dataset.uuid;
    wx.showActionSheet({
      itemList: ['确认删除该记录', '取消'],
      itemColor: '#E5702A',
      success: (res) => {
        if (res.tapIndex !== 0) return;
        db.records
          .remove(uuid)
          .then(() => {
            wx.showToast({ title: '已删除', icon: 'success' });
            this.refresh();
          })
          .catch(() => wx.showToast({ title: '删除失败', icon: 'none' }));
      },
    });
  },
});
