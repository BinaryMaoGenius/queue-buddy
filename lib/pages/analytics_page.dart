import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/firebase_service.dart';
import '../constants/app_colors.dart';
import '../utils/responsive_utils.dart';

class AnalyticsPage extends StatefulWidget {
  final String agenceId;
  const AnalyticsPage({super.key, required this.agenceId});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> with SingleTickerProviderStateMixin {
  late AnimationController _bgAnimController;

  @override
  void initState() {
    super.initState();
    _bgAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _bgAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);
    final FirebaseService firebaseService = FirebaseService();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: StreamBuilder<Map<String, dynamic>>(
        stream: firebaseService.getAnalyticsStream(widget.agenceId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }
          final stats = snapshot.data!;
          
          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildSliverAppBar(),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(Responsive.hp(2.5)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSummaryGrid(stats),
                      const SizedBox(height: 32),
                      _buildChartSection(stats['volumeByHour'] as Map<int, int>),
                      const SizedBox(height: 32),
                      _buildWaitTimeSection((stats['avgWait'] as num).toDouble()),
                      const SizedBox(height: 48),
                      Center(
                        child: Text(
                          "Données mises à jour en temps réel",
                          style: TextStyle(
                            color: AppColors.mutedForeground.withOpacity(0.6),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          );
        }
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
      title: const Text(
        "RAPPORTS D'ACTIVITÉ",
        style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 14, color: Colors.white),
      ),
      centerTitle: true,
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
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: const [AppColors.primary, AppColors.primaryVibrant, Color(0xFF032F23)],
                      stops: [0.0, _bgAnimController.value, 1.0],
                    ),
                  ),
                );
              },
            ),
            Positioned(
              bottom: 40,
              left: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "PERFORMANCE",
                    style: TextStyle(color: Colors.white.withOpacity(0.6), fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 2),
                  ),
                  const Text(
                    "Statistiques Agence",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 28, letterSpacing: -0.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryGrid(Map<String, dynamic> stats) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.1,
      children: [
        _StatCardPro(
          title: "Clients du jour",
          value: stats['totalToday'].toString(),
          icon: Icons.people_alt_rounded,
          color: AppColors.primaryVibrant,
          trend: "+12%",
        ),
        _StatCardPro(
          title: "Tickets Validés",
          value: stats['processedToday'].toString(),
          icon: Icons.verified_rounded,
          color: AppColors.statusOk,
          trend: "Match",
        ),
      ],
    );
  }

  Widget _buildChartSection(Map<int, int> data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader("Volume d'affluence", "Par créneau horaire"),
        const SizedBox(height: 16),
        Container(
          height: 260,
          padding: const EdgeInsets.fromLTRB(16, 32, 16, 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 10)),
            ],
          ),
          child: BarChart(
            BarChartData(
              barGroups: _generateGroups(data),
              gridData: const FlGridData(show: false),
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      if (value % 2 == 0 && value >= 8 && value <= 18) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text("${value.toInt()}h", style: TextStyle(fontSize: 10, color: AppColors.mutedForeground.withOpacity(0.8), fontWeight: FontWeight.bold)),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => AppColors.primary,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    return BarTooltipItem(
                      "${rod.toY.toInt()} clients",
                      const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<BarChartGroupData> _generateGroups(Map<int, int> data) {
    return List.generate(11, (i) {
      final h = i + 8;
      final val = (data[h] ?? 0).toDouble();
      return BarChartGroupData(
        x: h,
        barRods: [
          BarChartRodData(
            toY: val,
            color: h == DateTime.now().hour ? AppColors.accent : AppColors.primary,
            width: 14,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: 15,
              color: AppColors.background,
            ),
          ),
        ],
      );
    });
  }

  Widget _buildWaitTimeSection(double avgMinutes) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(32),
        image: DecorationImage(
          image: const NetworkImage("https://www.transparenttextures.com/patterns/cubes.png"),
          opacity: 0.05,
          colorFilter: ColorFilter.mode(Colors.white.withOpacity(0.1), BlendMode.srcIn),
        ),
        boxShadow: [
          BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 25, offset: const Offset(0, 15)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("TEMPS D'ATTENTE MOYEN", style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                  const SizedBox(height: 4),
                  const Text("Efficacité du Service", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                ],
              ),
              const Icon(Icons.timer_outlined, color: Colors.white, size: 30),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "${avgMinutes.toInt()}",
                style: const TextStyle(color: Colors.white, fontSize: 56, fontWeight: FontWeight.w900, height: 1),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 8, left: 8),
                child: Text("minutes", style: TextStyle(color: Colors.white70, fontSize: 18, fontWeight: FontWeight.w600)),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                child: const Text("Optimal", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title.toUpperCase(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.primary, letterSpacing: -0.5)),
        Text(subtitle, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.mutedForeground.withOpacity(0.7))),
      ],
    );
  }
}

class _StatCardPro extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String trend;

  const _StatCardPro({required this.title, required this.value, required this.icon, required this.color, required this.trend});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 15, offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: color, size: 20),
              ),
              Text(trend, style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.w900)),
            ],
          ),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: AppColors.primary, height: 1.1)),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.mutedForeground.withOpacity(0.8), letterSpacing: -0.2)),
        ],
      ),
    );
  }
}

