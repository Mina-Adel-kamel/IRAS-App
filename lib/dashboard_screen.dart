// dashboard_screen.dart
// ✅ FIXES:
//   1. Donut tooltip يعمل على الموبايل بـ GestureDetector (onTapDown)
//      ويظهر لـ 1.5 ثانية بعد اللمس
//   2. Logout يرجع لصفحة Login
//   3. استبدال LayoutBuilder بـ MediaQuery لحل مشكلة الـ Web

import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';
import 'alert_queue_screen.dart';
import 'actions_screen.dart';
import 'automated_actions_screen.dart';
import 'siem_screan.dart';
import 'documentation_screen.dart';
import 'playbook_screen.dart';
import 'case_reports_screen.dart';
import 'api_service.dart';
import 'login_screen.dart';

const Color kAccent     = Color(0xFFCAF135);
const Color kFieldBg    = Color(0xFF0D1A30);
const Color kCardBg     = Color(0xFF070F1E);
const Color kPageBg     = Color(0xFF030810);
const Color kSidebar    = Color(0xFF060D1B);
const Color kCardBorder = Color(0xFF0F1E35);
const Color kSubText    = Color(0xFF5C7A99);
const Color kBodyText   = Colors.white;
const Color kCritical   = Color(0xFFE53E3E);
const Color kHigh       = Color(0xFFED8936);
const Color kMedium     = Color(0xFF4299E1);
const Color kLow        = Color(0xFF48BB78);

const double kDesktopBreakpoint = 720;

final ValueNotifier<String?> kStatusBarText = ValueNotifier(null);

void showStatusBar(String text, {int seconds = 3}) {
  kStatusBarText.value = text;
  Timer(Duration(seconds: seconds), () => kStatusBarText.value = null);
}

class _NavItem {
  final IconData icon; final String label;
  const _NavItem(this.icon, this.label);
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedNav = 0;

  static const _navItems = [
    _NavItem(Icons.home_rounded,           'Dashboard'),
    _NavItem(Icons.notifications_outlined, 'Alert queue'),
    _NavItem(Icons.play_circle_outline,    'Actions'),
    _NavItem(Icons.auto_fix_high_outlined, 'Automated Actions'),
    _NavItem(Icons.storage_outlined,       'SIEM'),
    _NavItem(Icons.description_outlined,   'Documentation'),
    _NavItem(Icons.menu_book_outlined,     'Playbooks'),
    _NavItem(Icons.folder_copy_outlined,   'Case reports'),
  ];

  static const _navRoutes = [
    'iras.local/dashboard',         'iras.local/alert-queue',    'iras.local/actions',
    'iras.local/automated-actions', 'iras.local/siem',           'iras.local/documentation',
    'iras.local/playbooks',         'iras.local/case-reports',
  ];

  String? _hoveredRoute;

  void _navigate(int index) {
    setState(() => _selectedNav = index);
    if (Navigator.of(context).canPop()) Navigator.of(context).pop();
  }

