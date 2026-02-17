// ========================================
// Écran de connexion par PIN
// Permet aux utilisateurs de se connecter avec leur code PIN
// ========================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/manac_config_service.dart';
import '../theme/app_theme.dart';
import 'main_screen.dart';

class PinLoginScreen extends StatefulWidget {
  const PinLoginScreen({super.key});

  @override
  State<PinLoginScreen> createState() => _PinLoginScreenState();
}

class _PinLoginScreenState extends State<PinLoginScreen> {
  final List<String> _pinDigits = ['', '', '', ''];
  final List<TextEditingController> _controllers = List.generate(
    4,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());
  String _error = '';
  bool _isLoading = false;

  final ManacConfigService _configService = ManacConfigService();

  @override
  void initState() {
    super.initState();
    // Focus on first field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[0].requestFocus();
    });
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _onDigitChanged(int index, String value) {
    setState(() {
      _error = '';
    });

    if (value.isNotEmpty) {
      // Move to next field
      if (index < 3) {
        _focusNodes[index + 1].requestFocus();
      } else {
        // Last digit entered - verify PIN
        _verifyPin();
      }
    }
  }

  void _onKeyPress(int index, RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      // Handle backspace
      if (event.logicalKey == LogicalKeyboardKey.backspace) {
        if (_pinDigits[index].isEmpty && index > 0) {
          // Move to previous field
          _focusNodes[index - 1].requestFocus();
          _controllers[index - 1].clear();
          setState(() {
            _pinDigits[index - 1] = '';
          });
        }
      }
    }
  }

  void _verifyPin() {
    final enteredPin = _pinDigits.join();

    if (enteredPin.length != 4) {
      setState(() {
        _error = 'Veuillez entrer un code PIN complet';
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Verify PIN
    final isValid = _configService.verifyPinCode(enteredPin);

    if (isValid) {
      // Navigate to main screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainScreen()),
      );
    } else {
      setState(() {
        _error = 'Code PIN incorrect';
        _isLoading = false;
        // Clear all fields
        for (var controller in _controllers) {
          controller.clear();
        }
        _pinDigits.fillRange(0, 4, '');
        _focusNodes[0].requestFocus();
      });
    }
  }

  void _clearPin() {
    setState(() {
      for (var i = 0; i < 4; i++) {
        _pinDigits[i] = '';
        _controllers[i].clear();
      }
      _error = '';
      _focusNodes[0].requestFocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.orangeBlueGradient,
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lock_outline,
                      color: Colors.white,
                      size: 60,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Title
                  const Text(
                    'Connexion PIN',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Entrez votre code PIN à 4 chiffres',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // PIN Input
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(4, (index) {
                      return Container(
                        width: 60,
                        height: 70,
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        child: RawKeyboardListener(
                          focusNode: FocusNode(),
                          onKey: (event) => _onKeyPress(index, event),
                          child: TextField(
                            controller: _controllers[index],
                            focusNode: _focusNodes[index],
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                            maxLength: 1,
                            obscureText: true,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            decoration: InputDecoration(
                              counterText: '',
                              filled: true,
                              fillColor: Colors.white.withValues(alpha: 0.2),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: _error.isNotEmpty
                                      ? Colors.red
                                      : Colors.white.withValues(alpha: 0.5),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.white.withValues(alpha: 0.5),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            onChanged: (value) {
                              setState(() {
                                _pinDigits[index] = value;
                              });
                              _onDigitChanged(index, value);
                            },
                          ),
                        ),
                      );
                    }),
                  ),

                  // Error message
                  if (_error.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      _error,
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 14,
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),

                  // Loading indicator
                  if (_isLoading)
                    const CircularProgressIndicator(
                      color: Colors.white,
                    ),

                  const SizedBox(height: 24),

                  // Login with password button
                  TextButton(
                    onPressed: () {
                      // Go back to regular login
                      Navigator.of(context).pop();
                    },
                    child: Text(
                      'Se connecter avec un mot de passe',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
