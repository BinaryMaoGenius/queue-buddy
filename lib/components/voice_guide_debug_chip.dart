import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';

import '../services/voice_guide_controller.dart';

/// Small reusable chip to visualize voice guide debug status in-app.
///
/// This widget is intended for debug builds only.
/// In release/profile builds it returns an empty widget.
class VoiceGuideDebugChip extends StatelessWidget {
  final String scope;
  final VoiceGuideStatus? status;
  final String? reason;
  final VoiceGuideController? controller;
  final bool visible;
  final EdgeInsetsGeometry margin;
  final EdgeInsetsGeometry padding;
  final double elevation;
  final VoidCallback? onTap;

  const VoiceGuideDebugChip({
    super.key,
    required this.scope,
    this.status,
    this.reason,
    this.controller,
    this.visible = true,
    this.margin = const EdgeInsets.all(8),
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    this.elevation = 0,
    this.onTap,
  });

  VoiceGuideDebugChip.fromResult({
    super.key,
    required this.scope,
    required VoiceGuideResult result,
    this.controller,
    this.visible = true,
    this.margin = const EdgeInsets.all(8),
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    this.elevation = 0,
    this.onTap,
  }) : status = result.status,
       reason = result.reason;

  const VoiceGuideDebugChip.live({
    super.key,
    required this.scope,
    required this.controller,
    this.visible = true,
    this.margin = const EdgeInsets.all(8),
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    this.elevation = 0,
    this.onTap,
  }) : status = null,
       reason = null;

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode || !visible) {
      return const SizedBox.shrink();
    }

    if (controller != null) {
      return StreamBuilder<VoiceGuideDebugSnapshot>(
        stream: controller!.debugStream,
        initialData: controller!.currentDebugSnapshot,
        builder: (context, snapshot) {
          final liveResult = snapshot.data?.lastResultByScope[scope];
          final effectiveStatus = liveResult?.status ?? status;
          final effectiveReason = liveResult?.reason ?? reason;
          return _buildChip(
            context,
            effectiveStatus: effectiveStatus,
            effectiveReason: effectiveReason,
          );
        },
      );
    }

    return _buildChip(
      context,
      effectiveStatus: status,
      effectiveReason: reason,
    );
  }

  Widget _buildChip(
    BuildContext context, {
    required VoiceGuideStatus? effectiveStatus,
    required String? effectiveReason,
  }) {
    final _Visual visual = _visualFor(effectiveStatus);

    return Container(
      margin: margin,
      child: Material(
        color: visual.background,
        elevation: elevation,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap:
              onTap ??
              () => _showDetails(
                context,
                effectiveStatus: effectiveStatus,
                effectiveReason: effectiveReason,
              ),
          child: Padding(
            padding: padding,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(visual.icon, size: 14, color: visual.foreground),
                const SizedBox(width: 6),
                Text(
                  '$scope: ${visual.label}',
                  style: TextStyle(
                    color: visual.foreground,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDetails(
    BuildContext context, {
    required VoiceGuideStatus? effectiveStatus,
    required String? effectiveReason,
  }) {
    final _Visual visual = _visualFor(effectiveStatus);

    showDialog<void>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text('Voice Guide • $scope'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _detailRow('Status', visual.label),
                const SizedBox(height: 8),
                _detailRow(
                  'Reason',
                  effectiveReason?.trim().isNotEmpty == true
                      ? effectiveReason!.trim()
                      : '—',
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  Widget _detailRow(String title, String value) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(color: Colors.black87, fontSize: 13),
        children: [
          TextSpan(
            text: '$title: ',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          TextSpan(text: value),
        ],
      ),
    );
  }

  _Visual _visualFor(VoiceGuideStatus? value) {
    switch (value) {
      case VoiceGuideStatus.played:
        return const _Visual(
          label: 'played',
          icon: Icons.check_circle_rounded,
          foreground: Color(0xFF065F46),
          background: Color(0xFFE6F8F0),
        );
      case VoiceGuideStatus.skippedCooldown:
        return const _Visual(
          label: 'cooldown',
          icon: Icons.timer_off_rounded,
          foreground: Color(0xFF92400E),
          background: Color(0xFFFEF3C7),
        );
      case VoiceGuideStatus.skippedNotConfigured:
        return const _Visual(
          label: 'no-key',
          icon: Icons.key_off_rounded,
          foreground: Color(0xFF7C2D12),
          background: Color(0xFFFFE4D6),
        );
      case VoiceGuideStatus.skippedEmpty:
        return const _Visual(
          label: 'empty',
          icon: Icons.text_fields_rounded,
          foreground: Color(0xFF4B5563),
          background: Color(0xFFF3F4F6),
        );
      case VoiceGuideStatus.preempted:
        return const _Visual(
          label: 'preempted',
          icon: Icons.low_priority_rounded,
          foreground: Color(0xFF1E40AF),
          background: Color(0xFFDBEAFE),
        );
      case VoiceGuideStatus.superseded:
        return const _Visual(
          label: 'superseded',
          icon: Icons.swap_horiz_rounded,
          foreground: Color(0xFF1F2937),
          background: Color(0xFFE5E7EB),
        );
      case VoiceGuideStatus.failed:
        return const _Visual(
          label: 'failed',
          icon: Icons.error_rounded,
          foreground: Color(0xFF991B1B),
          background: Color(0xFFFEE2E2),
        );
      case null:
        return const _Visual(
          label: 'idle',
          icon: Icons.volume_mute_rounded,
          foreground: Color(0xFF6B7280),
          background: Color(0xFFF3F4F6),
        );
    }
  }
}

class _Visual {
  final String label;
  final IconData icon;
  final Color foreground;
  final Color background;

  const _Visual({
    required this.label,
    required this.icon,
    required this.foreground,
    required this.background,
  });
}
