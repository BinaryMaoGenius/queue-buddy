import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../constants/app_strings.dart';
import '../services/firebase_service.dart';
import '../models/agence.dart';
import '../components/soloba_assistant.dart';
import '../components/glass_container.dart';
import '../services/djelia_speech_service.dart';
import '../components/voice_guide_debug_chip.dart';
import '../constants/app_colors.dart';
import '../services/voice_guide_controller.dart';
import 'ticket_page.dart';
import '../utils/responsive_utils.dart';

class TakeTicketPage extends StatefulWidget {
  final Agence agency;
  final String? initialServiceId;

  const TakeTicketPage({
    super.key,
    required this.agency,
    this.initialServiceId,
  });

  @override
  State<TakeTicketPage> createState() => _TakeTicketPageState();
}

class _TakeTicketPageState extends State<TakeTicketPage> {
  final _formKey = GlobalKey<FormState>();
  final VoiceGuideController _voiceGuide = VoiceGuideController();
  final DjeliaSpeechService _speechService = DjeliaSpeechService();

  List<String> selectedServices = [];
  final TextEditingController _nomController = TextEditingController();
  final TextEditingController _telController = TextEditingController();
  bool isLoading = false;

  static const String _takeTicketBehaviorSpeech =
      "Nin yoro la, sugandi baara min i b’a fe, sɔrɔ i ka tɔgɔ ni telefonu nimɛro, o kɔfɛ i bɛ se ka i ka ticket ta.";

  @override
  void initState() {
    super.initState();
    if (widget.initialServiceId != null) {
      selectedServices.add(widget.initialServiceId!);
    }
    Future.microtask(
      () => _playVoiceGuide(
        force: true,
        priority: VoiceGuidePriority.critical,
        immediate: true,
      ),
    );
  }

  Future<void> _playVoiceGuide({
    bool force = false,
    bool immediate = false,
    VoiceGuidePriority priority = VoiceGuidePriority.normal,
  }) async {
    final result = await _voiceGuide.request(
      scopeKey: 'screen:take_ticket:auto-entry',
      text: _takeTicketBehaviorSpeech,
      priority: priority,
      force: force,
      immediate: immediate,
      minReplayInterval: const Duration(seconds: 8),
    );

    if (!result.isPlayed) {
      debugPrint("[TakeTicketPage] Voice guide skipped: ${result.reason}");
    }
  }

  @override
  void dispose() {
    _nomController.dispose();
    _telController.dispose();
    super.dispose();
  }

  final List<Map<String, dynamic>> services = [
    {
      'id': 'versement',
      'name': 'Versement',
      'bambara': 'Wari don',
      'icon': Icons.arrow_downward_rounded,
    },
    {
      'id': 'retrait',
      'name': 'Retrait',
      'bambara': 'Wari bɔ',
      'icon': Icons.account_balance_wallet_outlined,
    },
    {
      'id': 'virement',
      'name': 'Virement',
      'bambara': 'Wari ci',
      'icon': Icons.swap_horiz_rounded,
    },
    {
      'id': 'renseignement',
      'name': 'Renseignement',
      'bambara': 'Ɲɛfɔli',
      'icon': Icons.info_outline_rounded,
    },
  ];

