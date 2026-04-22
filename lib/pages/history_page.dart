import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../models/ticket.dart';
import '../services/firebase_service.dart';
import '../constants/app_colors.dart';
import '../constants/app_strings.dart';
import 'package:intl/intl.dart';
import '../utils/responsive_utils.dart';
import '../services/voice_guide_controller.dart';
import '../components/voice_guide_debug_chip.dart';
import '../services/djelia_speech_service.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _bgAnimController;
  final VoiceGuideController _voiceGuideController = VoiceGuideController();
  final DjeliaSpeechService _speechService = DjeliaSpeechService();

  @override
  void initState() {
    super.initState();
    _bgAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat(reverse: true);
    _scheduleVoiceGuide();
  }

  @override
  void dispose() {
    _bgAnimController.dispose();
    super.dispose();
  }

  Future<void> _scheduleVoiceGuide() async {
    if (!mounted) return;

    await _voiceGuideController.requestForScreen(
      screenId: 'history',
      text: AppStrings.historyVoiceGuideBm,
      priority: VoiceGuidePriority.critical,
      minReplayInterval: Duration.zero,
      force: true,
      immediate: true,
    );
  }

  Future<void> _speakHistoryGuideDirect() async {
    try {
      await _speechService.speakText(
        text: AppStrings.historyVoiceGuideBm,
        description: "Moussa speaks with a very clear voice and friendly tone",
        format: "mp3",
      );
    } catch (e) {
      debugPrint("[HistoryPage] Direct TTS failed: $e");
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
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                Responsive.padding,
                24,
                Responsive.padding,
                8,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: VoiceGuideDebugChip.live(
                      scope: 'screen:history',
                      controller: _voiceGuideController,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.history_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "TOUS VOS TICKETS",
                        style: TextStyle(
                          color: AppColors.primary.withOpacity(0.8),
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          FutureBuilder<List<Ticket>>(
            future: context.read<FirebaseService>().getHistoryTickets(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                );
              }

              final tickets = snapshot.data ?? [];

              if (tickets.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(32),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.05),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.assignment_late_rounded,
                                size: 60,
                                color: AppColors.primary.withOpacity(0.2),
                              ),
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              AppStrings.noTickets,
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              AppStrings.futureTicketsPrompt,
                              style: TextStyle(
                                color: AppColors.mutedForeground,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      )
                      .animate()
                      .fadeIn(duration: 600.ms)
                      .scale(begin: const Offset(0.9, 0.9)),
                );
              }

              return SliverPadding(
                padding: EdgeInsets.all(Responsive.padding),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final ticket = tickets[index];
                    return _HistoryCardPro(ticket: ticket)
                        .animate(delay: (index * 60).ms)
                        .fadeIn(duration: 400.ms)
                        .slideY(begin: 0.1, curve: Curves.easeOutQuad);
                  }, childCount: tickets.length),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: Responsive.hp(25),
      pinned: true,
      backgroundColor: AppColors.primary,
      elevation: 0,
      leading: const BackButton(color: Colors.white),
      actions: [
        IconButton(
          tooltip: "Lire l'aide vocale",
          onPressed: _speakHistoryGuideDirect,
          icon: const Icon(
            Icons.volume_up_rounded,
            color: Colors.white,
            size: 20,
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            AnimatedBuilder(
              animation: _bgAnimController,
              builder: (context, child) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomLeft,
                      end: Alignment.topRight,
                      colors: const [
                        Color(0xFF032F23),
                        AppColors.primary,
                        Color(0xFF065F46),
                      ],
                      stops: [0.0, _bgAnimController.value, 1.0],
                    ),
                  ),
                );
              },
            ),
            Positioned(
              bottom: 40,
              left: 20,
              right: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      "ARCHIVES",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 10,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Historique des Tickets",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 28,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryCardPro extends StatelessWidget {
  final Ticket ticket;
  const _HistoryCardPro({required this.ticket});

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(ticket.statut);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 6, color: statusColor),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              ticket.numeroTicket,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                color: AppColors.primary,
                                fontSize: 18,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  ticket.typeOperation,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16,
                                    color: AppColors.foreground,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  DateFormat(
                                    'd MMMM yyyy • HH:mm',
                                    'fr',
                                  ).format(ticket.createdAt),
                                  style: TextStyle(
                                    color: AppColors.mutedForeground
                                        .withOpacity(0.7),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _StatusBadge(statut: ticket.statut),
                        ],
                      ),
                      if (ticket.rating != null) ...[
                        const SizedBox(height: 16),
                        const Divider(height: 1),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Text(
                              "VOTRE ÉVALUATION",
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                color: AppColors.mutedForeground.withOpacity(
                                  0.6,
                                ),
                                letterSpacing: 0.5,
                              ),
                            ),
                            const Spacer(),
                            Row(
                              children: List.generate(
                                5,
                                (i) => Icon(
                                  Icons.star_rounded,
                                  size: 16,
                                  color:
                                      i < ticket.rating!
                                          ? Colors.amber
                                          : Colors.grey.withOpacity(0.2),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String statut) {
    switch (statut) {
      case 'enAttente':
        return Colors.orange;
      case 'appele':
        return AppColors.statusWarn;
      case 'valide':
        return AppColors.statusOk;
      default:
        return Colors.grey;
    }
  }
}

class _StatusBadge extends StatelessWidget {
  final String statut;
  const _StatusBadge({required this.statut});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;

    switch (statut) {
      case 'enAttente':
        color = Colors.orange;
        label = "ATTENTE";
        break;
      case 'appele':
        color = AppColors.statusWarn;
        label = "APPELÉ";
        break;
      case 'valide':
        color = AppColors.statusOk;
        label = "TERMINÉ";
        break;
      default:
        color = Colors.grey;
        label = statut.toUpperCase();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 8,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
