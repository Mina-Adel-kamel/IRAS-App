// automated_actions_screen.dart
// ✅ FIXES:
//   1. Bar Chart: عمود Success يظهر من ارتفاع 0 ببطء (2 ثانية، easeInOut)
//   2. باقي الأعمدة تظهر بنفس ارتفاع Success عند اللمس أو الـ hover
//   3. PDF: pageTheme يحتوي كل الإعدادات
//   4. ScrollController مستقل لكل Scrollbar
//   5. استبدال LayoutBuilder داخل SingleChildScrollView بـ Builder+MediaQuery
//   6. إضافة width ثابتة على _DropF لحل مشكلة unbounded constraints
//   7. ✅ تساوي ارتفاع الـ stat cards
//   8. ✅ حل overflow في _ActionRow بتقليل عرض الأعمدة

import 'package:flutter/material.dart';
import 'dart:math';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'api_service.dart';
import 'file_service.dart';

const Color kAccent     = Color(0xFFCAF135);
const Color kFieldBg    = Color(0xFF0D1A30);
const Color kCardBg     = Color(0xFF0A1628);
const Color kPageBg     = Color(0xFF060E1C);
const Color kCardBorder = Color(0xFF1A2A3A);
const Color kSubText    = Color(0xFF6B8299);
const Color kBodyText   = Colors.white;
const Color kCritical   = Color(0xFFE53E3E);
const Color kHigh       = Color(0xFFED8936);
const Color kLow        = Color(0xFF48BB78);
const Color kMedium     = Color(0xFF4299E1);

const Color cContainment   = Color(0xFFE53E3E);
const Color cNotification  = Color(0xFFED8936);
const Color cInvestigation = Color(0xFF4299E1);
const Color cRemediation   = Color(0xFF48BB78);

Future<void> _exportPDF(List<AutoAction> actions, BuildContext ctx) async {
  final now      = DateTime.now();
  final dateStr  = '${now.year}-${now.month.toString().padLeft(2,'0')}-${now.day.toString().padLeft(2,'0')}';
  final fileName = 'automated_actions_$dateStr.pdf';

  final successCount = actions.where((a) => a.status == 'Success').length;
  final pendingCount = actions.where((a) => a.status == 'Pending').length;
  final failedCount  = actions.where((a) => a.status == 'Failed').length;
  final partialCount = actions.where((a) => a.status == 'Partial').length;

  const pdfBg     = PdfColor.fromInt(0xFF060E1C);
  const pdfCard   = PdfColor.fromInt(0xFF0A1628);
  const pdfAccent = PdfColor.fromInt(0xFFCAF135);
  const pdfBody   = PdfColors.white;
  const pdfSub    = PdfColor.fromInt(0xFF6B8299);
  const pdfBorder = PdfColor.fromInt(0xFF1A2A3A);
  const pdfLow    = PdfColor.fromInt(0xFF48BB78);
  const pdfHigh   = PdfColor.fromInt(0xFFED8936);
  const pdfCrit   = PdfColor.fromInt(0xFFE53E3E);
  const pdfMed    = PdfColor.fromInt(0xFF4299E1);

  PdfColor statusColor(String s) =>
      s == 'Success' ? pdfLow : s == 'Pending' ? pdfHigh : s == 'Failed' ? pdfCrit : pdfSub;
  PdfColor catColor(String c) =>
      c == 'Notification' ? pdfHigh : c == 'Investigation' ? pdfMed : c == 'Containment' ? pdfCrit : pdfLow;

  pw.Widget statBox(String label, String value, PdfColor color) =>
      pw.Expanded(child: pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(color: pdfCard, borderRadius: pw.BorderRadius.circular(6), border: pw.Border.all(color: pdfBorder)),
        child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Text(label, style: pw.TextStyle(color: pdfSub, fontSize: 9)),
          pw.SizedBox(height: 4),
          pw.Text(value, style: pw.TextStyle(color: color, fontSize: 18, fontWeight: pw.FontWeight.bold)),
        ]),
      ));

  final robotoRegular = await PdfGoogleFonts.robotoRegular();
  final robotoBold    = await PdfGoogleFonts.robotoBold();
  final doc = pw.Document();

  doc.addPage(pw.MultiPage(
    pageTheme: pw.PageTheme(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      theme: pw.ThemeData.withFont(base: robotoRegular, bold: robotoBold),
      buildBackground: (_) => pw.FullPage(ignoreMargins: true, child: pw.Container(color: pdfBg)),
    ),
    build: (_) => [
      pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: pw.BoxDecoration(color: pdfCard, borderRadius: pw.BorderRadius.circular(8), border: pw.Border.all(color: pdfAccent, width: 1.5)),
        child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
          pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text('IRAS', style: pw.TextStyle(color: pdfAccent, fontSize: 20, fontWeight: pw.FontWeight.bold, letterSpacing: 2)),
            pw.SizedBox(height: 2),
            pw.Text('Automated Actions Execution Log', style: pw.TextStyle(color: pdfSub, fontSize: 9)),
          ]),
          pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
            pw.Text(dateStr, style: pw.TextStyle(color: pdfSub, fontSize: 9)),
            pw.SizedBox(height: 4),
            pw.Text('Total: ${actions.length} actions', style: pw.TextStyle(color: pdfBody, fontSize: 11, fontWeight: pw.FontWeight.bold)),
          ]),
        ]),
      ),
      pw.SizedBox(height: 14),
      pw.Row(children: [
        statBox('Total', '${actions.length}', pdfAccent),
        pw.SizedBox(width: 10), statBox('Success', '$successCount', pdfLow),
        pw.SizedBox(width: 10), statBox('Pending', '$pendingCount', pdfHigh),
        pw.SizedBox(width: 10), statBox('Failed',  '$failedCount',  pdfCrit),
        pw.SizedBox(width: 10), statBox('Partial', '$partialCount', pdfSub),
      ]),
      pw.SizedBox(height: 14),
      pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: pw.BoxDecoration(color: PdfColor.fromInt(0xFF071222)),
        child: pw.Row(children: [
          pw.SizedBox(width: 55,  child: pw.Text('Alert ID',    style: pw.TextStyle(color: pdfSub, fontSize: 8, fontWeight: pw.FontWeight.bold))),
          pw.SizedBox(width: 130, child: pw.Text('Action Type', style: pw.TextStyle(color: pdfSub, fontSize: 8, fontWeight: pw.FontWeight.bold))),
          pw.SizedBox(width: 80,  child: pw.Text('Category',    style: pw.TextStyle(color: pdfSub, fontSize: 8, fontWeight: pw.FontWeight.bold))),
          pw.SizedBox(width: 60,  child: pw.Text('Status',      style: pw.TextStyle(color: pdfSub, fontSize: 8, fontWeight: pw.FontWeight.bold))),
          pw.SizedBox(width: 50,  child: pw.Text('Duration',    style: pw.TextStyle(color: pdfSub, fontSize: 8, fontWeight: pw.FontWeight.bold))),
          pw.SizedBox(width: 30,  child: pw.Text('API',         style: pw.TextStyle(color: pdfSub, fontSize: 8, fontWeight: pw.FontWeight.bold))),
          pw.Expanded(            child: pw.Text('Playbook',    style: pw.TextStyle(color: pdfSub, fontSize: 8, fontWeight: pw.FontWeight.bold))),
        ]),
      ),
      ...actions.asMap().entries.map((entry) {
        final i = entry.key; final a = entry.value;
        final rowBg = i.isEven ? pdfCard : PdfColor.fromInt(0xFF071828);
        return pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: pw.BoxDecoration(color: rowBg),
          child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.center, children: [
            pw.SizedBox(width: 55,  child: pw.Text(a.alertId,    style: pw.TextStyle(color: pdfSub,  fontSize: 8))),
            pw.SizedBox(width: 130, child: pw.Text(a.actionType, style: pw.TextStyle(color: pdfBody, fontSize: 8, fontWeight: pw.FontWeight.bold))),
            pw.SizedBox(width: 80,  child: pw.Container(padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3), decoration: pw.BoxDecoration(color: catColor(a.category).shade(0.15), borderRadius: pw.BorderRadius.circular(4)), child: pw.Text(a.category, style: pw.TextStyle(color: catColor(a.category), fontSize: 7, fontWeight: pw.FontWeight.bold)))),
            pw.SizedBox(width: 60,  child: pw.Container(padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3), decoration: pw.BoxDecoration(color: statusColor(a.status).shade(0.15), borderRadius: pw.BorderRadius.circular(4)), child: pw.Text(a.status,   style: pw.TextStyle(color: statusColor(a.status),   fontSize: 7, fontWeight: pw.FontWeight.bold)))),
            pw.SizedBox(width: 50, child: pw.Text(a.duration,      style: pw.TextStyle(color: pdfBody, fontSize: 8))),
            pw.SizedBox(width: 30, child: pw.Text('${a.apiCalls}', style: pw.TextStyle(color: pdfSub,  fontSize: 8))),
            pw.Expanded(child: pw.Text(a.playbook, style: pw.TextStyle(color: a.playbook == '-' ? pdfSub : pdfBody, fontSize: 7), overflow: pw.TextOverflow.clip)),
          ]),
        );
      }),
      pw.SizedBox(height: 16),
      pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: pw.BoxDecoration(color: pdfCard, borderRadius: pw.BorderRadius.circular(6), border: pw.Border.all(color: pdfBorder)),
        child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
          pw.Text('IRAS v1.0 — Automated Actions Report', style: pw.TextStyle(color: pdfSub, fontSize: 8)),
          pw.Text(dateStr, style: pw.TextStyle(color: pdfAccent, fontSize: 8, fontWeight: pw.FontWeight.bold)),
        ]),
      ),
    ],
  ));

  final bytes = await doc.save();
  if (ctx.mounted) await FileService().saveAndOpen(bytes: bytes, fileName: fileName, ctx: ctx);
}

