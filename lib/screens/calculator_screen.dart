import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/stealth_provider.dart';
import '../providers/journey_provider.dart';

class CalculatorScreen extends ConsumerStatefulWidget {
  const CalculatorScreen({super.key});

  @override
  ConsumerState<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends ConsumerState<CalculatorScreen> {
  String _display = '0';
  String _typedSequence = '';
  double? _operand1;
  String? _operator;
  bool _shouldResetDisplay = false;

  void _onDigitPressed(String digit) {
    setState(() {
      _typedSequence += digit;
      if (_display == '0' || _shouldResetDisplay) {
        _display = digit;
        _shouldResetDisplay = false;
      } else {
        if (_display.length < 10) {
          _display += digit;
        }
      }
    });
  }

  void _onDecimalPressed() {
    setState(() {
      _typedSequence += '.';
      if (_shouldResetDisplay) {
        _display = '0.';
        _shouldResetDisplay = false;
      } else if (!_display.contains('.')) {
        _display += '.';
      }
    });
  }

  void _onOperatorPressed(String op) {
    setState(() {
      _typedSequence += op;
      _operand1 = double.tryParse(_display);
      _operator = op;
      _shouldResetDisplay = true;
    });
  }

  void _onClearPressed() {
    setState(() {
      _display = '0';
      _typedSequence = '';
      _operand1 = null;
      _operator = null;
      _shouldResetDisplay = false;
    });
  }

  void _onToggleSignPressed() {
    setState(() {
      if (_display != '0') {
        if (_display.startsWith('-')) {
          _display = _display.substring(1);
        } else {
          _display = '-$_display';
        }
      }
    });
  }

  void _onPercentPressed() {
    setState(() {
      final val = double.tryParse(_display);
      if (val != null) {
        final res = val / 100.0;
        _display = _formatResult(res);
      }
    });
  }

  void _onEqualsPressed() {
    // 1. Check Secret Codes in typed digits sequence
    final digitsOnly = _typedSequence.replaceAll(RegExp(r'[^0-9]'), '');

    if (digitsOnly.endsWith(StealthCodes.unlockCode)) {
      // Return to real Gekko app UI
      _typedSequence = '';
      ref.read(stealthProvider.notifier).disableStealth();
      return;
    }

    if (digitsOnly.endsWith(StealthCodes.panicCode)) {
      // Silent Emergency Panic Trigger (No visual UI change!)
      _typedSequence = '';
      ref.read(journeyProvider.notifier).triggerSOS(
            triggerSource: 'Silent Disguise Panic Code (911)',
          );
      // Fall through to compute math or keep display without alerting user
    }

    // 2. Perform normal arithmetic
    if (_operand1 != null && _operator != null) {
      final operand2 = double.tryParse(_display) ?? 0.0;
      double result = 0.0;

      switch (_operator) {
        case '+':
          result = _operand1! + operand2;
          break;
        case '-':
          result = _operand1! - operand2;
          break;
        case '×':
          result = _operand1! * operand2;
          break;
        case '÷':
          result = operand2 != 0 ? _operand1! / operand2 : double.nan;
          break;
      }

      setState(() {
        _display = _formatResult(result);
        _operand1 = null;
        _operator = null;
        _shouldResetDisplay = true;
        _typedSequence = '';
      });
    }
  }

  String _formatResult(double val) {
    if (val.isNaN || val.isInfinite) return 'Error';
    if (val == val.toInt().toDouble()) {
      return val.toInt().toString();
    }
    // Limit decimal places for display
    String str = val.toStringAsFixed(4);
    while (str.contains('.') && (str.endsWith('0') || str.endsWith('.'))) {
      str = str.substring(0, str.length - 1);
    }
    return str;
  }

  Widget _buildButton({
    required String text,
    required Color bgColor,
    required Color textColor,
    required VoidCallback onTap,
    int flex = 1,
  }) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.all(6.0),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(40),
          child: Container(
            decoration: BoxDecoration(
              color: bgColor,
              shape: flex == 1 ? BoxShape.circle : BoxShape.rectangle,
              borderRadius: flex > 1 ? BorderRadius.circular(40) : null,
            ),
            child: Center(
              child: Text(
                text,
                style: TextStyle(
                  color: textColor,
                  fontSize: 28,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Roboto',
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFF000000);
    const lightGray = Color(0xFFA5A5A5);
    const darkGray = Color(0xFF333333);
    const orange = Color(0xFFFF9F0A);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // Display Area
            Expanded(
              child: Container(
                alignment: Alignment.bottomRight,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    _display,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 72,
                      fontWeight: FontWeight.w300,
                      fontFamily: 'Roboto',
                    ),
                  ),
                ),
              ),
            ),

            // Keypad
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Column(
                children: [
                  // Row 1
                  Row(
                    children: [
                      _buildButton(
                        text: 'AC',
                        bgColor: lightGray,
                        textColor: Colors.black,
                        onTap: _onClearPressed,
                      ),
                      _buildButton(
                        text: '±',
                        bgColor: lightGray,
                        textColor: Colors.black,
                        onTap: _onToggleSignPressed,
                      ),
                      _buildButton(
                        text: '%',
                        bgColor: lightGray,
                        textColor: Colors.black,
                        onTap: _onPercentPressed,
                      ),
                      _buildButton(
                        text: '÷',
                        bgColor: orange,
                        textColor: Colors.white,
                        onTap: () => _onOperatorPressed('÷'),
                      ),
                    ],
                  ),

                  // Row 2
                  Row(
                    children: [
                      _buildButton(
                        text: '7',
                        bgColor: darkGray,
                        textColor: Colors.white,
                        onTap: () => _onDigitPressed('7'),
                      ),
                      _buildButton(
                        text: '8',
                        bgColor: darkGray,
                        textColor: Colors.white,
                        onTap: () => _onDigitPressed('8'),
                      ),
                      _buildButton(
                        text: '9',
                        bgColor: darkGray,
                        textColor: Colors.white,
                        onTap: () => _onDigitPressed('9'),
                      ),
                      _buildButton(
                        text: '×',
                        bgColor: orange,
                        textColor: Colors.white,
                        onTap: () => _onOperatorPressed('×'),
                      ),
                    ],
                  ),

                  // Row 3
                  Row(
                    children: [
                      _buildButton(
                        text: '4',
                        bgColor: darkGray,
                        textColor: Colors.white,
                        onTap: () => _onDigitPressed('4'),
                      ),
                      _buildButton(
                        text: '5',
                        bgColor: darkGray,
                        textColor: Colors.white,
                        onTap: () => _onDigitPressed('5'),
                      ),
                      _buildButton(
                        text: '6',
                        bgColor: darkGray,
                        textColor: Colors.white,
                        onTap: () => _onDigitPressed('6'),
                      ),
                      _buildButton(
                        text: '-',
                        bgColor: orange,
                        textColor: Colors.white,
                        onTap: () => _onOperatorPressed('-'),
                      ),
                    ],
                  ),

                  // Row 4
                  Row(
                    children: [
                      _buildButton(
                        text: '1',
                        bgColor: darkGray,
                        textColor: Colors.white,
                        onTap: () => _onDigitPressed('1'),
                      ),
                      _buildButton(
                        text: '2',
                        bgColor: darkGray,
                        textColor: Colors.white,
                        onTap: () => _onDigitPressed('2'),
                      ),
                      _buildButton(
                        text: '3',
                        bgColor: darkGray,
                        textColor: Colors.white,
                        onTap: () => _onDigitPressed('3'),
                      ),
                      _buildButton(
                        text: '+',
                        bgColor: orange,
                        textColor: Colors.white,
                        onTap: () => _onOperatorPressed('+'),
                      ),
                    ],
                  ),

                  // Row 5
                  Row(
                    children: [
                      _buildButton(
                        text: '0',
                        bgColor: darkGray,
                        textColor: Colors.white,
                        flex: 2,
                        onTap: () => _onDigitPressed('0'),
                      ),
                      _buildButton(
                        text: '.',
                        bgColor: darkGray,
                        textColor: Colors.white,
                        onTap: _onDecimalPressed,
                      ),
                      _buildButton(
                        text: '=',
                        bgColor: orange,
                        textColor: Colors.white,
                        onTap: _onEqualsPressed,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
