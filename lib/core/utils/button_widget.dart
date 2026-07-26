import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:voucher_manager/core/utils/colors/app_colors.dart';

class ButtonWidget extends StatefulWidget {
  final String? name;
  final IconData? icons;
  final void Function()? onPress;
  final double? height, width;
  final Color? shadow, color, textColor, iconColor;
  final TextStyle? textStyle;
  final Widget? helperWidget;
  final bool? isLoading;
  const ButtonWidget({
    super.key,
    this.name,
    this.icons,
    required this.onPress,
    this.height,
    this.width,
    this.shadow,
    this.color,
    this.textColor,
    this.textStyle,
    this.iconColor,
    this.helperWidget,
    this.isLoading = false,
  });

  @override
  State<ButtonWidget> createState() => _ButtonWidgetState();
}

class _ButtonWidgetState extends State<ButtonWidget> {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        setState(() {
          widget.onPress?.call();
        });
      },
      child: Container(
        margin: const EdgeInsets.all(5),
        padding: EdgeInsets.all(10.w),
        height: widget.height?.h,
        width: widget.width?.w,
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(14)),
          gradient: LinearGradient(
            colors: [
              widget.color ?? AppColors.mainColor,
              widget.shadow ?? const Color.fromARGB(255, 255, 207, 134),
            ],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
          color: widget.color ?? AppColors.mainColor,
          border: Border.all(
            color:
                widget.color == Colors.transparent
                    ? AppColors.mainColor
                    : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            widget.name != null && widget.helperWidget == null
                ? Text(
                  widget.name!,
                  style:
                      widget.textStyle ??
                      Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: widget.textColor ?? Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                )
                : widget.helperWidget ?? const SizedBox.shrink(),
            SizedBox(width: 5.w),
            widget.icons != null
                ? Icon(widget.icons, color: widget.iconColor ?? Colors.white)
                : const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }
}
