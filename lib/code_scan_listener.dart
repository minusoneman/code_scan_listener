library;

import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rxdart/rxdart.dart';

typedef BarcodeScannedCallback = void Function(String barcode);

const Duration _hundredMs = Duration(milliseconds: 100);

const String _lineFeed = '\n';

/// This widget will listen for raw PHYSICAL keyboard events　even when other controls have primary focus.
/// It will buffer all characters coming in specifed `bufferDuration` time frame　that end with line feed character and call callback function with result.
/// Keep in mind this widget will listen for events even when not visible.
/// Windows seems to be using the [KeyDownEvent] instead of the [KeyUpEvent], this behaviour can be managed by setting [useKeyDownEvent].
class CodeScanListener extends StatefulWidget {
  final Widget child;
  final BarcodeScannedCallback onBarcodeScanned;
  final Duration bufferDuration;
  final bool useKeyDownEvent;

  /// This widget will listFren for raw PHYSICAL keyboard events　even when other controls have primary focus.
  /// It will buffer all characters coming in specifed `bufferDuration` time frame　that end with line feed character and call callback function with result.
  /// Keep in mind this widget will listen for events even when not visible.
  const CodeScanListener(
      {super.key,

      /// Child widget to be displayed.
      required this.child,

      /// Callback to be called when barcode is scanned.
      required this.onBarcodeScanned,

      /// When experiencing issueswith empty barcodes on Windows,set this value to true. Default value is `false`.
      this.useKeyDownEvent = false,

      /// Maximum time between two key events.
      /// If time between two key events is longer than this value
      /// previous keys will be ignored.
      this.bufferDuration = _hundredMs});

  @override
  State<CodeScanListener> createState() => _CodeScanListenerState();
}

class _CodeScanListenerState extends State<CodeScanListener> {
  final List<String> _scannedChars = [];
  final _controller = StreamController<String?>();
  late StreamSubscription<String?> _keyboardSubscription;

  DateTime? _lastScannedCharCodeTime;

  bool _keyBoardCallback(KeyEvent keyEvent) {
    switch ((keyEvent, widget.useKeyDownEvent)) {
      case (KeyEvent(logicalKey: final key), _)
          when key.keyId > 255 && key != LogicalKeyboardKey.enter:
        return false;
      case (KeyUpEvent(logicalKey: LogicalKeyboardKey.enter), false):
        _controller.sink.add(_lineFeed);
        return false;

      case (final KeyUpEvent event, false):
        _controller.sink.add(event.logicalKey.keyLabel);
        return false;

      case (KeyDownEvent(logicalKey: LogicalKeyboardKey.enter), true):
        _controller.sink.add(_lineFeed);
        return false;

      case (final KeyDownEvent event, true):
        _controller.sink.add(event.logicalKey.keyLabel);
        return false;
    }

    return false;
  }

  @override
  void initState() {
    HardwareKeyboard.instance.addHandler(_keyBoardCallback);
    _keyboardSubscription =
        _controller.stream.whereNotNull().listen(onKeyEvent);
    super.initState();
  }

  void onKeyEvent(String char) {
    // remove any pending characters older than bufferDuration value
    checkPendingCharCodesToClear();
    _lastScannedCharCodeTime = clock.now();
    if (char == _lineFeed) {
      widget.onBarcodeScanned.call(_scannedChars.join());
      resetScannedCharCodes();
    } else {
      // add character to list of scanned characters;
      _scannedChars.add(char);
    }
  }

  void checkPendingCharCodesToClear() {
    if (_lastScannedCharCodeTime case final lastScanned?
        when lastScanned
            .isBefore(clock.now().subtract(widget.bufferDuration))) {
      resetScannedCharCodes();
    }
  }

  void resetScannedCharCodes() {
    _lastScannedCharCodeTime = null;
    _scannedChars.clear();
  }

  void addScannedCharCode(String charCode) => _scannedChars.add(charCode);

  @override
  Widget build(BuildContext context) => widget.child;

  @override
  void dispose() {
    _keyboardSubscription.cancel();
    _controller.close();
    HardwareKeyboard.instance.removeHandler(_keyBoardCallback);
    super.dispose();
  }
}
