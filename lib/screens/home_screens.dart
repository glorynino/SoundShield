// ============================================================
//  lib/screens/home_screens.dart
//  Écran principal avec navigation entre :
//  - Page Statistiques
//  - Page Lecteur Audio
// ============================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/app_theme.dart';
import 'player_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    _StatistiquesPage(),
    PlayerScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        // IndexedStack garde les pages en mémoire → pas de rechargement
        // quand on revient sur la page stats ou player
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        selectedLabelStyle: GoogleFonts.syne(
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: GoogleFonts.syne(fontSize: 11),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_rounded),
            activeIcon: Icon(Icons.bar_chart_rounded),
            label: 'Statistiques',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.headphones_outlined),
            activeIcon: Icon(Icons.headphones_rounded),
            label: 'Lecteur',
          ),
        ],
      ),
    );
  }
}

// ============================================================
//  Page Statistiques (anciennement HomeScreen)
// ============================================================
class _StatistiquesPage extends StatefulWidget {
  const _StatistiquesPage();

  @override
  State<_StatistiquesPage> createState() => _StatistiquesPageState();
}

class _StatistiquesPageState extends State<_StatistiquesPage> {
  final _auth = FirebaseAuth.instance;
  final _db   = FirebaseFirestore.instance;

  String _prenom = '';
  String _nom    = '';
  int _objectif  = 20;
  bool _loading  = true;

  final List<int> _minutesParJour = [
    12, 0, 45, 30, 0, 60, 25, 0, 90, 15,
    0, 40, 55, 20, 0, 70, 35, 0, 50, 80,
    0, 25, 60, 45, 0, 30, 55, 0, 40, 20,
  ];

  final List<Map<String, dynamic>> _topMorceaux = [
    {'titre': 'Sourate Al-Fatiha',   'artiste': 'Mishary Rashid',   'minutes': 45,  'ecoutes': 12},
    {'titre': 'Sourate Al-Baqarah',  'artiste': 'Abdul Basit',      'minutes': 120, 'ecoutes': 8},
    {'titre': 'Sourate Al-Kahf',     'artiste': 'Maher Al Muaiqly', 'minutes': 60,  'ecoutes': 6},
    {'titre': 'Sourate Yasin',       'artiste': 'Saud Al-Shuraim',  'minutes': 35,  'ecoutes': 5},
    {'titre': 'Sourate Al-Mulk',     'artiste': 'Mishary Rashid',   'minutes': 20,  'ecoutes': 4},
  ];

  @override
  void initState() {
    super.initState();
    _loadProfil();
  }

