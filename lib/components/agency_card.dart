import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/agence.dart';
import '../constants/app_colors.dart';
import '../services/firebase_service.dart';
import '../constants/app_strings.dart';
import '../pages/take_ticket_page.dart';
import 'glass_container.dart';
import '../utils/responsive_utils.dart';

class AgencyCard extends StatefulWidget {
  final Agence agency;
  final bool isExpanded;
  final VoidCallback onToggle;

  const AgencyCard({
    super.key,
    required this.agency,
    required this.isExpanded,
    required this.onToggle,
  });

  @override
  State<AgencyCard> createState() => _AgencyCardState();
}

class _AgencyCardState extends State<AgencyCard> {
  final FirebaseService _firebaseService = FirebaseService();

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutQuart,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: widget.isExpanded ? 0.08 : 0.04),
            blurRadius: widget.isExpanded ? 30 : 20,
            offset: Offset(0, widget.isExpanded ? 15 : 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Column(
          children: [
            InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                widget.onToggle();
              },
              child: Padding(
                padding: EdgeInsets.all(Responsive.padding),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Agency Icon / Initial
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: AppColors.premiumGradient,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.account_balance_rounded, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.agency.nom,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: Responsive.fs(16)),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.agency.adresse,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.mutedForeground,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.orange.withValues(alpha: 0.25)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.timer_rounded, size: 14, color: Colors.orange),
                                const SizedBox(width: 6),
                                Text(
                                  "${AppStrings.peakHoursLabel} ${widget.agency.peakHours}",
                                  style: const TextStyle(
                                    color: Colors.orange,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          "~${widget.agency.enAttenteCount * 5} min",
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w900,
                            fontSize: Responsive.fs(16),
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: AppColors.statusOk,
                                shape: BoxShape.circle,
                              ),
                            ).animate(onPlay: (c) => c.repeat())
                             .scale(duration: 1.seconds, begin: const Offset(1, 1), end: const Offset(1.5, 1.5))
                             .fadeOut(duration: 1.seconds),
                            const SizedBox(width: 4),
                            Text(
                              AppStrings.live.toUpperCase(),
                              style: TextStyle(
                                color: AppColors.statusOk.withValues(alpha: 0.8),
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            // Expanded content with glass effect
            AnimatedHorizontalScale(
              show: widget.isExpanded,
              duration: 400.ms,
              child: Padding(
                padding: EdgeInsets.fromLTRB(Responsive.padding, 0, Responsive.padding, Responsive.padding),
                child: GlassContainer(
                  borderRadius: 24,
                  opacity: 0.05,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        // GAB (Distributeurs automatiques) vs Guichets (Comptoirs humains)
                        StreamBuilder<List<GAB>>(
                      stream: _firebaseService.getGabs(widget.agency.id),
                      builder: (context, gabSnapshot) {
                        final gabs = gabSnapshot.data ?? [];
                        final okGabs = gabs.where((g) => g.statut == 'online').length;
                        
                        return StreamBuilder<List<Guichet>>(
                          stream: _firebaseService.getGuichets(widget.agency.id),
                          builder: (context, guichetSnapshot) {
                            final guichets = guichetSnapshot.data ?? [];
                            final openGuichets = guichets.where((g) => g.statut == 'open').length;
                            
                            return Column(
                              children: [
                                // GAB Section — ATMs (Carte bancaire)
                                _DetailedInfoRow(
                                  icon: Icons.credit_card_rounded,
                                  title: AppStrings.gabLabel,
                                  subtitle: AppStrings.gabDescription,
                                  statusText: "$okGabs sur ${gabs.length} fonctionnels",
                                  color: okGabs == gabs.length ? AppColors.statusOk : AppColors.statusWarn,
                                ),
                                const SizedBox(height: 10),
                                // Guichet Section — Human service counters
                                _DetailedInfoRow(
                                  icon: Icons.support_agent_rounded,
                                  title: AppStrings.guichetLabel,
                                  subtitle: AppStrings.guichetDescription,
                                  statusText: "$openGuichets sur ${guichets.length} fonctionnels",
                                  color: openGuichets > 0 ? AppColors.statusOk : AppColors.statusError,
                                ),
                                const SizedBox(height: 10),
                                // Peak hours
                                _InfoBadge(
                                  label: "${AppStrings.peakHoursLabel} ${widget.agency.peakHours}",
                                  icon: Icons.timer_rounded,
                                  color: Colors.orange,
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Action Button
                    ElevatedButton(
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TakeTicketPage(agency: widget.agency),
                          ),
                        );
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.airplane_ticket_rounded, size: Responsive.fs(20)),
                          SizedBox(width: Responsive.wp(3)),
                          Text(AppStrings.takeTicket.toUpperCase(), style: TextStyle(fontSize: Responsive.fs(14))),
                        ],
                      ),
                    ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  ).animate().fadeIn(duration: 600.ms, curve: Curves.easeOut).moveY(begin: 12, end: 0, duration: 600.ms, curve: Curves.easeOutBack);
}
}

class AnimatedHorizontalScale extends StatelessWidget {
  final bool show;
  final Widget child;
  final Duration duration;

  const AnimatedHorizontalScale({super.key, required this.show, required this.child, required this.duration});

  @override
  Widget build(BuildContext context) {
    return AnimatedCrossFade(
      firstChild: const SizedBox(width: double.infinity),
      secondChild: child,
      crossFadeState: show ? CrossFadeState.showSecond : CrossFadeState.showFirst,
      duration: duration,
    );
  }
}

class _InfoBadge extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _InfoBadge({
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12, 
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailedInfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String statusText;
  final Color color;

  const _DetailedInfoRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.statusText,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.foreground,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              statusText,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
