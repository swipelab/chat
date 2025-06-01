import 'package:app/theme.dart';
import 'package:flutter/cupertino.dart';

class Input extends StatelessWidget {
  const Input({
    this.controller,
    this.obscureText = false,
    super.key,
  });

  final TextEditingController? controller;
  final bool obscureText;

  @override
  Widget build(BuildContext context) {
    return CupertinoTextField(
      controller: controller,
      obscureText: obscureText,
      padding: EdgeInsets.symmetric(
        vertical: 12,
        horizontal: 8,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: colors.fill.grey,
      ),
    );
  }
}
