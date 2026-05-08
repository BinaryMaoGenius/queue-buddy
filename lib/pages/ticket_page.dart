import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/ticket.dart';
import '../services/firebase_service.dart';
import '../services/notification_service.dart';
import '../constants/app_colors.dart';
import '../constants/app_strings.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/pdf_service.dart';
import '../utils/responsive_utils.dart';
import 'package:provider/provider.dart';
import '../components/glass_container.dart';
import '../components/voice_guide_debug_chip.dart';
import '../services/voice_guide_controller.dart';
import '../services/djelia_speech_service.dart';

class TicketPage extends StatefulWidget {
  final Ticket ticket;

  const TicketPage({super.key, required this.ticket});

  @override
  State<TicketPage> createState() => _TicketPageState();
}

class _TicketPageState extends State<TicketPage> with TickerProviderStateMixin {
  late final FirebaseService _firebaseService;
  final NotificationService _notifService = NotificationService();
  final VoiceGuideController _voiceGuide = VoiceGuideController();
  final DjeliaSpeechService _speechService = DjeliaSpeechService();
  final GlobalKey _ticketKey = GlobalKey();
  bool _showSuccessBanner = true;
  bool _voiceGuidePlayed = false;
  late AnimationController _successController;
  late Animation<double> _successAnimation;

