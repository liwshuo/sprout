import 'package:flutter_test/flutter_test.dart';
import 'package:sprout/core/scanner/isbn.dart';

void main() {
  group('isValidIsbn', () {
    test('合法 ISBN-13（978 前缀）', () {
      expect(isValidIsbn('9787115428028'), isTrue);
      expect(isValidIsbn('978-7-115-42802-8'), isTrue);
    });

    test('合法 ISBN-10（含校验位 X）', () {
      expect(isValidIsbn('020161622X'), isTrue);
    });

    test('非图书 EAN-13（无 978/979 前缀）应判非法', () {
      // 常见食品/快递条码前缀，即使校验位算法通过也必须拒绝
      expect(isValidIsbn('6901234567892'), isFalse);
    });

    test('校验位错误应判非法', () {
      expect(isValidIsbn('9787115428029'), isFalse);
    });

    test('长度非 10/13 应判非法', () {
      expect(isValidIsbn('12345'), isFalse);
    });
  });
}
