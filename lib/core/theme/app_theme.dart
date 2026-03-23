import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';

class AppTheme {
  // Korean-friendly font fallback for all platforms
  static const _fontFallback = ['Malgun Gothic', 'NanumGothic', 'Noto Sans KR', 'Segoe UI', 'sans-serif'];

  static TextTheme _applyKoreanFont(TextTheme base) {
    return base.apply(
      fontFamily: 'Malgun Gothic',
      fontFamilyFallback: _fontFallback,
    );
  }

  static ThemeData get darkTheme {
    final theme = FlexThemeData.dark(
      scheme: FlexScheme.blueM3,
      surfaceMode: FlexSurfaceMode.highScaffoldLowSurface,
      blendLevel: 18,
      subThemesData: const FlexSubThemesData(
        blendOnLevel: 20,
        inputDecoratorBorderType: FlexInputBorderType.outline,
        inputDecoratorRadius: 8,
        cardRadius: 12,
        elevatedButtonRadius: 8,
        filledButtonRadius: 8,
        outlinedButtonRadius: 8,
        textButtonRadius: 8,
        fabRadius: 16,
        navigationBarIndicatorRadius: 12,
      ),
    );
    return theme.copyWith(textTheme: _applyKoreanFont(theme.textTheme));
  }

  static ThemeData get lightTheme {
    final theme = FlexThemeData.light(
      scheme: FlexScheme.blueM3,
      surfaceMode: FlexSurfaceMode.highScaffoldLowSurface,
      blendLevel: 7,
      subThemesData: const FlexSubThemesData(
        blendOnLevel: 10,
        inputDecoratorBorderType: FlexInputBorderType.outline,
        inputDecoratorRadius: 8,
        cardRadius: 12,
        elevatedButtonRadius: 8,
        filledButtonRadius: 8,
        outlinedButtonRadius: 8,
        textButtonRadius: 8,
        fabRadius: 16,
        navigationBarIndicatorRadius: 12,
      ),
    );
    return theme.copyWith(textTheme: _applyKoreanFont(theme.textTheme));
  }
}
