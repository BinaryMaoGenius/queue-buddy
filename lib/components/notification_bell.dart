import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/notification_service.dart';
import '../constants/app_colors.dart';
import '../constants/app_strings.dart';

class NotificationBell extends StatefulWidget {
  const NotificationBell({super.key});

  @override
  State<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<NotificationBell> {
  final NotificationService _notifService = NotificationService();

  void _showNotificationPanel() {
    _notifService.markAllRead();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _NotificationPanel(service: _notifService),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AppNotification>>(
      stream: _notifService.notificationStream,
      builder: (context, snapshot) {
        final unread = _notifService.unreadCount;
        
        return Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton.filledTonal(
              onPressed: _showNotificationPanel,
              icon: Icon(
                unread > 0 ? Icons.notifications_active_rounded : Icons.notifications_rounded,
                color: Colors.white,
                size: 22,
              ),
              style: IconButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.2),
              ),
            ),
            if (unread > 0)
              Positioned(
                right: 2,
                top: 2,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: AppColors.statusError,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.statusError.withValues(alpha: 0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      unread > 9 ? '9+' : unread.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ).animate().scale(duration: 300.ms, curve: Curves.easeOutBack),
              ),
          ],
        );
      },
    );
  }
}

class _NotificationPanel extends StatelessWidget {
  final NotificationService service;

  const _NotificationPanel({required this.service});

  IconData _getIcon(String type) {
    switch (type) {
      case 'ticket_taken': return Icons.check_circle_rounded;
      case '30min': return Icons.timer_rounded;
      case '10min': return Icons.alarm_rounded;
      case 'your_turn': return Icons.notifications_active_rounded;
      default: return Icons.notifications_rounded;
    }
  }

  Color _getColor(String type) {
    switch (type) {
      case 'ticket_taken': return AppColors.statusOk;
      case '30min': return AppColors.accent;
      case '10min': return AppColors.statusWarn;
      case 'your_turn': return AppColors.statusError;
      default: return AppColors.primary;
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inMinutes < 1) return "À l'instant";
    if (diff.inMinutes < 60) return "Il y a ${diff.inMinutes} min";
    if (diff.inHours < 24) return "Il y a ${diff.inHours}h";
    return "Il y a ${diff.inDays}j";
  }

  @override
  Widget build(BuildContext context) {
    final notifications = service.notifications;
    
    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.85,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            children: [
              // Handle
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.mutedForeground.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Title
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.notifications_rounded, color: AppColors.primary, size: 24),
                        const SizedBox(width: 12),
                        Text(
                          AppStrings.notifications,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                    if (notifications.isNotEmpty)
                      TextButton(
                        onPressed: () {
                          service.clearAll();
                          Navigator.pop(context);
                        },
                        child: const Text("Tout effacer", style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Notification List
              Expanded(
                child: notifications.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.notifications_off_rounded, size: 64, color: AppColors.mutedForeground.withValues(alpha: 0.3)),
                          const SizedBox(height: 16),
                          const Text(
                            AppStrings.noNotifications,
                            style: TextStyle(color: AppColors.mutedForeground, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: notifications.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final notif = notifications[index];
                        final color = _getColor(notif.type);
                        
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: notif.isRead ? Colors.transparent : color.withValues(alpha: 0.3),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Icon(_getIcon(notif.type), color: color, size: 22),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          notif.title,
                                          style: TextStyle(
                                            fontWeight: notif.isRead ? FontWeight.w600 : FontWeight.w900,
                                            fontSize: 14,
                                          ),
                                        ),
                                        Text(
                                          _formatTime(notif.time),
                                          style: const TextStyle(
                                            fontSize: 10,
                                            color: AppColors.mutedForeground,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      notif.body,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.mutedForeground,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ).animate(delay: (index * 50).ms).fadeIn().slideX(begin: 0.05);
                      },
                    ),
              ),
            ],
          ),
        );
      },
    );
  }
}
