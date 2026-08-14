import 'package:flutter/material.dart';

import '../utils/app_lock.dart';

class PinLockScreen extends StatefulWidget {
  final VoidCallback onUnlocked;

  const PinLockScreen({super.key, required this.onUnlocked});

  @override
  State<PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends State<PinLockScreen> {
  final pinController = TextEditingController();
  String? errorText;

  @override
  void dispose() {
    pinController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final correct = await AppLock.verifyPin(pinController.text.trim());

    if (!mounted) return;

    if (correct) {
      widget.onUnlocked();
      return;
    }

    setState(() {
      errorText = 'Incorrect PIN';
    });

    pinController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F6),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🔒', style: TextStyle(fontSize: 48)),

              const SizedBox(height: 16),

              const Text(
                'MyXpenses is Locked',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF292323),
                ),
              ),

              const SizedBox(height: 6),

              const Text(
                'Enter your PIN to continue',
                style: TextStyle(fontSize: 13, color: Color(0xFF8B8583)),
              ),

              const SizedBox(height: 24),

              TextField(
                controller: pinController,
                obscureText: true,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 6,
                autofocus: true,
                style: const TextStyle(fontSize: 24, letterSpacing: 8),
                decoration: InputDecoration(
                  counterText: '',
                  errorText: errorText,
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: (_) => _submit(),
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF277765),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: const Text(
                    'Unlock',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
