// case_reports_screen.dart
// ✅ FIXES:
//   1. شريط التمرير أقصى اليمين باستخدام ScrollbarTheme + mainAxisMargin صفر
//   2. PDF Crash: pageTheme يحتوي كل الإعدادات
//   3. UI Overflow: SingleChildScrollView في tabs
//   4. أيقونة التنزيل: Icons.download_outlined

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'api_service.dart';
import 'file_service.dart';

const Color kPageBg     = Color(0xFF030810);
const Color kCardBg     = Color(0xFF070F1E);
const Color kCardBorder = Color(0xFF0F1E35);
const Color kAccent     = Color(0xFFCAF135);
const Color kSubText    = Color(0xFF5C7A99);
const Color kFieldBg    = Color(0xFF040B14);
const Color kCritical   = Color(0xFFE53E3E);
const Color kHigh       = Color(0xFFED8936);
const Color kMedium     = Color(0xFF4299E1);
const Color kLow        = Color(0xFF48BB78);

Future<void> _saveReport(BuildContext ctx, CaseReport c) async {
  final now      = DateTime.now();
  final dateStr  = '${now.year}-${now.month.toString().padLeft(2,'0')}-${now.day.toString().padLeft(2,'0')}';
  final timeStr  = '${now.hour.toString().padLeft(2,'0')}:${now.minute.toString().padLeft(2,'0')}:${now.second.toString().padLeft(2,'0')}';
  final fileName = 'case_report_${c.caseId}_$dateStr.pdf';

  final resolution  = c.status == 'TP' ? 'True Positive - Confirmed Threat' : 'False Positive - Not a Real Threat';
  final alertParts  = c.alertRule.split(' - ');
  final alertName   = alertParts.isNotEmpty ? alertParts[0] : c.alertRule;
  final actionName  = alertParts.length > 1  ? alertParts[1] : c.type;
  final processName = alertName.contains('Keylogger')  ? 'keylog.exe'
      : alertName.contains('Ransomware') ? 'ransom.exe'
      : alertName.contains('Crypto')     ? 'miner.exe'
      : alertName.contains('DLL')        ? 'inject.dll'
      : alertName.contains('Malware')    ? 'malware.exe'
      : 'unknown.exe';
  final processId   = (c.caseId.hashCode % 9000 + 1000).abs();
  final threatScore = c.severity == 'Critical' ? 93 : 72;
  final alertId     = (c.caseId.hashCode % 9000 + 1000).abs();
  final logEntries  = (c.caseId.hashCode % 40000 + 10000).abs();
  final relEvents   = (c.caseId.hashCode % 200 + 50).abs();
  final apiCalls    = (c.caseId.hashCode % 30 + 10).abs();
  final dataProc    = (c.caseId.hashCode % 400 + 100).abs();

  const pdfBg     = PdfColor.fromInt(0xFF030810);
  const pdfCard   = PdfColor.fromInt(0xFF070F1E);
  const pdfCard2  = PdfColor.fromInt(0xFF0A1628);
  const pdfAccent = PdfColor.fromInt(0xFFCAF135);
  const pdfBody   = PdfColors.white;
  const pdfSub    = PdfColor.fromInt(0xFF5C7A99);
  const pdfBorder = PdfColor.fromInt(0xFF0F1E35);
  const pdfLow    = PdfColor.fromInt(0xFF48BB78);
  const pdfCrit   = PdfColor.fromInt(0xFFE53E3E);
  final  pdfSev   = c.severity == 'Critical' ? PdfColor.fromInt(0xFFE53E3E)
      : c.severity == 'High'     ? PdfColor.fromInt(0xFFED8936)
      : PdfColor.fromInt(0xFF4299E1);
  final resColor  = c.status == 'TP' ? pdfCrit : pdfLow;

  pw.Widget pRow(String label, String value, {PdfColor? vc}) => pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 9),
    child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      pw.SizedBox(width: 130, child: pw.Text(label, style: pw.TextStyle(color: pdfSub, fontSize: 10))),
      pw.Expanded(child: pw.Text(value, style: pw.TextStyle(color: vc ?? pdfBody, fontSize: 11, fontWeight: pw.FontWeight.bold))),
    ]),
  );

  pw.Widget pSection(String title, List<pw.Widget> kids) => pw.Container(
    margin: const pw.EdgeInsets.only(bottom: 16),
    padding: const pw.EdgeInsets.all(14),
    decoration: pw.BoxDecoration(color: pdfCard, borderRadius: pw.BorderRadius.circular(7), border: pw.Border.all(color: pdfBorder)),
    child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      pw.Text(title, style: pw.TextStyle(color: pdfAccent, fontSize: 11, fontWeight: pw.FontWeight.bold)),
      pw.SizedBox(height: 8), pw.Divider(color: pdfBorder, thickness: 0.5), pw.SizedBox(height: 8),
      ...kids,
    ]),
  );

  pw.Widget pStep(String text) => pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 6),
    child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      pw.Text('[OK] ', style: pw.TextStyle(color: pdfLow, fontSize: 10, fontWeight: pw.FontWeight.bold)),
      pw.Expanded(child: pw.Text(text, style: pw.TextStyle(color: pdfBody, fontSize: 10))),
    ]),
  );

  pw.Widget pBullet(String text) => pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 7),
    child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      pw.Text('• ', style: pw.TextStyle(color: pdfAccent, fontSize: 11)),
      pw.Expanded(child: pw.Text(text, style: pw.TextStyle(color: pdfBody, fontSize: 10, lineSpacing: 1.5))),
    ]),
  );

  pw.Widget pThreatBar(int score) {
    final filled = score.clamp(0, 100); final empty = 100 - filled;
    return pw.Container(height: 10,
      decoration: pw.BoxDecoration(color: PdfColor.fromInt(0xFF0F1E35), borderRadius: pw.BorderRadius.circular(5)),
      child: pw.Row(children: [
        pw.Expanded(flex: filled, child: pw.Container(height: 10, decoration: pw.BoxDecoration(color: pdfSev, borderRadius: pw.BorderRadius.circular(5)))),
        if (empty > 0) pw.Expanded(flex: empty, child: pw.SizedBox(height: 10)),
      ]),
    );
  }

  final robotoRegular = await PdfGoogleFonts.robotoRegular();
  final robotoBold    = await PdfGoogleFonts.robotoBold();
  final doc = pw.Document();

  doc.addPage(pw.MultiPage(
    pageTheme: pw.PageTheme(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.symmetric(horizontal: 32, vertical: 28),
      theme: pw.ThemeData.withFont(base: robotoRegular, bold: robotoBold),
      buildBackground: (_) => pw.FullPage(ignoreMargins: true, child: pw.Container(color: pdfBg)),
    ),
    build: (_) => [
      pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: pw.BoxDecoration(color: pdfCard, borderRadius: pw.BorderRadius.circular(9), border: pw.Border.all(color: pdfAccent, width: 1.5)),
        child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
          pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text('IRAS', style: pw.TextStyle(color: pdfAccent, fontSize: 22, fontWeight: pw.FontWeight.bold, letterSpacing: 2)),
            pw.SizedBox(height: 3),
            pw.Text('Incident Response Automation System', style: pw.TextStyle(color: pdfSub, fontSize: 9)),
          ]),
          pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
            pw.Text('CASE REPORT', style: pw.TextStyle(color: pdfBody, fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 5),
            pw.Container(padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: pw.BoxDecoration(color: pdfSev, borderRadius: pw.BorderRadius.circular(4)), child: pw.Text(c.severity, style: pw.TextStyle(color: PdfColors.white, fontSize: 10, fontWeight: pw.FontWeight.bold))),
          ]),
        ]),
      ),
      pw.SizedBox(height: 14),
      pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: pw.BoxDecoration(color: pdfCard2, borderRadius: pw.BorderRadius.circular(5)),
        child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
          pw.Text('Case ID: ${c.caseId}', style: pw.TextStyle(color: pdfAccent, fontSize: 10, fontWeight: pw.FontWeight.bold)),
          pw.Text('Generated: $dateStr  $timeStr', style: pw.TextStyle(color: pdfSub, fontSize: 9)),
          pw.Text('Status: CLOSED', style: pw.TextStyle(color: pdfLow, fontSize: 10, fontWeight: pw.FontWeight.bold)),
        ]),
      ),
      pw.SizedBox(height: 16),
      pSection('CASE OVERVIEW', [
        pRow('Case ID', c.caseId), pRow('Alert Rule', c.alertRule), pRow('Alert Name', alertName),
        pRow('Action Taken', actionName), pRow('Severity', c.severity, vc: pdfSev), pRow('Type', c.type),
        pRow('Resolution', resolution, vc: resColor), pRow('Resolved Date', c.resolved),
      ]),
      pSection('ANALYST INFORMATION', [pRow('Analyst', 'Automated Response System'), pRow('Time to Resolve', 'Immediate (5.234s)'), pRow('Resolution Date', c.resolved)]),
      pSection('NETWORK INFORMATION',  [pRow('Source IP', '192.168.18.72'), pRow('MAC Address', '00:1B:44:11:3A:F5'), pRow('Destination IP', '-')]),
      pSection('ENDPOINT INFORMATION', [pRow('Hostname', 'WS-EXEC-08'), pRow('Process Name', processName, vc: pdfAccent), pRow('Process ID', '$processId')]),
      pSection('THREAT INTELLIGENCE', [
        pRow('Threat Score', '$threatScore / 100', vc: pdfSev),
        pw.SizedBox(height: 6), pThreatBar(threatScore), pw.SizedBox(height: 6),
        pw.Text(threatScore >= 90 ? 'Critical Threat — Immediate action required' : 'High Threat — Investigate promptly', style: pw.TextStyle(color: pdfSev, fontSize: 10)),
        pw.SizedBox(height: 8),
        pRow('Alert ID', '$alertId'), pRow('Original Date', '2025-11-11'), pRow('Timestamp', '2025-11-11 14:22:38'),
      ]),
      pSection('INVESTIGATION', [
        pw.Text('Actions Taken:', style: pw.TextStyle(color: pdfSub, fontSize: 10, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 6),
        pStep('Automated action triggered: $actionName'),
        pStep('Execution initiated at ${c.resolved} $timeStr'),
        pStep('Log Collection     - completed (1.234s)'),
        pStep('Pattern Matching   - completed (2.341s)'),
        pStep('Timeline Creation  - completed (0.892s)'),
        pStep('Report Generation  - completed (0.767s)'),
        pw.SizedBox(height: 10),
        pw.Text('Findings:', style: pw.TextStyle(color: pdfSub, fontSize: 10, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 6),
        pRow('Alert', alertName),
        pRow('Severity', '${c.severity}  |  Type: ${c.type}  |  Status: ${c.status}'),
        pRow('Duration', '5.234s  |  API Calls: $apiCalls  |  Data: $dataProc MB'),
        pRow('Log Entries', '$logEntries'), pRow('Related Events', '$relEvents'),
        pRow('Playbook', 'Log Analysis Automation v2.0'), pRow('Triggered By', 'SIEM Correlation Engine'),
      ]),
      pSection('RECOMMENDATIONS', [
        pBullet('Automated response completed successfully.'),
        pBullet('Continue monitoring affected assets closely.'),
        pBullet('Schedule immediate incident review.'),
        pBullet('Consider implementing additional preventive controls.'),
        pBullet('Resolution: $resolution'),
      ]),
      pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: pw.BoxDecoration(color: pdfCard, borderRadius: pw.BorderRadius.circular(5), border: pw.Border.all(color: pdfBorder)),
        child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
          pw.Text('End of Report — ${c.caseId}', style: pw.TextStyle(color: pdfSub, fontSize: 9)),
          pw.Text('IRAS v1.0', style: pw.TextStyle(color: pdfAccent, fontSize: 9, fontWeight: pw.FontWeight.bold)),
        ]),
      ),
    ],
  ));

  final bytes = await doc.save();
  if (ctx.mounted) await FileService().saveAndOpen(bytes: bytes, fileName: fileName, ctx: ctx);
}

