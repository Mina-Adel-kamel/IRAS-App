import 'package:flutter/material.dart';
import 'api_service.dart';

const Color kAccent     = Color(0xFFCAF135);
const Color kFieldBg    = Color(0xFF0D1A30);
const Color kCardBg     = Color(0xFF070F1E);
const Color kPageBg     = Color(0xFF030810);
const Color kCardBorder = Color(0xFF0F1E35);
const Color kSubText    = Color(0xFF5C7A99);
const Color kBodyText   = Colors.white;
const Color kCritical   = Color(0xFFE53E3E);
const Color kHigh       = Color(0xFFED8936);
const Color kMedium     = Color(0xFF4299E1);
const Color kLow        = Color(0xFF48BB78);

class AlertQueueScreen extends StatefulWidget {
  const AlertQueueScreen({super.key});
  @override
  State<AlertQueueScreen> createState() => _AlertQueueScreenState();
}

class _AlertQueueScreenState extends State<AlertQueueScreen> {
  final _alertService = AlertQueueService();

  String _severityFilter = 'All';
  String _typeFilter     = 'All';
  String _searchQuery    = '';
  int    _currentPage    = 1;
  int    _perPage        = 5;

  final _searchCtrl = TextEditingController();
  final Set<String> _assignedIds = {};

  List<AlertItem> _allAlerts = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() { super.initState(); _loadAlerts(); }

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  Future<void> _loadAlerts() async {
    setState(() { _loading = true; _error = null; });
    try {
      final alerts = await _alertService.getAlerts(severity: _severityFilter, type: _typeFilter, search: _searchQuery);
      setState(() { _allAlerts = alerts; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  List<AlertItem> get _filtered => _allAlerts.where((a) {
    final sevOk  = _severityFilter == 'All' || a.severity == _severityFilter;
    final typeOk = _typeFilter     == 'All' || a.type     == _typeFilter;
    final srchOk = _searchQuery.isEmpty || a.rule.toLowerCase().contains(_searchQuery.toLowerCase()) || a.id.toLowerCase().contains(_searchQuery.toLowerCase());
    return sevOk && typeOk && srchOk;
  }).toList();

  int get _totalPages => ((_filtered.length) / _perPage).ceil().clamp(1, 999);

  List<AlertItem> get _paginated {
    final f = _filtered;
    final s = (_currentPage - 1) * _perPage;
    final e = (s + _perPage).clamp(0, f.length);
    if (s >= f.length) return [];
    return f.sublist(s, e);
  }

  void _goPage(int p) {
    if (p < 1 || p > _totalPages) return;
    setState(() => _currentPage = p);
  }

  Color _sevColor(String s) {
    switch (s) {
      case 'Critical': return kCritical;
      case 'High':     return kHigh;
      case 'Medium':   return kMedium;
      default:         return kLow;
    }
  }

  void _showAssignDialog(BuildContext ctx, AlertItem a) {
    showDialog(
      context: ctx,
      barrierColor: Colors.black.withOpacity(0.55),
      builder: (_) => _AssignDialog(
        alert: a,
        onAssign: () async {
          try { await _alertService.assignAlert(a.id); } catch (_) {}
          setState(() => _assignedIds.add(a.id));
        },
      ),
    );
  }

  void _showViewDialog(BuildContext ctx, AlertItem a) {
    showDialog(
      context: ctx,
      barrierColor: Colors.black.withOpacity(0.55),
      builder: (_) => _ViewDialog(alert: a, sevColor: _sevColor(a.severity)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: kAccent));
    if (_error != null) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.error_outline, color: kCritical, size: 40),
        const SizedBox(height: 12),
        const Text('Failed to load alerts', style: TextStyle(color: kBodyText, fontSize: 16)),
        const SizedBox(height: 8),
        TextButton(onPressed: _loadAlerts, child: const Text('Retry', style: TextStyle(color: kAccent))),
      ]));
    }

    final isWide     = MediaQuery.of(context).size.width >= 700;
    final hPad       = isWide ? 28.0 : 14.0;
    final rows       = _paginated;
    final totalPages = _totalPages;
    final filtered   = _filtered;