  void _logout() {
    if (Navigator.of(context).canPop()) Navigator.of(context).pop();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Widget _buildPage() {
    switch (_selectedNav) {
      case 0: return _DashboardBody(onViewAll: () => setState(() => _selectedNav = 1));
      case 1: return const AlertQueueScreen();
      case 2: return const ActionsScreen();
      case 3: return const AutomatedActionsScreen();
      case 4: return const SiemScrean();
      case 5: return const DocumentationScreen();
      case 6: return const PlaybooksScreen();
      case 7: return const CaseReportsScreen();
      default: return Center(child: Text(_navItems[_selectedNav].label, style: const TextStyle(color: kSubText, fontSize: 22)));
    }
  }

  Widget _buildSidebarContent({bool inDrawer = false}) {
    return Container(
      width: 210, color: kSidebar,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(height: inDrawer ? MediaQuery.of(context).padding.top + 20 : 32),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
            Text('IRAS', style: TextStyle(color: kAccent, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 1.6)),
            SizedBox(height: 4),
            Text('Incident Response Automation System', style: TextStyle(color: kSubText, fontSize: 10, height: 1.5)),
          ]),
        ),
        const SizedBox(height: 28),
        Expanded(child: ListView.builder(
          padding: EdgeInsets.zero,
          itemCount: _navItems.length,
          itemBuilder: (_, i) => _SidebarTile(
            item: _navItems[i], route: _navRoutes[i], active: _selectedNav == i,
            onTap: () => _navigate(i),
            onHoverEnter: () => setState(() => _hoveredRoute = _navRoutes[i]),
            onHoverExit:  () => setState(() => _hoveredRoute = null),
          ),
        )),
        Padding(padding: const EdgeInsets.all(14),
          child: _SidebarTile(
            item: const _NavItem(Icons.logout_rounded, 'Logout'),
            route: '', active: false,
            onTap: _logout,
            onHoverEnter: () {}, onHoverExit: () {},
          ),
        ),
        SizedBox(height: inDrawer ? MediaQuery.of(context).padding.bottom : 0),
      ]),
    );
  }

  // ✅ FIX: استبدال LayoutBuilder بـ MediaQuery.of(context).size.width
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop   = screenWidth >= kDesktopBreakpoint;

    if (isDesktop) {
      return Scaffold(
        backgroundColor: kPageBg,
        body: Stack(children: [
          Row(children: [
            _buildSidebarContent(inDrawer: false),
            Expanded(child: _buildPage()),
          ]),
          ValueListenableBuilder<String?>(
            valueListenable: kStatusBarText,
            builder: (_, statusText, __) {
              final display = _hoveredRoute ?? statusText;
              return AnimatedPositioned(
                duration: const Duration(milliseconds: 180), curve: Curves.easeOut,
                bottom: display != null ? 0 : -32, left: 0, right: 0,
                child: _BrowserStatusBar(text: display ?? ''),
              );
            },
          ),
        ]),
      );
    } else {
      return Scaffold(
        backgroundColor: kPageBg,
        appBar: AppBar(
          backgroundColor: kSidebar, elevation: 0,
          leading: Builder(builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu_rounded, color: kAccent),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          )),
          title: Row(children: [
            const Text('IRAS', style: TextStyle(color: kAccent, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1.6)),
            const SizedBox(width: 8),
            Text(_navItems[_selectedNav].label, style: const TextStyle(color: kSubText, fontSize: 13, fontWeight: FontWeight.w400)),
          ]),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(height: 1, color: kCardBorder),
          ),
        ),
        drawer: Drawer(backgroundColor: Colors.transparent, width: 210, child: _buildSidebarContent(inDrawer: true)),
        body: Stack(children: [
          _buildPage(),
          ValueListenableBuilder<String?>(
            valueListenable: kStatusBarText,
            builder: (_, statusText, __) {
              if (statusText == null) return const SizedBox.shrink();
              return Positioned(bottom: 0, left: 0, right: 0, child: _BrowserStatusBar(text: statusText));
            },
          ),
        ]),
      );
    }
  }
}

class _BrowserStatusBar extends StatelessWidget {
  final String text;
  const _BrowserStatusBar({required this.text});
  @override
  Widget build(BuildContext context) => Container(
    height: 26, width: double.infinity,
    decoration: BoxDecoration(
      color: const Color(0xFF1E2430),
      border: const Border(top: BorderSide(color: Color(0xFF2A3545), width: 1)),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, -2))],
    ),
    padding: const EdgeInsets.symmetric(horizontal: 12),
    alignment: Alignment.centerLeft,
    child: Text(text, style: const TextStyle(color: Color(0xFFCDD6E0), fontSize: 12, fontFamily: 'monospace'), overflow: TextOverflow.ellipsis),
  );
}

