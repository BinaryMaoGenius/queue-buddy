import 'glass_container.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:record/record.dart';
import 'package:http/http.dart' as http;
import 'package:cross_file/cross_file.dart';
import 'dart:typed_data';
import '../constants/app_colors.dart';
import '../constants/app_strings.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/soloba_service.dart';
import '../services/djelia_speech_service.dart';

class SolobaAssistant extends StatefulWidget {
  final Function(String) onSelectService;

  const SolobaAssistant({super.key, required this.onSelectService});

  @override
  State<SolobaAssistant> createState() => _SolobaAssistantState();
}

class _SolobaAssistantState extends State<SolobaAssistant> {
  final SolobaService _solobaService = SolobaService();
  final AudioRecorder _record = AudioRecorder();
  final DjeliaSpeechService _speechService = DjeliaSpeechService();

  bool isListening = false;
  bool isProcessing = false;
  bool showConfirmation = false;
  bool showDemoMenu = false;
  String? resultBambara;
  String? resultText;
  String? serviceId;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _record.dispose();
    _speechService.dispose();
    super.dispose();
  }

  void toggleListening() async {
    HapticFeedback.mediumImpact();

    if (isListening) {
      // STOP recording
      setState(() {
        isListening = false;
        isProcessing = true;
      });
      try {
        final path = await _record.stop();
        if (path != null) {
          Uint8List audioBytes;
          if (kIsWeb) {
            // Sur le Web, le chemin est un blob URI
            final response = await http.get(Uri.parse(path));
            audioBytes = response.bodyBytes;
          } else {
            // Sur Windows/Mobile, on utilise XFile qui est plus sûr que dart:io pour le web-compat
            audioBytes = await XFile(path).readAsBytes();
          }

          final result = await _solobaService.recognizeSpeech(audioBytes);
          if (!mounted) return;
          HapticFeedback.heavyImpact();
          setState(() {
            isProcessing = false;
            showConfirmation = true;
            resultBambara = result.bambara;
            resultText = result.text;
            serviceId = result.serviceId;
          });

          // Voice Feedback
          _speakConfirmation(result.labelBambara, result.text);
        } else {
          throw Exception(AppStrings.audioError);
        }
      } catch (e) {
        if (!mounted) return;
        setState(() {
          isProcessing = false;
          isListening = false;
        });
        // Show error with option to try demo mode
        _showAsrErrorWithDemo(e.toString());
      }
    } else {
      // START recording
      if (await _record.hasPermission()) {
        await _record.start(
          const RecordConfig(encoder: AudioEncoder.wav),
          path: '',
        );
        setState(() {
          isListening = true;
          showConfirmation = false;
          showDemoMenu = false;
        });
      } else {
        if (!mounted) return;
        // If permission denied, offer demo mode
        setState(() => showDemoMenu = true);
      }
    }
  }

  void _showAsrErrorWithDemo(String error) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (ctx) => Container(
            padding: const EdgeInsets.all(32),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.statusWarn.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.mic_off_rounded,
                    color: AppColors.statusWarn,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Assistant vocal indisponible",
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                ),
                const SizedBox(height: 8),
                Text(
                  AppStrings.asrUnavailable,
                  style: const TextStyle(
                    color: AppColors.mutedForeground,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    setState(() => showDemoMenu = true);
                  },
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text(
                    AppStrings.tryDemoVoice,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text(
                    "Fermer",
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  void _selectDemoService(String id, String bambara, String text) {
    HapticFeedback.heavyImpact();
    setState(() {
      showDemoMenu = false;
      showConfirmation = true;
      resultBambara = bambara;
      resultText = text;
      serviceId = id;
    });

    // Voice Feedback for Demo
    _speakConfirmation(bambara, text);
  }

  Future<void> _speakConfirmation(String bambara, String french) async {
    try {
      await _speechService.speakText(
        text: "$bambara. $french choisi.",
        description:
            "Sira speaks with a clear, professional and friendly female voice in Bambara",
      );
    } catch (e) {
      debugPrint("[SolobaAssistant] Djelia TTS fallback: $e");
    }
  }

  void cancel() {
    HapticFeedback.lightImpact();
    setState(() {
      isListening = false;
      isProcessing = false;
      showConfirmation = false;
      showDemoMenu = false;
    });
  }

  void confirm() {
    if (serviceId != null) {
      HapticFeedback.mediumImpact();
      widget.onSelectService(serviceId!);
      setState(() {
        showConfirmation = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.bottomCenter,
      children: [
        // Premium FAB
        if (!isListening && !isProcessing && !showConfirmation && !showDemoMenu)
          Semantics(
            label: "Démarrer l'assistant vocal Sira",
            child: Container(
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: FloatingActionButton.extended(
                onPressed: toggleListening,
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                icon: const Icon(Icons.mic_rounded),
                label: const Text(
                  AppStrings.assistantBtn('fr'),
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    letterSpacing: 1.5,
                  ),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(32),
                ),
              ),
            ).animate().scale(
              delay: 200.ms,
              duration: 400.ms,
              curve: Curves.easeOutBack,
            ),
          ),

        // Demo Service Selection Menu
        if (showDemoMenu)
          Positioned(
            bottom: 24,
            left: 16,
            right: 16,
            child: GlassContainer(
              borderRadius: 32,
              blur: 15,
              opacity: 0.95,
              color: Colors.white,
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.1),
                width: 1.5,
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.accent.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.auto_awesome_rounded,
                                color: AppColors.accent,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              AppStrings.demoMode,
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 12,
                                letterSpacing: 2,
                                color: AppColors.accent,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 20),
                          onPressed: cancel,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Sélectionnez un service comme si Sira vous avait compris",
                      style: TextStyle(
                        color: AppColors.mutedForeground,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    _DemoServiceButton(
                      icon: Icons.arrow_downward_rounded,
                      bambara: "Wari don",
                      label: "Versement",
                      onTap:
                          () => _selectDemoService(
                            'versement',
                            'Wari don',
                            'Versement',
                          ),
                    ),
                    const SizedBox(height: 8),
                    _DemoServiceButton(
                      icon: Icons.account_balance_wallet_outlined,
                      bambara: "Wari bɔ",
                      label: "Retrait",
                      onTap:
                          () => _selectDemoService(
                            'retrait',
                            'Wari bɔ',
                            'Retrait',
                          ),
                    ),
                    const SizedBox(height: 8),
                    _DemoServiceButton(
                      icon: Icons.swap_horiz_rounded,
                      bambara: "Wari ci",
                      label: "Virement",
                      onTap:
                          () => _selectDemoService(
                            'virement',
                            'Wari ci',
                            'Virement',
                          ),
                    ),
                    const SizedBox(height: 8),
                    _DemoServiceButton(
                      icon: Icons.info_outline_rounded,
                      bambara: "Ɲɛfɔli",
                      label: "Renseignement",
                      onTap:
                          () => _selectDemoService(
                            'renseignement',
                            'Ɲɛfɔli',
                            'Renseignement',
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ).animate().slideY(
            begin: 0.4,
            duration: 500.ms,
            curve: Curves.easeOutQuart,
          ),

        // Listening Overlay
        if (isListening || isProcessing)
          Positioned.fill(
            child: GlassContainer(
              blur: 20,
              opacity: 0.8,
              borderRadius: 0,
              color: Colors.white,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isProcessing)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 60),
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    )
                  else
                    // Dynamic Mic Pulse
                    Container(
                          width: 160,
                          height: 160,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Container(
                              width: 90,
                              height: 90,
                              decoration: BoxDecoration(
                                gradient: AppColors.premiumGradient,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(
                                      alpha: 0.4,
                                    ),
                                    blurRadius: 30,
                                    offset: const Offset(0, 15),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.mic_rounded,
                                size: 45,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        )
                        .animate(
                          onPlay:
                              (controller) => controller.repeat(reverse: true),
                        )
                        .scale(
                          begin: const Offset(1, 1),
                          end: const Offset(1.2, 1.2),
                          duration: 800.ms,
                          curve: Curves.easeInOut,
                        ),

                  const SizedBox(height: 64),
                  Text(
                    isProcessing
                        ? AppStrings.analyzing('fr')
                        : AppStrings.solobaListeningBambara,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                    textAlign: TextAlign.center,
                  ).animate().fadeIn().slideY(begin: 0.1),
                  const SizedBox(height: 12),
                  Text(
                    isProcessing
                        ? AppStrings.pleaseWait('fr')
                        : AppStrings.solobaListeningDesc('fr'),
                    style: const TextStyle(
                      color: AppColors.mutedForeground,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ).animate().fadeIn(delay: 200.ms),

                  const SizedBox(height: 80),
                  if (isListening)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        10,
                        (index) => Container(
                              width: 4,
                              height: 40,
                              margin: const EdgeInsets.symmetric(horizontal: 5),
                              decoration: BoxDecoration(
                                gradient: AppColors.premiumGradient,
                                borderRadius: BorderRadius.circular(10),
                              ),
                            )
                            .animate(
                              onPlay:
                                  (controller) =>
                                      controller.repeat(reverse: true),
                            )
                            .scaleY(
                              begin: 0.2,
                              end: 2.5,
                              delay: (index * 100).ms,
                              duration: 600.ms,
                            ),
                      ),
                    ),

                  if (isListening)
                    Padding(
                      padding: const EdgeInsets.only(top: 80),
                      child: TextButton.icon(
                        onPressed: toggleListening,
                        icon: const Icon(Icons.stop_rounded),
                        label: const Text(
                          AppStrings.stop('fr'),
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 40,
                            vertical: 20,
                          ),
                          backgroundColor: AppColors.statusWarn,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                      ).animate().scale(curve: Curves.easeOutBack),
                    )
                  else
                    const SizedBox(height: 100),

                  if (isListening)
                    Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: TextButton.icon(
                        onPressed: cancel,
                        icon: const Icon(Icons.close_rounded),
                        label: const Text(
                          AppStrings.cancel('fr'),
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.foreground,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 40,
                            vertical: 20,
                          ),
                          backgroundColor: AppColors.secondary.withValues(
                            alpha: 0.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ).animate().fadeIn(),

        // Confirmation Overlay
        if (showConfirmation)
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: GlassContainer(
              borderRadius: 40,
              blur: 15,
              opacity: 0.95,
              color: Colors.white,
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.1),
                width: 1.5,
              ),
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.auto_awesome_rounded,
                        color: AppColors.primary,
                        size: 36,
                      ),
                    ).animate().scale(
                      duration: 400.ms,
                      curve: Curves.easeOutBack,
                    ),
                    const SizedBox(height: 32),
                    Text(
                      "${AppStrings.aiUnderstood('fr')} (${resultBambara != resultText ? 'DJELIA + AI' : 'KEYWORD'})",
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.mutedForeground,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Column(
                      children: [
                        Text(
                          resultBambara!,
                          style: Theme.of(
                            context,
                          ).textTheme.headlineMedium?.copyWith(
                            color: AppColors.primary,
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "\u201C $resultText \u201D",
                          style: const TextStyle(
                            fontSize: 18,
                            color: AppColors.mutedForeground,
                            fontWeight: FontWeight.w600,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
                    const SizedBox(height: 40),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: cancel,
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(64),
                              side: BorderSide(
                                color: AppColors.primary.withValues(alpha: 0.2),
                                width: 1.5,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(22),
                              ),
                              foregroundColor: AppColors.mutedForeground,
                            ),
                            child: const Text(
                              AppStrings.retry('fr'),
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: confirm,
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size.fromHeight(64),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(22),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              AppStrings.continueBtn('fr'),
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ).animate().slideY(
            begin: 0.6,
            duration: 600.ms,
            curve: Curves.easeOutQuart,
          ),
      ],
    );
  }
}

class _DemoServiceButton extends StatelessWidget {
  final IconData icon;
  final String bambara;
  final String label;
  final VoidCallback onTap;

  const _DemoServiceButton({
    required this.icon,
    required this.bambara,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.secondary.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    bambara,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.mutedForeground,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: AppColors.mutedForeground.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}
