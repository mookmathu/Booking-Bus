import 'package:flutter/material.dart';
import 'dart:math' as math;

// ============================================================
// AppAppBar — standard bar (Login, Search, Ticket, Payment …)
// ============================================================
class AppAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final bool automaticallyImplyLeading;
  final bool showNotificationAction;
  final bool showProfileAction;
  final int notificationCount;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onProfileTap;

  const AppAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.automaticallyImplyLeading = true,
    this.showNotificationAction = false,
    this.showProfileAction = false,
    this.notificationCount = 0,
    this.onNotificationTap,
    this.onProfileTap,
  });

  @override
  Size get preferredSize => Size.fromHeight(subtitle == null ? 72 : 86);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: automaticallyImplyLeading,
      toolbarHeight: preferredSize.height,
      titleSpacing: automaticallyImplyLeading ? 0 : 20,
      leading: automaticallyImplyLeading
          ? IconButton(
              icon: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.arrow_back_ios_new,
                    color: Colors.white, size: 16),
              ),
              onPressed: () => Navigator.of(context).pop(),
            )
          : null,
      title: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
              color: Colors.white,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: const TextStyle(
                fontSize: 12.5,
                color: Colors.white70,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
      actions: [
        if (showNotificationAction)
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                _glassAction(
                  icon: Icons.notifications_none_rounded,
                  onTap: onNotificationTap ??
                      () => Navigator.pushNamed(context, '/Notification'),
                ),
                if (notificationCount > 0)
                  Positioned(
                    top: -3,
                    right: -3,
                    child: Container(
                      width: 19,
                      height: 19,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF8C00), Color(0xFFFF5722)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: const Color(0xFF2E5DA2), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF5722).withOpacity(0.45),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: Text(
                        notificationCount > 9 ? '9+' : '$notificationCount',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        if (showProfileAction)
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: _glassAction(
              icon: Icons.person_outline_rounded,
              onTap: onProfileTap,
            ),
          ),
      ],
      flexibleSpace: const _AppBarBackground(),
    );
  }

  static Widget _glassAction({required IconData icon, VoidCallback? onTap}) {
    return Material(
      color: Colors.white.withOpacity(0.18),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        splashColor: Colors.white.withOpacity(0.2),
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}

// ============================================================
// HomeAppBar — greeting + notification & profile action buttons
// ============================================================
class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String userName;
  final int notificationCount;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onProfileTap;

  const HomeAppBar({
    super.key,
    this.userName = 'ผู้ใช้งาน',
    this.notificationCount = 0,
    this.onNotificationTap,
    this.onProfileTap,
  });

  @override
  Size get preferredSize => const Size.fromHeight(88);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      toolbarHeight: preferredSize.height,
      titleSpacing: 20,
      title: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'สวัสดี, $userName 👋',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 5),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'จะไปที่ไหนวันนี้?',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      actions: [
        // Notification bell
        Padding(
          padding: const EdgeInsets.only(right: 10),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              _glassRound(
                icon: Icons.notifications_none_rounded,
                onTap: onNotificationTap ??
                    () => Navigator.pushNamed(context, '/Notification'),
              ),
              if (notificationCount > 0)
                Positioned(
                  top: -3,
                  right: -3,
                  child: Container(
                    width: 19,
                    height: 19,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF8C00), Color(0xFFFF5722)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: const Color(0xFF2E5DA2), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF5722).withOpacity(0.45),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: Text(
                      notificationCount > 9 ? '9+' : '$notificationCount',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
        ),
        // Profile icon
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: _glassRound(
            icon: Icons.person_outline_rounded,
            onTap: onProfileTap,
          ),
        ),
      ],
      flexibleSpace: const _AppBarBackground(),
    );
  }

  static Widget _glassRound({required IconData icon, VoidCallback? onTap}) {
    return Material(
      color: Colors.white.withOpacity(0.18),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        splashColor: Colors.white.withOpacity(0.2),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}

// ============================================================
// Shared background
// ============================================================
class _AppBarBackground extends StatelessWidget {
  const _AppBarBackground();

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF4A80C4),
                  Color(0xFF2E5DA2),
                  Color(0xFF1E3F75),
                ],
                stops: [0.0, 0.55, 1.0],
              ),
            ),
          ),
          Positioned(
            top: -40,
            right: -30,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withOpacity(0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -35,
            left: 60,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withOpacity(0.09),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: Transform.rotate(
              angle: -math.pi / 8,
              child: Align(
                alignment: const Alignment(1.5, -0.5),
                child: Container(
                  width: 60,
                  height: 200,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.0),
                        Colors.white.withOpacity(0.07),
                        Colors.white.withOpacity(0.0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 1.5,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Colors.white.withOpacity(0.2),
                    Colors.white.withOpacity(0.2),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}