class _SidebarTile extends StatelessWidget {
  final _NavItem item; final String route; final bool active;
  final VoidCallback onTap, onHoverEnter, onHoverExit;
  const _SidebarTile({required this.item, required this.route, required this.active, required this.onTap, required this.onHoverEnter, required this.onHoverExit});
  @override
  Widget build(BuildContext context) => MouseRegion(
    cursor: SystemMouseCursors.click,
    onEnter: (_) => onHoverEnter(), onExit: (_) => onHoverExit(),
    child: GestureDetector(onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: active ? kAccent.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          border: active ? Border.all(color: kAccent.withOpacity(0.2)) : null,
        ),
        child: Row(children: [
          Icon(item.icon, size: 17, color: active ? kAccent : kSubText),
          const SizedBox(width: 11),
          Expanded(child: Text(item.label,
            style: TextStyle(color: active ? kAccent : kSubText, fontSize: 13, fontWeight: active ? FontWeight.w600 : FontWeight.w400),
            overflow: TextOverflow.ellipsis)),
        ]),
      ),
    ),
  );
}

// ══════════════════════════════════════════════════════════════
//  DASHBOARD BODY
// ══════════════════════════════════════════════════════════════
class _DashboardBody extends StatefulWidget {
  final VoidCallback onViewAll;
  const _DashboardBody({required this.onViewAll});
  @override State<_DashboardBody> createState() => _DashboardBodyState();
}

class _DashboardBodyState extends State<_DashboardBody> {
  bool _showTypes = true;

  final _dashService   = DashboardService();
  DashboardStats?      _stats;
  List<DashboardAlert> _openAlerts = [];
  List<ChartSegment>   _typeSegs   = [];
  List<ChartSegment>   _sevSegs    = [];
  bool    _loading = true;
  String? _error;

  @override void initState() { super.initState(); _loadData(); }

  Future<void> _loadData() async {
    setState(() { _loading = true; _error = null; });
    try {
      final r = await Future.wait([
        _dashService.getStats(),
        _dashService.getOpenAlerts(),
        _dashService.getAlertsByType(),
        _dashService.getAlertsBySeverity(),
      ]);
      setState(() {
        _stats      = r[0] as DashboardStats;
        _openAlerts = r[1] as List<DashboardAlert>;
        _typeSegs   = r[2] as List<ChartSegment>;
        _sevSegs    = r[3] as List<ChartSegment>;
        _loading    = false;
      });
    } catch (e) { setState(() { _error = e.toString(); _loading = false; }); }
  }

  // ✅ FIX: استبدال LayoutBuilder بـ MediaQuery.of(context).size.width
  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: kAccent));
    if (_error != null) return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.error_outline, color: kCritical, size: 40), const SizedBox(height: 12),
      const Text('Failed to load data', style: TextStyle(color: kBodyText, fontSize: 16)), const SizedBox(height: 8),
      TextButton(onPressed: _loadData, child: const Text('Retry', style: TextStyle(color: kAccent))),
    ]));

    final stats   = _stats!;
    final isWide  = MediaQuery.of(context).size.width >= 600;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.center, children: const [
          Text('Dashboard', style: TextStyle(color: kBodyText, fontSize: 22, fontWeight: FontWeight.w700)),
          SizedBox(width: 8),
          Icon(Icons.home_rounded, color: kAccent, size: 24),
        ]),
        const SizedBox(height: 6),
        Row(children: [
          const Text('details', style: TextStyle(color: kSubText, fontSize: 13)),
          const SizedBox(width: 8),
          Container(width: 4, height: 4, decoration: const BoxDecoration(color: kSubText, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text('${stats.incomingAlerts} alerts incoming', style: const TextStyle(color: kSubText, fontSize: 13)),
        ]),
        const SizedBox(height: 20),
        _ResponsiveStatCards(stats: stats, isWide: isWide),
        const SizedBox(height: 24),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Flexible(child: Text('Alerts overview', style: TextStyle(color: kBodyText, fontSize: 15, fontWeight: FontWeight.w600))),
          const SizedBox(width: 8),
          Row(children: [
            _ToggleBtn(label: 'Types',    active: _showTypes,  onTap: () => setState(() => _showTypes = true)),
            const SizedBox(width: 6),
            _ToggleBtn(label: 'Severity', active: !_showTypes, onTap: () => setState(() => _showTypes = false)),
          ]),
        ]),
        const SizedBox(height: 16),
        isWide
          ? SizedBox(height: 450, child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Expanded(flex: 4, child: _DonutCard(showTypes: _showTypes, typeSegs: _typeSegs, sevSegs: _sevSegs)),
              const SizedBox(width: 14),
              Expanded(flex: 5, child: _OpenAlertsCard(alerts: _openAlerts, onTap: widget.onViewAll)),
            ]))
          : Column(children: [
              SizedBox(height: 340, child: _DonutCard(showTypes: _showTypes, typeSegs: _typeSegs, sevSegs: _sevSegs)),
              const SizedBox(height: 14),
              SizedBox(height: 400, child: _OpenAlertsCard(alerts: _openAlerts, onTap: widget.onViewAll)),
            ]),
      ]),
    );
  }
}