    return Scaffold(
      backgroundColor: kPageBg,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(hPad, hPad, hPad, 12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            const Text('Alert queue', style: TextStyle(color: kBodyText, fontSize: 22, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            const Text('Monitor and manage incoming security alerts.', style: TextStyle(color: kSubText, fontSize: 12)),
            const SizedBox(height: 14),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              decoration: BoxDecoration(color: kCardBg, borderRadius: BorderRadius.circular(10), border: Border.all(color: kCardBorder)),
              child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Assigned alert', style: TextStyle(color: kBodyText, fontSize: 13, fontWeight: FontWeight.w600)),
                SizedBox(height: 4),
                Text("You haven't picked up any alert! Assign yourself to an alert to start investigating.", style: TextStyle(color: kSubText, fontSize: 12, height: 1.5)),
              ]),
            ),
            const SizedBox(height: 12),

            _buildFilters(isWide),
            const SizedBox(height: 10),

            Expanded(child: Container(
              decoration: BoxDecoration(color: kCardBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: kCardBorder)),
              child: Column(children: [

                if (isWide)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: kCardBorder))),
                    child: const Row(children: [
                      SizedBox(width: 76,  child: Text('ID',        style: _hS)),
                      Expanded(            child: Text('Alert rule', style: _hS)),
                      SizedBox(width: 95,  child: Text('Severity',  style: _hS)),
                      SizedBox(width: 125, child: Text('Type',      style: _hS)),
                      SizedBox(width: 100, child: Text('Date',      style: _hS)),
                      SizedBox(width: 130, child: Text('Status',    style: _hS)),
                      SizedBox(width: 145, child: Text('Action',    style: _hS)),
                    ]),
                  )
                else
                  const Padding(
                    padding: EdgeInsets.fromLTRB(14, 12, 14, 8),
                    child: Align(alignment: Alignment.centerLeft, child: Text('Alerts', style: TextStyle(color: kBodyText, fontSize: 13, fontWeight: FontWeight.w600))),
                  ),

                if (!isWide) const Divider(color: kCardBorder, height: 1),

                Expanded(child: rows.isEmpty
                    ? const Center(child: Text('No alerts found', style: TextStyle(color: kSubText, fontSize: 14)))
                    : isWide
                        ? ListView.separated(
                            padding: EdgeInsets.zero,
                            itemCount: rows.length,
                            separatorBuilder: (_, __) => const Divider(color: kCardBorder, height: 1),
                            itemBuilder: (ctx, i) {
                              final a = rows[i];
                              return _AlertRow(
                                alert: a, sevColor: _sevColor(a.severity),
                                assigned: _assignedIds.contains(a.id),
                                onAssign: () => _showAssignDialog(ctx, a),
                                onView:   () => _showViewDialog(ctx, a),
                              );
                            },
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(10),
                            itemCount: rows.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (ctx, i) {
                              final a = rows[i];
                              return _AlertMobileCard(
                                alert: a, sevColor: _sevColor(a.severity),
                                assigned: _assignedIds.contains(a.id),
                                onAssign: () => _showAssignDialog(ctx, a),
                                onView:   () => _showViewDialog(ctx, a),
                              );
                            },
                          )),

                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: const BoxDecoration(border: Border(top: BorderSide(color: kCardBorder))),
                  child: Column(children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text('${filtered.length} total', style: const TextStyle(color: kSubText, fontSize: 11)),
                      Row(children: [
                        const Text('Show: ', style: TextStyle(color: kSubText, fontSize: 11)),
                        _ShowDropdown(value: _perPage, onChanged: (v) => setState(() { _perPage = v; _currentPage = 1; })),
                      ]),
                    ]),
                    const SizedBox(height: 8),
                    SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [
                      _PagBtn(label: 'Prev', icon: Icons.chevron_left, enabled: _currentPage > 1, onTap: () => _goPage(_currentPage - 1)),
                      const SizedBox(width: 8),
                      ...List.generate(totalPages > 7 ? 7 : totalPages, (i) {
                        final pg     = i + 1;
                        final active = pg == _currentPage;
                        return GestureDetector(
                          onTap: () => _goPage(pg),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            width: 28, height: 28,
                            decoration: BoxDecoration(
                              color: active ? kAccent : Colors.transparent,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: active ? kAccent : kCardBorder),
                            ),
                            child: Center(child: Text('$pg', style: TextStyle(color: active ? Colors.black : kSubText, fontSize: 12, fontWeight: active ? FontWeight.w700 : FontWeight.w400))),
                          ),
                        );
                      }),
                      const SizedBox(width: 8),
                      _PagBtn(label: 'Next', icon: Icons.chevron_right, enabled: _currentPage < totalPages, onTap: () => _goPage(_currentPage + 1), iconAfter: true),
                    ])),
                  ]),
                ),
              ]),
            )),
          ]),
        ),
      ),
    );
  }

  Widget _buildFilters(bool isWide) {
    final search = Container(
      height: 36,
      decoration: BoxDecoration(color: kCardBg, borderRadius: BorderRadius.circular(8), border: Border.all(color: kCardBorder)),
      child: Row(children: [
        const SizedBox(width: 10),
        const Icon(Icons.search, color: kSubText, size: 14),
        const SizedBox(width: 7),
        Expanded(child: TextField(
          controller: _searchCtrl,
          style: const TextStyle(color: kBodyText, fontSize: 12),
          decoration: const InputDecoration(hintText: 'Search for an alert', hintStyle: TextStyle(color: kSubText, fontSize: 12), border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero),
          onChanged: (v) => setState(() { _searchQuery = v; _currentPage = 1; }),
        )),
      ]),
    );

    final sevDrop  = _DropFilter(prefix: 'Severity', value: _severityFilter, options: const ['All', 'Critical', 'High', 'Medium', 'Low'], onChanged: (v) => setState(() { _severityFilter = v; _currentPage = 1; }));
    final typeDrop = _DropFilter(prefix: 'Type', value: _typeFilter, options: const ['All', 'Endpoint', 'Network', 'Malware', 'Phishing', 'Firewall', 'Web Application', 'Data Exfiltration'], onChanged: (v) => setState(() { _typeFilter = v; _currentPage = 1; }));

    if (isWide) {
      return Row(children: [Expanded(child: search), const SizedBox(width: 10), sevDrop, const SizedBox(width: 10), typeDrop]);
    }
    return Column(children: [
      search,
      const SizedBox(height: 8),
      Row(children: [
        Expanded(child: sevDrop),
        const SizedBox(width: 8),
        Expanded(child: typeDrop),
      ]),
    ]);
  }
}

