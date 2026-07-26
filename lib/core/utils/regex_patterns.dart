/// Regex helpers for extracting voucher username/password pairs from
/// raw PDF text.
///
/// The vast majority of Wi-Fi voucher PDF exports lay each card out as
/// two adjacent tokens: a 7-digit username immediately followed (on the
/// same line, or the very next token) by a 2-3 digit password, e.g.:
///
///   7522659   10
///   7522660   105
///
/// Because layouts vary between printers/generators, we don't assume a
/// fixed separator - we tokenize the whole text and pair up a 7-digit
/// number with the very next 2-3 digit number that follows it.
class RegexPatterns {
  RegexPatterns._();

  /// Matches a standalone 7-digit username, e.g. "7522659".
  static final RegExp usernamePattern = RegExp(r'\b\d{7}\b');

  /// Matches a standalone 2-3 digit password, e.g. "10", "16", "105".
  static final RegExp passwordPattern = RegExp(r'\b\d{2,3}\b');

  /// Matches ANY run of 2-7 digits - used to tokenize the document so we
  /// can walk through numbers in document order and pair them up.
  static final RegExp anyNumberToken = RegExp(r'\b\d{2,7}\b');
}

/// A single (username, password) pair extracted from source text, plus
/// the raw match for debugging/traceability.
class ExtractedPair {
  final String username;
  final String password;

  const ExtractedPair({required this.username, required this.password});

  @override
  String toString() => 'ExtractedPair(username: $username, password: $password)';
}