  Future<void> _submit() async {
    if (_formKey.currentState!.validate() && selectedServices.isNotEmpty) {
      HapticFeedback.mediumImpact();
      setState(() => isLoading = true);
      try {
        // We take one ticket but with multiple operations or we join them as a string
        final String operations = selectedServices
            .map((id) {
              return services.firstWhere((s) => s['id'] == id)['name'];
            })
            .join(" & ");

        final ticket = await context.read<FirebaseService>().prendreTicket(
          agenceId: widget.agency.id,
          nom: _nomController.text,
          tel: _telController.text,
          operation: operations,
        );

        if (!mounted) return;
        HapticFeedback.heavyImpact();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => TicketPage(ticket: ticket)),
        );
      } catch (e) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("${AppStrings.errorPrefix}$e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // App Bar Area
          SliverAppBar(
            pinned: true,
            leadingWidth: Responsive.wp(20),
            toolbarHeight: Responsive.hp(10),
            leading: Padding(
              padding: EdgeInsets.only(
                left: Responsive.padding,
                top: 12,
                bottom: 12,
              ),
              child: InkWell(
                onTap: () => Navigator.pop(context),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                ),
              ),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.agency.nom,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontSize: Responsive.fs(18)),
                ),
                Text(
                  widget.agency.adresse,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            actions: [
              IconButton(
                tooltip: "Écouter l'aide de la page",
                onPressed: () async {
                  try {
                    await _speechService.speakText(
                      text: _takeTicketBehaviorSpeech,
                      description:
                          "Moussa speaks with a very clear voice and friendly tone",
                      format: "mp3",
                    );
                  } catch (e) {
                    debugPrint("[TakeTicketPage] Direct TTS failed: $e");
                  }
                },
                icon: const Icon(
                  Icons.volume_up_rounded,
                  color: AppColors.primary,
                ),
              ),
              SizedBox(width: Responsive.padding / 2),
            ],
          ),