// ══════════════════════════════════════════════════════════════
//  SCREEN
// ══════════════════════════════════════════════════════════════
class CaseReportsScreen extends StatefulWidget {
  const CaseReportsScreen({super.key});
  @override State<CaseReportsScreen> createState() => _CaseReportsScreenState();
}

class _CaseReportsScreenState extends State<CaseReportsScreen> {
  final _service     = CaseReportsService();
  final _scrollCtrl  = ScrollController();
  final _search1Ctrl = TextEditingController();
  final _search2Ctrl = TextEditingController();

  String _searchId   = '';
  String _searchRule = '';
  String _sevFilter  = 'All Severities';
  String _resFilter  = 'All Resolutions';

  List<CaseReport> _allCases = [];
  bool    _loading = true;
  String? _error;

  @override void initState() { super.initState(); _loadCases(); }
  @override void dispose() { _scrollCtrl.dispose(); _search1Ctrl.dispose(); _search2Ctrl.dispose(); super.dispose(); }

  Future<void> _loadCases() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await _service.getCases();
      setState(() { _allCases = data; _loading = false; });
    } catch (e) { setState(() { _error = e.toString(); _loading = false; }); }
  }

  int get _tpCount => _allCases.where((c) => c.status == 'TP').length;
  int get _fpCount => _allCases.where((c) => c.status == 'FP').length;

  List<CaseReport> get _filtered => _allCases.where((c) {
    final i = _searchId.isEmpty   || c.caseId.toLowerCase().contains(_searchId.toLowerCase());
    final r = _searchRule.isEmpty || c.alertRule.toLowerCase().contains(_searchRule.toLowerCase()) || c.type.toLowerCase().contains(_searchRule.toLowerCase());
    final s = _sevFilter == 'All Severities'  || c.severity == _sevFilter;
    final e = _resFilter == 'All Resolutions' || c.status   == _resFilter;
    return i && r && s && e;
  }).toList();

  Color _sevColor(String s) =>
      s == 'Critical' ? kCritical : s == 'High' ? kHigh : s == 'Medium' ? kMedium : kLow;

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(backgroundColor: kPageBg, body: Center(child: CircularProgressIndicator(color: kAccent)));
    if (_error != null) {
      return Scaffold(backgroundColor: kPageBg, body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.error_outline, color: kCritical, size: 40), const SizedBox(height: 12),
        const Text('Failed to load cases', style: TextStyle(color: Colors.white, fontSize: 16)), const SizedBox(height: 8),
        TextButton(onPressed: _loadCases, child: const Text('Retry', style: TextStyle(color: kAccent))),
      ])));
    }

    final filtered = _filtered;

    return Scaffold(
      backgroundColor: kPageBg,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: LayoutBuilder(builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 600;
          final hPad   = isWide ? 40.0 : 14.0;

          return Padding(
            padding: EdgeInsets.fromLTRB(hPad, hPad, hPad, 0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 8, children: const [
                Text('Case reports', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
                Icon(Icons.folder_copy_outlined, color: kAccent, size: 22),
              ]),
              const SizedBox(height: 4),
              const Text('Resolved incidents and documentation', style: TextStyle(color: kSubText, fontSize: 13)),
              const SizedBox(height: 20),

              Expanded(child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: kCardBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: kCardBorder)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _StatCards(total: _allCases.length, tp: _tpCount, fp: _fpCount, latestDate: _allCases.isNotEmpty ? _allCases.first.resolved : '—', isWide: isWide),
                  const SizedBox(height: 18),
                  _SearchBars(ctrl1: _search1Ctrl, ctrl2: _search2Ctrl, isWide: isWide,
                    onChanged1: (v) => setState(() => _searchId   = v),
                    onChanged2: (v) => setState(() => _searchRule = v)),
                  const SizedBox(height: 10),
                  _FilterRow(sevFilter: _sevFilter, resFilter: _resFilter, filteredCount: filtered.length, totalCount: _allCases.length,
                    onSevChanged: (v) => setState(() => _sevFilter = v),
                    onResChanged: (v) => setState(() => _resFilter = v)),
                  const SizedBox(height: 12),

                  if (isWide) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                      child: Row(children: [
                        SizedBox(width: 100, child: Text('Case ID',   style: _hS)),
                        Expanded(            child: Text('Alert rule', style: _hS)),
                        SizedBox(width: 88,  child: Text('Severity',  style: _hS)),
                        SizedBox(width: 120, child: Text('Type',      style: _hS)),
                        SizedBox(width: 62,  child: Text('Status',    style: _hS)),
                        SizedBox(width: 100, child: Text('Resolved',  style: _hS)),
                        SizedBox(width: 100, child: Text('Action',    style: _hS)),
                      ]),
                    ),
                    const Divider(color: kCardBorder, height: 1),
                  ],

                  // ✅ ScrollbarTheme لضبط موقع الـ scrollbar أقصى اليمين
                  Expanded(
                    child: ScrollbarTheme(
                      data: ScrollbarThemeData(
                        thumbColor: WidgetStateProperty.all(kAccent.withOpacity(0.5)),
                        trackColor: WidgetStateProperty.all(kCardBorder.withOpacity(0.3)),
                        trackBorderColor: WidgetStateProperty.all(Colors.transparent),
                        thickness: WidgetStateProperty.all(5),
                        radius: const Radius.circular(3),
                        // ✅ mainAxisMargin = 0 لأقصى اليمين بدون أي مسافة
                        mainAxisMargin: 0,
                        // ✅ crossAxisMargin = 0 للصق الـ scrollbar بحافة اليمين تماماً
                        crossAxisMargin: 0,
                        thumbVisibility: WidgetStateProperty.all(true),
                        trackVisibility: WidgetStateProperty.all(true),
                      ),
                      child: Scrollbar(
                        controller: _scrollCtrl,
                        thumbVisibility: true,
                        child: filtered.isEmpty
                            ? const Center(child: Text('No cases found', style: TextStyle(color: kSubText, fontSize: 14)))
                            : isWide
                                ? ListView.separated(
                                    controller: _scrollCtrl,
                                    // ✅ padding.right = 8 لإعطاء مسافة صغيرة بين الـ list والـ scrollbar
                                    padding: const EdgeInsets.only(right: 8),
                                    itemCount: filtered.length,
                                    separatorBuilder: (_, __) => const Divider(color: kCardBorder, height: 1),
                                    itemBuilder: (ctx, i) {
                                      final cr = filtered[i];
                                      return _CaseRow(caseReport: cr, sevColor: _sevColor(cr.severity),
                                        onView:     () => Navigator.of(ctx).push(MaterialPageRoute(builder: (_) => _CaseDetailPage(caseReport: cr))),
                                        onDownload: () => _saveReport(ctx, cr));
                                    },
                                  )
                                : ListView.separated(
                                    controller: _scrollCtrl,
                                    padding: const EdgeInsets.only(top: 4, bottom: 12, right: 8),
                                    itemCount: filtered.length,
                                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                                    itemBuilder: (ctx, i) {
                                      final cr = filtered[i];
                                      return _CaseMobileCard(caseReport: cr, sevColor: _sevColor(cr.severity),
                                        onView:     () => Navigator.of(ctx).push(MaterialPageRoute(builder: (_) => _CaseDetailPage(caseReport: cr))),
                                        onDownload: () => _saveReport(ctx, cr));
                                    },
                                  ),
                      ),
                    ),
                  ),
                ]),
              )),
            ]),
          );
        }),
      ),
    );
  }
}