class _ResponsiveStatCards extends StatelessWidget {
  final DashboardStats stats; final bool isWide;
  const _ResponsiveStatCards({required this.stats, required this.isWide});
  @override
  Widget build(BuildContext context) {
    final cards = [
      _StatCardData(title: 'Total alerts',  value: '${stats.totalAlerts}'),
      _StatCardData(title: 'Closed alerts', value: '${stats.closedAlerts}'),
      _StatCardData(title: 'Closed as TP',  value: '${stats.closedAsTP}'),
      _StatCardData(title: 'Closed as FP',  value: '${stats.closedAsFP}'),
    ];
    if (isWide) {
      return Column(children: [
        Row(children: [
          Expanded(child: _StatCard(title: cards[0].title, value: cards[0].value)),
          const SizedBox(width: 14),
          Expanded(child: _StatCard(title: cards[1].title, value: cards[1].value)),
        ]),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: _StatCard(title: cards[2].title, value: cards[2].value)),
          const SizedBox(width: 14),
          Expanded(child: _StatCard(title: cards[3].title, value: cards[3].value)),
        ]),
      ]);
    }
    return Wrap(spacing: 12, runSpacing: 12,
      children: cards.map((c) => SizedBox(
        width: (MediaQuery.of(context).size.width - 56) / 2,
        child: _StatCard(title: c.title, value: c.value),
      )).toList());
  }
}

class _StatCardData { final String title, value; const _StatCardData({required this.title, required this.value}); }

class _StatCard extends StatelessWidget {
  final String title, value;
  const _StatCard({required this.title, required this.value});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(14, 14, 14, 18),
    decoration: BoxDecoration(color: kCardBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: kCardBorder)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(color: kSubText, fontSize: 12)),
      const SizedBox(height: 8),
      FittedBox(fit: BoxFit.scaleDown, child: Text(value, style: const TextStyle(color: kBodyText, fontSize: 28, fontWeight: FontWeight.w700))),
    ]),
  );
}

class _ToggleBtn extends StatelessWidget {
  final String label; final bool active; final VoidCallback onTap;
  const _ToggleBtn({required this.label, required this.active, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(onTap: onTap,
    child: AnimatedContainer(duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: active ? kAccent : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: active ? kAccent : kCardBorder),
      ),
      child: Text(label, style: TextStyle(
        color: active ? Colors.black : kSubText,
        fontSize: 11,
        fontWeight: active ? FontWeight.w700 : FontWeight.w400,
      ))));
}

// ══════════════════════════════════════════════════════════════
//  DONUT CARD
//  ✅ Tooltip يعمل على الموبايل بـ GestureDetector + onTapDown
//  ✅ يظهر لـ 1.5 ثانية بعد اللمس
// ══════════════════════════════════════════════════════════════
class _Seg { final String label; final int val; final Color color; const _Seg(this.label, this.val, this.color); }

Color _hexToColor(String hex) {
  final h = hex.replaceAll('#', '');
  return Color(int.parse('FF$h', radix: 16));
}

class _DonutCard extends StatefulWidget {
  final bool showTypes; final List<ChartSegment> typeSegs, sevSegs;
  const _DonutCard({required this.showTypes, required this.typeSegs, required this.sevSegs});
  @override State<_DonutCard> createState() => _DonutCardState();
}