const _hS = TextStyle(color: kSubText, fontSize: 12, fontWeight: FontWeight.w700);

// ══════════════════════════════════════════════════════════════
//  ALERT ROW (Wide)
// ══════════════════════════════════════════════════════════════
class _AlertRow extends StatefulWidget {
  final AlertItem alert; final Color sevColor; final bool assigned; final VoidCallback onAssign, onView;
  const _AlertRow({required this.alert, required this.sevColor, required this.assigned, required this.onAssign, required this.onView});
  @override
  State<_AlertRow> createState() => _AlertRowState();
}

class _AlertRowState extends State<_AlertRow> {
  bool _hovered = false;

  Widget _statusWidget() {
    final s = widget.alert.status;
    if (s == 'Open') {
      return Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Row(mainAxisSize: MainAxisSize.min, children: [Container(width: 6, height: 6, decoration: const BoxDecoration(color: kLow, shape: BoxShape.circle)), const SizedBox(width: 5), const Text('Open', style: TextStyle(color: kBodyText, fontSize: 12, fontWeight: FontWeight.w600))]),
        if (widget.assigned) const Text('• analyst', style: TextStyle(color: kAccent, fontSize: 11, fontWeight: FontWeight.w600)),
      ]);
    }
    final name = s.replaceFirst('Closed • ', '');
    return Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
      const Text('Closed', style: TextStyle(color: kSubText, fontSize: 11)),
      Text('• $name', style: const TextStyle(color: kAccent, fontSize: 11, fontWeight: FontWeight.w600)),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.alert;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        color: _hovered ? kFieldBg.withOpacity(0.35) : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          SizedBox(width: 76,  child: Text(a.id, style: const TextStyle(color: kSubText, fontSize: 11), overflow: TextOverflow.ellipsis, maxLines: 2)),
          Expanded(child: Text(a.rule, style: const TextStyle(color: kBodyText, fontSize: 13, fontWeight: FontWeight.w600))),
          SizedBox(width: 95, child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(color: widget.sevColor.withOpacity(0.15), borderRadius: BorderRadius.circular(6), border: Border.all(color: widget.sevColor.withOpacity(0.45))),
            child: Text(a.severity, textAlign: TextAlign.center, style: TextStyle(color: widget.sevColor, fontSize: 11, fontWeight: FontWeight.w700)),
          )),
          SizedBox(width: 125, child: Text(a.type, style: const TextStyle(color: kSubText, fontSize: 12), overflow: TextOverflow.ellipsis)),
          SizedBox(width: 100, child: Text(a.date, style: const TextStyle(color: kSubText, fontSize: 12))),
          SizedBox(width: 130, child: _statusWidget()),
          SizedBox(width: 145, child: Row(children: [
            GestureDetector(
              onTap: widget.onAssign,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: widget.assigned ? kAccent.withOpacity(0.25) : kAccent,
                  borderRadius: BorderRadius.circular(8),
                  border: widget.assigned ? Border.all(color: kAccent) : null,
                ),
                child: Text(widget.assigned ? 'Assigned' : 'Assign', style: TextStyle(color: widget.assigned ? kAccent : Colors.black, fontSize: 12, fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: widget.onView,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(color: Colors.transparent, borderRadius: BorderRadius.circular(8), border: Border.all(color: kCardBorder)),
                child: const Text('View', style: TextStyle(color: kBodyText, fontSize: 12, fontWeight: FontWeight.w500)),
              ),
            ),
          ])),
        ]),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  ALERT MOBILE CARD
