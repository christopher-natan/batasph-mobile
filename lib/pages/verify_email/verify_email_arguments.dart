class VerifyEmailArguments {
  final String email;

  /// True when arriving from a blocked sign-in: the registration code may be
  /// long expired, so a fresh one is requested as the page opens.
  final bool sendCodeOnOpen;

  const VerifyEmailArguments({
    required this.email,
    required this.sendCodeOnOpen,
  });
}