const _hS = TextStyle(color: kSubText, fontSize: 11, fontWeight: FontWeight.w700);

class _StatCards extends StatelessWidget {
  final int total, tp, fp; final String latestDate; final bool isWide;
  const _StatCards({required this.total, required this.tp, required this.fp, required this.latestDate, required this.isWide});

  Widget _card(IconData icon, Color c, String title, String value) => Container(
    padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
    decoration: BoxDecoration(color: kPageBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: kCardBorder)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
      Row(children: [Icon(icon, size: 15, color: c), const SizedBox(width: 7), Flexible(child: Text(title, style: const TextStyle(color: kSubText, fontSize: 12)))]),
      const SizedBox(height: 10),
      Text(value, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
    ]),
  );

  @override
  Widget build(BuildContext context) {
    final items = [
      _card(Icons.folder_copy_outlined,    kAccent,            'Total Cases',     '$total'),
      _card(Icons.check_circle_outlined,   Colors.redAccent,   'True Positives',  '$tp'),
      _card(Icons.cancel_outlined,         Colors.greenAccent, 'False Positives', '$fp'),
      _card(Icons.calendar_today_outlined, kAccent,            'Resolved Date',   latestDate),
    ];
    if (isWide) {
      return IntrinsicHeight(child: Row(crossAxisAlignment: CrossAxisAlignment.stretch,
        children: items.asMap().entries.map((e) => Expanded(child: Padding(padding: EdgeInsets.only(right: e.key < items.length - 1 ? 12 : 0), child: e.value))).toList()));
    }
    return Column(children: [
      IntrinsicHeight(child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [Expanded(child: items[0]), const SizedBox(width: 10), Expanded(child: items[1])])),
      const SizedBox(height: 10),
      IntrinsicHeight(child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [Expanded(child: items[2]), const SizedBox(width: 10), Expanded(child: items[3])])),
    ]);
  }
}

