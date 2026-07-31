import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:voucher_manager/core/utils/colors/app_colors.dart';
import 'package:voucher_manager/core/utils/colors/hex_color.dart';

ThemeData appThemeDark() {
  final base = ThemeData.dark(useMaterial3: false);
  return base.copyWith(
    scaffoldBackgroundColor: AppColors.darkBackground,
    dividerColor: Colors.transparent,
    iconTheme: const IconThemeData(color: AppColors.darkPrimaryText),
    cardTheme: CardTheme(color: HexColor("#151617")),
    //------------------------- Snack Bar Theme --------------------------------
    snackBarTheme: SnackBarThemeData(
      contentTextStyle: TextStyle(
        fontFamily: 'Bahij_TheSansArabic',
        color: AppColors.darkPrimaryText,
        fontSize: 14.sp,
      ),
      backgroundColor: AppColors.lightSurface,
    ),
    //------------------------- Dialog Theme -----------------------------------
    dialogTheme: const DialogTheme(backgroundColor: AppColors.darkBackground),
    //------------------------- App Bar Theme ----------------------------------
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.darkBackground,
      centerTitle: true,
      elevation: 0.2,
      iconTheme: const IconThemeData(color: AppColors.darkPrimaryText),
      titleTextStyle: TextStyle(
        fontSize: 16.sp,
        color: AppColors.darkPrimaryText,
        fontWeight: FontWeight.w700,
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
    textTheme: _buildTextTheme(AppColors.darkPrimaryText),
    //------------------------- Color Schema -----------------------------------
    colorScheme: base.colorScheme.copyWith(
        surface: AppColors.darkSurface,
        primary: AppColors.darkPrimaryText,
        secondary: AppColors.darkBackground,
        onSurface: AppColors.darkPrimaryText,
        // تجنب وضع Colors.white هنا إذا كان يُستخدم لخلفية الأزرار
        onPrimary: AppColors.darkSurface,
        onSecondary: AppColors.darkBackground,
        onTertiary: AppColors.darkSurface,
        secondaryContainer: AppColors.warning,
        onSurfaceVariant: AppColors.darkBackground),
  );
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
