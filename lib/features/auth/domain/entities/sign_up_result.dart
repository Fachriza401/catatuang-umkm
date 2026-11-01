import 'app_user.dart';

enum SignUpOutcome { signedIn, emailVerificationRequired }

class SignUpResult {
  const SignUpResult({required this.outcome, this.user});

  final SignUpOutcome outcome;
  final AppUser? user;

  bool get requiresEmailVerification =>
      outcome == SignUpOutcome.emailVerificationRequired;
}
