import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class EnterNewPasswordScreen extends StatefulWidget {
  final String email;

  const EnterNewPasswordScreen({super.key, required this.email});

  @override
  State<EnterNewPasswordScreen> createState() => _EnterNewPasswordScreenState();
}

class _EnterNewPasswordScreenState extends State<EnterNewPasswordScreen> {
  final _newPassCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _newPassCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  String? _validate() {
    final newPass = _newPassCtrl.text;
    final confirm = _confirmCtrl.text;
    if (newPass.isEmpty || confirm.isEmpty) return 'Please fill in both fields.';
    if (newPass.length < 8) return 'Password must be at least 8 characters.';
    if (newPass != confirm) return 'Passwords do not match.';
    return null;
  }

  Future<void> _submit() async {
    final validationError = _validate();
    if (validationError != null) {
      setState(() => _error = validationError);
      return;
    }

    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final newPassword = _newPassCtrl.text;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await FirebaseAuth.instance.currentUser!.updatePassword(newPassword);
      if (!mounted) return;
      nav.pop();
      messenger.showSnackBar(const SnackBar(
        content: Text('Password updated successfully.'),
        behavior: SnackBarBehavior.floating,
      ));
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      if (e.code == 'requires-recent-login') {
        await _reAuthAndRetry(newPassword, nav, messenger);
      } else {
        setState(() => _error = e.message ?? 'Failed to update password.');
      }
    } catch (_) {
      if (mounted) setState(() => _error = 'Failed to update password. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _reAuthAndRetry(
    String newPassword,
    NavigatorState nav,
    ScaffoldMessengerState messenger,
  ) async {
    final currentPassCtrl = TextEditingController();
    String? dialogError;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: Theme.of(ctx).colorScheme.surface,
          title: Text('Confirm your identity',
              style: TextStyle(color: Theme.of(ctx).colorScheme.onSurface)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'For security, please enter your current password to continue.',
                style: TextStyle(
                    color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                    fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: currentPassCtrl,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Current password',
                  filled: true,
                  fillColor: Theme.of(ctx).scaffoldBackgroundColor,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none),
                  errorText: dialogError,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Cancel',
                  style: TextStyle(
                      color: Theme.of(ctx).colorScheme.onSurfaceVariant)),
            ),
            ElevatedButton(
              onPressed: () async {
                final credential = EmailAuthProvider.credential(
                  email: widget.email,
                  password: currentPassCtrl.text,
                );
                try {
                  await FirebaseAuth.instance.currentUser!
                      .reauthenticateWithCredential(credential);
                  if (ctx.mounted) Navigator.pop(ctx, true);
                } on FirebaseAuthException catch (_) {
                  setDialogState(() => dialogError = 'Incorrect password. Try again.');
                }
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white),
              child: const Text('Confirm'),
            ),
          ],
        ),
      ),
    );

    currentPassCtrl.dispose();
    if (confirmed != true || !mounted) return;

    try {
      await FirebaseAuth.instance.currentUser!.updatePassword(newPassword);
      if (!mounted) return;
      nav.pop();
      messenger.showSnackBar(const SnackBar(
        content: Text('Password updated successfully.'),
        behavior: SnackBarBehavior.floating,
      ));
    } catch (_) {
      if (mounted) setState(() => _error = 'Failed to update password. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0.5,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppTheme.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Change Password',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.lock_outline, color: AppTheme.primary, size: 32),
              ),
              const SizedBox(height: 24),
              Text('Set a new password',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface)),
              const SizedBox(height: 8),
              Text('Must be at least 8 characters.',
                  style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurfaceVariant)),
              const SizedBox(height: 32),
              TextField(
                controller: _newPassCtrl,
                obscureText: _obscureNew,
                onChanged: (_) => setState(() => _error = null),
                decoration: InputDecoration(
                  labelText: 'New password',
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                  suffixIcon: IconButton(
                    icon: Icon(
                        _obscureNew ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: Theme.of(context).colorScheme.onSurfaceVariant),
                    onPressed: () => setState(() => _obscureNew = !_obscureNew),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _confirmCtrl,
                obscureText: _obscureConfirm,
                onChanged: (_) => setState(() => _error = null),
                decoration: InputDecoration(
                  labelText: 'Confirm new password',
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                  suffixIcon: IconButton(
                    icon: Icon(
                        _obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: Theme.of(context).colorScheme.onSurfaceVariant),
                    onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!,
                    style: const TextStyle(color: AppTheme.error, fontSize: 13)),
              ],
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.5, color: Colors.white),
                        )
                      : const Text('Update Password',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
