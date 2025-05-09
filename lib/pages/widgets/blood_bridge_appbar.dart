import 'package:bloodbridge/pages/widgets/notification_badge.dart';
import 'package:flutter/material.dart';

class BloodBridgeAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showNotificationIcon;
  final List<Widget>? actions;

  const BloodBridgeAppBar({
    Key? key,
    required this.title,
    this.showNotificationIcon = true,
    this.actions,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: Colors.red,
      elevation: 0,
      iconTheme: const IconThemeData(color: Colors.white),
      actions: [
        if (showNotificationIcon) 
          const NotificationBadge(),
        if (actions != null) 
          ...actions!,
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}