class _SearchBars extends StatelessWidget {
  final TextEditingController ctrl1, ctrl2;
  final bool isWide;
  final ValueChanged<String> onChanged1, onChanged2;
  const _SearchBars({required this.ctrl1, required this.ctrl2, required this.isWide, required this.onChanged1, required this.onChanged2});

  Widget _bar(TextEditingController ctrl, String hint, ValueChanged<String> cb) => Container(
    height: 40,
    decoration: BoxDecoration(color: kFieldBg, borderRadius: BorderRadius.circular(10), border: Border.all(color: kCardBorder, width: 1.2)),
    child: TextField(
      controller: ctrl,
      style: const TextStyle(color: Colors.white, fontSize: 12),
      cursorColor: kAccent, onChanged: cb,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.search_rounded, color: kSubText, size: 15),
        hintText: hint, hintStyle: const TextStyle(color: kSubText, fontSize: 12),
        border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none,
        fillColor: Colors.transparent, filled: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    if (isWide) return Row(children: [Expanded(child: _bar(ctrl1, 'Search by Case ID or Alert ID...', onChanged1)), const SizedBox(width: 12), Expanded(child: _bar(ctrl2, 'Search by Rule, Analyst, Type...', onChanged2))]);
    return Column(children: [_bar(ctrl1, 'Search by Case ID...', onChanged1), const SizedBox(height: 8), _bar(ctrl2, 'Search by Rule / Type...', onChanged2)]);
  }
}

