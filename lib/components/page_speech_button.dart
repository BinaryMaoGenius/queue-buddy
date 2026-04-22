import 'package:flutter/material.dart';

import '../services/djelia_speech_service.dart';
import '../services/voice_guide_controller.dart';

/// Reusable button that executes a direct TTS API call on tap.
///
/// Usage:
/// - Place it in an AppBar `actions`
/// - Or anywhere in page UI
///
/// This widget now runs in direct TTS mode only.
/// Legacy queue-related parameters are kept only for backward compatibility.
class PageSpeechButton extends StatefulWidget {
  final String speechText;
  final String tooltip;

  /// TTS voice tuning
  final String description;
  final String format;

  /// Visual customization
  final IconData icon;
  final double iconSize;
  final Color? color;

  /// Optional callback with result (`played`, `failed`)
  final ValueChanged<VoiceGuideResult>? onResult;

  @Deprecated('No-op in direct TTS mode. Kept for backward compatibility.')
  final String? scopeKey;
  @Deprecated('No-op in direct TTS mode. Kept for backward compatibility.')
  final VoiceGuideController? controller;
  @Deprecated('No-op in direct TTS mode. Kept for backward compatibility.')
  final VoiceGuidePriority priority;
  @Deprecated('No-op in direct TTS mode. Kept for backward compatibility.')
  final Duration minReplayInterval;
  @Deprecated('No-op in direct TTS mode. Kept for backward compatibility.')
  final bool forceReplay;
  @Deprecated('No-op in direct TTS mode. Kept for backward compatibility.')
  final bool immediate;

  const PageSpeechButton({
    super.key,
    required this.speechText,
    this.tooltip = "Lire l'aide vocale",
    this.description =
        "Moussa speaks with a very clear voice and friendly tone",
    this.format = "mp3",
    this.icon = Icons.volume_up_rounded,
    this.iconSize = 22,
    this.color,
    this.onResult,
    this.scopeKey,
    this.controller,
    this.priority = VoiceGuidePriority.high,
    this.minReplayInterval = const Duration(seconds: 8),
    this.forceReplay = true,
    this.immediate = true,
  });

  @override
  State<PageSpeechButton> createState() => _PageSpeechButtonState();
}

class _PageSpeechButtonState extends State<PageSpeechButton> {
  late final DjeliaSpeechService _directSpeech;
  bool _isRequesting = false;

  @override
  void initState() {
    super.initState();
    _directSpeech = DjeliaSpeechService();
  }

  Future<void> _speakPageBehavior() async {
    if (_isRequesting || widget.speechText.trim().isEmpty) return;

    setState(() => _isRequesting = true);

    try {
      await _directSpeech.speakText(
        text: widget.speechText,
        description: widget.description,
        format: widget.format,
      );

      widget.onResult?.call(
        const VoiceGuideResult(
          VoiceGuideStatus.played,
          'Played via direct TTS API call.',
        ),
      );
    } catch (e) {
      widget.onResult?.call(
        VoiceGuideResult(VoiceGuideStatus.failed, 'Direct TTS call failed: $e'),
      );
    } finally {
      if (mounted) {
        setState(() => _isRequesting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: widget.tooltip,
      onPressed: _isRequesting ? null : _speakPageBehavior,
      icon:
          _isRequesting
              ? SizedBox(
                width: widget.iconSize,
                height: widget.iconSize,
                child: const CircularProgressIndicator(strokeWidth: 2),
              )
              : Icon(widget.icon, size: widget.iconSize, color: widget.color),
    );
  }
}
