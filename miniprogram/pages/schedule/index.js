// pages/schedule/index.js —— 课表：周网格总览 + 日视图；从课程库拖拽排课
// 交互：课程库 chip 拖入空白格=新增；课程块拖动=调整时间；长按课程块=删除确认；点击不弹编辑
const app = getApp();
const db = require('../../utils/db');
const auth = require('../../utils/auth');
const { WEEKDAYS } = require('../../utils/constants');
const dateUtil = require('../../utils/date');

const COL = db.COLLECTIONS.scheduleItems;

// —— 网格布局常量（rpx）——
const HOUR_H = 100;   // 每小时高度
const COL_W = 150;    // 每天列宽（周视图）
const TIME_W = 70;    // 时间轴列宽
const GRID_W_RPX = TIME_W + 7 * COL_W;   // 1120
// 新增课程默认时长（分钟）：校内 40 / 兴趣班 60
const DEFAULT_DUR = { school: 40, extra: 60 };
// 拖动课程块的长按删除阈值
const LONGPRESS_MS = 500;
// 拖拽时间吸附精度（分钟）
const SNAP_MIN = 10;

function pad2(n) { return String(n).padStart(2, '0'); }
function toMin(t) { const [h, m] = String(t || '0:0').split(':').map(Number); return h * 60 + m; }
function fmt(min) { const m = Math.max(0, min); return `${pad2(Math.floor(m / 60))}:${pad2(m % 60)}`; }
function clamp(v, a, b) { return Math.max(a, Math.min(b, v)); }
function colorOf(item) {
  if (item && item.color) return item.color;
  return item && item.type === 'school' ? '#6FB0E3' : '#FF8C42';
}

