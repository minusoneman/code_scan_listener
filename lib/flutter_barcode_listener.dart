library flutter_barcode_listener;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

typedef BarcodeScannedCallback = void Function(String barcode);

/// 1秒
const Duration aSecond = Duration(seconds: 1);

/// 100ミリ秒
const Duration hundredMs = Duration(milliseconds: 100);

/// 改行文字
const String lineFeed = '\n';

/// This widget will listen for raw PHYSICAL keyboard events　even when other controls have primary focus.
/// It will buffer all characters coming in specifed `bufferDuration` time frame　that end with line feed character and call callback function with result.
/// Keep in mind this widget will listen for events even when not visible.
/// Windows seems to be using the [RawKeyDownEvent] instead of the [RawKeyUpEvent], this behaviour can be managed by setting [useKeyDownEvent].
///
/// このウィジェットは、他のコントロールが主フォーカスを持っているときでも、生の物理キーボードイベントをリッスンします。
/// 指定された `bufferDuration` 時間内に来る、改行文字で終わる全ての文字をバッファリングし、その結果でコールバック関数を呼び出します。
/// このウィジェットは、表示されていないときでもイベントをリッスンすることに留意してください。
/// Windowsは[RawKeyUpEvent]の代わりに[RawKeyDownEvent]を使っているようですが、この動作は[useKeyDownEvent]を設定することで管理することができます。
class BarcodeKeyboardListener extends StatefulWidget {
  final Widget child;
  final BarcodeScannedCallback onBarcodeScanned;
  final Duration bufferDuration;
  final bool useKeyDownEvent;

  /// This widget will listFren for raw PHYSICAL keyboard events　even when other controls have primary focus.
  /// It will buffer all characters coming in specifed `bufferDuration` time frame　that end with line feed character and call callback function with result.
  /// Keep in mind this widget will listen for events even when not visible.
  ///
  /// このウィジェットは、他のコントロールが主フォーカスを持っているときでも、生の物理キーボードイベントに対してリスンを行います。
  /// 指定された `bufferDuration` 時間内に来る、改行文字で終わる全ての文字をバッファリングし、その結果でコールバック関数を呼び出します。
  /// このウィジェットは、表示されていないときでもイベントをリッスンすることに留意してください。
  const BarcodeKeyboardListener(
      {super.key,

      /// Child widget to be displayed.
      required this.child,

      /// Callback to be called when barcode is scanned.
      required this.onBarcodeScanned,

      /// When experiencing issueswith empty barcodes on Windows,set this value to true. Default value is `false`.
      /// Windowsで空のバーコードの問題が発生した場合、この値をtrueに設定します。デフォルトは `false` です。
      this.useKeyDownEvent = false,

      /// Maximum time between two key events.
      /// If time between two key events is longer than this value
      /// previous keys will be ignored.
      ///
      /// 2つのキーイベント間の最大時間。
      /// 2つのキーイベント間の時間がこの値より長い場合、以前のキーは無視されます。
      this.bufferDuration = hundredMs});

  @override
  State<BarcodeKeyboardListener> createState() =>
      _BarcodeKeyboardListenerState();
}

class _BarcodeKeyboardListenerState extends State<BarcodeKeyboardListener> {
  List<String> _scannedChars = [];
  DateTime? _lastScannedCharCodeTime;
  late StreamSubscription<String?> _keyboardSubscription;

  late final BarcodeScannedCallback _onBarcodeScannedCallback =
      widget.onBarcodeScanned;
  late final Duration _bufferDuration = widget.bufferDuration;

  final _controller = StreamController<String?>();

  late final bool _useKeyDownEvent = widget.useKeyDownEvent;

  @override
  void initState() {
    RawKeyboard.instance.addListener(_keyBoardCallback);
    _keyboardSubscription =
        _controller.stream.where((char) => char != null).listen(onKeyEvent);
    super.initState();
  }

  void onKeyEvent(String? char) {
    // remove any pending characters older than bufferDuration value
    // bufferDurationの値より古い保留文字を削除する。
    checkPendingCharCodesToClear();
    _lastScannedCharCodeTime = DateTime.now();
    if (char == lineFeed) {
      _onBarcodeScannedCallback.call(_scannedChars.join());
      resetScannedCharCodes();
    } else {
      // add character to list of scanned characters;
      // スキャンされた文字のリストに文字を追加する；

      _scannedChars.add(char!);
    }
  }

  void checkPendingCharCodesToClear() {
    if (_lastScannedCharCodeTime != null) {
      if (_lastScannedCharCodeTime!
          .isBefore(DateTime.now().subtract(_bufferDuration))) {
        resetScannedCharCodes();
      }
    }
  }

  void resetScannedCharCodes() {
    _lastScannedCharCodeTime = null;
    _scannedChars = [];
  }

  void addScannedCharCode(String charCode) {
    _scannedChars.add(charCode);
  }

  void _keyBoardCallback(RawKeyEvent keyEvent) {
    if (keyEvent.logicalKey.keyId > 255 &&
        keyEvent.data.logicalKey != LogicalKeyboardKey.enter) return;
    if ((!_useKeyDownEvent && keyEvent is RawKeyUpEvent) ||
        (_useKeyDownEvent && keyEvent is RawKeyDownEvent)) {
      if (keyEvent.data is RawKeyEventDataAndroid) {
        _controller.sink.add(String.fromCharCode(
            ((keyEvent.data) as RawKeyEventDataAndroid).codePoint));
      } else if (keyEvent.data is RawKeyEventDataFuchsia) {
        _controller.sink.add(String.fromCharCode(
            ((keyEvent.data) as RawKeyEventDataFuchsia).codePoint));
      } else if (keyEvent.data.logicalKey == LogicalKeyboardKey.enter) {
        _controller.sink.add(lineFeed);
      } else if (keyEvent.data is RawKeyEventDataWeb) {
        _controller.sink.add(((keyEvent.data) as RawKeyEventDataWeb).keyLabel);
      } else if (keyEvent.data is RawKeyEventDataLinux) {
        _controller.sink
            .add(((keyEvent.data) as RawKeyEventDataLinux).keyLabel);
      } else if (keyEvent.data is RawKeyEventDataWindows) {
        _controller.sink.add(String.fromCharCode(
            ((keyEvent.data) as RawKeyEventDataWindows).keyCode));
      } else if (keyEvent.data is RawKeyEventDataMacOs) {
        _controller.sink
            .add(((keyEvent.data) as RawKeyEventDataMacOs).characters);
      } else if (keyEvent.data is RawKeyEventDataIos) {
        _controller.sink
            .add(((keyEvent.data) as RawKeyEventDataIos).characters);
      } else {
        _controller.sink.add(keyEvent.character);
      }
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;

  @override
  void dispose() {
    _keyboardSubscription.cancel();
    _controller.close();
    RawKeyboard.instance.removeListener(_keyBoardCallback);
    super.dispose();
  }
}