  Future<void> _loadProfil() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    try {
      final doc = await _db.collection('users').doc(uid).get();
      final data = doc.data();
      if (data != null && mounted) {
        setState(() {
          _prenom   = data['prenom'] ?? '';
          _nom      = data['nom']    ?? '';
          _objectif = data['objectifMensuel'] ?? 20;
          _loading  = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _updateObjectif(int val) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    setState(() => _objectif = val);
    await _db.collection('users').doc(uid).update({'objectifMensuel': val});
  }

  int get _totalMinutes => _minutesParJour.fold(0, (a, b) => a + b);
  int get _totalHeures  => _totalMinutes ~/ 60;
  int get _restMinutes  => _totalMinutes % 60;
  double get _progression =>
      (_totalMinutes / (_objectif * 60)).clamp(0.0, 1.0);
  int get _joursActifs =>
      _minutesParJour.where((m) => m > 0).length;
  int get _maxMinutes =>
      _minutesParJour.reduce((a, b) => a > b ? a : b);
  int get _nbJoursMois {
    final now = DateTime.now();
    return DateTime(now.year, now.month + 1, 0).day;
  }
  List<int> get _joursAffiches =>
      _minutesParJour.take(_nbJoursMois).toList();

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader()),
            SliverToBoxAdapter(child: _buildStatsGlobales()),
            SliverToBoxAdapter(child: _buildObjectif()),
            SliverToBoxAdapter(child: _buildHistogramme()),
            SliverToBoxAdapter(child: _buildTopMorceaux()),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final now = DateTime.now();
    final mois = ['','Janvier','Février','Mars','Avril','Mai','Juin',
        'Juillet','Août','Septembre','Octobre','Novembre','Décembre'][now.month];
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$mois ${now.year}',
                    style: GoogleFonts.syne(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        letterSpacing: 2)),
                const SizedBox(height: 4),
                RichText(
                  text: TextSpan(
                    text: 'Bonjour, ',
                    style: GoogleFonts.syne(
                        color: AppColors.textSecondary, fontSize: 22),
                    children: [
                      TextSpan(
                        text: '$_prenom $_nom',
                        style: GoogleFonts.syne(
                            color: AppColors.textPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _auth.signOut(),
            child: Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(Icons.logout_rounded,
                  color: AppColors.textSecondary, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGlobales() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(child: _statCard(
            icon: Icons.headphones_rounded,
            label: 'Temps total',
            value: '${_totalHeures}h ${_restMinutes}min',
            color: AppColors.primary,
          )),
          const SizedBox(width: 12),
          Expanded(child: _statCard(
            icon: Icons.calendar_today_rounded,
            label: 'Jours actifs',
            value: '$_joursActifs jours',
            color: AppColors.accent,
          )),
        ],
      ),
    );
  }

  Widget _statCard({required IconData icon, required String label,
      required String value, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 12),
          Text(value,
              style: GoogleFonts.syne(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(label,
              style: GoogleFonts.syne(
                  color: AppColors.textSecondary, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildObjectif() {
    final pct = (_progression * 100).toInt();
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Objectif mensuel',
                  style: GoogleFonts.syne(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _objectif,
                    isDense: true,
                    dropdownColor: AppColors.surface,
                    style: GoogleFonts.syne(
                        color: AppColors.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700),
                    icon: const Icon(Icons.keyboard_arrow_down_rounded,
                        color: AppColors.primary, size: 16),
                    items: [5, 10, 15, 20, 25, 30, 40, 50]
                        .map((h) => DropdownMenuItem(
                            value: h, child: Text('$h heures')))
                        .toList(),
                    onChanged: (v) => v != null ? _updateObjectif(v) : null,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Stack(
            children: [
              Container(
                height: 10,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              FractionallySizedBox(
                widthFactor: _progression,
                child: Container(
                  height: 10,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.accent]),
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text('${_totalHeures}h ${_restMinutes}min écoutées',
                  style: GoogleFonts.syne(
                      color: AppColors.textSecondary, fontSize: 12)),
              const Spacer(),
              Text('$pct%',
                  style: GoogleFonts.syne(
                    color: _progression >= 1.0
                        ? AppColors.accent
                        : AppColors.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  )),
            ],
          ),
          if (_progression >= 1.0) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: AppColors.accent.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle_rounded,
                      color: AppColors.accent, size: 14),
                  const SizedBox(width: 6),
                  Text('Objectif atteint ! 🎉',
                      style: GoogleFonts.syne(
                          color: AppColors.accent,
                          fontSize: 12,
                          fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHistogramme() {
    final jours = _joursAffiches;
    final now   = DateTime.now();
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Minutes écoutées ce mois',
              style: GoogleFonts.syne(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text('Chaque barre = 1 jour',
              style: GoogleFonts.syne(
                  color: AppColors.textSecondary, fontSize: 11)),
          const SizedBox(height: 20),
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(jours.length, (i) {
                final isToday = (i + 1) == now.day;
                final ratio = _maxMinutes > 0
                    ? jours[i] / _maxMinutes
                    : 0.0;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1.5),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Flexible(
                          child: FractionallySizedBox(
                            heightFactor: ratio > 0
                                ? ratio.clamp(0.05, 1.0)
                                : 0.03,
                            child: Container(
                              decoration: BoxDecoration(
                                color: isToday
                                    ? AppColors.accent
                                    : ratio > 0
                                        ? AppColors.primary.withValues(
                                            alpha: 0.7 + ratio * 0.3)
                                        : AppColors.border,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(jours.length, (i) {
              final show = (i + 1) == 1 ||
                  (i + 1) % 5 == 0 ||
                  (i + 1) == jours.length;
              return Expanded(
                child: Text(
                  show ? '${i + 1}' : '',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.syne(
                    color: (i + 1) == now.day
                        ? AppColors.accent
                        : AppColors.textSecondary,
                    fontSize: 9,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildTopMorceaux() {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Morceaux les plus écoutés',
              style: GoogleFonts.syne(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          ...List.generate(_topMorceaux.length,
              (i) => _morceauRow(i + 1, _topMorceaux[i])),
        ],
      ),
    );
  }

  Widget _morceauRow(int rang, Map<String, dynamic> m) {
    final colors = [
      AppColors.accent, AppColors.primary, AppColors.primaryLight,
      AppColors.textSecondary, AppColors.textSecondary,
    ];
    final color = colors[rang - 1];
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text('#$rang',
                style: GoogleFonts.syne(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.w800)),
          ),
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.music_note_rounded, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(m['titre'],
                    style: GoogleFonts.syne(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Text(m['artiste'],
                    style: GoogleFonts.syne(
                        color: AppColors.textSecondary, fontSize: 11)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${m['ecoutes']}x',
                  style: GoogleFonts.syne(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700)),
              Text('${m['minutes']} min',
                  style: GoogleFonts.syne(
                      color: AppColors.textSecondary, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }
}