// ══════════════════════════════════════════════════════════════
class _AlertMobileCard extends StatelessWidget {
  final AlertItem alert; final Color sevColor; final bool assigned; final VoidCallback onAssign, onView;
  const _AlertMobileCard({required this.alert, required this.sevColor, required this.assigned, required this.onAssign, required this.onView});

  @override
  Widget build(BuildContext context) {
    final a = alert;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: kPageBg, borderRadius: BorderRadius.circular(10), border: Border.all(color: kCardBorder)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(a.id, style: const TextStyle(color: kSubText, fontSize: 11)),
          Text(a.date, style: const TextStyle(color: kSubText, fontSize: 11)),
        ]),
        const SizedBox(height: 8),
        Text(a.rule, style: const TextStyle(color: kBodyText, fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        if (a.hostname.isNotEmpty || a.processName.isNotEmpty) ...[
          Wrap(spacing: 8, runSpacing: 6, children: [
            if (a.hostname.isNotEmpty)    _InfoPill(label: 'Host',    value: a.hostname),
            if (a.processName.isNotEmpty) _InfoPill(label: 'Process', value: a.processName, valueColor: kAccent),
          ]),
          const SizedBox(height: 10),
        ],
        Wrap(spacing: 8, runSpacing: 6, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: sevColor.withOpacity(0.15), borderRadius: BorderRadius.circular(6), border: Border.all(color: sevColor.withOpacity(0.45))),
            child: Text(a.severity, style: TextStyle(color: sevColor, fontSize: 11, fontWeight: FontWeight.w700)),
          ),
          Text(a.type, style: const TextStyle(color: kSubText, fontSize: 12)),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: GestureDetector(
            onTap: onAssign,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 9),
              decoration: BoxDecoration(
                color: assigned ? kAccent.withOpacity(0.25) : kAccent,
                borderRadius: BorderRadius.circular(8),
                border: assigned ? Border.all(color: kAccent) : null,
              ),
              child: Center(child: Text(assigned ? 'Assigned' : 'Assign', style: TextStyle(color: assigned ? kAccent : Colors.black, fontSize: 12, fontWeight: FontWeight.w700))),
            ),
          )),
          const SizedBox(width: 10),
          Expanded(child: GestureDetector(
            onTap: onView,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 9),
              decoration: BoxDecoration(color: Colors.transparent, borderRadius: BorderRadius.circular(8), border: Border.all(color: kCardBorder)),
              child: const Center(child: Text('View', style: TextStyle(color: kBodyText, fontSize: 12, fontWeight: FontWeight.w500))),
            ),
          )),
        ]),
      ]),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final String label, value;
  final Color? valueColor;
  const _InfoPill({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(maxWidth: 200),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(color: kFieldBg, borderRadius: BorderRadius.circular(8), border: Border.all(color: kCardBorder)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
      Text(label, style: const TextStyle(color: kSubText, fontSize: 10)),
      const SizedBox(height: 2),
      Text(value, style: TextStyle(color: valueColor ?? kBodyText, fontSize: 12, fontWeight: FontWeight.w600, fontFamily: valueColor != null ? 'monospace' : null), overflow: TextOverflow.ellipsis),
    ]),
  );
}

