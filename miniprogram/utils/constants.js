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

const WEEKDAYS = ['一', '二', '三', '四', '五', '六', '日'];

module.exports = {
  CATEGORY_COLORS,
  CATEGORIES,
  categoryColor,
  MOOD_EMOJI,
  MOODS,
  moodEmoji,
  BOOK_STATUS,
  WEEKDAYS,
};
