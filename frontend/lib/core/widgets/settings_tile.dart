import 'package:flutter/material.dart';

import '../theme/flock_theme.dart';

class SettingsTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData leadingIcon;
  final VoidCallback? onTap;
  final Color? iconColor;

  const SettingsTile({
    super.key,
    required this.title,
    required this.leadingIcon,
    this.subtitle,
    this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: Icon(leadingIcon, color: iconColor ?? FlockColors.darkGreen),
        title: Text(title),
        subtitle: subtitle == null ? null : Text(subtitle!),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