// ══════════════════════════════════════════════════════════════
//  VIEW DIALOG
// ══════════════════════════════════════════════════════════════
class _ViewDialog extends StatefulWidget {
  final AlertItem alert; final Color sevColor;
  const _ViewDialog({required this.alert, required this.sevColor});
  @override
  State<_ViewDialog> createState() => _ViewDialogState();
}

class _ViewDialogState extends State<_ViewDialog> {
  int _tab = 0;
  static const _tabs = [
    _TabDef(icon: Icons.bar_chart_rounded,     label: 'Overview'),
    _TabDef(icon: Icons.account_tree_outlined, label: 'Network'),
    _TabDef(icon: Icons.monitor_outlined,      label: 'Endpoint'),
    _TabDef(icon: Icons.gps_fixed_outlined,    label: 'Threat Intel'),
  ];

  @override
  Widget build(BuildContext context) {
    final a       = widget.alert;
    final screenW = MediaQuery.of(context).size.width;
    final hPad    = screenW < 500 ? 10.0 : 60.0;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: hPad, vertical: 30),
      child: Container(
        constraints: BoxConstraints(maxWidth: 780, maxHeight: MediaQuery.of(context).size.height * 0.88),
        decoration: BoxDecoration(color: kCardBg, borderRadius: BorderRadius.circular(14), border: Border.all(color: kCardBorder), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 40)]),
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 14, 0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Flexible(child: Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 8, runSpacing: 6, children: [
                  Text('Alert #${a.id}', style: const TextStyle(color: kBodyText, fontSize: 16, fontWeight: FontWeight.w800)),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: widget.sevColor.withOpacity(0.2), borderRadius: BorderRadius.circular(6), border: Border.all(color: widget.sevColor.withOpacity(0.5))), child: Text(a.severity, style: TextStyle(color: widget.sevColor, fontSize: 12, fontWeight: FontWeight.w700))),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: kCritical.withOpacity(0.15), borderRadius: BorderRadius.circular(6), border: Border.all(color: kCritical.withOpacity(0.5))), child: const Text('Malicious', style: TextStyle(color: kCritical, fontSize: 12, fontWeight: FontWeight.w700))),
                ])),
                const SizedBox(width: 8),
                GestureDetector(onTap: () => Navigator.pop(context), child: Container(width: 28, height: 28, decoration: BoxDecoration(color: kFieldBg, borderRadius: BorderRadius.circular(6), border: Border.all(color: kCardBorder)), child: const Icon(Icons.close, color: kSubText, size: 15))),
              ]),
              const SizedBox(height: 6),
              Text(a.rule,        style: const TextStyle(color: kBodyText, fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(a.description, style: const TextStyle(color: kSubText, fontSize: 12, height: 1.4)),
              const SizedBox(height: 12),
              SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(
                children: List.generate(_tabs.length, (i) {
                  final active = _tab == i;
                  return GestureDetector(
                    onTap: () => setState(() => _tab = i),
                    child: Container(
                      margin: const EdgeInsets.only(right: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(color: active ? kAccent.withOpacity(0.15) : Colors.transparent, borderRadius: BorderRadius.circular(8), border: Border.all(color: active ? kAccent.withOpacity(0.5) : Colors.transparent)),
                      child: Row(children: [Icon(_tabs[i].icon, size: 13, color: active ? kAccent : kSubText), const SizedBox(width: 5), Text(_tabs[i].label, style: TextStyle(color: active ? kAccent : kSubText, fontSize: 12, fontWeight: active ? FontWeight.w600 : FontWeight.w400))]),
                    ),
                  );
                }),
              )),
            ]),
          ),
          const Divider(color: kCardBorder, height: 1),
          Expanded(child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
            child: _tab == 0 ? _OverviewTab(a: a)
                : _tab == 1 ? _NetworkTab(a: a)
                : _tab == 2 ? _EndpointTab(a: a)
                : _ThreatIntelTab(a: a),
          )),
        ]),
      ),
    );
  }
}

class _TabDef {
  final IconData icon; final String label;
  const _TabDef({required this.icon, required this.label});
}

class _InfoField extends StatelessWidget {
  final String label, value; final Color? valueColor;
  const _InfoField({required this.label, required this.value, this.valueColor});
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label, style: const TextStyle(color: kSubText, fontSize: 11)),
    const SizedBox(height: 4),
    Text(value, style: TextStyle(color: valueColor ?? kBodyText, fontSize: 14, fontWeight: FontWeight.w600)),
  ]);
}

