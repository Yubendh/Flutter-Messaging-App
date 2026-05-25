import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/verify_otp_screen.dart';
import '../services/otp_service.dart';
import '../screens/home/home_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AppAuthProvider>();
    if (!auth.isLoggedIn) return const LoginScreen();
    if (!auth.isEmailVerified) {
      return const VerifyOtpScreen(
        purpose: OtpPurpose.emailVerification,
        autoSendOnLoad: true,
      );
    }
    return const HomeScreen();
  }
}
