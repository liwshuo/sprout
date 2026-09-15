// utils/constants.js —— 与 Flutter 端对齐的展示令牌
// 分类色、心情 emoji、预置标签、书籍状态等，页面统一引用避免硬编码。

// 分类 → 主题色（日历圆点 / 记录卡片色条），对齐 app/lib/core/theme/app_colors.dart
const CATEGORY_COLORS = {
  日常: '#FF8C42',
  阅读: '#7ED9C3',
  课表: '#8FC7F0',
  运动: '#FF9EB5',
  才艺: '#B7A5F0',
  出行: '#8FC7F0',
  家务: '#7ED9C3',
  情绪: '#FF9EB5',
  里程碑: '#E5702A',
  其他: '#9A8F82',
};

const CATEGORIES = Object.keys(CATEGORY_COLORS);

function categoryColor(category) {
  return CATEGORY_COLORS[category] || '#FF8C42';
}

// 心情 emoji，对齐 Flutter moodEmoji
const MOOD_EMOJI = {
  happy: '😄',
  calm: '😊',
  excited: '🤩',
  tired: '😪',
  upset: '😣',
};

const MOODS = [
  { key: 'happy', emoji: '😄', label: '开心' },
  { key: 'calm', emoji: '😊', label: '平静' },
  { key: 'excited', emoji: '🤩', label: '兴奋' },
  { key: 'tired', emoji: '😪', label: '疲惫' },
  { key: 'upset', emoji: '😣', label: '难过' },
];

function moodEmoji(mood) {
  return MOOD_EMOJI[mood] || '';
}

// 书籍状态
const BOOK_STATUS = {
  want: { key: 'want', label: '想读' },
  reading: { key: 'reading', label: '在读' },
  done: { key: 'done', label: '读完' },
};

// 书型（决定打卡交互形态）：
//  picture = 绘本 / 短书  → 默认「读完整本」一键打卡（也支持读一部分）
//  chapter = 章节书       → 打卡时选「读到第几章」（含系列分册「读完这册」）
//  free    = 自由阅读     → 起始页自动带上次进度，只填结束页
// 兼容：历史书无 bookType 时按「有 totalChapters → chapter，否则 free」推断。
const BOOK_TYPES = {
  picture: { key: 'picture', label: '绘本' },
  chapter: { key: 'chapter', label: '章节书' },
  free: { key: 'free', label: '自由阅读' },
};

// 绘本/短书判定阈值：总页数 ≤ 此值可走「读完整本」一键打卡
const PICTURE_MAX_PAGES = 80;

const WEEKDAYS = ['一', '二', '三', '四', '五', '六', '日'];

// 日历事件四源 → 主题色（日历彩色圆点 / 事件卡片色条），对齐设计方案 P0-b
//  record   = 成长记录（暖橙）
//  schedule = 课表/课外班（天蓝）
//  todo     = 待办（丁香紫）
//  reading  = 阅读打卡（薄荷绿）
const EVENT_TYPE_COLORS = {
  record: '#FF8C42',
  schedule: '#8FC7F0',
  todo: '#B7A5F0',
  reading: '#7ED9C3',
};

// 事件类型中文名（卡片/图例用）
const EVENT_TYPE_LABELS = {
  record: '成长记录',
  schedule: '课外班',
  todo: '待办',
  reading: '阅读打卡',
};

function eventTypeColor(type) {
  return EVENT_TYPE_COLORS[type] || '#FF8C42';
}

module.exports = {
  CATEGORY_COLORS,
  CATEGORIES,
  categoryColor,
  MOOD_EMOJI,
  MOODS,
  moodEmoji,
  BOOK_STATUS,
  BOOK_TYPES,
  PICTURE_MAX_PAGES,
  WEEKDAYS,
  EVENT_TYPE_COLORS,
  EVENT_TYPE_LABELS,
  eventTypeColor,
};
