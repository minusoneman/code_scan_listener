library;

import 'dart:async';
import 'dart:io';

import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rxdart/rxdart.dart';

typedef BarcodeScannedCallback = void Function(String barcode);

const Duration _hundredMs = Duration(milliseconds: 100);

enum SuffixType { enter, tab }

/// This widget will listen for raw PHYSICAL keyboard events　even when other controls have primary focus.
/// It will buffer all characters coming in specifed `bufferDuration` time frame　that end with line feed character and call callback function with result.
/// Keep in mind this widget will listen for events even when not visible.
/// Windows seems to be using the [KeyDownEvent] instead of the [KeyUpEvent], this behaviour can be managed by setting [useKeyDownEvent].
class CodeScanListener extends StatefulWidget {
  final Widget child;
  final BarcodeScannedCallback? onBarcodeScanned;
  final Duration bufferDuration;
  final bool useKeyDownEvent;
  final SuffixType suffixType;

  /// This widget will listFren for raw PHYSICAL keyboard events　even when other controls have primary focus.
  /// It will buffer all characters coming in specifed `bufferDuration` time frame　that end with line feed character and call callback function with result.
  /// Keep in mind this widget will listen for events even when not visible.
  const CodeScanListener({
    super.key,

    /// Child widget to be displayed.
    required this.child,

    /// Callback to be called when barcode is scanned.
    required this.onBarcodeScanned,

    /// When experiencing issueswith empty barcodes on Windows,set this value to true. Default value is `false`.
    this.useKeyDownEvent = false,

    /// Maximum time between two key events.
    /// If time between two key events is longer than this value
    /// previous keys will be ignored.
    this.bufferDuration = _hundredMs,

    /// detect suffix type
    this.suffixType = SuffixType.enter,
  });

  @override
  State<CodeScanListener> createState() => _CodeScanListenerState();
}

const keyMap = {
  '/': '/',
  '0': '0',
  '1': '1',
  '2': '2',
  '3': '3',
  '4': '4',
  '5': '5',
  '6': '6',
  '7': '7',
  '8': '8',
  '9': '9',
  'A': 'A',
  'B': 'B',
  'C': 'C',
  'D': 'D',
  'E': 'E',
  'F': 'F',
  'G': 'G',
  'H': 'H',
  'I': 'I',
  'J': 'J',
  'K': 'K',
  'L': 'L',
  'M': 'M',
  'N': 'N',
  'O': 'O',
  'P': 'P',
  'Q': 'Q',
  'R': 'R',
  'S': 'S',
  'T': 'T',
  'U': 'U',
  'V': 'V',
  'W': 'W',
  'X': 'X',
  'Y': 'Y',
  'Z': 'Z',
  '-': '-',
  '.': '.',
  '+': '+',
  '=': '+',
  'Minus': '-',
  'Numpad Subtract': '-',
  'Numpad Add': '+',
  'Equal': '+',
};

const Map<int, String> _debugNames = <int, String>{
  0x00070004: 'A',
  0x00070005: 'B',
  0x00070006: 'C',
  0x00070007: 'D',
  0x00070008: 'E',
  0x00070009: 'F',
  0x0007000a: 'G',
  0x0007000b: 'H',
  0x0007000c: 'I',
  0x0007000d: 'J',
  0x0007000e: 'K',
  0x0007000f: 'L',
  0x00070010: 'M',
  0x00070011: 'N',
  0x00070012: 'O',
  0x00070013: 'P',
  0x00070014: 'Q',
  0x00070015: 'R',
  0x00070016: 'S',
  0x00070017: 'T',
  0x00070018: 'U',
  0x00070019: 'V',
  0x0007001a: 'W',
  0x0007001b: 'X',
  0x0007001c: 'Y',
  0x0007001d: 'Z',
  0x0007001e: '1',
  0x0007001f: '2',
  0x00070020: '3',
  0x00070021: '4',
  0x00070022: '5',
  0x00070023: '6',
  0x00070024: '7',
  0x00070025: '8',
  0x00070026: '9',
  0x00070027: '0',
  0x00070028: 'Enter',
  0x00070029: 'Escape',
  0x0007002a: 'Backspace',
  0x0007002b: 'Tab',
  0x0007002c: 'Space',
  0x0007002d: '-',
  0x0007002e: 'Equal',
  0x0007002f: 'Bracket Left',
  0x00070030: 'Bracket Right',
  0x00070031: 'Backslash',
  0x00070033: 'Semicolon',
  0x00070034: 'Quote',
  0x00070035: 'Backquote',
  0x00070036: 'Comma',
  0x00070037: 'Period',
  0x00070038: '/',
  0x00070039: 'Caps Lock',
  0x00070054: 'Numpad Divide',
  0x00070055: 'Numpad Multiply',
  0x00070056: '-',
  0x00070057: '+',
  0x00070058: 'Numpad Enter',
  0x00070059: '1',
  0x0007005a: '2',
  0x0007005b: '3',
  0x0007005c: '4',
  0x0007005d: '5',
  0x0007005e: '6',
  0x0007005f: '7',
  0x00070060: '8',
  0x00070061: '9',
  0x00070062: '0',
  0x00070063: 'Numpad Decimal',
  0x00070064: 'Intl Backslash',
  0x00070067: '+', //'Numpad Equal',
};

class _CodeScanListenerState extends State<CodeScanListener> {
  late final suffixKey = switch (widget.suffixType) {
    SuffixType.enter => LogicalKeyboardKey.enter,
    SuffixType.tab => LogicalKeyboardKey.tab,
  };

  late final suffix = switch (widget.suffixType) {
    SuffixType.enter => '\n',
    SuffixType.tab => '\t',
  };

  final List<String> _scannedChars = [];
  final _controller = StreamController<String?>();
  late StreamSubscription<String?> _keyboardSubscription;

  DateTime? _lastScannedCharCodeTime;

  bool _keyBoardCallback(KeyEvent keyEvent) {
    // Duration? prevDuration;
    //
    // final duration = keyEvent.timeStamp;
    //
    // /// Avoid repeated key presse - specifically on Sunmi scanners
    // if (prevDuration == duration) {
    //   return false;
    // }
    //
    // prevDuration = duration;

    if (keyEvent is! KeyDownEvent) {
      return (Platform.isAndroid || Platform.isIOS);
    }

    // final test = HardwareKeyboard.instance.physicalKeysPressed;
    //
    // print(test);

    // print("timestamp: ${keyEvent.timeStamp}");
    // print("keyId: ${upEvent.physicalKey.usbHidUsage}");

    // print("logicalKey: ${upEvent.deviceType}");
    // print("char: ${upEvent.character}");

    // print(keyEvent);

    final key = keyMap[keyEvent.logicalKey.keyLabel] ??
        _debugNames[keyEvent.physicalKey.usbHidUsage];

    if (keyEvent.logicalKey == suffixKey) {
      _controller.sink.add(suffix);
    } else if (key != null) {
      // print("key: $key");
      _controller.sink.add(key);
    }

    return (Platform.isIOS || Platform.isAndroid);
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
    if (char == suffix) {
      widget.onBarcodeScanned?.call(_scannedChars.join());
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