class _OverviewTab extends StatelessWidget {
  final AlertItem a;
  const _OverviewTab({required this.a});
  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 400;
    final col1 = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_InfoField(label: 'Alert ID', value: a.id), const SizedBox(height: 14), _InfoField(label: 'Status', value: 'Open', valueColor: kLow), const SizedBox(height: 14), _InfoField(label: 'Last Seen', value: a.lastSeen)]);
    final col2 = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_InfoField(label: 'Type', value: a.type), const SizedBox(height: 14), _InfoField(label: 'Timestamp', value: a.timestamp), const SizedBox(height: 14), _InfoField(label: 'Event Count', value: '${a.eventCount}')]);
    final col3 = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _InfoField(label: 'Date', value: a.date), const SizedBox(height: 14),
      _InfoField(label: 'First Seen', value: a.firstSeen), const SizedBox(height: 14),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Threat Score', style: TextStyle(color: kSubText, fontSize: 11)),
        const SizedBox(height: 6),
        Row(children: [Text('${a.threatScore}/100', style: const TextStyle(color: kBodyText, fontSize: 13, fontWeight: FontWeight.w600)), const SizedBox(width: 8), Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: a.threatScore / 100, backgroundColor: kCardBorder, color: a.threatScore >= 80 ? kCritical : a.threatScore >= 60 ? kHigh : kMedium, minHeight: 6)))]),
      ]),
    ]);
    if (isWide) return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: col1), Expanded(child: col2), Expanded(child: col3)]);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [col1, const SizedBox(height: 14), col2, const SizedBox(height: 14), col3]);
  }
}

class _NetworkTab extends StatelessWidget {
  final AlertItem a;
  const _NetworkTab({required this.a});
  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 380;
    final src = Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: kPageBg, borderRadius: BorderRadius.circular(10), border: Border.all(color: kCardBorder)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Container(width: 8, height: 8, decoration: const BoxDecoration(color: kLow, shape: BoxShape.circle)), const SizedBox(width: 6), const Text('Source', style: TextStyle(color: kBodyText, fontSize: 14, fontWeight: FontWeight.w600))]), const SizedBox(height: 12), const Text('IP Address', style: TextStyle(color: kSubText, fontSize: 11)), const SizedBox(height: 4), Text(a.srcIp, style: const TextStyle(color: kBodyText, fontSize: 15, fontWeight: FontWeight.w700))]));
    final dst = Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: kPageBg, borderRadius: BorderRadius.circular(10), border: Border.all(color: kCritical.withOpacity(0.4))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Container(width: 8, height: 8, decoration: const BoxDecoration(color: kCritical, shape: BoxShape.circle)), const SizedBox(width: 6), const Text('Destination', style: TextStyle(color: kCritical, fontSize: 14, fontWeight: FontWeight.w600))]), const SizedBox(height: 12), const Text('IP Address', style: TextStyle(color: kSubText, fontSize: 11)), const SizedBox(height: 4), Text(a.dstIp, style: const TextStyle(color: kBodyText, fontSize: 15, fontWeight: FontWeight.w700))]));
    return isWide ? Row(children: [Expanded(child: src), const SizedBox(width: 14), Expanded(child: dst)]) : Column(children: [src, const SizedBox(height: 12), dst]);
  }
}

class _EndpointTab extends StatelessWidget {
  final AlertItem a;
  const _EndpointTab({required this.a});
  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 380;

    Widget hostnameBox = Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: kPageBg, borderRadius: BorderRadius.circular(10), border: Border.all(color: kCardBorder)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: const [Icon(Icons.computer, color: kSubText, size: 14), SizedBox(width: 6), Text('Hostname', style: TextStyle(color: kSubText, fontSize: 11, fontWeight: FontWeight.w600))]),
        const SizedBox(height: 8),
        Text(a.hostname.isEmpty ? '—' : a.hostname, style: const TextStyle(color: kBodyText, fontSize: 15, fontWeight: FontWeight.w700)),
      ]),
    );

    Widget processBox = Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: kPageBg, borderRadius: BorderRadius.circular(10), border: Border.all(color: kAccent.withOpacity(0.3))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: const [Icon(Icons.terminal, color: kAccent, size: 14), SizedBox(width: 6), Text('Process Name', style: TextStyle(color: kSubText, fontSize: 11, fontWeight: FontWeight.w600))]),
        const SizedBox(height: 8),
        Text(a.processName.isEmpty ? '—' : a.processName, style: const TextStyle(color: kAccent, fontSize: 15, fontWeight: FontWeight.w700, fontFamily: 'monospace')),
      ]),
    );

    return isWide
        ? Row(children: [Expanded(child: hostnameBox), const SizedBox(width: 14), Expanded(child: processBox)])
        : Column(children: [hostnameBox, const SizedBox(height: 12), processBox]);
  }
}

