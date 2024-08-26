import 'package:code_scan_listener/code_scan_listener.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Test that onBarcodeScanned is working correctly',
      (tester) async {
    String? scannedBarcode;
    await tester.pumpWidget(CodeScanListener(
      child: Container(),
      onBarcodeScanned: (barcode) => scannedBarcode = barcode,
    ));
    await tester.sendKeyEvent(LogicalKeyboardKey.digit1);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);

    // check(scannedBarcode).equals('1');

    await tester.sendKeyEvent(LogicalKeyboardKey.digit2);
    await tester.sendKeyEvent(LogicalKeyboardKey.digit3);

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);

    // check(scannedBarcode).equals('23');

    await tester.sendKeyEvent(LogicalKeyboardKey.digit4);
    await tester.sendKeyEvent(LogicalKeyboardKey.digit5);

    // without enter
    // check(scannedBarcode).equals('23');
  });

  testWidgets('Tab suffix', (tester) async {
    String? scannedBarcode;
    await tester.pumpWidget(CodeScanListener(
      onBarcodeScanned: (barcode) => scannedBarcode = barcode,
      suffixType: SuffixType.tab,
      child: Container(),
    ));
    await tester.sendKeyEvent(LogicalKeyboardKey.digit1);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);

    expect(scannedBarcode, '1');

    await tester.sendKeyEvent(LogicalKeyboardKey.digit2);
    await tester.sendKeyEvent(LogicalKeyboardKey.digit3);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);

    expect(scannedBarcode, '23');

    await tester.sendKeyEvent(LogicalKeyboardKey.digit4);
    await tester.sendKeyEvent(LogicalKeyboardKey.digit5);

    // without tab
    expect(scannedBarcode, '23');
  });
}