class AutomatedActionsScreen extends StatefulWidget {
  const AutomatedActionsScreen({super.key});
  @override State<AutomatedActionsScreen> createState() => _AutomatedActionsScreenState();
}

class _AutomatedActionsScreenState extends State<AutomatedActionsScreen> {
  final _service         = AutomatedActionsService();
  List<AutoAction>       _allActions = [];
  AutomatedActionsStats? _stats;
  bool    _loading = true;
  String? _error;
  String  _statusFilter   = 'All Status';
  String  _categoryFilter = 'All Categories';
  String  _searchQuery    = '';
  bool    _liveMonitor    = false;

  final _searchCtrl      = TextEditingController();
  final _scrollCtrl      = ScrollController();
  final _tableScrollCtrl = ScrollController();
  final _simulateKey     = GlobalKey();
  final Set<String>      _expanded = {};

  @override void initState() { super.initState(); _loadData(); }
  @override void dispose() { _searchCtrl.dispose(); _scrollCtrl.dispose(); _tableScrollCtrl.dispose(); super.dispose(); }

  Future<void> _loadData() async {
    setState(() { _loading = true; _error = null; });
    try {
      final r = await Future.wait([_service.getActions(), _service.getStats()]);
      setState(() {
        _allActions = r[0] as List<AutoAction>;
        _stats      = r[1] as AutomatedActionsStats;
        _loading    = false;
      });
    } catch (e) { setState(() { _error = e.toString(); _loading = false; }); }
  }

  List<AutoAction> get _filtered => _allActions.where((a) {
    final s = _statusFilter   == 'All Status'     || a.status   == _statusFilter;
    final c = _categoryFilter == 'All Categories' || a.category == _categoryFilter;
    final q = _searchQuery.isEmpty || a.actionType.toLowerCase().contains(_searchQuery.toLowerCase()) || a.alertId.contains(_searchQuery);
    return s && c && q;
  }).toList();

  int      _cat(String c) => _allActions.where((a) => a.category == c).length;
  Color    _catColor(String c) => c == 'Notification' ? cNotification : c == 'Investigation' ? cInvestigation : c == 'Containment' ? cContainment : cRemediation;
  IconData _catIcon(String c)  => c == 'Notification' ? Icons.notifications_outlined : c == 'Investigation' ? Icons.search : c == 'Containment' ? Icons.shield_outlined : Icons.build_circle_outlined;