class _ThreatIntelTab extends StatelessWidget {
  final AlertItem a;
  const _ThreatIntelTab({required this.a});
  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Threat Score', style: TextStyle(color: kAccent, fontSize: 14, fontWeight: FontWeight.w700)),
      const SizedBox(height: 14),
      Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        RichText(text: TextSpan(children: [TextSpan(text: '${a.threatScore}', style: const TextStyle(color: kBodyText, fontSize: 44, fontWeight: FontWeight.w800)), const TextSpan(text: ' / 100', style: TextStyle(color: kSubText, fontSize: 16))])),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ClipRRect(borderRadius: BorderRadius.circular(6), child: LinearProgressIndicator(value: a.threatScore / 100, backgroundColor: kCardBorder, color: a.threatScore >= 80 ? kCritical : a.threatScore >= 60 ? kHigh : kMedium, minHeight: 12)),
          const SizedBox(height: 6),
          Text(a.threatScore >= 90 ? 'Critical Threat — Immediate action required' : a.threatScore >= 70 ? 'High Threat — Investigate promptly' : 'Moderate Threat — Monitor closely', style: TextStyle(color: a.threatScore >= 80 ? kCritical : kHigh, fontSize: 11)),
        ])),
      ]),
    ]);
  }
}

// ── Assign Dialog ─────────────────────────────────────────────
class _AssignDialog extends StatelessWidget {
  final AlertItem alert; final VoidCallback onAssign;
  const _AssignDialog({required this.alert, required this.onAssign});
  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    final hPad    = screenW < 500 ? 14.0 : 60.0;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: hPad, vertical: 40),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(color: kCardBg, borderRadius: BorderRadius.circular(14), border: Border.all(color: kCardBorder), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 30)]),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(width: 36, height: 36, decoration: BoxDecoration(color: kAccent.withOpacity(0.15), borderRadius: BorderRadius.circular(8), border: Border.all(color: kAccent.withOpacity(0.5))), child: const Icon(Icons.person_add_outlined, color: kAccent, size: 18)),
            const SizedBox(width: 12),
            const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Assign Alert', style: TextStyle(color: kBodyText, fontSize: 15, fontWeight: FontWeight.w700)),
              SizedBox(height: 2),
              Text('Assign this alert to yourself to start investigating.', style: TextStyle(color: kSubText, fontSize: 11)),
            ])),
            GestureDetector(onTap: () => Navigator.pop(context), child: const Icon(Icons.close, color: kSubText, size: 18)),
          ]),
          const SizedBox(height: 14),
          const Divider(color: kCardBorder),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: kPageBg, borderRadius: BorderRadius.circular(8), border: Border.all(color: kCardBorder)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(alert.rule, style: const TextStyle(color: kBodyText, fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Wrap(spacing: 8, runSpacing: 6, children: [
                _MiniChip(label: alert.severity, color: alert.severity == 'Critical' ? kCritical : alert.severity == 'High' ? kHigh : alert.severity == 'Medium' ? kMedium : kLow),
                const _MiniChip(label: 'Malicious', color: kCritical),
              ]),
              const SizedBox(height: 8),
              Row(children: [const Text('ID: ', style: TextStyle(color: kSubText, fontSize: 11)), Text(alert.id, style: const TextStyle(color: kBodyText, fontSize: 11))]),
            ]),
          ),
          const SizedBox(height: 12),
          const Text('Assign to', style: TextStyle(color: kSubText, fontSize: 12)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(color: kFieldBg, borderRadius: BorderRadius.circular(8), border: Border.all(color: kAccent.withOpacity(0.5))),
            child: Row(children: [
              Container(width: 26, height: 26, decoration: BoxDecoration(color: kAccent.withOpacity(0.2), shape: BoxShape.circle), child: const Center(child: Text('A', style: TextStyle(color: kAccent, fontSize: 12, fontWeight: FontWeight.w700)))),
              const SizedBox(width: 10),
              const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('analyst', style: TextStyle(color: kBodyText, fontSize: 13, fontWeight: FontWeight.w600)),
                Text('SOC Analyst • Level 1', style: TextStyle(color: kSubText, fontSize: 11)),
              ])),
              const Icon(Icons.check_circle, color: kAccent, size: 18),
            ]),
          ),
          const SizedBox(height: 18),
          Row(children: [
            Expanded(child: OutlinedButton(style: OutlinedButton.styleFrom(foregroundColor: kBodyText, side: const BorderSide(color: kCardBorder), padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(fontSize: 13)))),
            const SizedBox(width: 10),
            Expanded(child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: kAccent, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), onPressed: () { onAssign(); Navigator.pop(context); }, child: const Text('Confirm Assign', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)))),
          ]),
        ]),
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  final String label; final Color color;
  const _MiniChip({required this.label, required this.color});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(4), border: Border.all(color: color.withOpacity(0.4))),
    child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700)),
  );
}