class _FilterRow extends StatelessWidget {
  final String sevFilter, resFilter;
  final int filteredCount, totalCount;
  final ValueChanged<String> onSevChanged, onResChanged;
  const _FilterRow({required this.sevFilter, required this.resFilter, required this.filteredCount, required this.totalCount, required this.onSevChanged, required this.onResChanged});

  Widget _drop(String val, List<String> opts, ValueChanged<String> cb) => Container(
    height: 34, padding: const EdgeInsets.symmetric(horizontal: 12),
    constraints: const BoxConstraints(maxWidth: 180),
    decoration: BoxDecoration(color: kFieldBg, borderRadius: BorderRadius.circular(20), border: Border.all(color: kCardBorder)),
    child: DropdownButtonHideUnderline(child: DropdownButton<String>(
      value: val, dropdownColor: kFieldBg,
      icon: const Icon(Icons.arrow_drop_down_rounded, color: kSubText, size: 16),
      style: const TextStyle(color: Colors.white, fontSize: 12),
      borderRadius: BorderRadius.circular(12), isExpanded: true,
      onChanged: (v) { if (v != null) cb(v); },
      items: opts.map((o) => DropdownMenuItem(value: o, child: Text(o, style: TextStyle(color: o == val ? kAccent : Colors.white, fontWeight: o == val ? FontWeight.bold : FontWeight.w400), overflow: TextOverflow.ellipsis))).toList(),
    )),
  );

  @override
  Widget build(BuildContext context) {
    return Wrap(spacing: 10, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
      const Icon(Icons.filter_list, color: kSubText, size: 13),
      const Text('Filters:', style: TextStyle(color: kSubText, fontSize: 12)),
      _drop(sevFilter, ['All Severities', 'Critical', 'High', 'Medium', 'Low'], onSevChanged),
      _drop(resFilter, ['All Resolutions', 'TP', 'FP'], onResChanged),
      RichText(text: TextSpan(style: const TextStyle(color: kSubText, fontSize: 12), children: [
        const TextSpan(text: 'Showing '),
        TextSpan(text: '$filteredCount', style: const TextStyle(color: kAccent, fontWeight: FontWeight.w700)),
        TextSpan(text: ' of $totalCount cases'),
      ])),
    ]);
  }
}

class _CaseRow extends StatefulWidget {
  final CaseReport caseReport; final Color sevColor; final VoidCallback onView, onDownload;
  const _CaseRow({required this.caseReport, required this.sevColor, required this.onView, required this.onDownload});
  @override State<_CaseRow> createState() => _CaseRowState();
}