class _DonutCardState extends State<_DonutCard> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _anim;
  int    _hoveredSegIndex = -1;
  Offset _tooltipOffset   = Offset.zero;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _ctrl.forward();
  }

  @override
  void didUpdateWidget(_DonutCard old) {
    super.didUpdateWidget(old);
    if (old.showTypes != widget.showTypes) {
      setState(() => _hoveredSegIndex = -1);
      _ctrl.forward(from: 0.0);
    }
  }

  @override
  void dispose() { _ctrl.dispose(); _hideTimer?.cancel(); super.dispose(); }

  List<_Seg> get _segs {
    final source = widget.showTypes ? widget.typeSegs : widget.sevSegs;
    return source.map((s) => _Seg(s.label, s.value, _hexToColor(s.color))).toList();
  }

  int _segIndexAt(Offset local, Size size, List<_Seg> segs) {
    final cx = size.width / 2, cy = size.height / 2;
    final r = (min(size.width, size.height) / 2) * 0.72;
    const stroke = 58.0;
    final dx = local.dx - cx, dy = local.dy - cy;
    final dist = sqrt(dx * dx + dy * dy);
    if (dist < r - stroke / 2 || dist > r + stroke / 2) return -1;
    double angle = atan2(dy, dx) + pi / 2;
    if (angle < 0) angle += 2 * pi;
    final total = segs.fold<int>(0, (s, e) => s + e.val);
    const gap = 0.012;
    double current = 0;
    for (int i = 0; i < segs.length; i++) {
      final sweep = (segs[i].val / total) * 2 * pi - gap;
      if (angle >= current && angle <= current + sweep) return i;
      current += sweep + gap;
    }
    return -1;
  }

  @override
  Widget build(BuildContext context) {
    final segs = _segs;
    if (segs.isEmpty) return Container(
      decoration: BoxDecoration(color: kCardBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: kCardBorder)),
      child: const Center(child: Text('No data', style: TextStyle(color: kSubText))),
    );
    final total = segs.fold<int>(0, (s, e) => s + e.val);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: kCardBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: kCardBorder)),
      child: Column(children: [
        Expanded(child: AnimatedBuilder(
          animation: _anim,
          builder: (_, __) => LayoutBuilder(builder: (context, constraints) {
            final size = Size(constraints.maxWidth, constraints.maxHeight);
            return Stack(alignment: Alignment.center, children: [
              GestureDetector(
                onTapDown: (details) {
                  _hideTimer?.cancel();
                  final idx = _segIndexAt(details.localPosition, size, segs);
                  setState(() { _hoveredSegIndex = idx; _tooltipOffset = details.localPosition; });
                  if (idx != -1) {
                    _hideTimer = Timer(const Duration(milliseconds: 1500), () {
                      if (mounted) setState(() => _hoveredSegIndex = -1);
                    });
                  }
                },
                child: MouseRegion(
                  onHover: (event) {
                    _hideTimer?.cancel();
                    final idx = _segIndexAt(event.localPosition, size, segs);
                    setState(() { _hoveredSegIndex = idx; if (idx != -1) _tooltipOffset = event.localPosition; });
                  },
                  onExit: (_) { _hideTimer?.cancel(); setState(() => _hoveredSegIndex = -1); },
                  child: CustomPaint(size: size, painter: _DonutPainter(segs: segs, progress: _anim.value, hoveredIndex: _hoveredSegIndex)),
                ),
              ),
              Column(mainAxisSize: MainAxisSize.min, children: [
                Text('$total', style: const TextStyle(color: kBodyText, fontSize: 28, fontWeight: FontWeight.w800)),
                const Text('Alerts', style: TextStyle(color: kSubText, fontSize: 12)),
              ]),
              if (_hoveredSegIndex >= 0 && _hoveredSegIndex < segs.length)
                Positioned(
                  left: (_tooltipOffset.dx + 12).clamp(0.0, size.width - 125),
                  top:  (_tooltipOffset.dy - 58).clamp(0.0, size.height - 62),
                  child: IgnorePointer(child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D1B2E),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: kCardBorder),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 10)],
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Container(width: 12, height: 12, decoration: BoxDecoration(color: segs[_hoveredSegIndex].color, borderRadius: BorderRadius.circular(3))),
                      const SizedBox(width: 7),
                      Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                        Text(segs[_hoveredSegIndex].label, style: const TextStyle(color: kBodyText, fontSize: 11, fontWeight: FontWeight.w600)),
                        Text('${segs[_hoveredSegIndex].val}', style: TextStyle(color: segs[_hoveredSegIndex].color, fontSize: 13, fontWeight: FontWeight.bold)),
                      ]),
                    ]),
                  )),
                ),
            ]);
          }),
        )),
        const SizedBox(height: 16),
        Wrap(spacing: 10, runSpacing: 6, alignment: WrapAlignment.center,
          children: segs.map((s) => Row(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(color: s.color, shape: BoxShape.circle)),
            const SizedBox(width: 5),
            Text('${s.label} ${s.val}', style: const TextStyle(color: kSubText, fontSize: 10)),
          ])).toList()),
      ]),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<_Seg> segs; final double progress; final int hoveredIndex;
  const _DonutPainter({required this.segs, required this.progress, this.hoveredIndex = -1});
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2, cy = size.height / 2;
    final r = (min(size.width, size.height) / 2) * 0.72;
    const stroke = 52.0, gap = 0.012;
    final total = segs.fold<int>(0, (s, e) => s + e.val);
    if (total == 0) return;
    final allowed = 2 * pi * progress;
    double drawn = 0, start = -pi / 2;
    for (int i = 0; i < segs.length; i++) {
      final seg = segs[i];
      if (drawn >= allowed) break;
      final full  = (seg.val / total) * 2 * pi - gap;
      final sweep = full.clamp(0.0, allowed - drawn);
      if (sweep > 0) {
        final isHovered = hoveredIndex == i;
        canvas.drawArc(
          Rect.fromCircle(center: Offset(cx, cy), radius: r), start, sweep, false,
          Paint()
            ..color = isHovered ? seg.color : seg.color.withOpacity(0.85)
            ..style = PaintingStyle.stroke
            ..strokeWidth = isHovered ? stroke + 8 : stroke
            ..strokeCap = StrokeCap.butt,
        );
      }
      drawn += full + gap; start += full + gap;
    }
  }
  @override bool shouldRepaint(_DonutPainter old) => old.progress != progress || old.segs != segs || old.hoveredIndex != hoveredIndex;
}