  Widget _badge(String s) {
    final color = s == 'Success' ? kLow : s == 'Pending' ? kHigh : s == 'Failed' ? kCritical : kSubText;
    final icon  = s == 'Success' ? Icons.check_circle_outlined : s == 'Pending' ? Icons.schedule : s == 'Failed' ? Icons.cancel_outlined : Icons.remove_circle_outline;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withOpacity(0.5))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, color: color, size: 11), const SizedBox(width: 4), Text(s, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600))]),
    );
  }

  void _toggleLiveMonitor(BuildContext ctx) {
    setState(() => _liveMonitor = !_liveMonitor);
    if (_liveMonitor) {
      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
        backgroundColor: kCardBg, behavior: SnackBarBehavior.floating, margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: const BorderSide(color: kCardBorder)),
        duration: const Duration(seconds: 30),
        content: Row(children: [
          Container(width: 30, height: 30, decoration: BoxDecoration(color: kMedium.withOpacity(0.15), shape: BoxShape.circle, border: Border.all(color: kMedium.withOpacity(0.4))), child: const Icon(Icons.info_outline, color: kMedium, size: 15)),
          const SizedBox(width: 10),
          const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text('Live Monitor Activated', style: TextStyle(color: kBodyText, fontSize: 13, fontWeight: FontWeight.w700)),
            Text('Monitoring automated actions in real-time.', style: TextStyle(color: kSubText, fontSize: 11)),
          ])),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () { setState(() => _liveMonitor = false); ScaffoldMessenger.of(ctx).hideCurrentSnackBar(); },
            child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: kFieldBg, borderRadius: BorderRadius.circular(7), border: Border.all(color: kCardBorder)), child: const Text('Stop', style: TextStyle(color: kBodyText, fontSize: 11, fontWeight: FontWeight.w600))),
          ),
        ]),
      ));
    } else { ScaffoldMessenger.of(ctx).hideCurrentSnackBar(); }
  }

  void _showSimulateMenu(BuildContext ctx) {
    final box = _simulateKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final offset = box.localToGlobal(Offset.zero); final size = box.size;
    showMenu<String>(
      context: ctx, color: kCardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: const BorderSide(color: kCardBorder)),
      position: RelativeRect.fromLTRB(offset.dx, offset.dy + size.height + 6, offset.dx + size.width, offset.dy + size.height + 200),
      items: [
        PopupMenuItem(value: 'Critical Alert', padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), child: Row(children: [Container(width: 9, height: 9, decoration: const BoxDecoration(color: kCritical, shape: BoxShape.circle)), const SizedBox(width: 10), const Text('Critical Alert', style: TextStyle(color: kBodyText, fontSize: 13))])),
        PopupMenuItem(value: 'High Alert',     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), child: Row(children: [Container(width: 9, height: 9, decoration: const BoxDecoration(color: kHigh,     shape: BoxShape.circle)), const SizedBox(width: 10), const Text('High Alert',     style: TextStyle(color: kBodyText, fontSize: 13))])),
      ],
    ).then((val) {
      if (val != null && ctx.mounted) {
        final isCrit = val == 'Critical Alert';
        ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
          backgroundColor: kCardBg, behavior: SnackBarBehavior.floating, margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: const BorderSide(color: kCardBorder)),
          duration: const Duration(seconds: 2),
          content: Row(children: [Icon(Icons.bolt, color: isCrit ? kCritical : kHigh, size: 18), const SizedBox(width: 10), Text('$val simulation triggered', style: const TextStyle(color: kBodyText, fontSize: 13))]),
        ));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(backgroundColor: kPageBg, body: Center(child: CircularProgressIndicator(color: kAccent)));
    if (_error != null) {
      return Scaffold(backgroundColor: kPageBg, body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.error_outline, color: kCritical, size: 40), const SizedBox(height: 12),
        const Text('Failed to load', style: TextStyle(color: kBodyText, fontSize: 16)),
        TextButton(onPressed: _loadData, child: const Text('Retry', style: TextStyle(color: kAccent))),
      ])));
    }

    final stats    = _stats!;
    final contain  = _cat('Containment');
    final notif    = _cat('Notification');
    final invest   = _cat('Investigation');
    final remedi   = _cat('Remediation');
    final filtered = _filtered;
    final isWide   = MediaQuery.of(context).size.width >= 600;

    return Scaffold(
      backgroundColor: kPageBg,
      body: SafeArea(
        child: Scrollbar(
          controller: _scrollCtrl, thumbVisibility: true, thickness: 5,
          child: SingleChildScrollView(
            controller: _scrollCtrl,
            padding: const EdgeInsets.fromLTRB(14, 18, 16, 20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Automated Actions', style: TextStyle(color: kBodyText, fontSize: 22, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text('Real-time monitoring • ${_allActions.length} total actions', style: const TextStyle(color: kSubText, fontSize: 12)),
              const SizedBox(height: 16),
              _buildStatCards(stats, isWide),
              const SizedBox(height: 14),
              _buildCharts(stats, contain, notif, invest, remedi, isWide),
              const SizedBox(height: 14),
              _buildLogHeader(isWide),
              const SizedBox(height: 10),
              _buildFilters(isWide),
              const SizedBox(height: 6),
              Row(children: [
                Flexible(child: Text('Showing ${filtered.length} of ${_allActions.length} actions', style: const TextStyle(color: kSubText, fontSize: 11))),
                const Spacer(),
                Text('${stats.success} ok',   style: const TextStyle(color: kLow,      fontSize: 11, fontWeight: FontWeight.w600)),
                const Text('  •  ', style: TextStyle(color: kSubText, fontSize: 11)),
                Text('${stats.pending} pend', style: const TextStyle(color: kHigh,     fontSize: 11, fontWeight: FontWeight.w600)),
                const Text('  •  ', style: TextStyle(color: kSubText, fontSize: 11)),
                Text('${stats.failed} fail',  style: const TextStyle(color: kCritical, fontSize: 11, fontWeight: FontWeight.w600)),
              ]),
              const SizedBox(height: 8),
              _buildTable(filtered, isWide),
              const SizedBox(height: 16),
              _buildBottomCards(stats, isWide),
            ]),
          ),
        ),
      ),
    );
  }

  // ✅ FIX: استخدام IntrinsicHeight لتساوي ارتفاع الـ cards
  Widget _buildStatCards(AutomatedActionsStats stats, bool isWide) {
    final cards = <Widget>[
      _StatCard(icon: Icons.bolt,                  iconColor: kAccent,   label: 'Total Actions', value: '${stats.total}',   sub: 'All time'),
      _StatCard(icon: Icons.check_circle_outlined, iconColor: kLow,      label: 'Successful',    value: '${stats.success}', sub: '${stats.total > 0 ? (stats.success / stats.total * 100).toStringAsFixed(1) : 0}% rate', valueColor: kLow),
      _StatCard(icon: Icons.schedule,              iconColor: kHigh,     label: 'Pending',       value: '${stats.pending}', sub: 'In progress', valueColor: kHigh),
      _StatCard(icon: Icons.cancel_outlined,       iconColor: kCritical, label: 'Failed',        value: '${stats.failed}',  sub: 'Needs attention', valueColor: kCritical),
      _StatCard(icon: Icons.show_chart,            iconColor: kAccent,   label: 'Avg Duration',  value: '${stats.avgDuration.toStringAsFixed(2)}s', sub: 'Per action'),
      _StatCard(icon: Icons.share,                 iconColor: kMedium,   label: 'API Calls',     value: '${stats.totalApiCalls}', sub: 'Total executed'),
    ];

    if (isWide) {
      // ✅ IntrinsicHeight يجعل كل الـ cards بنفس الارتفاع
      return IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: cards.asMap().entries.map((e) =>
            Expanded(child: Padding(
              padding: EdgeInsets.only(right: e.key < cards.length - 1 ? 8 : 0),
              child: e.value,
            )),
          ).toList(),
        ),
      );
    }

    // Mobile: 2x3 grid بـ IntrinsicHeight في كل row
    return Column(children: [
      IntrinsicHeight(child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Expanded(child: cards[0]),
        const SizedBox(width: 10),
        Expanded(child: cards[1]),
      ])),
      const SizedBox(height: 10),
      IntrinsicHeight(child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Expanded(child: cards[2]),
        const SizedBox(width: 10),
        Expanded(child: cards[3]),
      ])),
      const SizedBox(height: 10),
      IntrinsicHeight(child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Expanded(child: cards[4]),
        const SizedBox(width: 10),
        Expanded(child: cards[5]),
      ])),
    ]);
  }

  Widget _buildCharts(AutomatedActionsStats stats, int contain, int notif, int invest, int remedi, bool isWide) {
    final donut = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: kCardBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: kCardBorder)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: const [Icon(Icons.show_chart, color: kAccent, size: 14), SizedBox(width: 8), Text('Actions by Category', style: TextStyle(color: kBodyText, fontSize: 13, fontWeight: FontWeight.w700))]),
        const SizedBox(height: 12),
        SizedBox(height: 200, child: _AnimatedDonut(
          values: [contain, notif, invest, remedi],
          colors: [cContainment, cNotification, cInvestigation, cRemediation],
          labels: ['Containment', 'Notification', 'Investigation', 'Remediation'],
        )),
        const SizedBox(height: 10),
        Wrap(spacing: 10, runSpacing: 6, children: [
          _Leg('Containment',   contain, cContainment),
          _Leg('Notification',  notif,   cNotification),
          _Leg('Investigation', invest,  cInvestigation),
          _Leg('Remediation',   remedi,  cRemediation),
        ]),
      ]),
    );

    final barChart = Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      decoration: BoxDecoration(color: kCardBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: kCardBorder)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: const [Icon(Icons.show_chart, color: kAccent, size: 14), SizedBox(width: 8), Text('Execution Status', style: TextStyle(color: kBodyText, fontSize: 13, fontWeight: FontWeight.w700))]),
        const SizedBox(height: 12),
        SizedBox(height: 260, child: ClipRect(child: _AnimatedBarChart(
          success: stats.success, pending: stats.pending, failed: stats.failed, partial: stats.partial,
        ))),
      ]),
    );

    if (isWide) return Row(children: [Expanded(flex: 5, child: donut), const SizedBox(width: 12), Expanded(flex: 5, child: barChart)]);
    return Column(children: [donut, const SizedBox(height: 12), barChart]);
  }

  Widget _buildLogHeader(bool isWide) {
    if (isWide) {
      return Row(children: [
        const Icon(Icons.terminal, color: kAccent, size: 14), const SizedBox(width: 8),
        const Text('Automated Actions Execution Log', style: TextStyle(color: kBodyText, fontSize: 13, fontWeight: FontWeight.w700)),
        const Spacer(),
        Builder(builder: (ctx) => _TopBtn(icon: Icons.download_outlined, label: 'Export', onTap: () => _exportPDF(_filtered, ctx))),
        const SizedBox(width: 8),
        Builder(builder: (ctx) => _TopBtn(icon: _liveMonitor ? Icons.visibility : Icons.visibility_outlined, label: 'Live Monitor', active: _liveMonitor, onTap: () => _toggleLiveMonitor(ctx))),
        const SizedBox(width: 8),
        Builder(builder: (ctx) => _SimulateBtn(simulateKey: _simulateKey, onTap: () => _showSimulateMenu(ctx))),
      ]);
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Row(children: [Icon(Icons.terminal, color: kAccent, size: 14), SizedBox(width: 8), Text('Execution Log', style: TextStyle(color: kBodyText, fontSize: 13, fontWeight: FontWeight.w700))]),
      const SizedBox(height: 10),
      Wrap(spacing: 8, runSpacing: 8, children: [
        Builder(builder: (ctx) => _TopBtn(icon: Icons.download_outlined, label: 'Export', onTap: () => _exportPDF(_filtered, ctx))),
        Builder(builder: (ctx) => _TopBtn(icon: _liveMonitor ? Icons.visibility : Icons.visibility_outlined, label: 'Live Monitor', active: _liveMonitor, onTap: () => _toggleLiveMonitor(ctx))),
        Builder(builder: (ctx) => _SimulateBtn(simulateKey: _simulateKey, onTap: () => _showSimulateMenu(ctx))),
      ]),
    ]);
  }

  Widget _buildFilters(bool isWide) {
    final search = Container(
      height: 36,
      decoration: BoxDecoration(color: kCardBg, borderRadius: BorderRadius.circular(8), border: Border.all(color: kCardBorder)),
      child: Row(children: [
        const SizedBox(width: 10), const Icon(Icons.search, color: kSubText, size: 14), const SizedBox(width: 7),
        Expanded(child: TextField(controller: _searchCtrl, style: const TextStyle(color: kBodyText, fontSize: 12),
          decoration: const InputDecoration(hintText: 'Search actions...', hintStyle: TextStyle(color: kSubText, fontSize: 12), border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero),
          onChanged: (v) => setState(() => _searchQuery = v))),
      ]),
    );
    if (isWide) {
      return Row(children: [
        Expanded(child: search), const SizedBox(width: 10),
        _DropF(value: _statusFilter,   options: const ['All Status',     'Success', 'Pending', 'Failed', 'Partial'],                     onChanged: (v) => setState(() => _statusFilter   = v)),
        const SizedBox(width: 10),
        _DropF(value: _categoryFilter, options: const ['All Categories', 'Notification', 'Investigation', 'Containment', 'Remediation'], onChanged: (v) => setState(() => _categoryFilter = v)),
      ]);
    }
    return Column(children: [
      search, const SizedBox(height: 8),
      Row(children: [
        Expanded(child: _DropF(value: _statusFilter,   options: const ['All Status',     'Success', 'Pending', 'Failed', 'Partial'],                     onChanged: (v) => setState(() => _statusFilter   = v))),
        const SizedBox(width: 8),
        Expanded(child: _DropF(value: _categoryFilter, options: const ['All Categories', 'Notification', 'Investigation', 'Containment', 'Remediation'], onChanged: (v) => setState(() => _categoryFilter = v))),
      ]),
    ]);
  }

  Widget _buildTable(List<AutoAction> filtered, bool isWide) {
    return SizedBox(height: 460, child: Container(
      decoration: BoxDecoration(color: kCardBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: kCardBorder)),
      child: Column(children: [
        if (isWide)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: kCardBorder))),
            // ✅ FIX: استخدام SingleChildScrollView للـ header عشان يتطابق مع الـ rows
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(width: 730, child: Row(children: const [
                SizedBox(width: 20),
                SizedBox(width: 65,  child: Text('Alert ID',    style: _hS)),
                SizedBox(width: 175, child: Text('Action Type', style: _hS)),
                SizedBox(width: 120, child: Text('Category',    style: _hS)),
                SizedBox(width: 100, child: Text('Status',      style: _hS)),
                SizedBox(width: 65,  child: Text('Duration',    style: _hS)),
                SizedBox(width: 35,  child: Text('API',         style: _hS)),
                Expanded(            child: Text('Playbook',    style: _hS)),
              ])),
            ),
          ),
        Expanded(child: Scrollbar(
          controller: _tableScrollCtrl, thumbVisibility: true,
          child: filtered.isEmpty
              ? const Center(child: Text('No actions found', style: TextStyle(color: kSubText, fontSize: 14)))
              : isWide
                  ? ListView.separated(controller: _tableScrollCtrl, padding: EdgeInsets.zero, itemCount: filtered.length,
                      separatorBuilder: (_, __) => const Divider(color: kCardBorder, height: 1),
                      itemBuilder: (ctx, i) {
                        final a = filtered[i]; final key = '${a.alertId}_$i';
                        return _ActionRow(action: a, expanded: _expanded.contains(key), catColor: _catColor(a.category), catIcon: _catIcon(a.category), badge: _badge(a.status),
                          onToggle: () => setState(() { _expanded.contains(key) ? _expanded.remove(key) : _expanded.add(key); }));
                      })
                  : ListView.separated(controller: _tableScrollCtrl, padding: const EdgeInsets.all(10), itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (ctx, i) {
                        final a = filtered[i]; final key = '${a.alertId}_$i';
                        return _ActionMobileCard(action: a, expanded: _expanded.contains(key), catColor: _catColor(a.category), catIcon: _catIcon(a.category), badge: _badge(a.status),
                          onToggle: () => setState(() { _expanded.contains(key) ? _expanded.remove(key) : _expanded.add(key); }));
                      }),
        )),
      ]),
    ));
  }

  Widget _buildBottomCards(AutomatedActionsStats stats, bool isWide) {
    final tips = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: kCardBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: kCardBorder)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: const [Icon(Icons.lightbulb, color: kAccent, size: 14), SizedBox(width: 8), Text('Quick Tips', style: TextStyle(color: kBodyText, fontSize: 13, fontWeight: FontWeight.w700))]),
        const SizedBox(height: 12),
        _Tip('Click on any row to expand and view detailed execution steps'),
        _Tip('Use filters to focus on specific action types or statuses'),
        _Tip('Export saves the PDF directly to your Downloads folder'),
        _Tip('Live Monitor shows real-time action execution'),
      ]),
    );
    final metrics = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: kCardBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: kCardBorder)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: const [Icon(Icons.bar_chart_rounded, color: kAccent, size: 14), SizedBox(width: 8), Text('Performance Metrics', style: TextStyle(color: kBodyText, fontSize: 13, fontWeight: FontWeight.w700))]),
        const SizedBox(height: 14),
        _PerfRow('Success Rate:',      '${stats.total > 0 ? (stats.success / stats.total * 100).toStringAsFixed(1) : 0}%', kLow),
        _PerfRow('Avg Response Time:', '${stats.avgDuration.toStringAsFixed(2)}s', kBodyText),
        _PerfRow('Total API Calls:',   '${stats.totalApiCalls}',                   kBodyText),
      ]),
    );
    if (isWide) return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: tips), const SizedBox(width: 12), Expanded(child: metrics)]);
    return Column(children: [tips, const SizedBox(height: 12), metrics]);
  }
}

