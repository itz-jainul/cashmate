class AppStrings {
  static const String appName = 'CashMate';
  static const String appTagline = 'Find your cash exchange match.';

  // Home
  static const String greetingPrefix = 'Hi, ';
  static const String homeSubtitle = 'Find someone to exchange money with.';
  static const String whatDoYouNeed = 'What do you have?';
  static const String iHaveCash = 'I Have Cash';
  static const String iHaveDigital = 'I Have Digital Money';
  static const String activeRequest = 'Your Request';
  static const String noActiveRequest = 'No active request';
  static const String createRequest = 'Create Request';

  // Request creation
  static const String enterAmount = 'Enter Amount';
  static const String cashToDigital = 'Cash → Digital';
  static const String digitalToCash = 'Digital → Cash';
  static const String safetyWarning =
      'CashMate does not transfer or hold money. The actual exchange happens directly between users. Never share UPI PIN, passwords, or OTPs.';

  // Status
  static const String searching = 'Searching...';
  static const String matchFound = '🎉 Match Found!';
  static const String connected = 'Connected ✓';
  static const String accepted = 'Connection Accepted';
  static const String completed = 'Exchange Completed';
  static const String cancelled = 'Cancelled';
  static const String expired = 'Expired';

  /// Cleans runtime exception strings for user-friendly UI display
  static String cleanError(Object? error) {
    if (error == null) return '';
    final raw = error
        .toString()
        .replaceFirst(RegExp(r'^(Error:\s*)?(Dart\s+exception:\s*)?(Exception:\s*)?'), '')
        .trim();

    if (raw.contains('popup-closed-by-user')) {
      return 'Google sign-in was cancelled before completion.';
    }
    if (raw.contains('user-not-found')) {
      return 'No account found with this email address.';
    }
    if (raw.contains('wrong-password') || raw.contains('invalid-credential')) {
      return 'Incorrect email or password. Please try again.';
    }
    if (raw.contains('email-already-in-use')) {
      return 'An account already exists with this email address.';
    }
    if (raw.contains('network-request-failed')) {
      return 'Network connection failed. Please check your internet connection.';
    }
    if (raw.contains('too-many-requests')) {
      return 'Too many failed attempts. Please try again in a few minutes.';
    }
    if (raw.contains('invalid-email')) {
      return 'Please enter a valid email address.';
    }
    if (raw.contains('weak-password')) {
      return 'Password is too weak. Please use at least 8 characters.';
    }

    // Strip [prefix/code] if still present
    final stripped = raw.replaceFirst(RegExp(r'^\[[^\]]+\]\s*'), '');
    return stripped.isNotEmpty ? stripped : raw;
  }
}
