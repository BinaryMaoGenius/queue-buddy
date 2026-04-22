import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../constants/app_colors.dart';
import '../constants/app_strings.dart';
import '../models/gab.dart';
import '../models/ticket.dart';
import '../services/firebase_service.dart';
import '../utils/responsive_utils.dart';
import '../services/voice_guide_controller.dart';
import '../components/voice_guide_debug_chip.dart';
import '../services/djelia_speech_service.dart';
import 'analytics_page.dart';

class BackofficePage extends StatefulWidget {
  final String agenceId;

  const BackofficePage({super.key, required this.agenceId});

  @override
  State<BackofficePage> createState() => _BackofficePageState();
}

class _BackofficePageState extends State<BackofficePage>
    with SingleTickerProviderStateMixin {
  late final FirebaseService _firebaseService;
  bool _serviceReady = false;

  final VoiceGuideController _voiceGuide = VoiceGuideController();
  final DjeliaSpeechService _speechService = DjeliaSpeechService();
  bool isCalling = false;
  late AnimationController _headerAnimController;
  int _activeTab = 0; // 0: Tickets, 1: Terminaux

  @override
  void initState() {
    super.initState();
    _headerAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _scheduleVoiceGuide();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_serviceReady) {
      _firebaseService = context.read<FirebaseService>();
      _serviceReady = true;
    }
  }

  @override
  void dispose() {
    _headerAnimController.dispose();
    super.dispose();
  }

  Future<void> _scheduleVoiceGuide({bool immediate = false}) async {
    if (!mounted) return;

    final result = await _voiceGuide.requestForScreen(
      screenId: 'backoffice',
      text:
          "I ni sogoma. Nin ye back office ye. I bɛ se ka ticketw lajɛ, ka olu wele ka i ɲɛfɛ, ani ka analyse lajɛ.",
      priority:
          immediate ? VoiceGuidePriority.critical : VoiceGuidePriority.normal,
      immediate: immediate,
      minReplayInterval: const Duration(seconds: 20),
    );

    if (!result.isPlayed) {
      debugPrint("[BackofficePage] Voice guide skipped: ${result.reason}");
    }
  }

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);

    if (!_serviceReady) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: StreamBuilder<List<Ticket>>(
        stream: _firebaseService.getTickets(widget.agenceId),
        builder: (context, snapshot) {
          final tickets = snapshot.data ?? [];
          final activeTickets =
              tickets
                  .where((t) => t.statut == 'enAttente' || t.statut == 'appele')
                  .toList();

          final enAttenteCount =
              tickets.where((t) => t.statut == 'enAttente').length;
          final appeleCount = tickets.where((t) => t.statut == 'appele').length;
          final processedCount =
              tickets.where((t) => t.statut == 'valide').length;

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildSliverAppBar(enAttenteCount, appeleCount, processedCount),
              _buildTabPicker(),
              if (_activeTab == 0) ...[
                if (snapshot.connectionState == ConnectionState.waiting)
                  const SliverFillRemaining(
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    ),
                  )
                else if (activeTickets.isEmpty)
                  _buildEmptyState()
                else
                  _buildTicketList(activeTickets),
              ] else ...[
                _buildTerminalsList(),
              ],
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          );
        },
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Builder(
            builder:
                (_) => VoiceGuideDebugChip.live(
                  scope: 'screen:backoffice',
                  controller: _voiceGuide,
                  margin: EdgeInsets.only(bottom: 10),
                ),
          ),
          if (_activeTab == 0) _buildCallNextFAB(),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildSliverAppBar(int attente, int appele, int processed) {
    return SliverAppBar(
      expandedHeight: Responsive.hp(35),
      pinned: true,
      stretch: true,
      backgroundColor: AppColors.primary,
      elevation: 0,
      title: const Text(
        "BACK OFFICE PROMAX",
        style: TextStyle(
          fontWeight: FontWeight.w900,
          letterSpacing: 2,
          fontSize: 16,
          color: Colors.white,
        ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          tooltip: "Expliquer la page",
          icon: const Icon(
            Icons.record_voice_over_rounded,
            color: Colors.white,
          ),
          onPressed: () async {
            try {
              await _speechService.speakText(
                text:
                    "Nin ye back office ye. I bɛ se ka ticketw lajɛ, ka olu wele, ka analytics lajɛ, ani ka baara ɲɛnabɔ.",
                description:
                    "Moussa speaks with a very clear voice and friendly tone",
                format: "mp3",
              );
            } catch (e) {
              debugPrint("[BackofficePage] Direct TTS failed: $e");
            }
          },
        ),
        IconButton(
          icon: const Icon(Icons.analytics_rounded, color: Colors.white),
          onPressed:
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => AnalyticsPage(agenceId: widget.agenceId),
                ),
              ),
        ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            AnimatedBuilder(
              animation: _headerAnimController,
              builder: (context, child) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      stops: [0.0, _headerAnimController.value, 1.0],
                      colors: const [
                        AppColors.primary,
                        AppColors.primaryVibrant,
                        Color(0xFF031D16),
                      ],
                    ),
                  ),
                );
              },
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(25, 60, 25, 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "SUPERVISEUR AGENCE",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: Colors.white.withOpacity(0.6),
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.agenceId.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: _CompactStat(
                            label: "Attente",
                            value: attente.toString(),
                            color: AppColors.statusWarn,
                          ),
                        ),
                        Expanded(
                          child: _CompactStat(
                            label: "Guichet",
                            value: appele.toString(),
                            color: AppColors.statusOk,
                          ),
                        ),
                        Expanded(
                          child: _CompactStat(
                            label: "Traités",
                            value: processed.toString(),
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabPicker() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Expanded(
                child: _TabButton(
                  label: "TICKETS",
                  isActive: _activeTab == 0,
                  onTap: () => setState(() => _activeTab = 0),
                ),
              ),
              Expanded(
                child: _TabButton(
                  label: "TERMINAUX",
                  isActive: _activeTab == 1,
                  onTap: () => setState(() => _activeTab = 1),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline_rounded,
              size: 80,
              color: AppColors.statusOk.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            const Text(
              "Aucun ticket actif",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTicketList(List<Ticket> tickets) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => _TicketCard(
            ticket: tickets[index],
            onValidate: () {
              HapticFeedback.heavyImpact();
              _firebaseService.validerTicket(tickets[index].id);
            },
          ),
          childCount: tickets.length,
        ),
      ),
    );
  }

  Widget _buildTerminalsList() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            _buildTerminalSection(
              "GUICHETS",
              _firebaseService.getGuichets(widget.agenceId),
            ),
            const SizedBox(height: 24),
            _buildTerminalSection(
              "GABS (ATM)",
              _firebaseService.getGabs(widget.agenceId),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTerminalSection(String title, Stream<dynamic> stream) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: AppColors.primary,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 12),
        StreamBuilder(
          stream: stream,
          builder: (context, snapshot) {
            final items = snapshot.data as List? ?? [];
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                mainAxisExtent: 100,
              ),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final bool isGab = item is GAB;
                final String status = item.statut;
                final bool isActive = status == 'online' || status == 'open';

                return Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "${isGab ? 'ATM' : 'G.'} ${item.numero}",
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                            ),
                          ),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color:
                                  isActive
                                      ? AppColors.statusOk
                                      : AppColors.statusError,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          final String newStatus =
                              isActive
                                  ? (isGab ? 'maintenance' : 'closed')
                                  : (isGab ? 'online' : 'open');
                          _firebaseService.updateGuichetStatus(
                            item.id,
                            newStatus,
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 6,
                            horizontal: 12,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            isActive ? "DÉSACTIVER" : "ACTIVER",
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color:
                                  isActive
                                      ? AppColors.statusError
                                      : AppColors.statusOk,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildCallNextFAB() {
    return FloatingActionButton.extended(
      onPressed:
          isCalling
              ? null
              : () async {
                HapticFeedback.heavyImpact();
                setState(() => isCalling = true);
                await _firebaseService.appelerSuivant(widget.agenceId);
                setState(() => isCalling = false);
              },
      backgroundColor: AppColors.statusWarn,
      icon:
          isCalling
              ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
              : const Icon(Icons.campaign_rounded, color: Colors.white),
      label: const Text(
        AppStrings.callNext,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          letterSpacing: 1,
        ),
      ),
      elevation: 10,
    );
  }
}

class _CompactStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _CompactStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w900,
            color: Colors.white.withOpacity(0.5),
          ),
        ),
      ],
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.white : AppColors.mutedForeground,
              fontWeight: FontWeight.w900,
              fontSize: 11,
              letterSpacing: 1,
            ),
          ),
        ),
      ),
    );
  }
}

class _TicketCard extends StatelessWidget {
  final Ticket ticket;
  final VoidCallback onValidate;

  const _TicketCard({required this.ticket, required this.onValidate});

  @override
  Widget build(BuildContext context) {
    final bool isCalling = ticket.statut == 'appele';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border:
            isCalling
                ? Border.all(color: AppColors.statusWarn, width: 2)
                : null,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: const BoxDecoration(
              color: AppColors.background,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                ticket.numeroTicket.split('-').last,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ticket.clientNom,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
                Text(
                  "${ticket.typeOperation} • ${ticket.clientTel}",
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.mutedForeground,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (isCalling)
            IconButton.filled(
              onPressed: onValidate,
              icon: const Icon(Icons.check_rounded),
              style: IconButton.styleFrom(backgroundColor: AppColors.statusOk),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                "ATTENTE",
                style: TextStyle(
                  color: Colors.orange,
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