const _hS = TextStyle(color: kSubText, fontSize: 11, fontWeight: FontWeight.w700);

// ✅ FIX: _StatCard بيتمدد ليملي الـ height المتاح (crossAxisAlignment.stretch)
class _StatCard extends StatelessWidget {
  final IconData icon; final Color iconColor; final String label, value, sub; final Color? valueColor;
  const _StatCard({required this.icon, required this.iconColor, required this.label, required this.value, required this.sub, this.valueColor});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: kCardBg, borderRadius: BorderRadius.circular(10), border: Border.all(color: kCardBorder)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.max, children: [
      Row(children: [
        Flexible(child: Text(label, style: const TextStyle(color: kSubText, fontSize: 11))),
        const Spacer(),
        Icon(icon, color: iconColor, size: 14),
      ]),
      const SizedBox(height: 6),
      Text(value, style: TextStyle(color: valueColor ?? kBodyText, fontSize: 20, fontWeight: FontWeight.w800)),
      const SizedBox(height: 2),
      Text(sub, style: const TextStyle(color: kSubText, fontSize: 10)),
    ]),
  );
}

// ══ ANIMATED DONUT ══════════════════════════════════════════════
class _AnimatedDonut extends StatefulWidget {
  final List<int> values; final List<Color> colors; final List<String> labels;
  const _AnimatedDonut({required this.values, required this.colors, required this.labels});
  @override State<_AnimatedDonut> createState() => _AnimatedDonutState();
}

