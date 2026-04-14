import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/firebase_service.dart';
import '../models/ticket.dart';
import '../models/agence.dart';
import '../constants/app_colors.dart';
import '../constants/app_strings.dart';
import '../utils/responsive_utils.dart';
import 'package:flutter/services.dart';

class AdminDashboardPage extends StatefulWidget {
  final String agenceId;
  const AdminDashboardPage({super.key, required this.agenceId});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> with SingleTickerProviderStateMixin {
  final FirebaseService _firebaseService = FirebaseService();
  bool isCalling = false;

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1B3E),
        elevation: 0,
        title: const Text("Tableau de bord de SIRA", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
        centerTitle: false,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16, top: 12, bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Center(child: Text("Dernière mise à jour : ${DateTime.now().day} avr 2026", style: const TextStyle(color: Colors.white, fontSize: 10))),
          ),
        ],
      ),
      body: StreamBuilder<Map<String, dynamic>>(
        stream: _firebaseService.getAnalyticsStream(widget.agenceId),
        builder: (context, analyticsSnapshot) {
          return StreamBuilder<List<Ticket>>(
            stream: _firebaseService.getTickets(widget.agenceId),
            builder: (context, ticketsSnapshot) {
              if (analyticsSnapshot.connectionState == ConnectionState.waiting || ticketsSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Color(0xFF0D1B3E)));
              }

              final stats = analyticsSnapshot.data ?? {
                'totalToday': 0,
                'avgWait': 0,
                'processedToday': 0,
                'volumeByHour': <int, int>{},
              };

              final tickets = ticketsSnapshot.data ?? [];
              final activeTickets = tickets.where((t) => t.statut == 'enAttente' || t.statut == 'appele').toList();
              final historyTickets = tickets.where((t) => t.statut == 'valide').take(5).toList();

              return SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // ROW 1: KPIs
                    _buildKPIRow(activeTickets.where((t)=>t.statut=='enAttente').length, stats),
                    const SizedBox(height: 24),

                    // ROW 2: Pie Charts + Column Chart
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildPieAnalysis(title: "Analyse des GAB (ATM)", stream: _firebaseService.getGabs(widget.agenceId))),
                        const SizedBox(width: 24),
                        Expanded(child: _buildPieAnalysis(title: "Analyse des guichets", stream: _firebaseService.getGuichets(widget.agenceId))),
                        const SizedBox(width: 24),
                        Expanded(flex: 2, child: _buildHighFrequencyChart(stats['volumeByHour'] as Map<int, int>)),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // ROW 3: Operations Distribution + Wait time by type
                    Row(
                      children: [
                        Expanded(child: _buildOperationsDistributionChart(tickets)),
                        const SizedBox(width: 24),
                        Expanded(child: _buildWaitTimeByTypeChart()),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // ROW 4: History Table
                    _buildHistoryTable(historyTickets),

                    const SizedBox(height: 100),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: isCalling ? null : () async {
          setState(() => isCalling = true);
          await _firebaseService.appelerSuivant(widget.agenceId);
          setState(() => isCalling = false);
        },
        backgroundColor: const Color(0xFF0D1B3E),
        icon: isCalling ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.campaign, color: Colors.white),
        label: const Text("APPELER SUIVANT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildKPIRow(int waiting, Map<String, dynamic> stats) {
    return Row(
      children: [
        Expanded(child: _StatCard(title: "Nombre de clients en attente", value: waiting.toString(), trend: "-18%", color: Colors.green)),
        const SizedBox(width: 16),
        Expanded(child: _StatCard(title: "Temps d'attente moyen (min)", value: "${stats['avgWait'].toInt()}", trend: "-25%", color: Colors.green)),
        const SizedBox(width: 16),
        Expanded(child: _StatCard(title: "Clients servis aujourd'hui", value: stats['totalToday'].toString(), trend: "+14%", color: Colors.green)),
        const SizedBox(width: 16),
        Expanded(child: _StatCard(title: "Tickets validés aujourd'hui", value: stats['processedToday'].toString(), trend: "+17%", color: Colors.green)),
      ],
    );
  }

  Widget _buildPieAnalysis({required String title, required Stream stream}) {
    return Container(
      padding: const EdgeInsets.all(20),
      height: 300,
      decoration: _cardDeco(),
      child: Column(
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const Spacer(),
          StreamBuilder(
            stream: stream,
            builder: (context, snapshot) {
              final items = snapshot.data as List? ?? [];
              final int active = items.where((i) => i.statut == 'online' || i.statut == 'open').length;
              final int inactive = items.length - active;
              
              return SizedBox(
                height: 180,
                child: PieChart(
                  PieChartData(
                    sections: [
                      PieChartSectionData(value: active.toDouble(), color: const Color(0xFF4F46E5), title: "$active", radius: 50, titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      PieChartSectionData(value: inactive.toDouble(), color: const Color(0xFF94A3B8), title: "$inactive", radius: 50, titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ],
                    centerSpaceRadius: 40,
                  ),
                ),
              );
            },
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _Legend(color: const Color(0xFF4F46E5), label: "Actif"),
              const SizedBox(width: 16),
              _Legend(color: const Color(0xFF94A3B8), label: "Inactif"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHighFrequencyChart(Map<int, int> data) {
    return Container(
      padding: const EdgeInsets.all(20),
      height: 300,
      decoration: _cardDeco(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Courbe de fréquentation horaire", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 20),
          Expanded(
            child: BarChart(
              BarChartData(
                barGroups: List.generate(10, (i) {
                  int hour = i + 9;
                  double val = (data[hour] ?? 0).toDouble();
                  return BarChartGroupData(
                    x: hour,
                    barRods: [BarChartRodData(toY: val, color: const Color(0xFF4F46E5), width: 16, borderRadius: BorderRadius.circular(4))],
                  );
                }),
                gridData: const FlGridData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (val, _) => Text("${val.toInt()}h", style: const TextStyle(fontSize: 10)),
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOperationsDistributionChart(List<Ticket> tickets) {
    return Container(
      padding: const EdgeInsets.all(20),
      height: 280,
      decoration: _cardDeco(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Clients par type d'opération effectué", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 20),
          Expanded(
            child: Row(
              children: [
                Expanded(flex: 3, child: _OpBox(label: "Dépôts", color: const Color(0xFF312E81))),
                const SizedBox(width: 4),
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      Expanded(child: _OpBox(label: "Retraits", color: const Color(0xFF6366F1))),
                      const SizedBox(height: 4),
                      Expanded(child: _OpBox(label: "Gestion de compte", color: const Color(0xFF818CF8))),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaitTimeByTypeChart() {
    return Container(
      padding: const EdgeInsets.all(20),
      height: 280,
      decoration: _cardDeco(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Temps d'attente estimé par type de transaction", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 20),
          _HBar(label: "Deposits", val: 0.2),
          _HBar(label: "Retraits", val: 0.5),
          _HBar(label: "Gestion c.", val: 0.7),
          _HBar(label: "Renseignement", val: 0.9),
        ],
      ),
    );
  }

  Widget _buildHistoryTable(List<Ticket> history) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: _cardDeco(),
      child: Column(
        children: [
          const Text("Historiques des tickets", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 20),
          Table(
            border: TableBorder(horizontalInside: BorderSide(color: Colors.grey.shade200)),
            children: [
              const TableRow(
                children: [
                  _TH("N° du ticket"), _TH("Client"), _TH("Opération"), _TH("Heure"), _TH("Status"),
                ],
              ),
              ...history.map((t) => TableRow(
                children: [
                  _TD(t.numeroTicket), _TD(t.clientNom), _TD(t.typeOperation), _TD("${t.createdAt.hour}:${t.createdAt.minute}"), _TD("Validé"),
                ],
              )),
            ],
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDeco() => BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]);
}

class _StatCard extends StatelessWidget {
  final String title, value, trend;
  final Color color;
  const _StatCard({required this.title, required this.value, required this.trend, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
      child: Column(
        children: [
          Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey), textAlign: TextAlign.center),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Color(0xFF0D1B3E))),
          const SizedBox(height: 4),
          Text(trend, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color; final String label;
  const _Legend({required this.color, required this.label});
  @override Widget build(BuildContext context) => Row(children: [Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)), const SizedBox(width: 8), Text(label, style: const TextStyle(fontSize: 12))]);
}

class _TH extends StatelessWidget {
  final String text; const _TH(this.text);
  @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)));
}

class _TD extends StatelessWidget {
  final String text; const _TD(this.text);
  @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text(text, style: const TextStyle(fontSize: 13)));
}

class _HBar extends StatelessWidget {
  final String label; final double val;
  const _HBar({required this.label, required this.val});
  @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 12), child: Row(children: [SizedBox(width: 80, child: Text(label, style: const TextStyle(fontSize: 10))), Expanded(child: LinearProgressIndicator(value: val, minHeight: 12, borderRadius: BorderRadius.circular(4), color: const Color(0xFF312E81), backgroundColor: Colors.grey.shade100))]));
}

class _OpBox extends StatelessWidget {
  final String label; final Color color;
  const _OpBox({required this.label, required this.color});
  @override Widget build(BuildContext context) => Container(alignment: Alignment.center, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)), child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)));
}


