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
    sliderTheme: SliderThemeData(
      thumbShape: SliderComponentShape.noThumb,
      trackShape: const RoundedRectSliderTrackShape(),
    ),
    //--------------------- Drop Down Menue Theme ------------------------------
    dropdownMenuTheme: DropdownMenuThemeData(
      menuStyle: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(HexColor("#151617")),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
        ),
        shadowColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
    ),
    //------------------------- Snake Bar Theme --------------------------------
    snackBarTheme: SnackBarThemeData(
      contentTextStyle: TextStyle(
        fontFamily: 'Bahij_TheSansArabic',
        color: AppColors.darkPrimaryText,
        fontSize: 14.sp,
      ),
      backgroundColor: AppColors.lightSurface,
    ),
    //------------------------- Drawer Theme -----------------------------------
    drawerTheme: const DrawerThemeData(
      backgroundColor: AppColors.darkBackground,
    ),
    //------------------------- Search Bar Theme -------------------------------
    searchBarTheme: SearchBarThemeData(
      backgroundColor: WidgetStatePropertyAll(HexColor("#393C3F")),
      shadowColor: const WidgetStatePropertyAll(Colors.transparent),
    ),
    //------------------------- Dialog Theme -----------------------------------
    dialogTheme: const DialogTheme(backgroundColor: AppColors.darkBackground),
    //------------------------- Floating Action Button Theme -------------------
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.mainColor,
    ),
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
    //------------------------- Bottom Navigation Bar Theme --------------------
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      selectedItemColor: AppColors.mainColor,
      unselectedItemColor: Colors.grey,
      selectedLabelStyle: TextStyle(
        fontSize: 14.sp,
        fontWeight: FontWeight.normal,
      ),
    ),
    //------------------------- ButtonStyle Theme ------------------------------
    textButtonTheme: TextButtonThemeData(
      style: ButtonStyle(
        textStyle: WidgetStatePropertyAll(
          TextStyle(
            fontSize: 16.sp,
            color: AppColors.aleart,
            fontWeight: FontWeight.w700,
            fontFamily: 'Bahij_TheSansArabic',
          ),
        ),
      ),
    ),
    menuButtonTheme: MenuButtonThemeData(
      style: ButtonStyle(
        textStyle: WidgetStatePropertyAll(
          TextStyle(
            fontSize: 16.sp,
            color: AppColors.aleart,
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
      surface: AppColors.darkBackground,
      primary: AppColors.darkPrimaryText,
      secondary: AppColors.darkBackground,
      onSurface: AppColors.darkPrimaryText,
      onPrimary: Colors.white,
      onSecondary: AppColors.darkSurface,
      onTertiary: AppColors.darkSurface,
    ),
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