class _AnimatedDonutState extends State<_AnimatedDonut> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _anim;
  int?   _hoveredIdx;
  Offset _tooltipPos = Offset.zero;
  DateTime? _tapTime;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _ctrl.forward();
  }
  @override void dispose() { _ctrl.dispose(); super.dispose(); }

  int? _indexAtPosition(Offset local, Size size) {
    final cx = size.width / 2, cy = size.height / 2;
    final dx = local.dx - cx, dy = local.dy - cy;
    final dist = sqrt(dx * dx + dy * dy);
    final r = (size.shortestSide / 2) * 0.78;
    const sh = 22.0;
    if (dist < r - sh || dist > r + sh) return null;
    var angle = atan2(dy, dx) + pi / 2;
    if (angle < 0) angle += 2 * pi;
    final tv = widget.values.fold<int>(0, (s, e) => s + e);
    double cum = 0;
    for (var i = 0; i < widget.values.length; i++) {
      cum += (widget.values[i] / tv) * 2 * pi;
      if (angle <= cum) return i;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.values.fold<int>(0, (s, e) => s + e);
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => LayoutBuilder(builder: (ctx, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        return Stack(alignment: Alignment.center, children: [
          GestureDetector(
            onTapDown: (d) {
              final idx = _indexAtPosition(d.localPosition, size);
              setState(() { _hoveredIdx = idx; _tooltipPos = d.localPosition; _tapTime = DateTime.now(); });
              if (idx != null) Future.delayed(const Duration(milliseconds: 1500), () { if (mounted && _tapTime != null && DateTime.now().difference(_tapTime!).inMilliseconds >= 1490) setState(() => _hoveredIdx = null); });
            },
            child: MouseRegion(
              onHover: (e) { final idx = _indexAtPosition(e.localPosition, size); setState(() { _hoveredIdx = idx; _tooltipPos = e.localPosition; }); },
              onExit: (_) => setState(() => _hoveredIdx = null),
              child: CustomPaint(size: size, painter: _DonutPainter(values: widget.values, colors: widget.colors, progress: _anim.value, hoveredIdx: _hoveredIdx)),
            ),
          ),
          IgnorePointer(child: _hoveredIdx != null
            ? Column(mainAxisSize: MainAxisSize.min, children: [
                Text('${widget.values[_hoveredIdx!]}', style: TextStyle(color: widget.colors[_hoveredIdx!], fontSize: 24, fontWeight: FontWeight.w800)),
                Text(widget.labels[_hoveredIdx!], style: const TextStyle(color: kSubText, fontSize: 10)),
              ])
            : Column(mainAxisSize: MainAxisSize.min, children: [
                Text('$total', style: const TextStyle(color: kBodyText, fontSize: 28, fontWeight: FontWeight.w800)),
                const Text('Actions', style: TextStyle(color: kSubText, fontSize: 11)),
              ])),
          if (_hoveredIdx != null)
            Positioned(
              left: (_tooltipPos.dx + 14).clamp(0.0, size.width - 140),
              top:  (_tooltipPos.dy - 62).clamp(0.0, size.height - 56),
              child: IgnorePointer(child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(color: const Color(0xFF0D1B2E), borderRadius: BorderRadius.circular(8), border: Border.all(color: kCardBorder), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 10)]),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(width: 10, height: 10, decoration: BoxDecoration(color: widget.colors[_hoveredIdx!], borderRadius: BorderRadius.circular(3))),
                  const SizedBox(width: 7),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                    Text(widget.labels[_hoveredIdx!], style: const TextStyle(color: kBodyText, fontSize: 11, fontWeight: FontWeight.w600)),
                    Text('${widget.values[_hoveredIdx!]}', style: TextStyle(color: widget.colors[_hoveredIdx!], fontSize: 13, fontWeight: FontWeight.bold)),
                  ]),
                ]),
              )),
            ),
        ]);
      }),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<int> values; final List<Color> colors; final double progress; final int? hoveredIdx;
  const _DonutPainter({required this.values, required this.colors, required this.progress, this.hoveredIdx});
  @override
  void paint(Canvas canvas, Size size) {
    final total = values.fold<int>(0, (s, e) => s + e);
    if (total == 0) return;
    final cx = size.width / 2, cy = size.height / 2;
    final r = (min(size.width, size.height) / 2) * 0.78;
    const stroke = 30.0, gap = 0.012;
    final allowed = 2 * pi * progress;
    double drawn = 0, start = -pi / 2;
    for (var i = 0; i < values.length; i++) {
      if (drawn >= allowed) break;
      final full  = (values[i] / total) * 2 * pi - gap;
      final sweep = full.clamp(0.0, allowed - drawn);
      if (sweep > 0) {
        final isHov = hoveredIdx == i;
        canvas.drawArc(Rect.fromCircle(center: Offset(cx, cy), radius: isHov ? r + 4 : r), start, sweep, false,
          Paint()..color = isHov ? colors[i] : colors[i].withOpacity(0.85)..style = PaintingStyle.stroke..strokeWidth = isHov ? stroke + 6 : stroke);
      }
      drawn += full + gap; start += full + gap;
    }
  }
  @override bool shouldRepaint(_DonutPainter o) => o.progress != progress || o.values != values || o.hoveredIdx != hoveredIdx;
}

