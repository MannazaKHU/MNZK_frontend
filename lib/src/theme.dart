import 'package:flutter/material.dart';

class JakuColors {
  const JakuColors({this.dark = false});
  final bool dark;
  static JakuColors of(BuildContext context) =>
      JakuColors(dark: Theme.of(context).brightness == Brightness.dark);
  Color get background => Color(dark ? 0xff0e1911 : 0xfffbfdf7);
  Color get panel => Color(dark ? 0xff132317 : 0xffe9f8e3);
  Color get card => Color(dark ? 0xff1a2c1f : 0xffffffff);
  Color get ink => Color(dark ? 0xffeef8ea : 0xff10251a);
  Color get body => Color(dark ? 0xffa3b9a7 : 0xff55685a);
  Color get line => Color(dark ? 0xff27412c : 0xffdcecd6);
  Color get accent => Color(dark ? 0xff6fdc80 : 0xff26a046);
  Color get strong => Color(dark ? 0xff93e9a0 : 0xff1b7434);
  Color get soft => Color(dark ? 0xff1f3a25 : 0xffdaf4d1);
  Color get arc => Color(dark ? 0xff1c3622 : 0xffc8eebe);
  Color get sun => Color(dark ? 0xffff9a76 : 0xffe2643b);
  static const green = Color(0xff62d674);
  static const stickerInk = Color(0xff10251a);
  static const peach = Color(0xffffd9b8);
  static const butter = Color(0xffffeaa0);
  static const lilac = Color(0xffdcd4ff);
  static const avatars = [peach, butter, lilac, green, Color(0xffc9ecff)];
}

ThemeData jakuTheme(Brightness brightness) {
  final c = JakuColors(dark: brightness == Brightness.dark);
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    scaffoldBackgroundColor: c.background,
    fontFamily: 'Noto Sans KR',
    fontFamilyFallback: const [
      'Apple SD Gothic Neo',
      'Malgun Gothic',
      'sans-serif',
    ],
    colorScheme: ColorScheme.fromSeed(
      seedColor: c.accent,
      brightness: brightness,
    ).copyWith(primary: c.ink, surface: c.card, onSurface: c.ink),
    textTheme: TextTheme(
      bodyMedium: TextStyle(fontSize: 16, height: 1.6, color: c.body),
      bodyLarge: TextStyle(fontSize: 17, height: 1.6, color: c.body),
      titleMedium: TextStyle(
        fontSize: 18,
        height: 1.4,
        fontWeight: FontWeight.w700,
        color: c.ink,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: c.card,
      hintStyle: TextStyle(
        color: c.body.withValues(alpha: .75),
        fontWeight: FontWeight.w400,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 26, vertical: 20),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(32),
        borderSide: BorderSide(color: c.line, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(32),
        borderSide: BorderSide(color: c.line, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(32),
        borderSide: BorderSide(color: c.ink, width: 1.5),
      ),
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: c.accent,
      selectionColor: c.soft,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: c.ink,
      contentTextStyle: TextStyle(color: c.background, fontSize: 14),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
    dividerColor: c.line,
  );
}