// ══════════════════════════════════════════════════════════════
//  OPEN ALERTS CARD
// ══════════════════════════════════════════════════════════════
class _OpenAlertsCard extends StatefulWidget {
  final List<DashboardAlert> alerts; final VoidCallback onTap;
  const _OpenAlertsCard({required this.alerts, required this.onTap});
  @override State<_OpenAlertsCard> createState() => _OpenAlertsCardState();
}

class _OpenAlertsCardState extends State<_OpenAlertsCard> {
  String _currentSort  = 'Severity';
  int    _hoveredIndex = -1;

  List<DashboardAlert> get _sorted {
    final list = List<DashboardAlert>.from(widget.alerts);
    if (_currentSort == 'Severity') {
      const order = {'Critical': 0, 'High': 1, 'Medium': 2, 'Low': 3};
      list.sort((a, b) => (order[a.severity] ?? 4).compareTo(order[b.severity] ?? 4));
    } else if (_currentSort == 'Type') {
      list.sort((a, b) => a.type.compareTo(b.type));
    } else if (_currentSort == 'ID') {
      list.sort((a, b) => a.id.compareTo(b.id));
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final alerts = _sorted;
    return Container(
      decoration: BoxDecoration(color: kCardBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: kCardBorder)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Flexible(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Open alerts', style: TextStyle(color: kBodyText, fontSize: 14, fontWeight: FontWeight.bold)),
              SizedBox(height: 3),
              Text('Monitor new alerts as they arrive.', style: TextStyle(color: kSubText, fontSize: 10), overflow: TextOverflow.ellipsis),
            ])),
            const SizedBox(width: 8),
            Row(children: [
              const Text('Sort by', style: TextStyle(color: kSubText, fontSize: 11)),
              const SizedBox(width: 6),
              _SortDropdown(currentValue: _currentSort, onChanged: (val) { if (val != null) setState(() => _currentSort = val); }),
            ]),
          ]),
        ),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0A1628),
            border: Border(top: BorderSide(color: kCardBorder), bottom: BorderSide(color: kCardBorder)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(children: const [
            Expanded(flex: 3, child: Text('ID',         style: TextStyle(color: kSubText, fontSize: 11, fontWeight: FontWeight.w700))),
            Expanded(flex: 5, child: Text('Alert rule', style: TextStyle(color: kSubText, fontSize: 11, fontWeight: FontWeight.w700))),
            SizedBox(width: 72, child: Text('Severity',  style: TextStyle(color: kSubText, fontSize: 11, fontWeight: FontWeight.w700))),
          ]),
        ),
        Expanded(child: alerts.isEmpty
          ? const Center(child: Text('No open alerts', style: TextStyle(color: kSubText, fontSize: 13)))
          : ListView.builder(
              itemCount: alerts.length,
              itemBuilder: (context, i) {
                final a = alerts[i]; final isHovered = _hoveredIndex == i;
                return MouseRegion(
                  onEnter: (_) => setState(() => _hoveredIndex = i),
                  onExit:  (_) => setState(() => _hoveredIndex = -1),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 130),
                    decoration: BoxDecoration(
                      color: isHovered ? Colors.white.withOpacity(0.04) : (i.isEven ? Colors.transparent : const Color(0xFF060D1C)),
                      border: Border(bottom: BorderSide(color: kCardBorder.withOpacity(0.35))),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: Row(children: [
                      Expanded(flex: 3, child: Text(a.id,   overflow: TextOverflow.ellipsis, style: const TextStyle(color: kSubText,  fontSize: 10))),
                      Expanded(flex: 5, child: Text(a.rule, overflow: TextOverflow.ellipsis, style: const TextStyle(color: kBodyText, fontSize: 10))),
                      SizedBox(width: 72, child: _SeverityBadge(a.severity)),
                    ]),
                  ),
                );
              },
            ),
        ),
        Container(
          decoration: BoxDecoration(border: Border(top: BorderSide(color: kCardBorder.withOpacity(0.5)))),
          padding: const EdgeInsets.fromLTRB(0, 10, 14, 12),
          child: Align(alignment: Alignment.centerRight,
            child: InkWell(onTap: widget.onTap, borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: kAccent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: kAccent, width: 1.2),
                  boxShadow: [BoxShadow(color: kAccent.withOpacity(0.1), blurRadius: 8, spreadRadius: 1)],
                ),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Text('Open full queue', style: TextStyle(color: kAccent, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                  SizedBox(width: 6),
                  Icon(Icons.arrow_forward_ios_rounded, color: kAccent, size: 11),
                ]),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

class _SortDropdown extends StatelessWidget {
  final String currentValue; final ValueChanged<String?> onChanged;
  const _SortDropdown({required this.currentValue, required this.onChanged});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8),
    decoration: BoxDecoration(color: kFieldBg, borderRadius: BorderRadius.circular(6), border: Border.all(color: kCardBorder)),
    child: DropdownButtonHideUnderline(child: DropdownButton<String>(
      value: currentValue, dropdownColor: kCardBg,
      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: kSubText, size: 16),
      style: const TextStyle(color: kBodyText, fontSize: 11),
      onChanged: onChanged,
      items: <String>['Severity', 'Type', 'ID'].map((v) => DropdownMenuItem<String>(value: v, child: Text(v))).toList(),
    )),
  );
}

class _SeverityBadge extends StatelessWidget {
  final String level;
  const _SeverityBadge(this.level);
  @override
  Widget build(BuildContext context) {
    Color color = kMedium;
    if (level == 'Critical') color = kCritical;
    else if (level == 'High') color = kHigh;
    else if (level == 'Low')  color = kLow;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withOpacity(0.4), width: 1),
      ),
      child: Center(child: Text(level, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold))),
    );
  }
}