// ══════════════════════════════════════════════════════════════
// BAR CHART
// ══════════════════════════════════════════════════════════════
class _AnimatedBarChart extends StatefulWidget {
  final int success, pending, failed, partial;
  const _AnimatedBarChart({required this.success, required this.pending, required this.failed, required this.partial});
  @override State<_AnimatedBarChart> createState() => _AnimatedBarChartState();
}

class _AnimatedBarChartState extends State<_AnimatedBarChart> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _anim;
  int _activeIdx = -1;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
    _ctrl.forward();
  }
  @override void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final realValues = [widget.success, widget.pending, widget.failed, widget.partial];
    final labels     = ['Success', 'Pending', 'Failed', 'Partial'];
    final colors     = [kLow, kHigh, kCritical, kSubText];
    final maxVal     = realValues.fold<int>(0, (a, b) => a > b ? a : b).toDouble();

    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => LayoutBuilder(builder: (context, constraints) {
        const labelAreaH  = 44.0;
        const bottomAreaH = 28.0;
        const axisW       = 36.0;
        final availH = constraints.maxHeight;
        final barsH  = (availH - labelAreaH - bottomAreaH).clamp(10.0, availH);

        final successFrac = maxVal == 0 ? 0.0 : realValues[0] / maxVal;
        final successBarH = (barsH * successFrac * _anim.value).clamp(0.0, barsH);

        return Stack(children: [
          Row(children: [
            SizedBox(width: axisW, height: availH,
              child: Column(children: [
                SizedBox(height: labelAreaH),
                Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.end,
                  children: ['100', '75', '50', '25', '0'].map((v) => Text(v, style: const TextStyle(color: kSubText, fontSize: 9))).toList())),
                SizedBox(height: bottomAreaH),
              ]),
            ),
            const SizedBox(width: 6),
            Expanded(child: Column(children: [
              SizedBox(height: labelAreaH,
                child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: List.generate(4, (i) {
                  final show = i == 0 || _activeIdx == i;
                  return Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                      AnimatedOpacity(duration: const Duration(milliseconds: 200), opacity: show ? 1.0 : 0.0,
                        child: Text('${realValues[i]}', style: TextStyle(color: colors[i], fontSize: 11, fontWeight: FontWeight.w700), textAlign: TextAlign.center)),
                    ]),
                  ));
                })),
              ),
              Flexible(child: SizedBox(height: barsH,
                child: Row(crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(4, (i) {
                    final isActive = _activeIdx == i;
                    double barH;
                    if (i == 0) {
                      barH = successBarH;
                    } else if (isActive) {
                      barH = successBarH;
                    } else {
                      barH = 0.0;
                    }
                    return Expanded(child: GestureDetector(
                      onTapDown: (details) {
                        if (i == 0) return;
                        setState(() => _activeIdx = isActive ? -1 : i);
                        if (!isActive) {
                          Future.delayed(const Duration(milliseconds: 2000), () {
                            if (mounted && _activeIdx == i) setState(() => _activeIdx = -1);
                          });
                        }
                      },
                      child: MouseRegion(
                        onEnter: (_) { if (i > 0) setState(() => _activeIdx = i); },
                        onExit:  (_) { if (i > 0) setState(() => _activeIdx = -1); },
                        child: Align(alignment: Alignment.bottomCenter,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOutCubic,
                            width: double.infinity,
                            height: barH,
                            decoration: BoxDecoration(
                              color: (i == 0 || isActive) ? colors[i] : Colors.transparent,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                              boxShadow: isActive && i > 0 ? [BoxShadow(color: colors[i].withOpacity(0.45), blurRadius: 14, spreadRadius: 2)] : [],
                            ),
                          ),
                        ),
                      ),
                    ));
                  }),
                ),
              )),
              Container(height: 1, color: kCardBorder),
              SizedBox(height: bottomAreaH,
                child: Row(children: List.generate(4, (i) => Expanded(child: Center(child: Text(labels[i],
                  style: TextStyle(color: _activeIdx == i ? colors[i] : kSubText, fontSize: 10, fontWeight: _activeIdx == i ? FontWeight.w700 : FontWeight.w400))))))),
            ])),
          ]),
          if (_activeIdx > 0)
            Builder(builder: (ctx) {
              final i        = _activeIdx;
              final barWidth = (constraints.maxWidth - axisW - 6) / 4;
              final centerX  = axisW + 6 + (i * barWidth) + barWidth / 2;
              const tooltipW = 110.0;
              double left = centerX - tooltipW / 2;
              left = left.clamp(axisW + 4.0, constraints.maxWidth - tooltipW - 4.0);
              return Positioned(
                left: left, top: (labelAreaH - 70.0).clamp(0.0, availH - 80.0),
                child: IgnorePointer(child: Container(
                  width: tooltipW,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(color: const Color(0xFF0D1B2E), borderRadius: BorderRadius.circular(8), border: Border.all(color: kCardBorder), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.55), blurRadius: 14)]),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(labels[i], style: TextStyle(color: colors[i], fontSize: 11, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text('${realValues[i]}', style: TextStyle(color: colors[i], fontSize: 22, fontWeight: FontWeight.w800)),
                  ]),
                )),
              );
            }),
        ]);
      }),
    );
  }
}

