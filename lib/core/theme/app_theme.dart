import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:voucher_manager/core/utils/colors/app_colors.dart';
import 'package:voucher_manager/core/utils/colors/hex_color.dart';

ThemeData appThemeLight() {
  final base = ThemeData.light(useMaterial3: false);
  return base.copyWith(
      scaffoldBackgroundColor: AppColors.lightBackground,
      primaryColor: AppColors.mainColor,
      dividerColor: Colors.transparent,

      //------------------------- Icon Theme -------------------------------------
      iconTheme: const IconThemeData(color: AppColors.lightPrimaryText),
      //------------------------- Card Theme -------------------------------------
      cardTheme: CardTheme(color: AppColors.lightSurface),
      //------------------------- Snack Bar Theme --------------------------------
      snackBarTheme: const SnackBarThemeData(
        contentTextStyle: TextStyle(
          fontFamily: 'Bahij_TheSansArabic',
          color: AppColors.lightPrimaryText,
        ),
      ),
      //------------------------- Dialog Theme -----------------------------------
      dialogTheme: const DialogTheme(backgroundColor: Colors.white),
      //------------------------- App Bar Theme ----------------------------------
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.lightSurface,
        elevation: 0.3,
        iconTheme: const IconThemeData(color: AppColors.lightPrimaryText),
        centerTitle: true,
        shadowColor: Colors.black.withAlpha(10),
        surfaceTintColor: AppColors.lightPrimaryText,
        titleTextStyle: TextStyle(
          fontSize: 16.sp,
          color: AppColors.lightPrimaryText,
          fontFamily: 'Bahij_TheSansArabic',
        ),
      ),
      //------------------------- ButtonStyle Theme ------------------------------
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          textStyle: WidgetStatePropertyAll(
            TextStyle(
              fontSize: 16.sp,
              color: AppColors.darkPrimaryText,
              fontWeight: FontWeight.w700,
              fontFamily: 'Bahij_TheSansArabic',
            ),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          textStyle: WidgetStatePropertyAll(
            TextStyle(
              fontSize: 16.sp,
              color: AppColors.darkPrimaryText,
              fontWeight: FontWeight.w700,
              fontFamily: 'Bahij_TheSansArabic',
            ),
          ),
        ),
      ),
      //------------------------- Text Theme -------------------------------------
      textTheme: _buildTextTheme(AppColors.lightPrimaryText),
      //------------------------- Color Scheme Theme -----------------------------
      colorScheme: base.colorScheme.copyWith(
          surface: AppColors.lightSurface,
          primary: AppColors.lightPrimaryText,
          secondary: AppColors.lightSurface,
          // تخصيص لون ثابت للحاويات/الأزرار الثانوية بدلاً من onPrimary
          surfaceContainerHigh: AppColors.grayDark,
          onSurface: AppColors.lightPrimaryText,
          onSecondary: AppColors.colodBlue,
          onTertiary: AppColors.colodBlue,
          secondaryContainer: AppColors.warning,
          onSurfaceVariant: AppColors.lightPrimaryText));
}

TextTheme _buildTextTheme(Color textColor) {
  return TextTheme(
    titleLarge: TextStyle(
      fontFamily: 'Bahij_TheSansArabic',
      fontSize: 18.sp,
      color: textColor,
      fontWeight: FontWeight.w600,
    ),
    titleMedium: TextStyle(
      fontFamily: 'Bahij_TheSansArabic',
      fontSize: 16.sp,
      color: textColor,
    ),
    titleSmall: TextStyle(
      fontFamily: 'Bahij_TheSansArabic',
      fontSize: 14.sp,
      color: textColor,
    ),
    bodyLarge: TextStyle(
      fontFamily: 'Bahij_TheSansArabic',
      fontSize: 16.sp,
      color: textColor,
    ),
    bodyMedium: TextStyle(
      fontFamily: 'Bahij_TheSansArabic',
      fontSize: 14.sp,
      color: textColor,
    ),
    bodySmall: TextStyle(
      fontFamily: 'Bahij_TheSansArabic',
      fontSize: 12.sp,
      color: textColor,
    ),
  );
}
