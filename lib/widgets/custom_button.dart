import 'package:flutter/material.dart';

enum ButtonVariant { primary, success, danger, warning, outlined }

class CustomButton extends StatelessWidget {
  final String text;
  final IconData? icon;
  final VoidCallback? onPressed;
  final ButtonVariant variant;
  final bool isLoading;
  final bool isFullWidth;

  const CustomButton({
    Key? key,
    required this.text,
    this.icon,
    required this.onPressed,
    this.variant = ButtonVariant.primary,
    this.isLoading = false,
    this.isFullWidth = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Buton renkleri belirleme
    Color bgColor;
    Color fgColor = Colors.white;
    BorderSide? border;

    switch (variant) {
      case ButtonVariant.primary:
        bgColor = theme.primaryColor;
        break;
      case ButtonVariant.success:
        bgColor = const Color(0xFF2ECC71);
        break;
      case ButtonVariant.danger:
        bgColor = const Color(0xFFE74C3C);
        break;
      case ButtonVariant.warning:
        bgColor = const Color(0xFFF39C12);
        break;
      case ButtonVariant.outlined:
        bgColor = Colors.transparent;
        fgColor = theme.primaryColor;
        border = BorderSide(color: theme.primaryColor, width: 1.5);
        break;
    }

    final buttonContent = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading)
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(fgColor),
            ),
          )
        else ...[
          if (icon != null) ...[
            Icon(icon, size: 20, color: fgColor),
            const SizedBox(width: 8),
          ],
          Text(
            text,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: fgColor,
            ),
          ),
        ],
      ],
    );

    final style = ElevatedButton.styleFrom(
      backgroundColor: bgColor,
      foregroundColor: fgColor,
      elevation: variant == ButtonVariant.outlined ? 0 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
      side: border,
    );

    final button = variant == ButtonVariant.outlined
        ? OutlinedButton(
            onPressed: isLoading ? null : onPressed,
            style: style,
            child: buttonContent,
          )
        : ElevatedButton(
            onPressed: isLoading ? null : onPressed,
            style: style,
            child: buttonContent,
          );

    if (isFullWidth) {
      return SizedBox(
        width: double.infinity,
        child: button,
      );
    }

    return button;
  }
}
