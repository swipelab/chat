import 'package:flutter/material.dart';

import '../theme.dart';

class Line extends StatelessWidget {
  const Line({
    this.margin = EdgeInsets.zero,
    super.key,
  });

  final EdgeInsets margin;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: margin,
      child: ColoredBox(
        color: colors.outline.grey,
        child: SizedBox(
          height: 1,
          width: double.infinity,
        ),
      ),
    );
  }
}
