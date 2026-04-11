import 'package:flutter/material.dart';

import '../theme/flock_theme.dart';

class FlockMessageBanner extends StatelessWidget {
  final String message;
  final bool isError;
  final IconData? icon;

  const FlockMessageBanner({
    super.key,
    required this.message,
    this.isError = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isError
        ? Color.alphaBlend(const Color(0x26C62828), AppColors.background)
        : Color.alphaBlend(const Color(0x262E7D32), AppColors.background);
    final borderColor = isError
        ? Color.alphaBlend(const Color(0x66C62828), AppColors.middleground)
        : Color.alphaBlend(const Color(0x662E7D32), AppColors.middleground);
    final iconColor = AppColors.darkGreen;
    final textColor = AppColors.darkGreen;
    final bannerIcon = icon ?? (isError ? Icons.error_outline : Icons.check_circle_outline);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(bannerIcon, color: iconColor, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: textColor, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
