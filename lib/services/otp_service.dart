import 'dart:math';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';

enum OtpPurpose { emailVerification, passwordReset, changePassword }

class OtpService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const _expireMinutes = 15;

  Future<String> generateAndStore(String uid, OtpPurpose purpose) async {
    final code = _randomCode();
    final hash = _hash(code);

    await _db.collection('users').doc(uid).update({
      'otp': {
        'hash': hash,
        'purpose': purpose.name,
        'expiresAt': Timestamp.fromDate(
          DateTime.now().add(const Duration(minutes: _expireMinutes)),
        ),
      },
    });

    return code;
  }

  Future<bool> verify(String uid, String code, OtpPurpose purpose) async {
    final normalizedCode = code.trim().replaceAll(RegExp(r'\D'), '');
    if (normalizedCode.length != 6) return false;

    final doc = await _db.collection('users').doc(uid).get();
    final otp = doc.data()?['otp'] as Map<String, dynamic>?;
    if (otp == null) return false;

    final storedHash = otp['hash'] as String?;
    final storedPurpose = otp['purpose'] as String?;
    final expiresAt = otp['expiresAt'] as Timestamp?;

    if (storedHash == null || storedPurpose == null || expiresAt == null) {
      return false;
    }
    if (storedPurpose != purpose.name) return false;
    if (DateTime.now().isAfter(expiresAt.toDate())) return false;
    if (storedHash != _hash(normalizedCode)) return false;

    final updates = <String, dynamic>{'otp': FieldValue.delete()};
    if (purpose == OtpPurpose.emailVerification) {
      updates['emailVerified'] = true;
    } else if (purpose == OtpPurpose.passwordReset) {
      updates['passwordResetVerified'] = true;
      updates['passwordResetVerifiedAt'] = FieldValue.serverTimestamp();
    }

    await _db.collection('users').doc(uid).update(updates);
    return true;
  }

  Future<String> uidForEmail(String email) async {
    final snap = await _db
        .collection('users')
        .where('email', isEqualTo: email.trim().toLowerCase())
        .limit(1)
        .get();
    if (snap.docs.isEmpty) throw Exception('No account found for that email.');
    return snap.docs.first.id;
  }

  static String _randomCode() {
    final rand = Random.secure();
    return List.generate(6, (_) => rand.nextInt(10)).join();
  }

  static String _hash(String code) {
    return sha256.convert(utf8.encode(code)).toString();
  }
}