// ══ ACTION ROW ══════════════════════════════════════════════════
class _ActionRow extends StatefulWidget {
  final AutoAction action; final bool expanded; final Color catColor; final IconData catIcon; final Widget badge; final VoidCallback onToggle;
  const _ActionRow({required this.action, required this.expanded, required this.catColor, required this.catIcon, required this.badge, required this.onToggle});
  @override State<_ActionRow> createState() => _ActionRowState();
}

class _ActionRowState extends State<_ActionRow> {
  bool _hRow = false, _hAction = false;
  @override
  Widget build(BuildContext context) {
    final a = widget.action;
    return Column(children: [
      MouseRegion(
        onEnter: (_) => setState(() => _hRow = true),
        onExit:  (_) => setState(() => _hRow = false),
        child: GestureDetector(
          onTap: widget.onToggle,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            color: _hRow ? kFieldBg.withOpacity(0.5) : Colors.transparent,
            // ✅ FIX: تقليل الأعمدة من 780 لـ 730 عشان متعملش overflow
            child: SingleChildScrollView(scrollDirection: Axis.horizontal,
              child: SizedBox(width: 730, child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(children: [
                  SizedBox(width: 20, child: Icon(widget.expanded ? Icons.keyboard_arrow_down : Icons.chevron_right, color: kSubText, size: 14)),
                  SizedBox(width: 65,  child: Text(a.alertId, style: const TextStyle(color: kSubText, fontSize: 12), overflow: TextOverflow.ellipsis)),
                  SizedBox(width: 175, child: MouseRegion(
                    onEnter: (_) => setState(() => _hAction = true),
                    onExit:  (_) => setState(() => _hAction = false),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
                      decoration: BoxDecoration(color: _hAction ? kAccent.withOpacity(0.08) : Colors.transparent, borderRadius: BorderRadius.circular(6), border: Border.all(color: _hAction ? kAccent.withOpacity(0.35) : Colors.transparent)),
                      child: Row(children: [
                        Icon(Icons.diamond_outlined, color: _hAction ? kAccent : kSubText, size: 11), const SizedBox(width: 5),
                        Expanded(child: Text(a.actionType, overflow: TextOverflow.ellipsis, style: TextStyle(color: _hAction ? kAccent : kBodyText, fontSize: 12, fontWeight: FontWeight.w600))),
                      ]),
                    ),
                  )),
                  SizedBox(width: 120, child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: widget.catColor.withOpacity(0.1), borderRadius: BorderRadius.circular(5)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(widget.catIcon, color: widget.catColor, size: 11), const SizedBox(width: 4), Flexible(child: Text(a.category, style: TextStyle(color: widget.catColor, fontSize: 10, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis))]))),
                  SizedBox(width: 100, child: widget.badge),
                  SizedBox(width: 65,  child: Text(a.duration,      style: const TextStyle(color: kBodyText, fontSize: 11, fontFamily: 'monospace'))),
                  SizedBox(width: 35,  child: Text('${a.apiCalls}', style: const TextStyle(color: kSubText,  fontSize: 11))),
                  Expanded(child: Row(children: [
                    if (a.playbook != '-') ...[const Icon(Icons.description_outlined, color: kMedium, size: 11), const SizedBox(width: 4)],
                    Expanded(child: Text(a.playbook, overflow: TextOverflow.ellipsis, style: TextStyle(color: a.playbook != '-' ? kBodyText : kSubText, fontSize: 10))),
                  ])),
                ]),
              )),
            ),
          ),
        ),
      ),
      if (widget.expanded)
        Container(
          margin: const EdgeInsets.fromLTRB(56, 0, 16, 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: kPageBg, borderRadius: BorderRadius.circular(7), border: Border.all(color: kCardBorder)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Execution Steps', style: TextStyle(color: kAccent, fontSize: 12, fontWeight: FontWeight.w700)),
            const SizedBox(height: 7),
            ..._steps(a.category).map((s) => Padding(padding: const EdgeInsets.only(bottom: 5),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [const Icon(Icons.check_circle_outline, color: kLow, size: 12), const SizedBox(width: 6), Expanded(child: Text(s, style: const TextStyle(color: kSubText, fontSize: 11, height: 1.4)))]))),
          ]),
        ),
    ]);
  }
  List<String> _steps(String cat) => cat == 'Notification'
      ? ['Fetching alert details from SIEM...', 'Composing security notification...', 'Sending to SOC analyst via email and Slack...', 'Notification delivered successfully.']
      : cat == 'Investigation'
      ? ['Querying threat intelligence database...', 'Correlating IOCs with known threat actors...', 'Analyzing network traffic patterns...', 'Investigation report generated — threat confirmed.']
      : cat == 'Containment'
      ? ['Identifying affected endpoint/process...', 'Sending containment command to EDR...', 'Verifying isolation successful...', 'Endpoint contained — no further spread.']
      : ['Assessing remediation requirements...', 'Applying security patches/fixes...', 'Verifying remediation effectiveness...', 'System restored to secure state.'];
}

