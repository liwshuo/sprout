/// ISBN-10 / ISBN-13 格式与校验位校验（技术方案 §8.3）。
///
/// 关键：EAN-13 与 ISBN-13 校验位算法相同，必须靠 978/979 图书前缀区分书籍与
/// 食品/快递等非书籍条码，避免向书目 API 发无效请求。
bool isValidIsbn(String raw) {
  final s = raw.replaceAll(RegExp(r'[\s-]'), '');
  if (s.length == 13) {
    if (!RegExp(r'^\d{13}$').hasMatch(s)) return false;
    // 只有 978 / 979 前缀才是图书 EAN-13。
    if (!s.startsWith('978') && !s.startsWith('979')) return false;
    var sum = 0;
    for (var i = 0; i < 12; i++) {
      sum += int.parse(s[i]) * (i.isEven ? 1 : 3);
    }
    return (10 - sum % 10) % 10 == int.parse(s[12]);
  }
  if (s.length == 10) {
    if (!RegExp(r'^\d{9}[\dXx]$').hasMatch(s)) return false;
    var sum = 0;
    for (var i = 0; i < 9; i++) {
      sum += int.parse(s[i]) * (10 - i);
    }
    sum += (s[9].toUpperCase() == 'X') ? 10 : int.parse(s[9]);
    return sum % 11 == 0;
  }
  return false; // 长度非 10/13 → 非书籍条码
}

/// 归一化：去除空白与连字符，X 统一大写。
String normalizeIsbn(String raw) =>
    raw.replaceAll(RegExp(r'[\s-]'), '').toUpperCase();