class _CaseRowState extends State<_CaseRow> {
  bool _hovered = false;
  @override
  Widget build(BuildContext context) {
    final c = widget.caseReport; final isTP = c.status == 'TP';
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        color: _hovered ? kFieldBg.withOpacity(0.4) : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 13),
        child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          SizedBox(width: 100, child: Text(c.caseId, style: const TextStyle(color: kAccent, fontSize: 12, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
          Expanded(child: Text(c.alertRule, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600, height: 1.4))),
          SizedBox(width: 88, child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: widget.sevColor, borderRadius: BorderRadius.circular(14)), child: Text(c.severity, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)))),
          SizedBox(width: 120, child: Text(c.type, style: const TextStyle(color: Colors.white, fontSize: 11), overflow: TextOverflow.ellipsis)),
          SizedBox(width: 62, child: Container(width: 32, height: 32, decoration: BoxDecoration(color: isTP ? kCritical : kLow, shape: BoxShape.circle), child: Center(child: Text(c.status, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800))))),
          SizedBox(width: 100, child: Text(c.resolved, style: const TextStyle(color: kSubText, fontSize: 11))),
          SizedBox(width: 100, child: Row(children: [
            GestureDetector(onTap: widget.onView, child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(borderRadius: BorderRadius.circular(6), border: Border.all(color: kAccent.withOpacity(0.6))), child: const Text('View', style: TextStyle(color: kAccent, fontSize: 11, fontWeight: FontWeight.w600)))),
            const SizedBox(width: 8),
            GestureDetector(onTap: widget.onDownload, child: Container(padding: const EdgeInsets.all(5), decoration: BoxDecoration(color: kAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(6), border: Border.all(color: kAccent.withOpacity(0.4))), child: const Icon(Icons.download_outlined, color: kAccent, size: 16))),
          ])),
        ]),
      ),
    );
  }
}

class _CaseMobileCard extends StatelessWidget {
  final CaseReport caseReport; final Color sevColor; final VoidCallback onView, onDownload;
  const _CaseMobileCard({required this.caseReport, required this.sevColor, required this.onView, required this.onDownload});

  @override
  Widget build(BuildContext context) {
    final c = caseReport; final isTP = c.status == 'TP';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: kPageBg, borderRadius: BorderRadius.circular(10), border: Border.all(color: kCardBorder)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Flexible(child: Text(c.caseId, style: const TextStyle(color: kAccent, fontSize: 12, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
          Container(width: 32, height: 32, decoration: BoxDecoration(color: isTP ? kCritical : kLow, shape: BoxShape.circle), child: Center(child: Text(c.status, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)))),
        ]),
        const SizedBox(height: 8),
        Text(c.alertRule, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600, height: 1.4)),
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 6, children: [
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: sevColor, borderRadius: BorderRadius.circular(12)), child: Text(c.severity, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700))),
          Text(c.type,     style: const TextStyle(color: kSubText, fontSize: 12)),
          Text(c.resolved, style: const TextStyle(color: kSubText, fontSize: 12)),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: GestureDetector(onTap: onView, child: Container(
            padding: const EdgeInsets.symmetric(vertical: 9),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: kAccent.withOpacity(0.6))),
            child: const Center(child: Text('View', style: TextStyle(color: kAccent, fontSize: 12, fontWeight: FontWeight.w600)))))),
          const SizedBox(width: 10),
          GestureDetector(onTap: onDownload, child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(color: kAccent.withOpacity(0.12), borderRadius: BorderRadius.circular(8), border: Border.all(color: kAccent.withOpacity(0.5))),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.download_outlined, color: kAccent, size: 16), SizedBox(width: 5),
              Text('PDF', style: TextStyle(color: kAccent, fontSize: 12, fontWeight: FontWeight.w600)),
            ]))),
        ]),
      ]),
    );
  }
}

class _CaseDetailPage extends StatefulWidget {
  final CaseReport caseReport;
  const _CaseDetailPage({required this.caseReport});
  @override State<_CaseDetailPage> createState() => _CaseDetailPageState();
}

class _CaseDetailPageState extends State<_CaseDetailPage> {
  int _tab = 0;
  static const _tabs = [
    (Icons.show_chart,            'Overview'),
    (Icons.account_tree_outlined, 'Network'),
    (Icons.monitor_outlined,      'Endpoint'),
    (Icons.gps_fixed_outlined,    'Threat Intel'),
    (Icons.description_outlined,  'Investigation'),
  ];

  Widget _f(String l, String v, {Color? c}) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(l, style: const TextStyle(color: kSubText, fontSize: 11)),
    const SizedBox(height: 4),
    Text(v, style: TextStyle(color: c ?? Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
  ]);

