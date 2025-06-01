import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

const kAnimation = Duration(milliseconds: 200);

class Palette {
  late final FillPalette fill = FillPalette(
    grey: Color(0xFF323232),
  );

  final Color white = const Color(0xFFFFFFFF);
  final Color transparent = const Color(0x00000000);

  late final cupertino = CupertinoThemeData(
    brightness: Brightness.dark,
    textTheme: CupertinoTextThemeData(
      textStyle: TextStyle(fontFamily: 'Reddit Sans'),
    ),
  );

  late final material = ThemeData(
    useMaterial3: true,
    actionIconTheme: ActionIconThemeData(
      backButtonIconBuilder: (_) => Icon(CupertinoIcons.back),
    ),
    appBarTheme: AppBarTheme(
      centerTitle: false,
      iconTheme: IconThemeData(),
    ),
    fontFamily: 'Reddit Sans',
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.green,
      brightness: Brightness.dark,
    ),
  );
}

class FillPalette {
  final Color grey;

  FillPalette({required this.grey});
}

final colors = Palette();
