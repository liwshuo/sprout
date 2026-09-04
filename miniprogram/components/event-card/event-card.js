// components/event-card/event-card.js —— 可复用事件卡片
// 支持 type = record（成长记录）/ schedule（课外班·校内课）/ reading（阅读打卡）三种样式，
// 由传入的 CalendarEvent（见 services/calendar-service.js）驱动，卡片按类型分色。
Component({
  properties: {
    // CalendarEvent 结构，至少含 { type, title, subtitle, time, color, typeLabel }
    event: {
      type: Object,
      value: {},
    },
    // 是否显示右上角类型标签
    showTag: {
      type: Boolean,
      value: true,
    },
  },
});