  @override
  Widget build(BuildContext context) {
    final c          = widget.caseReport;
    final alertParts = c.alertRule.split(' - ');
    final alertName  = alertParts.isNotEmpty ? alertParts[0] : c.alertRule;
    final alertId    = (c.caseId.hashCode % 9000 + 1000).abs();
    final score      = c.severity == 'Critical' ? 0.93 : 0.72;
    final scoreLabel = c.severity == 'Critical' ? '93/100' : '72/100';
    final processName = alertName.contains('Keylogger')  ? 'keylog.exe'
        : alertName.contains('Ransomware') ? 'ransom.exe'
        : alertName.contains('Crypto')     ? 'miner.exe'
        : alertName.contains('DLL')        ? 'inject.dll'
        : alertName.contains('Malware')    ? 'malware.exe'
        : 'unknown.exe';
    final processId  = (c.caseId.hashCode % 9000 + 1000).abs();
    final logEntries = (c.caseId.hashCode % 40000 + 10000).abs();
    final relEvents  = (c.caseId.hashCode % 200 + 50).abs();
    final apiCalls   = (c.caseId.hashCode % 30 + 10).abs();
    final dataProc   = (c.caseId.hashCode % 400 + 100).abs();

    return Scaffold(
      backgroundColor: kPageBg,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(children: [
          Container(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: kCardBorder))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                GestureDetector(onTap: () => Navigator.pop(context), child: Container(width: 30, height: 30, decoration: BoxDecoration(color: kFieldBg, borderRadius: BorderRadius.circular(7), border: Border.all(color: kCardBorder)), child: const Icon(Icons.arrow_back_ios_new, color: kSubText, size: 13))),
                const SizedBox(width: 12),
                Expanded(child: Text('Case ${c.caseId}', style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis)),
              ]),
              const SizedBox(height: 12),
              Wrap(spacing: 20, runSpacing: 10, children: [
                _MetaChip(icon: Icons.person_outline,          label: 'Analyst',         value: 'Automated System'),
                _MetaChip(icon: Icons.schedule,                label: 'Time to Resolve', value: 'Immediate (5.234s)'),
                _MetaChip(icon: Icons.calendar_today_outlined, label: 'Resolution Date', value: c.resolved),
              ]),
              const SizedBox(height: 14),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(children: List.generate(_tabs.length, (i) {
                  final active = _tab == i;
                  return GestureDetector(
                    onTap: () => setState(() => _tab = i),
                    child: Container(
                      margin: const EdgeInsets.only(right: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(color: active ? kAccent : Colors.transparent, borderRadius: const BorderRadius.vertical(top: Radius.circular(8)), border: Border.all(color: active ? kAccent : kCardBorder)),
                      child: Row(children: [
                        Icon(_tabs[i].$1, size: 13, color: active ? Colors.black : kSubText), const SizedBox(width: 5),
                        Text(_tabs[i].$2, style: TextStyle(color: active ? Colors.black : kSubText, fontSize: 12, fontWeight: active ? FontWeight.w700 : FontWeight.w400)),
                      ]),
                    ),
                  );
                })),
              ),
            ]),
          ),

          Expanded(child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(14, 18, 14, 0),
            child: _tab == 0 ? _buildOverview(c, alertId, alertName, score, scoreLabel)
                : _tab == 1 ? _buildNetwork()
                : _tab == 2 ? _buildEndpoint(processName, processId)
                : _tab == 3 ? _buildThreatIntel(score)
                : _buildInvestigation(c, alertParts, logEntries, relEvents, apiCalls, dataProc),
          )),

          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 16),
            child: Builder(builder: (ctx) => GestureDetector(
              onTap: () => _saveReport(ctx, c),
              child: Container(
                width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 15),
                decoration: BoxDecoration(color: kAccent, borderRadius: BorderRadius.circular(10)),
                child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.download_outlined, color: Colors.black, size: 19), SizedBox(width: 8),
                  Text('Download Full Report', style: TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.bold)),
                ]),
              ),
            )),
          ),
        ]),
      ),
    );
  }

  Widget _buildOverview(CaseReport c, int alertId, String alertName, double score, String scoreLabel) {
    return LayoutBuilder(builder: (context, constraints) {
      final isWide = constraints.maxWidth >= 400;
      final col1 = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_f('Case ID', c.caseId), const SizedBox(height: 16), _f('Alert Name', alertName)]);
      final col2 = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_f('Alert ID', '$alertId'), const SizedBox(height: 16), _f('Timestamp', '2025-11-11 14:22:38')]);
      final col3 = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _f('Type', c.type), const SizedBox(height: 16),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: const [Icon(Icons.warning_amber_rounded, color: kCritical, size: 13), SizedBox(width: 5), Text('Threat Score', style: TextStyle(color: kSubText, fontSize: 11))]),
          const SizedBox(height: 6),
          Row(children: [Text(scoreLabel, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)), const SizedBox(width: 10), Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: score, backgroundColor: kCardBorder, color: kCritical, minHeight: 7)))]),
        ]),
      ]);
      if (isWide) return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: col1), Expanded(child: col2), Expanded(child: col3)]), const SizedBox(height: 20), _buildNotes(c), const SizedBox(height: 20)]);
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [col1, const SizedBox(height: 16), col2, const SizedBox(height: 16), col3, const SizedBox(height: 20), _buildNotes(c), const SizedBox(height: 20)]);
    });
  }

  Widget _buildNotes(CaseReport c) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const Text('Initial Notes', style: TextStyle(color: kSubText, fontSize: 12)), const SizedBox(height: 8),
    Container(width: double.infinity, padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: kCardBg, borderRadius: BorderRadius.circular(8), border: Border.all(color: kCardBorder)),
      child: Text('Automated action executed in response to ${c.severity} alert. Alert Rule: ${c.alertRule}. Status: Success.', style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.5))),
  ]);

  Widget _buildNetwork() {
    return LayoutBuilder(builder: (context, constraints) {
      final isWide = constraints.maxWidth >= 380;
      final src = Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: kCardBg, borderRadius: BorderRadius.circular(10), border: Border.all(color: kCardBorder)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Container(width: 8, height: 8, decoration: const BoxDecoration(color: kLow, shape: BoxShape.circle)), const SizedBox(width: 6), const Text('Source', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold))]), const SizedBox(height: 14), _f('IP Address', '192.168.18.72'), const SizedBox(height: 12), _f('MAC Address', '00:1B:44:11:3A:F5')]));
      final dst = Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: kCardBg, borderRadius: BorderRadius.circular(10), border: Border.all(color: kCritical.withOpacity(0.4))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Container(width: 8, height: 8, decoration: const BoxDecoration(color: kCritical, shape: BoxShape.circle)), const SizedBox(width: 6), const Text('Destination', style: TextStyle(color: kCritical, fontSize: 14, fontWeight: FontWeight.bold))]), const SizedBox(height: 14), _f('IP Address', '-')]));
      return Column(children: [isWide ? Row(children: [Expanded(child: src), const SizedBox(width: 16), Expanded(child: dst)]) : Column(children: [src, const SizedBox(height: 12), dst]), const SizedBox(height: 20)]);
    });
  }

  Widget _buildEndpoint(String processName, int processId) {
    return LayoutBuilder(builder: (context, constraints) {
      final isWide = constraints.maxWidth >= 380;
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        isWide ? Row(children: [Expanded(child: _f('Hostname', 'WS-EXEC-08')), const SizedBox(width: 40), Expanded(child: _f('Process Name', processName, c: kAccent))]) : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_f('Hostname', 'WS-EXEC-08'), const SizedBox(height: 16), _f('Process Name', processName, c: kAccent)]),
        const SizedBox(height: 20), _f('Process ID', '$processId'), const SizedBox(height: 20),
      ]);
    });
  }

  Widget _buildThreatIntel(double score) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Threat Score', style: TextStyle(color: kAccent, fontSize: 16, fontWeight: FontWeight.bold)), const SizedBox(height: 16),
      Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        RichText(text: TextSpan(children: [TextSpan(text: score >= 0.9 ? '93' : '72', style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold)), const TextSpan(text: ' / 100', style: TextStyle(color: kSubText, fontSize: 16))])),
        const SizedBox(width: 20),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ClipRRect(borderRadius: BorderRadius.circular(6), child: LinearProgressIndicator(value: score, backgroundColor: kCardBorder, color: kCritical, minHeight: 14)),
          const SizedBox(height: 6),
          Text(score >= 0.9 ? 'Critical Threat — Immediate action required' : 'High Threat — Investigate promptly', style: const TextStyle(color: kCritical, fontSize: 11)),
        ])),
      ]),
      const SizedBox(height: 20),
    ]);
  }

  Widget _buildInvestigation(CaseReport c, List<String> alertParts, int logEntries, int relEvents, int apiCalls, int dataProc) {
    final actionType = alertParts.length > 1 ? alertParts[1] : c.type;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Actions Taken', style: TextStyle(color: kAccent, fontSize: 15, fontWeight: FontWeight.bold)), const SizedBox(height: 12),
      ...['Automated action triggered: $actionType', 'Execution initiated at ${c.resolved} 05:06:45', 'Log Collection   - completed (1.234s)', 'Pattern Matching - completed (2.341s)', 'Timeline Creation - completed (0.892s)', 'Report Generation - completed (0.767s)']
          .map((s) => Padding(padding: const EdgeInsets.only(bottom: 9), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [const Icon(Icons.check_circle_outline, color: kLow, size: 14), const SizedBox(width: 8), Expanded(child: Text(s, style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4)))]))),
      const SizedBox(height: 20),
      const Text('Investigation Findings', style: TextStyle(color: kAccent, fontSize: 15, fontWeight: FontWeight.bold)), const SizedBox(height: 10),
      Container(width: double.infinity, padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: kCardBg, borderRadius: BorderRadius.circular(8), border: Border.all(color: kCardBorder)),
        child: Text('Automated Security Response executed for ${c.severity} severity alert. Alert: ${alertParts.isNotEmpty ? alertParts[0] : c.alertRule}. Action Type: $actionType (${c.type}). Status: ${c.status == "TP" ? "True Positive" : "False Positive"}. Duration: 5.234s. Log Entries: $logEntries. Related Events: $relEvents. API Calls: $apiCalls. Data Processed: $dataProc MB.', style: const TextStyle(color: Colors.white, fontSize: 12, height: 1.6))),
      const SizedBox(height: 20),
      Row(children: const [Icon(Icons.description_outlined, color: kAccent, size: 14), SizedBox(width: 6), Text('Recommendations', style: TextStyle(color: kAccent, fontSize: 15, fontWeight: FontWeight.bold))]),
      const SizedBox(height: 10),
      const Text('Automated response completed successfully. Continue monitoring affected assets closely. Schedule immediate incident review. Consider implementing additional preventive controls.', style: TextStyle(color: Colors.white, fontSize: 13, height: 1.6)),
      const SizedBox(height: 20),
    ]);
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon; final String label, value;
  const _MetaChip({required this.icon, required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
    Icon(icon, color: kAccent, size: 13), const SizedBox(width: 5),
    Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
      Text(label, style: const TextStyle(color: kSubText, fontSize: 10)),
      Text(value,  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
    ]),
  ]);
}