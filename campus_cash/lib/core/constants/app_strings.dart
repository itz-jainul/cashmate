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
    return error
        .toString()
        .replaceFirst(RegExp(r'^(Error:\s*)?(Dart\s+exception:\s*)?(Exception:\s*)?'), '')
        .trim();
  }
}