  @override
  void initState() {
    super.initState();
    _firebaseService = context.read<FirebaseService>();
    _subscribeToNotifications();

    // Trigger success notification + cache scheduled "your turn" alert
    _notifService.onTicketTaken(
      widget.ticket.id,
      widget.ticket.numeroTicket,
      estimatedWaitMinutes:
          widget.ticket.position > 0 ? widget.ticket.position * 5 : 5,
      createdAt: widget.ticket.createdAt,
    );

    // Success banner animation
    _successController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _successAnimation = CurvedAnimation(
      parent: _successController,
      curve: Curves.easeOutBack,
    );
    _successController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _playVoiceGuide();
    });

    // Auto-dismiss banner after 6 seconds
    Future.delayed(const Duration(seconds: 6), () {
      if (mounted) {
        setState(() => _showSuccessBanner = false);
      }
    });
  }

  Future<void> _playVoiceGuide() async {
    if (_voiceGuidePlayed) return;
    _voiceGuidePlayed = true;

    final result = await _voiceGuide.requestForScreen(
      screenId: 'ticket',
      text: AppStrings.ticketVoiceGuideBm,
      priority: VoiceGuidePriority.critical,
      minReplayInterval: const Duration(seconds: 8),
      immediate: true,
    );

    if (!result.isPlayed) {
      debugPrint("[TicketPage] Voice guide skipped: ${result.reason}");
    }
  }

  Future<void> _replayVoiceGuide() async {
    try {
      await _speechService.speakText(
        text: AppStrings.ticketVoiceGuideBm,
        description: "Moussa speaks with a very clear voice and friendly tone",
        format: 'mp3',
      );
    } catch (e) {
      debugPrint("[TicketPage] Direct TTS replay failed: $e");
    }
  }

  @override
  void dispose() {
    _successController.dispose();
    super.dispose();
  }

  Future<void> _subscribeToNotifications() async {
    await _firebaseService.subscribeToTicketTopic(widget.ticket.id);
  }

  Future<void> _downloadTicket() async {
    try {
      HapticFeedback.mediumImpact();
      await PdfService.generateAndDownloadTicket(widget.ticket);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  AppStrings.ticketSaved('fr'),
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            backgroundColor: AppColors.statusOk,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Erreur PDF: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.premiumGradient),
        child: SafeArea(
          child: Column(
            children: [
              AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                foregroundColor: Colors.white,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                title: Text(
                  AppStrings.yourTicket('fr'),
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 3,
                    fontSize: 14,
                  ),
                ),
                centerTitle: true,
                actions: [
                  IconButton(
                    tooltip: "Lire l'aide vocale",
                    onPressed: _replayVoiceGuide,
                    icon: const Icon(Icons.volume_up_rounded),
                  ),
                ],
              ),

              // Success Banner
              if (_showSuccessBanner)
                ScaleTransition(
                  scale: _successAnimation,
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.statusOk,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.statusOk.withValues(alpha: 0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.check_circle_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Ticket pris avec succès !",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "Vous serez notifié quand c'est votre tour",
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.close_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                          onPressed:
                              () => setState(() => _showSuccessBanner = false),
                        ),
                      ],
                    ),
                  ),
                ).animate().fadeIn().slideY(
                  begin: -0.3,
                  duration: 600.ms,
                  curve: Curves.easeOutBack,
                ),

              Expanded(
                child: StreamBuilder<Ticket?>(
                  stream: _firebaseService.getTicket(widget.ticket.id),
                  initialData: widget.ticket,
                  builder: (context, snapshot) {
                    final currentTicket = snapshot.data;

                    if (currentTicket == null) {
                      return const Center(
                        child: Text(
                          "Ticket introuvable",
                          style: TextStyle(color: Colors.white),
                        ),
                      );
                    }

                    final bool isCalled = currentTicket.statut == 'appele';

                    return Center(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.symmetric(
                          horizontal: Responsive.padding,
                          vertical: 24,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Align(
                              alignment: Alignment.centerRight,
                              child: VoiceGuideDebugChip.live(
                                scope: 'screen:ticket',
                                controller: _voiceGuide,
                                margin: const EdgeInsets.only(bottom: 8),
                              ),
                            ),
                            RepaintBoundary(
                              key: _ticketKey,
                              child: _TicketCard(
                                ticket: currentTicket,
                                isCalled: isCalled,
                              ),
                            ),
                            const SizedBox(height: 32),

                            if (!isCalled) ...[
                              // Waiting status - MUCH MORE VISIBLE
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    width: 1.5,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Container(
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(
                                              alpha: 0.15,
                                            ),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.hourglass_top_rounded,
                                            color: Colors.white,
                                            size: 36,
                                          ),
                                        )
                                        .animate(onPlay: (c) => c.repeat())
                                        .rotate(duration: 2.seconds),
                                    const SizedBox(height: 16),
                                    const Text(
                                      "Veuillez patienter...",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    StreamBuilder<Map<String, dynamic>>(
                                      stream: _firebaseService.getAnalyticsStream(currentTicket.agenceId),
                                      builder: (context, animSnapshot) {
                                        final analytics = animSnapshot.data;
                                        // We get all tickets to calculate the load factor
                                        return StreamBuilder<List<Ticket>>(
                                          stream: _firebaseService.getTickets(currentTicket.agenceId),
                                          builder: (context, ticketsSnapshot) {
                                            final activeTickets = ticketsSnapshot.data ?? [];
                                            final waitTime = _firebaseService.estimateWaitTime(
                                              activeTickets,
                                              currentTicket.position,
                                              analytics,
                                            );

                                            return Text(
                                              "Estimation : ~${waitTime.toStringAsFixed(0)} minutes",
                                              style: TextStyle(
                                                color: Colors.white.withValues(
                                                  alpha: 0.9,
                                                ),
                                                fontSize: 16,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            );
                                          },
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      AppStrings.notificationSoon('fr'),
                                      style: TextStyle(
                                        color: Colors.white.withValues(
                                          alpha: 0.7,
                                        ),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 16),
                                    // Notification status indicators
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 6,
                                      alignment: WrapAlignment.center,
                                      children: [
                                        _AlertChip(
                                          icon: Icons.check_circle,
                                          label: "Ticket confirmé",
                                          isActive: true,
                                        ),
                                        _AlertChip(
                                          icon: Icons.timer,
                                          label: "Alerte 30 min",
                                          isActive: false,
                                        ),
                                        _AlertChip(
                                          icon: Icons.alarm,
                                          label: "Alerte 10 min",
                                          isActive: false,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),
                            ] else
                              const SizedBox.shrink(),

                            const SizedBox(height: 24),

                            // Download Button
                            ElevatedButton.icon(
                                  onPressed: _downloadTicket,
                                  icon: const Icon(Icons.download_rounded),
                                  label: const Text(
                                    AppStrings.downloadTicket('fr'),
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: AppColors.primary,
                                    minimumSize: Size(
                                      double.infinity,
                                      Responsive.hp(7),
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                    elevation: 0,
                                  ),
                                )
                                .animate(delay: 400.ms)
                                .fadeIn()
                                .slideY(begin: 0.1),

                            const SizedBox(height: 12),

                            if (currentTicket.statut == 'valide' &&
                                currentTicket.rating == null)
                              _ReviewSection(ticketId: currentTicket.id)
                                  .animate()
                                  .fadeIn()
                                  .scale(begin: const Offset(0.9, 0.9)),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                HapticFeedback.mediumImpact();
                                Navigator.of(
                                  context,
                                ).popUntil((route) => route.isFirst);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white.withValues(
                                  alpha: 0.1,
                                ),
                                foregroundColor: Colors.white,
                                minimumSize: Size(
                                  double.infinity,
                                  Responsive.hp(8),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(28),
                                  side: BorderSide(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    width: 1.5,
                                  ),
                                ),
                                elevation: 0,
                              ),
                              child: const Text(
                                AppStrings.returnHome('fr'),
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AlertChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;

  const _AlertChip({
    required this.icon,
    required this.label,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color:
            isActive
                ? Colors.white.withValues(alpha: 0.2)
                : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              isActive
                  ? Colors.white.withValues(alpha: 0.4)
                  : Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color:
                isActive ? Colors.white : Colors.white.withValues(alpha: 0.4),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color:
                  isActive ? Colors.white : Colors.white.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _TicketCard extends StatelessWidget {
  final Ticket ticket;
  final bool isCalled;

  const _TicketCard({required this.ticket, required this.isCalled});

  @override
  Widget build(BuildContext context) {
    return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 40,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: Column(
            children: [
              // Top Part
              Padding(
                padding: EdgeInsets.all(Responsive.padding * 1.5),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        ticket.typeOperation.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primary,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      ticket.numeroTicket,
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        color: AppColors.primary,
                        fontSize: Responsive.fs(56),
                        letterSpacing: -2,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // QR Code
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.secondary,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        children: [
                          QrImageView(
                            data:
                                'SIRA-TICKET:${ticket.id}|${ticket.numeroTicket}|${ticket.clientNom}|${ticket.typeOperation}',
                            version: QrVersions.auto,
                            size: 120,
                            gapless: true,
                            eyeStyle: const QrEyeStyle(
                              eyeShape: QrEyeShape.square,
                              color: AppColors.primary,
                            ),
                            dataModuleStyle: const QrDataModuleStyle(
                              dataModuleShape: QrDataModuleShape.square,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            AppStrings.scanAtArrival('fr'),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.mutedForeground.withValues(
                                alpha: 0.7,
                              ),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                    const Divider(height: 1, color: AppColors.secondary),
                    const SizedBox(height: 24),

                    if (isCalled)
                      const Column(
                            children: [
                              Icon(
                                Icons.notifications_active_rounded,
                                color: AppColors.statusOk,
                                size: 56,
                              ),
                              SizedBox(height: 16),
                              Text(
                                AppStrings.itsYourTurn('fr'),
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.statusOk,
                                  letterSpacing: -1,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                AppStrings.presentAtCounter('fr'),
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.mutedForeground,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          )
                          .animate()
                          .scale(duration: 400.ms, curve: Curves.easeOutBack)
                          .shimmer(duration: 2.seconds)
                    else
                      Column(
                        children: [
                          const Text(
                            AppStrings.positionInQueue('fr'),
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.mutedForeground,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              ticket.position.toString(),
                              style: const TextStyle(
                                fontSize: 42,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            AppStrings.peopleInFront('fr'),
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.mutedForeground,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),

              // Perforation Effect
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    height: 1,
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(horizontal: 40),
                    color: AppColors.secondary,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _halfCircle(isLeft: true),
                      _halfCircle(isLeft: false),
                    ],
                  ),
                ],
              ),

              // Bottom Part
              Padding(
                padding: EdgeInsets.all(Responsive.padding * 1.5),
                child: Column(
                  children: [
                    _InfoRow(
                      label: "CLIENT",
                      value: ticket.clientNom.toUpperCase(),
                    ),
                    const SizedBox(height: 20),
                    _InfoRow(
                      label: "AGENCE",
                      value: ticket.agenceNom.toUpperCase(),
                    ),
                    const SizedBox(height: 20),
                    const _InfoRow(label: "DATE & HEURE", value: "AUJOURD'HUI"),
                  ],
                ),
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: 800.ms)
        .slideY(begin: 0.1, duration: 800.ms, curve: Curves.easeOutQuart);
  }

  Widget _halfCircle({required bool isLeft}) {
    return Container(
      width: 24,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          topRight: isLeft ? const Radius.circular(24) : Radius.zero,
          bottomRight: isLeft ? const Radius.circular(24) : Radius.zero,
          topLeft: isLeft ? Radius.zero : const Radius.circular(24),
          bottomLeft: isLeft ? Radius.zero : const Radius.circular(24),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.mutedForeground,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 13,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }
}

class _ReviewSection extends StatefulWidget {
  final String ticketId;
  const _ReviewSection({required this.ticketId});

  @override
  State<_ReviewSection> createState() => _ReviewSectionState();
}

class _ReviewSectionState extends State<_ReviewSection> {
  int _rating = 0;
  final TextEditingController _commentController = TextEditingController();
  late final FirebaseService _firebaseService;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _firebaseService = context.read<FirebaseService>();
  }

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      blur: 15,
      opacity: 0.1,
      borderRadius: 32,
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            const Text(
              AppStrings.yourReview,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              AppStrings.howWasWait,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  icon: Icon(
                    index < _rating
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color:
                        index < _rating
                            ? Colors.amber
                            : Colors.white.withValues(alpha: 0.3),
                    size: 40,
                  ),
                  onPressed: () => setState(() => _rating = index + 1),
                );
              }),
            ),
            if (_rating > 0) ...[
              const SizedBox(height: 24),
              TextField(
                controller: _commentController,
                maxLines: 2,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: AppStrings.optionalComment,
                  hintStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                  ),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed:
                    _isSubmitting
                        ? null
                        : () async {
                          setState(() => _isSubmitting = true);
                          await _firebaseService.submitReview(
                            widget.ticketId,
                            _rating,
                            _commentController.text,
                          );
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(AppStrings.thanksFeedback),
                              ),
                            );
                          }
                        },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.statusOk,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child:
                    _isSubmitting
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                          AppStrings.send,
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                          ),
                        ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
