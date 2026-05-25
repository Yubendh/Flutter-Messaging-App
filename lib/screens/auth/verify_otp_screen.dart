import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../constants/app_routes.dart';
import '../../providers/auth_provider.dart';
import '../../services/email_service.dart';
import '../../services/otp_service.dart';
import '../../theme/app_theme.dart';
import 'enter_new_password_screen.dart';
import 'reset_password_screen.dart';

class VerifyOtpScreen extends StatefulWidget {

  final String? initialUid;
  final String? initialEmail;
  final String? initialName;
  final OtpPurpose purpose;

  final bool autoSendOnLoad;

  const VerifyOtpScreen({
    super.key,
    this.initialUid,
    this.initialEmail,
    this.initialName,
    this.purpose = OtpPurpose.emailVerification,
    this.autoSendOnLoad = false,
  });

  @override
  State<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends State<VerifyOtpScreen> {
  final _otpService = OtpService();
  final _emailService = EmailService();

  late String _uid;
  late String _email;
  late String _name;

  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  bool _isLoading = true;
  bool _isVerifying = false;
  bool _isResending = false;
  String? _error;

  int _resendCooldown = 0;
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    _setup();

    for (int i = 1; i < 6; i++) {
      final idx = i;
      _focusNodes[idx].onKeyEvent = (node, event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.backspace &&
            _controllers[idx].text.isEmpty) {
          _focusNodes[idx - 1].requestFocus();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      };
    }
  }

  Future<void> _cancelEmailVerification() async {
    final nav = Navigator.of(context);
    final auth = context.read<AppAuthProvider>();
    await auth.logout();
    if (!mounted) return;
    nav.pushNamedAndRemoveUntil(AppRoutes.login, (r) => false);
  }

