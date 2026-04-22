import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

import '../services/djelia_speech_service.dart';
import '../services/voice_guide_controller.dart';
import 'admin_dashboard_page.dart';
import 'package:flutter/services.dart';

class AdminLoginPage extends StatefulWidget {
  final String agenceId;
  const AdminLoginPage({super.key, required this.agenceId});

  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final TextEditingController _pinController = TextEditingController();
  final VoiceGuideController _voiceGuide = VoiceGuideController();
  final DjeliaSpeechService _speechService = DjeliaSpeechService();
  String _error = "";

  static const String _adminLoginSpeech =
      "Nin ye admin donso yoro ye. PIN code don walasa i bɛ se ka back office lajɛ ani ka baara kɛ.";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _playVoiceGuide();
    });
  }

  Future<void> _playVoiceGuide({bool force = true}) async {
    final result = await _voiceGuide.request(
      scopeKey: 'screen:admin_login',
      text: _adminLoginSpeech,
      priority: VoiceGuidePriority.critical,
      immediate: true,
      force: force,
      minReplayInterval: Duration.zero,
    );

    if (!result.isPlayed) {
      debugPrint("[AdminLoginPage] Voice guide skipped: ${result.reason}");
    }
  }

  Future<void> _speakAdminLoginGuideDirect() async {
    try {
      await _speechService.speakText(
        text: _adminLoginSpeech,
        description: "Moussa speaks with a very clear voice and friendly tone",
        format: "mp3",
      );
    } catch (e) {
      debugPrint("[AdminLoginPage] Direct TTS failed: $e");
    }
  }

  void _login() {
    if (_pinController.text == "1234") {
      // Code par défaut pour l'agent
      HapticFeedback.heavyImpact();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => AdminDashboardPage(agenceId: widget.agenceId),
        ),
      );
    } else {
      setState(() => _error = "Code PIN incorrect");
      HapticFeedback.vibrate();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  tooltip: "Lire l'aide vocale",
                  onPressed: _speakAdminLoginGuideDirect,
                  icon: const Icon(
                    Icons.volume_up_rounded,
                    color: Colors.white,
                  ),
                ),
              ),
              const Icon(
                Icons.admin_panel_settings_rounded,
                color: Colors.white,
                size: 80,
              ),
              const SizedBox(height: 24),
              const Text(
                "ACCÈS BACK-OFFICE",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "Réservé aux agents de l'agence ${widget.agenceId}",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              Container(
                constraints: const BoxConstraints(maxWidth: 250),
                child: TextField(
                  controller: _pinController,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 10,
                  ),
                  decoration: InputDecoration(
                    hintText: "****",
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)),
                    enabledBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white, width: 2),
                    ),
                    focusedBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white, width: 4),
                    ),
                  ),
                  onChanged: (v) {
                    if (v.length == 4) _login();
                  },
                ),
              ),
              if (_error.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  _error,
                  style: const TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
              const SizedBox(height: 48),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "RETOUR",
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