// ── Shared helpers ────────────────────────────────────────────
class _ShowDropdown extends StatelessWidget {
  final int value; final ValueChanged<int> onChanged;
  const _ShowDropdown({required this.value, required this.onChanged});
  @override
  Widget build(BuildContext context) => Container(
    height: 30, padding: const EdgeInsets.symmetric(horizontal: 8),
    decoration: BoxDecoration(color: kCardBg, borderRadius: BorderRadius.circular(7), border: Border.all(color: kCardBorder)),
    child: DropdownButtonHideUnderline(child: DropdownButton<int>(
      value: value, dropdownColor: kFieldBg,
      style: const TextStyle(color: kBodyText, fontSize: 12),
      icon: const Icon(Icons.keyboard_arrow_down, color: kSubText, size: 14),
      isDense: true,
      items: [5, 10, 25].map((n) => DropdownMenuItem(value: n, child: Text('$n', style: TextStyle(color: value == n ? kAccent : kBodyText, fontSize: 12)))).toList(),
      onChanged: (v) { if (v != null) onChanged(v); },
    )),
  );
}

// ✅ FIX: حطينا width ثابتة على الـ Container عشان نحل مشكلة unbounded width
class _DropFilter extends StatelessWidget {
  final String prefix, value; final List<String> options; final ValueChanged<String> onChanged;
  const _DropFilter({required this.prefix, required this.value, required this.options, required this.onChanged});
  @override
  Widget build(BuildContext context) => Container(
    height: 36,
    width: 160, // ✅ width ثابتة لحل مشكلة unbounded constraints
    padding: const EdgeInsets.symmetric(horizontal: 10),
    decoration: BoxDecoration(color: kCardBg, borderRadius: BorderRadius.circular(8), border: Border.all(color: kCardBorder)),
    child: DropdownButtonHideUnderline(child: DropdownButton<String>(
      value: value, dropdownColor: kFieldBg,
      style: const TextStyle(color: kBodyText, fontSize: 12),
      icon: const Icon(Icons.keyboard_arrow_down, color: kSubText, size: 15),
      isDense: true, isExpanded: true,
      items: options.map((o) => DropdownMenuItem(value: o, child: Text(o == 'All' ? '$prefix  $o' : o, style: TextStyle(color: value == o ? kAccent : kBodyText, fontSize: 12), overflow: TextOverflow.ellipsis))).toList(),
      onChanged: (v) { if (v != null) onChanged(v); },
    )),
  );
}

class _PagBtn extends StatelessWidget {
  final String label; final IconData icon; final bool enabled, iconAfter; final VoidCallback onTap;
  const _PagBtn({required this.label, required this.icon, required this.enabled, required this.onTap, this.iconAfter = false});
  @override
  Widget build(BuildContext context) {
    final c = enabled ? kBodyText : kSubText;
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (!iconAfter) ...[Icon(icon, color: c, size: 15), const SizedBox(width: 2)],
        Text(label, style: TextStyle(color: c, fontSize: 12, fontWeight: enabled ? FontWeight.w600 : FontWeight.w400)),
        if (iconAfter)  ...[const SizedBox(width: 2), Icon(icon, color: c, size: 15)],
      ]),
    );
  }
}