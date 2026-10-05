class ForgotPasswordArguments {
  /// Whatever the user had typed on the sign-in screen; may be empty.
  final String initialEmail;

  const ForgotPasswordArguments({required this.initialEmail});
}