// ══ MOBILE CARD ══════════════════════════════════════════════════
class _ActionMobileCard extends StatelessWidget {
  final AutoAction action; final bool expanded; final Color catColor; final IconData catIcon; final Widget badge; final VoidCallback onToggle;
  const _ActionMobileCard({required this.action, required this.expanded, required this.catColor, required this.catIcon, required this.badge, required this.onToggle});
  @override
  Widget build(BuildContext context) {
    final a = action;
    return GestureDetector(onTap: onToggle,
      child: Container(padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(color: kPageBg, borderRadius: BorderRadius.circular(10), border: Border.all(color: kCardBorder)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Text(a.alertId, style: const TextStyle(color: kSubText, fontSize: 11)), const SizedBox(width: 8), Expanded(child: Text(a.actionType, style: const TextStyle(color: kBodyText, fontSize: 12, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)), Icon(expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: kSubText, size: 16)]),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 6, children: [
            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: catColor.withOpacity(0.1), borderRadius: BorderRadius.circular(5)), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(catIcon, color: catColor, size: 11), const SizedBox(width: 4), Text(a.category, style: TextStyle(color: catColor, fontSize: 10, fontWeight: FontWeight.w600))])),
            badge, Text(a.duration, style: const TextStyle(color: kBodyText, fontSize: 11, fontFamily: 'monospace')),
          ]),
          if (expanded) ...[
            const SizedBox(height: 10), const Divider(color: kCardBorder, height: 1), const SizedBox(height: 8),
            const Text('Execution Steps', style: TextStyle(color: kAccent, fontSize: 12, fontWeight: FontWeight.w700)), const SizedBox(height: 6),
            ..._steps(a.category).map((s) => Padding(padding: const EdgeInsets.only(bottom: 5), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [const Icon(Icons.check_circle_outline, color: kLow, size: 12), const SizedBox(width: 6), Expanded(child: Text(s, style: const TextStyle(color: kSubText, fontSize: 11, height: 1.4)))]))),
          ],
        ]),
      ),
    );
  }
  List<String> _steps(String cat) => cat == 'Notification'
      ? ['Fetching alert details from SIEM...', 'Composing security notification...', 'Sending to SOC analyst via email and Slack...', 'Notification delivered successfully.']
      : cat == 'Investigation'
      ? ['Querying threat intelligence database...', 'Correlating IOCs with known threat actors...', 'Analyzing network traffic patterns...', 'Investigation report generated — threat confirmed.']
      : cat == 'Containment'
      ? ['Identifying affected endpoint/process...', 'Sending containment command to EDR...', 'Verifying isolation successful...', 'Endpoint contained — no further spread.']
      : ['Assessing remediation requirements...', 'Applying security patches/fixes...', 'Verifying remediation effectiveness...', 'System restored to secure state.'];
}

// ══ HELPERS ══════════════════════════════════════════════════════
Widget _Leg(String label, int count, Color color) => Row(mainAxisSize: MainAxisSize.min, children: [
  Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
  const SizedBox(width: 5), Text('$label: $count', style: const TextStyle(color: kSubText, fontSize: 10)),
]);

class _SimulateBtn extends StatelessWidget {
  final GlobalKey simulateKey; final VoidCallback onTap;
  const _SimulateBtn({required this.simulateKey, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(key: simulateKey, onTap: onTap,
    child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), decoration: BoxDecoration(color: kAccent, borderRadius: BorderRadius.circular(8)),
      child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.bolt, color: Colors.black, size: 13), SizedBox(width: 5), Text('Simulate Alert', style: TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.w700))])));
}

class _TopBtn extends StatelessWidget {
  final IconData icon; final String label; final VoidCallback onTap; final bool active;
  const _TopBtn({required this.icon, required this.label, required this.onTap, this.active = false});
  @override
  Widget build(BuildContext context) => GestureDetector(onTap: onTap,
    child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(color: active ? kMedium.withOpacity(0.15) : kCardBg, borderRadius: BorderRadius.circular(8), border: Border.all(color: active ? kMedium.withOpacity(0.5) : kCardBorder)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, color: active ? kMedium : kSubText, size: 13), const SizedBox(width: 5), Text(label, style: TextStyle(color: active ? kMedium : kBodyText, fontSize: 12))])));
}

class _DropF extends StatelessWidget {
  final String value; final List<String> options; final ValueChanged<String> onChanged;
  const _DropF({required this.value, required this.options, required this.onChanged});
  @override
  Widget build(BuildContext context) => Container(
    height: 36,
    width: 160,
    padding: const EdgeInsets.symmetric(horizontal: 10),
    decoration: BoxDecoration(color: kCardBg, borderRadius: BorderRadius.circular(8), border: Border.all(color: kCardBorder)),
    child: DropdownButtonHideUnderline(child: DropdownButton<String>(
      value: value, dropdownColor: kFieldBg, style: const TextStyle(color: kBodyText, fontSize: 12),
      icon: const Icon(Icons.keyboard_arrow_down, color: kSubText, size: 14), isDense: true, isExpanded: true,
      items: options.map((o) => DropdownMenuItem(value: o, child: Text(o, style: TextStyle(color: o == value ? kAccent : kBodyText, fontSize: 12), overflow: TextOverflow.ellipsis))).toList(),
      onChanged: (v) { if (v != null) onChanged(v); },
    )),
  );
}

Widget _Tip(String text) => Padding(padding: const EdgeInsets.only(bottom: 8),
  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('• ', style: TextStyle(color: kSubText, fontSize: 12)), Expanded(child: Text(text, style: const TextStyle(color: kSubText, fontSize: 12, height: 1.5)))]));

Widget _PerfRow(String label, String value, Color valueColor) => Padding(padding: const EdgeInsets.only(bottom: 10),
  child: Row(children: [Text(label, style: const TextStyle(color: kSubText, fontSize: 13)), const Spacer(), Text(value, style: TextStyle(color: valueColor, fontSize: 13, fontWeight: FontWeight.w700))]));