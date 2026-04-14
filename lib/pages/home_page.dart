import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../components/agency_card.dart';
import '../components/soloba_assistant.dart';
import '../components/notification_bell.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../models/agence.dart';
import '../services/firebase_service.dart';
import '../constants/app_colors.dart';
import '../constants/app_strings.dart';
import 'take_ticket_page.dart';
import 'history_page.dart';
import 'backoffice_page.dart';
import 'admin_login_page.dart';
import 'package:intl/intl.dart';
import '../utils/responsive_utils.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirebaseService _firebaseService = FirebaseService();
  String? expandedAgencyId;
  bool _showWelcome = true;
  final FlutterTts _flutterTts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _initTts();
    // Auto-dismiss welcome banner after 8 seconds
    Future.delayed(const Duration(seconds: 8), () {
      if (mounted) {
        setState(() => _showWelcome = false);
      }
    });
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage("fr-FR"); // On utilise Fr car le Bambara n'est pas supporté nativement par TTS
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
    
    await _flutterTts.awaitSpeakCompletion(true);
    
    // Attendre un peu avant de parler pour laisser l'interface s'afficher
    Future.delayed(const Duration(milliseconds: 1200), () async {
      if (mounted && _showWelcome) {
        // Message en Bambara (lu par moteur Fr)
        await _flutterTts.speak(AppStrings.welcomeGreeting);
        
        // Petite pause naturelle
        await Future.delayed(const Duration(milliseconds: 800));
        
        if (mounted && _showWelcome) {
          // Message en Français
          await _flutterTts.speak(AppStrings.welcomeGreetingFr);
        }
      }
    });
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);
    
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Premium Header with Gradient
          SliverAppBar(
            expandedHeight: Responsive.hp(35),
            collapsedHeight: Responsive.hp(12),
            pinned: true,
            stretch: true,
            backgroundColor: AppColors.primary,
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground, StretchMode.blurBackground],
              background: Container(
                decoration: const BoxDecoration(
                  gradient: AppColors.premiumGradient,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(40),
                    bottomRight: Radius.circular(40),
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Image.asset(
                        'assets/images/premium_header.png',
                        fit: BoxFit.cover,
                      ).animate(onPlay: (c) => c.repeat())
                        .scale(begin: const Offset(1, 1), end: const Offset(1.05, 1.05), duration: 20.seconds, curve: Curves.easeInOutSine)
                        .then()
                        .scale(begin: const Offset(1.05, 1.05), end: const Offset(1, 1), duration: 20.seconds, curve: Curves.easeInOutSine),
                    ),
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              AppColors.primary.withValues(alpha: 0.4),
                              AppColors.primary.withValues(alpha: 0.9),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Top action buttons
                    Positioned(
                      top: 10,
                      right: 16,
                      child: SafeArea(
                        child: Row(
                          children: [
                            // Notification Bell
                            const NotificationBell(),
                            const SizedBox(width: 8),
                            // History
                            IconButton.filledTonal(
                              onPressed: () {
                                 Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const HistoryPage()),
                                );
                              },
                              icon: const Icon(Icons.history_rounded, color: Colors.white),
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.white.withValues(alpha: 0.2),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: SafeArea(
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(DateTime.now()).toUpperCase(),
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.7),
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 2,
                                    fontSize: Responsive.fs(12),
                                  ),
                                ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),
                                const SizedBox(height: 8),
                                GestureDetector(
                                  onLongPress: () {
                                    HapticFeedback.heavyImpact();
                                    _firebaseService.getAgences().first.then((agencies) {
                                      if (!context.mounted) return;
                                      if (agencies.isNotEmpty) {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (context) => AdminLoginPage(agenceId: agencies.first.id)),
                                        );
                                      }
                                    });
                                  },
                                  child: Text(
                                    AppStrings.homeTitle,
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                                      color: Colors.white,
                                      fontSize: Responsive.fs(56),
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -2,
                                    ),
                                  ),
                                ).animate().fadeIn(delay: 400.ms).scale(begin: const Offset(0.9, 0.9)),
                                Text(
                                  AppStrings.tagline,
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.8),
                                    fontWeight: FontWeight.w600,
                                    fontSize: Responsive.fs(16),
                                  ),
                                ).animate().fadeIn(delay: 600.ms),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Welcome Greeting Banner (Bambara)
          if (_showWelcome)
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(Responsive.padding, Responsive.padding, Responsive.padding, 0),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF064E3B), Color(0xFF059669)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.record_voice_over_rounded, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppStrings.welcomeGreeting,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.95),
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                fontStyle: FontStyle.italic,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              AppStrings.welcomeGreetingFr,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close_rounded, color: Colors.white.withValues(alpha: 0.6), size: 18),
                        onPressed: () => setState(() => _showWelcome = false),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.2, duration: 600.ms, curve: Curves.easeOutBack),
              ),
            ),

          // Quick Stats / Insights Overlay
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(Responsive.padding, Responsive.padding, Responsive.padding, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppStrings.proximityAgencies,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            "Conseil d'affluence",
                            style: TextStyle(color: AppColors.accent, fontSize: 11, fontWeight: FontWeight.w800),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Agency List Stream
          StreamBuilder<List<Agence>>(
            stream: _firebaseService.getAgences(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverToBoxAdapter(
                  child: Center(child: Padding(
                    padding: EdgeInsets.all(40.0),
                    child: CircularProgressIndicator(),
                  )),
                );
              }
              
              final agencies = snapshot.data ?? [];
              if (agencies.isEmpty) {
                return const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(40.0),
                      child: Text("Aucune agence trouvée.", style: TextStyle(color: AppColors.mutedForeground)),
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: Responsive.padding, vertical: 8),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final agency = agencies[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: AgencyCard(
                          agency: agency,
                          isExpanded: expandedAgencyId == agency.id,
                          onToggle: () {
                            setState(() {
                              expandedAgencyId = expandedAgencyId == agency.id ? null : agency.id;
                            });
                          },
                        ).animate(delay: (100 * index).ms).fadeIn().slideY(begin: 0.1),
                      );
                    },
                    childCount: agencies.length,
                  ),
                ),
              );
            },
          ),

          // Bottom Spacing for Assistant
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
      
      // Floating Bottom Navigation / Assistant
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: EdgeInsets.symmetric(horizontal: Responsive.padding),
        child: SolobaAssistant(
          onSelectService: (serviceId) {
            _firebaseService.getAgences().first.then((agencies) {
              if (!context.mounted) return;
              if (agencies.isNotEmpty) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TakeTicketPage(
                      agency: agencies.first,
                      initialServiceId: serviceId,
                    ),
                  ),
                );
              }
            });
          },
        ).animate().slideY(begin: 1, duration: 800.ms, curve: Curves.easeOutBack),
      ),
    );
  }
}