          // Main Content
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: Responsive.padding),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),

                    // Affluence Info Card (Glassmorphism)
                    GlassContainer(
                          opacity: 0.1,
                          borderRadius: 32,
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      AppStrings.estimatedTime('fr'),
                                      style: Theme.of(
                                        context,
                                      ).textTheme.labelSmall?.copyWith(
                                        fontWeight: FontWeight.w900,
                                        color:
                                            AppColors.primary, // More readable
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.statusOk.withValues(
                                          alpha: 0.15,
                                        ),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                                width: 6,
                                                height: 6,
                                                decoration: const BoxDecoration(
                                                  color: AppColors.statusOk,
                                                  shape: BoxShape.circle,
                                                ),
                                              )
                                              .animate(
                                                onPlay: (c) => c.repeat(),
                                              )
                                              .scale(
                                                duration: 800.ms,
                                                begin: const Offset(1, 1),
                                                end: const Offset(1.5, 1.5),
                                              )
                                              .fadeOut(),
                                          const SizedBox(width: 6),
                                          const Text(
                                            AppStrings.live,
                                            style: TextStyle(
                                              color: AppColors.statusOk,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.baseline,
                                  textBaseline: TextBaseline.alphabetic,
                                  children: [
                                    Text(
                                      "~${widget.agency.enAttenteCount * 5}",
                                      style: Theme.of(
                                        context,
                                      ).textTheme.displayLarge?.copyWith(
                                        fontSize: Responsive.fs(32),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Text(
                                      "min",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.mutedForeground,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                // PulseBar placeholder or custom widget
                                Container(
                                  height: 12,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: AppColors.secondary,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: FractionallySizedBox(
                                    alignment: Alignment.centerLeft,
                                    widthFactor: (widget.agency.enAttenteCount /
                                            50)
                                        .clamp(0.1, 1.0),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: AppColors.premiumGradient,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  "${widget.agency.enAttenteCount} ${AppStrings.peopleWaitingSuffix('fr')}",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .animate()
                        .fadeIn(delay: 200.ms)
                        .slideY(begin: 0.1, curve: Curves.easeOutBack),

                    const SizedBox(height: 40),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppStrings.availableServices('fr'),
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: Responsive.fs(18),
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      AppStrings.chooseVisitObject('fr'),
                      style: TextStyle(
                        color: AppColors.mutedForeground,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Service List
                    ...services.asMap().entries.map((entry) {
                      final i = entry.key;
                      final s = entry.value;
                      final isSelected = selectedServices.contains(s['id']);
                      return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: InkWell(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setState(() {
                                  if (isSelected) {
                                    selectedServices.remove(s['id']);
                                  } else {
                                    selectedServices.add(s['id']);
                                  }
                                });
                              },
                              borderRadius: BorderRadius.circular(24),
                              child: AnimatedContainer(
                                duration: 300.ms,
                                padding: EdgeInsets.all(Responsive.hp(2)),
                                decoration: BoxDecoration(
                                  color:
                                      isSelected
                                          ? AppColors.primary.withValues(
                                            alpha: 0.04,
                                          )
                                          : AppColors.secondary.withValues(
                                            alpha: 0.3,
                                          ),
                                  border: Border.all(
                                    color:
                                        isSelected
                                            ? AppColors.primary
                                            : Colors.transparent,
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color:
                                            isSelected
                                                ? AppColors.primary
                                                : Colors.white,
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow:
                                            isSelected
                                                ? [
                                                  BoxShadow(
                                                    color: AppColors.primary
                                                        .withValues(alpha: 0.2),
                                                    blurRadius: 10,
                                                    offset: const Offset(0, 4),
                                                  ),
                                                ]
                                                : null,
                                      ),
                                      child: Icon(
                                        s['icon'],
                                        color:
                                            isSelected
                                                ? Colors.white
                                                : AppColors.primary,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                s['name'],
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w800,
                                                  fontSize: 15,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                s['bambara'],
                                                style: TextStyle(
                                                  color: AppColors
                                                      .mutedForeground
                                                      .withValues(alpha: 0.5),
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w900,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const Text(
                                            AppStrings.quickServiceDesc,
                                            style: TextStyle(
                                              color: AppColors.mutedForeground,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (isSelected)
                                      const Icon(
                                        Icons.check_circle_rounded,
                                        color: AppColors.primary,
                                      ).animate().scale(),
                                  ],
                                ),
                              ),
                            ),
                          )
                          .animate(delay: (400 + i * 100).ms)
                          .fadeIn()
                          .slideX(begin: -0.1);
                    }),

                    const SizedBox(height: 40),
                    const Text(
                      AppStrings.yourInfo('fr'),
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 20),

                    TextFormField(
                      controller: _nomController,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                      decoration: _inputDecoration(
                        AppStrings.fullName('fr'),
                        Icons.person_rounded,
                      ),
                      validator:
                          (v) => v!.isEmpty ? AppStrings.enterNameError('fr') : null,
                    ).animate(delay: 800.ms).fadeIn(),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _telController,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(15),
                      ],
                      decoration: _inputDecoration(
                        AppStrings.phone('fr'),
                        Icons.phone_rounded,
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty)
                          return AppStrings.enterPhoneError('fr');
                        if (v.length < 8) return AppStrings.phoneMinLengthError;
                        return null;
                      },
                    ).animate(delay: 900.ms).fadeIn(),

                    const SizedBox(height: 40),

                    if (selectedServices.isNotEmpty)
                      ElevatedButton(
                        onPressed: isLoading ? null : _submit,
                        child:
                            isLoading
                                ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 3,
                                  ),
                                )
                                : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.confirmation_num_rounded),
                                    const SizedBox(width: 12),
                                    const Text(AppStrings.takeMyTicket),
                                    const SizedBox(width: 12),
                                    Container(
                                      width: 1,
                                      height: 20,
                                      color: Colors.white.withValues(
                                        alpha: 0.2,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      "#${widget.agency.enAttenteCount + 1}",
                                      style: const TextStyle(
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ],
                                ),
                      ).animate().scale().fadeIn(),

                    const SizedBox(height: 120),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      // Floating Bottom Navigation / Assistant
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: EdgeInsets.symmetric(horizontal: Responsive.padding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            VoiceGuideDebugChip.live(
              scope: 'screen:take_ticket',
              controller: _voiceGuide,
              margin: const EdgeInsets.only(bottom: 10),
            ),
            SolobaAssistant(
              onSelectService: (serviceId) {
                setState(() {
                  if (!selectedServices.contains(serviceId)) {
                    selectedServices.add(serviceId);
                  }
                });
              },
            ).animate().slideY(
              begin: 1,
              duration: 800.ms,
              curve: Curves.easeOutBack,
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(
        fontWeight: FontWeight.w600,
        color: AppColors.mutedForeground,
      ),
      prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
      filled: true,
      fillColor: AppColors.secondary.withValues(alpha: 0.3),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(24),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(24),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
    );
  }
}