Page({
  data: {
    viewMode: 'week',        // 'week' | 'day'
    todayWeekday: 1,
    selectedWeekday: 1,
    weekTabs: [],
    scrollLeft: 0,
    week: { cols: [], hours: [], lines: [], gridHeight: 0 },
    day: { events: [], hours: [], lines: [], gridHeight: 0 },
    loading: false,
    todayStr: '',

    // —— 课程库（拖拽源，数据来自 course_templates）——
    showLibrary: false,
    libCategory: 'school',
    courseLib: { school: [], extra: [] },
    hasTemplates: false,

    // —— 拖拽 ——
    dragging: false,
    dragGhost: { show: false, x: 0, y: 0, label: '', color: '#FF8C42' },
    dropHint: { show: false, weekday: 0, top: 0, height: 0, timeText: '' },
  },

  onLoad() {
    try {
      const info = (wx.getWindowInfo && wx.getWindowInfo()) || wx.getSystemInfoSync();
      this._ratio = (info.windowWidth || 375) / 750;
    } catch (e) { this._ratio = 0.5; }
    this._allItems = [];
    this._templates = [];
    this._base = 8; this._end = 19;
    this._scrollLeft = 0;
    this._edgeDir = 0;
    this._onChild = () => this.refresh();
    app.on && app.on('activeChildChanged', this._onChild);
    const tw = dateUtil.weekdayOf(Date.now());
    this.setData({ todayStr: dateUtil.todayStr(), todayWeekday: tw, selectedWeekday: tw });
  },
  onShow() {
    this.refresh();
    this.setData({ todayStr: dateUtil.todayStr() });
  },
  onUnload() {
    this._clearDragTimers();
    app.off && app.off('activeChildChanged', this._onChild);
  },

  async refresh() {
    this.setData({ loading: true });
    const childId = app.globalData.activeChildId;
    let items = [];
    let templates = [];
    if (childId) {
      [items, templates] = await Promise.all([
        db.scheduleItems.listAll(),
        db.courseTemplates.listAll(),
      ]);
    }
    const todayOff = dateUtil.markExcludedUuidsForDate(items);
    this._allItems = items.map((it) => Object.assign({}, it, { _todayOff: todayOff.has(it.uuid) }));
    this._templates = templates;
    this._buildViewModel();
    this._buildLibrary();
    this.setData({ loading: false });
    this._centerToday();
  },

  _buildLibrary() {
    const toChip = (t) => ({ templateId: t.uuid, name: t.name, type: t.type === 'school' ? 'school' : 'extra', color: colorOf(t) });
    const school = this._templates.filter((t) => t.type === 'school').map(toChip);
    const extra = this._templates.filter((t) => t.type !== 'school').map(toChip);
    this.setData({
      courseLib: { school, extra },
      hasTemplates: this._templates.length > 0,
    });
  },

  _buildViewModel() {
    const items = this._allItems || [];
    let base = 8, end = 19;
    items.forEach((it) => {
      base = Math.min(base, Math.floor(toMin(it.startTime) / 60));
      end = Math.max(end, Math.ceil(toMin(it.endTime) / 60));
    });
    base = clamp(base, 6, 8); end = clamp(end, 19, 22);
    this._base = base; this._end = end;
    const gridHeight = (end - base) * HOUR_H;
    const hours = [];
    for (let h = base; h < end; h++) hours.push({ label: `${h}:00`, top: (h - base) * HOUR_H });
    const lines = [];
    for (let h = base + 1; h < end; h++) lines.push((h - base) * HOUR_H);

    const weekDates = this._weekDates();
    const toEvent = (it) => {
      const s = toMin(it.startTime), e = toMin(it.endTime);
      return {
        uuid: it.uuid,
        courseName: it.courseName,
        type: it.type === 'school' ? 'school' : 'hobby',
        color: colorOf(it),
        startTime: it.startTime,
        endTime: it.endTime,
        startMin: s,
        durMin: Math.max(e - s, 15),
        weekday: Number(it.weekday),
        todayOff: !!it._todayOff,
        top: (s - base * 60) / 60 * HOUR_H,
        height: Math.max((e - s) / 60 * HOUR_H - 6, 44),
      };
    };

    const cols = [1, 2, 3, 4, 5, 6, 7].map((wd) => ({
      weekday: wd,
      wd: WEEKDAYS[wd - 1],
      dateLabel: weekDates[wd].dateLabel,
      isToday: weekDates[wd].isToday,
      events: items.filter((i) => Number(i.weekday) === wd)
        .sort((a, b) => toMin(a.startTime) - toMin(b.startTime))
        .map(toEvent),
    }));

    const weekTabs = [1, 2, 3, 4, 5, 6, 7].map((wd) => ({
      wd, label: WEEKDAYS[wd - 1], isToday: weekDates[wd].isToday,
    }));

    const selWd = this.data.selectedWeekday || this.data.todayWeekday || 1;
    const dayEvents = (cols[selWd - 1] || { events: [] }).events;

    this.setData({
      week: { cols, hours, lines, gridHeight },
      day: { events: dayEvents, hours, lines, gridHeight },
      weekTabs,
    });
  },

  _weekDates() {
    const now = new Date(); now.setHours(0, 0, 0, 0);
    const tw = dateUtil.weekdayOf(now.getTime());
    const monday = new Date(now.getTime() - (tw - 1) * 86400000);
    const todayTs = now.getTime();
    const out = {};
    for (let wd = 1; wd <= 7; wd++) {
      const d = new Date(monday.getTime() + (wd - 1) * 86400000);
      out[wd] = { dateLabel: `${d.getMonth() + 1}/${d.getDate()}`, isToday: d.getTime() === todayTs };
    }
    return out;
  },

  _centerToday() {
    if (this.data.viewMode !== 'week') return;
    const idx = (this.data.todayWeekday || 1) - 1;
    const ratio = this._ratio || 0.5;
    const centerRpx = TIME_W + idx * COL_W + COL_W / 2;
    const px = Math.max(0, centerRpx - 375) * ratio;
    this.setData({ scrollLeft: px });
  },

  onSwitchView(e) {
    const mode = e.currentTarget.dataset.mode;
    if (mode === this.data.viewMode) return;
    this.setData({ viewMode: mode });
    if (mode === 'week') setTimeout(() => this._centerToday(), 30);
  },
  onSelectDay(e) {
    const wd = Number(e.currentTarget.dataset.wd);
    const events = (this.data.week.cols[wd - 1] || { events: [] }).events;
    this.setData({ selectedWeekday: wd, 'day.events': events });
  },
  onWeekScroll(e) {
    this._scrollLeft = e.detail.scrollLeft;
  },

  // 课程库管理页入口
  goCourseLibrary() {
    if (auth.openLoginPage()) return;
    wx.navigateTo({ url: '/pages/schedule/course-library/index' });
  },

  // ==================== 课程库面板 & 拖拽 ====================
  toggleLibrary() {
    if (!this.data.showLibrary && auth.openLoginPage()) return;
    this.setData({ showLibrary: !this.data.showLibrary });
  },
  switchLibCategory(e) {
    this.setData({ libCategory: e.currentTarget.dataset.cat });
  },

  // —— 课程库 chip：长按拾起 → 拖入空白格新增 ——
  onChipTouchStart(e) {
    if (auth.openLoginPage()) return;
    const t = e.touches[0];
    const ds = e.currentTarget.dataset;
    this._pending = { mode: 'lib', name: ds.name, type: ds.type, color: ds.color, templateId: ds.tpl };
    this._lastXY = { x: t.clientX, y: t.clientY };
    this._moved = false;
    this._clearDragTimers();
    this._lpTimer = setTimeout(() => this._enterDrag(this._lastXY.x, this._lastXY.y), 150);
  },
  onChipTouchMove(e) { this._commonTouchMove(e); },
  onChipTouchEnd() { this._commonTouchEnd(); },

  // —— 课程块：拖动=调时间；长按=删除；点击=无 ——
  onBlockTouchStart(e) {
    const t = e.touches[0];
    const ds = e.currentTarget.dataset;
    const item = (this._allItems || []).find((i) => i.uuid === ds.uuid);
    if (!item) return;
    const s = toMin(item.startTime), en = toMin(item.endTime);
    this._pending = {
      mode: 'move', uuid: item.uuid, name: item.courseName,
      type: item.type === 'school' ? 'school' : 'extra', color: colorOf(item),
      durMin: Math.max(en - s, 15), weekday: Number(item.weekday),
    };
    this._lastXY = { x: t.clientX, y: t.clientY };
    this._moved = false;
    this._consumed = false;
    this._clearDragTimers();
    // 长按不动 → 删除确认
    this._lpTimer = setTimeout(() => {
      if (this.data.dragging || this._moved) return;
      this._consumed = true;
      this._confirmDeleteBlock(this._pending);
    }, LONGPRESS_MS);
  },
  onBlockTouchMove(e) { this._commonTouchMove(e); },
  onBlockTouchEnd() { this._commonTouchEnd(); },

  _commonTouchMove(e) {
    const t = e.touches[0];
    if (!t) return;
    const prev = this._lastXY || { x: t.clientX, y: t.clientY };
    if (Math.abs(t.clientX - prev.x) > 8 || Math.abs(t.clientY - prev.y) > 8) this._moved = true;
    this._lastXY = { x: t.clientX, y: t.clientY };
    if (this._consumed) return;
    if (!this.data.dragging) {
      if (this._moved) this._enterDrag(t.clientX, t.clientY);
      return;
    }
    this.setData({ 'dragGhost.x': t.clientX, 'dragGhost.y': t.clientY });
    this._updateEdgeScroll(t.clientX);
    this._updateDropHint(t.clientX, t.clientY);
  },
  _commonTouchEnd() {
    this._clearDragTimers();
    if (this.data.dragging) {
      const xy = this._lastXY;
      this._performDrop(xy.x, xy.y);
    }
    this._resetDrag();
  },

  _enterDrag(x, y) {
    if (this.data.dragging || this._consumed || !this._pending) return;
    if (this._lpTimer) { clearTimeout(this._lpTimer); this._lpTimer = null; }
    wx.vibrateShort && wx.vibrateShort({ type: 'light' });
    const p = this._pending;
    this._dragDur = p.mode === 'move' ? p.durMin : (DEFAULT_DUR[p.type] || 60);
    wx.createSelectorQuery().in(this).select('.week-scroll').boundingClientRect((r) => {
      this._scrollRect = r || null;
    }).exec();
    this.setData({
      dragging: true,
      dragGhost: { show: true, x, y, label: p.name, color: p.color },
    });
  },

  _updateEdgeScroll(x) {
    const r = this._scrollRect;
    if (!r) return;
    const EDGE = 44;
    let dir = 0;
    if (x < r.left + EDGE) dir = -1;
    else if (x > r.right - EDGE) dir = 1;
    if (dir === this._edgeDir) return;
    this._edgeDir = dir;
    if (this._edgeDwell) { clearTimeout(this._edgeDwell); this._edgeDwell = null; }
    this._stopAutoScroll();
    if (dir !== 0) this._edgeDwell = setTimeout(() => this._startAutoScroll(dir), 350);
  },
  _startAutoScroll(dir) {
    this._stopAutoScroll();
    const ratio = this._ratio || 0.5;
    const gridWidthPx = GRID_W_RPX * ratio;
    const viewport = (this._scrollRect && this._scrollRect.width) || (750 * ratio);
    const maxScroll = Math.max(0, gridWidthPx - viewport);
    this._autoTimer = setInterval(() => {
      let next = clamp((this._scrollLeft || 0) + dir * 60, 0, maxScroll);
      this._scrollLeft = next;
      this.setData({ scrollLeft: next });
    }, 100);
  },
  _stopAutoScroll() {
    if (this._autoTimer) { clearInterval(this._autoTimer); this._autoTimer = null; }
  },

  _updateDropHint(x, y) {
    wx.createSelectorQuery().in(this).selectAll('.daycol').boundingClientRect((rects) => {
      const hit = this._hitColumn(rects, x, y);
      if (!hit) { this.setData({ 'dropHint.show': false }); return; }
      const { minutes } = this._pointToTime(hit.rect, y);
      const dur = this._dragDur || 60;
      const startMin = this._base * 60 + minutes;
      this.setData({
        dropHint: {
          show: true, weekday: hit.weekday,
          top: minutes / 60 * HOUR_H, height: dur / 60 * HOUR_H,
          timeText: fmt(startMin),
        },
      });
    }).exec();
  },
  _hitColumn(rects, x, y) {
    if (!rects || !rects.length) return null;
    let col = rects.find((r) => x >= r.left && x <= r.right && y >= r.top && y <= r.bottom);
    if (!col) col = rects.find((r) => x >= r.left && x <= r.right);
    if (!col) return null;
    const wd = Number(col.dataset && col.dataset.weekday);
    if (!wd) return null;
    return { rect: col, weekday: wd };
  },
  _pointToTime(rect, y) {
    const ratio = this._ratio || 0.5;
    const hourPx = HOUR_H * ratio;
    const span = (this._end - this._base) * 60;
    let minutes = Math.round(((y - rect.top) / hourPx * 60) / SNAP_MIN) * SNAP_MIN;
    minutes = clamp(minutes, 0, span - SNAP_MIN);
    return { minutes, span };
  },

  _performDrop(x, y) {
    const p = this._pending;
    if (!p) return;
    wx.createSelectorQuery().in(this).selectAll('.daycol').boundingClientRect((rects) => {
      const hit = this._hitColumn(rects, x, y);
      if (!hit) {
        if (p.mode === 'lib') wx.showToast({ title: '拖到课表格子里松手即可添加', icon: 'none' });
        return;
      }
      const { minutes, span } = this._pointToTime(hit.rect, y);
      const base = this._base * 60;
      const dur = this._dragDur || DEFAULT_DUR[p.type] || 60;
      let startMin = base + minutes;
      let endMin = startMin + dur;
      if (endMin > base + span) { endMin = base + span; startMin = endMin - dur; }
      if (p.mode === 'lib') {
        this._createFromDrop(hit.weekday, p, fmt(startMin), fmt(endMin));
      } else {
        this._moveItemTo(p.uuid, hit.weekday, fmt(startMin), fmt(endMin));
      }
    }).exec();
  },

  _conflict(weekday, startTime, endTime, excludeUuid) {
    return (this._allItems || []).find((i) => {
      if (excludeUuid && i.uuid === excludeUuid) return false;
      if (Number(i.weekday) !== weekday) return false;
      return !(endTime <= i.startTime || startTime >= i.endTime);
    });
  },

  async _createFromDrop(weekday, chip, startTime, endTime) {
    if (this._conflict(weekday, startTime, endTime)) {
      wx.showToast({ title: `周${WEEKDAYS[weekday - 1]} ${startTime} 已有课，换个时间`, icon: 'none' });
      return;
    }
    wx.showLoading({ title: '添加中...', mask: true });
    try {
      await db.create(COL, {
        courseName: chip.name, type: chip.type, color: chip.color,
        templateId: chip.templateId || null,
        location: '', teacher: '', weekday, recurrence: 'weekly',
        startTime, endTime, startDate: null, endDate: null, excludedDates: [],
      });
      wx.hideLoading();
      wx.showToast({ title: `已加到周${WEEKDAYS[weekday - 1]} ${startTime}`, icon: 'none' });
      this.refresh();
    } catch (e) {
      wx.hideLoading();
      wx.showToast({ title: '添加失败', icon: 'none' });
    }
  },

  async _moveItemTo(uuid, weekday, startTime, endTime) {
    if (this._conflict(weekday, startTime, endTime, uuid)) {
      wx.showToast({ title: '该时段已有课，换个位置', icon: 'none' });
      return;
    }
    wx.showLoading({ title: '调整中...', mask: true });
    try {
      await db.scheduleItems.update(uuid, { weekday, startTime, endTime });
      wx.hideLoading();
      wx.showToast({ title: `已移到周${WEEKDAYS[weekday - 1]} ${startTime}`, icon: 'none' });
      this.refresh();
    } catch (e) {
      console.error('[schedule] 调整课程时间失败', e);
      wx.hideLoading();
      wx.showToast({ title: '调整失败', icon: 'none' });
    }
  },

  _confirmDeleteBlock(p) {
    wx.vibrateShort && wx.vibrateShort({ type: 'medium' });
    wx.showModal({
      title: '删除课程',
      content: `确认删除「${p.name}」这节课吗？`,
      confirmColor: '#e5702a',
      success: async (res) => {
        if (!res.confirm) return;
        try {
          await db.scheduleItems.remove(p.uuid);
          wx.showToast({ title: '已删除', icon: 'success' });
          this.refresh();
        } catch (e) {
          console.error('[schedule] 删除课程失败', e);
          wx.showToast({ title: '删除失败', icon: 'none' });
        }
      },
    });
  },

  _clearDragTimers() {
    if (this._lpTimer) { clearTimeout(this._lpTimer); this._lpTimer = null; }
    if (this._edgeDwell) { clearTimeout(this._edgeDwell); this._edgeDwell = null; }
    this._stopAutoScroll();
  },
  _resetDrag() {
    this._clearDragTimers();
    this._edgeDir = 0;
    this._pending = null;
    if (this.data.dragging || this.data.dragGhost.show || this.data.dropHint.show) {
      this.setData({ dragging: false, 'dragGhost.show': false, 'dropHint.show': false });
    }
  },
});
