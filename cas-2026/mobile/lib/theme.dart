// SmartFarm Interface v2: forest, sprout, wheat, kraft, water, earth. Sora for titles, Nunito for text.
import 'package:flutter/material.dart';

class C {
  static const kraft = Color(0xFFF4EEE0);
  static const paper = Color(0xFFFBF8F1);
  static const forest = Color(0xFF1F4A2C);
  static const forest2 = Color(0xFF2B6A35);
  static const pousse = Color(0xFFA6D65A);
  static const pousseSoft = Color(0xFFE3EFD6);
  static const ble = Color(0xFFE8B746);
  static const bleSoft = Color(0xFFF7E7BD);
  static const eau = Color(0xFF24648F);
  static const terre = Color(0xFF8B4A2B);
  static const flame = Color(0xFFA8392B);
  static const flameSoft = Color(0xFFF6D9D4);
  static const ink = Color(0xFF1D261D);
  static const ink2 = Color(0xFF5D5A4E);
  static const furrow = Color(0xFFD6C9AD);
  static const warn = Color(0xFFD18A12);
  static const chip = Color(0xFFECE4D0);
}

/// The "leaf" corners of buttons and tiles: rounded top-left and bottom-right.
BorderRadius leaf([double big = 18, double small = 6]) => BorderRadius.only(
    topLeft: Radius.circular(big), topRight: Radius.circular(small),
    bottomRight: Radius.circular(big), bottomLeft: Radius.circular(small));

TextStyle sora(double size, {FontWeight w = FontWeight.w700, Color color = C.ink, double? height}) =>
    TextStyle(fontFamily: 'Sora', fontSize: size, fontWeight: w, color: color, height: height, letterSpacing: -.2);

TextStyle nunito(double size, {FontWeight w = FontWeight.w400, Color color = C.ink, double? height}) =>
    TextStyle(fontFamily: 'Nunito', fontSize: size, fontWeight: w, color: color, height: height);

ThemeData buildTheme() => ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: C.kraft,
      colorScheme: ColorScheme.fromSeed(seedColor: C.forest, surface: C.kraft, primary: C.forest),
      fontFamily: 'Nunito',
      textTheme: const TextTheme(bodyMedium: TextStyle(fontFamily: 'Nunito', fontSize: 16, color: C.ink)),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: C.paper,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        enabledBorder: OutlineInputBorder(borderRadius: leaf(12, 4), borderSide: const BorderSide(color: Color(0xFFD9CFB8), width: 2)),
        focusedBorder: OutlineInputBorder(borderRadius: leaf(12, 4), borderSide: const BorderSide(color: C.forest, width: 2)),
        errorBorder: OutlineInputBorder(borderRadius: leaf(12, 4), borderSide: const BorderSide(color: C.flame, width: 2)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: leaf(12, 4), borderSide: const BorderSide(color: C.flame, width: 2)),
      ),
    );