  Future<void> _setup() async {
    try {
      if (widget.autoSendOnLoad) {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) return;

        _uid = user.uid;
        _email = user.email ?? '';
        try {
          final doc = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
          _name = doc.data()?['displayName'] as String? ?? '';
        } catch (_) {
          _name = '';
        }
        await _sendOtp(startCooldown: true);
      } else {
        _uid = widget.initialUid ?? FirebaseAuth.instance.currentUser?.uid ?? '';
        _email = widget.initialEmail ?? '';
        _name = widget.initialName ?? '';
        _startCooldown();
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Could not send verification code. Please try again.';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        WidgetsBinding.instance
            .addPostFrameCallback((_) => _focusNodes[0].requestFocus());
      }
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) { c.dispose(); }
    for (final f in _focusNodes) { f.dispose(); }
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    _resendCooldown = 60;
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        _resendCooldown--;
        if (_resendCooldown <= 0) t.cancel();
      });
    });
  }

  String get _code => _controllers.map((c) => c.text).join();

  void _applyOtpFromIndex(int startIndex, String rawValue) {
    final digits = rawValue.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return;

    for (int j = 0; j < digits.length && (startIndex + j) < 6; j++) {
      _controllers[startIndex + j].text = digits[j];
    }

    final nextIndex = (startIndex + digits.length).clamp(0, 5);
    if (_code.length == 6) {
      FocusScope.of(context).unfocus();
    } else {
      _focusNodes[nextIndex].requestFocus();
    }
  }

  Future<void> _sendOtp({bool startCooldown = false}) async {
    final code = await _otpService.generateAndStore(_uid, widget.purpose);
    if (widget.purpose == OtpPurpose.emailVerification) {
      await _emailService.sendVerificationCode(
          toEmail: _email, name: _name, code: code);
    } else {
      await _emailService.sendPasswordResetCode(
          toEmail: _email, name: _name, code: code);
    }
    if (startCooldown && mounted) _startCooldown();
  }

  Future<void> _verify() async {
    if (_code.length < 6) {
      setState(() => _error = 'Please enter all 6 digits.');
      return;
    }
    setState(() {
      _isVerifying = true;
      _error = null;
    });

    final provider = context.read<AppAuthProvider>();
    final nav = Navigator.of(context);

    try {
      final ok = await _otpService.verify(_uid, _code, widget.purpose);
      if (!mounted) return;

      if (ok) {
        if (widget.purpose == OtpPurpose.emailVerification) {
          await provider.refreshEmailVerified();
          if (!mounted) return;
          nav.pushNamedAndRemoveUntil(AppRoutes.home, (r) => false);
        } else if (widget.purpose == OtpPurpose.changePassword) {
          if (!mounted) return;
          nav.pushReplacement(MaterialPageRoute(
            builder: (_) => EnterNewPasswordScreen(email: _email),
          ));
        } else {
          try {
            await FirebaseAuth.instance
                .sendPasswordResetEmail(email: _email);
          } catch (_) {}
          if (!mounted) return;
          nav.pushAndRemoveUntil(
            MaterialPageRoute(
                builder: (_) => ResetPasswordScreen(email: _email)),
            (r) => false,
          );
        }
      } else {
        for (final c in _controllers) { c.clear(); }
        _focusNodes[0].requestFocus();
        setState(() => _error = 'Invalid or expired code. Please try again.');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Verification failed. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  Future<void> _resend() async {
    setState(() {
      _isResending = true;
      _error = null;
    });
    try {
      await _sendOtp();
      if (mounted) {
        _startCooldown();
        for (final c in _controllers) { c.clear(); }
        _focusNodes[0].requestFocus();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('A new code has been sent to your email.'),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (mounted) setState(() => _error = 'Failed to resend. Please try again.');
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final isVerification = widget.purpose == OtpPurpose.emailVerification;
    final maskedEmail = _maskEmail(_email);

    return PopScope(
      canPop: !isVerification,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop && isVerification) {
          await _cancelEmailVerification();
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          elevation: 0,
          automaticallyImplyLeading: !isVerification,
          leading: isVerification
              ? null
              : IconButton(
                  icon: Icon(Icons.arrow_back),
                  onPressed: () => Navigator.pop(context),
                ),
        ),
        body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 24),

              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.mark_email_read_outlined,
                    color: AppTheme.primary, size: 40),
              ),
              const SizedBox(height: 28),

              Text(
                isVerification ? 'Verify your email' : 'Enter reset code',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),

              Text(
                'We sent a 6-digit code to\n$maskedEmail',
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  6,
                  (i) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: _OtpBox(
                      controller: _controllers[i],
                      focusNode: _focusNodes[i],
                      onInput: (val) {
                        setState(() => _error = null);
                        final digits = val.replaceAll(RegExp(r'\D'), '');

                        if (digits.length > 1) {
                          _applyOtpFromIndex(i, digits);
                          return;
                        }

                        if (digits.isNotEmpty && i < 5) {
                          _focusNodes[i + 1].requestFocus();
                        }
                      },
                    ),
                  ),
                ),
              ),

              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(
                  _error!,
                  style: TextStyle(color: Colors.red, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ],

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isVerifying ? null : _verify,
                  child: _isVerifying
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.5, color: Colors.white),
                        )
                      : Text('Verify Code',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 20),

              if (_resendCooldown > 0)
                Text(
                  'Resend code in ${_resendCooldown}s',
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                )
              else
                GestureDetector(
                  onTap: _isResending ? null : _resend,
                  child: _isResending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          "Didn't receive a code? Resend",
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.primaryLight,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),

              if (isVerification) ...[
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: _cancelEmailVerification,
                  child: Text(
                    'Sign out',
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
      ),
    );
  }

  static String _maskEmail(String email) {
    final parts = email.split('@');
    if (parts.length != 2) return email;
    final name = parts[0];
    final domain = parts[1];
    if (name.length <= 2) return email;
    return '${name[0]}${'*' * (name.length - 2)}${name[name.length - 1]}@$domain';
  }
}

class _OtpBox extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onInput;

  const _OtpBox({
    required this.controller,
    required this.focusNode,
    required this.onInput,
  });

  @override
  State<_OtpBox> createState() => _OtpBoxState();
}

class _OtpBoxState extends State<_OtpBox> {
  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() => setState(() {});

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocusChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasFocus = widget.focusNode.hasFocus;

    return SizedBox(
      width: 44,
      height: 54,
      child: TextField(
        controller: widget.controller,
        focusNode: widget.focusNode,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        textInputAction: TextInputAction.next,
        maxLength: 1,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onSurface,
        ),
        decoration: InputDecoration(
          counterText: '',
          isDense: true,
          filled: true,
          fillColor: Theme.of(context).colorScheme.surface,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppTheme.divider, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: hasFocus ? AppTheme.primary : AppTheme.divider,
              width: hasFocus ? 2 : 1,
            ),
          ),
        ),
        onChanged: widget.onInput,
      ),
    );
  }
}
