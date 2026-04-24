import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
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

class ActionsScreen extends StatefulWidget {
  const ActionsScreen({super.key});
  @override
  State<ActionsScreen> createState() => _ActionsScreenState();
}

class _ActionsScreenState extends State<ActionsScreen> {
  final _actionsService = ActionsService();
  List<ClosedAlert> _closedAlerts = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAlerts();
  }

  Future<void> _loadAlerts() async {
    setState(() { _loading = true; _error = null; });
    try {
      final alerts = await _actionsService.getClosedAlerts();
      setState(() { _closedAlerts = alerts; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Color _sevColor(String s) {
    switch (s) {
      case 'Critical': return kCritical;
      case 'High':     return kHigh;
      case 'Medium':   return kMedium;
      default:         return kLow;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: kAccent));
    if (_error != null) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.error_outline, color: kCritical, size: 40),
        const SizedBox(height: 12),
        const Text('Failed to load', style: TextStyle(color: kBodyText, fontSize: 16)),
        TextButton(onPressed: _loadAlerts, child: const Text('Retry', style: TextStyle(color: kAccent))),
      ]));
    }

    return Scaffold(
      backgroundColor: kPageBg,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 600;
            return Padding(
              padding: EdgeInsets.fromLTRB(
                isWide ? 28 : 16,
                isWide ? 28 : 16,
                isWide ? 28 : 16,
                isWide ? 24 : 12,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Actions',
                    style: TextStyle(color: kBodyText, fontSize: 24, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Closed alerts  •  ${_closedAlerts.length} total',
                    style: const TextStyle(color: kSubText, fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: kCardBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: kCardBorder),
                      ),
                      child: Column(
                        children: [
                          Padding(
                            padding: EdgeInsets.fromLTRB(
                              isWide ? 20 : 12, 16,
                              isWide ? 20 : 12, 0,
                            ),
                            child: isWide
                                ? Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Expanded(child: _HeaderText()),
                                      const SizedBox(width: 12),
                                      _ResolvedBadge(count: _closedAlerts.length),
                                    ],
                                  )
                                : Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const _HeaderText(),
                                      const SizedBox(height: 10),
                                      _ResolvedBadge(count: _closedAlerts.length),
                                    ],
                                  ),
                          ),
                          const SizedBox(height: 12),
                          if (isWide) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
                              decoration: const BoxDecoration(
                                border: Border(
                                  top: BorderSide(color: kCardBorder),
                                  bottom: BorderSide(color: kCardBorder),
                                ),
                              ),
                              child: Row(children: [
                                SizedBox(width: 70,  child: Text('ID',         style: _hS)),
                                Expanded(            child: Text('Alert rule',  style: _hS)),
                                SizedBox(width: 100, child: Text('Severity',   style: _hS)),
                                SizedBox(width: 130, child: Text('Type',       style: _hS)),
                                SizedBox(width: 110, child: Text('Date',       style: _hS)),
                                SizedBox(width: 90,  child: Text('Resolution', style: _hS)),
                              ]),
                            ),
                          ] else ...[
                            const Divider(color: kCardBorder, height: 1),
                          ],
                          Expanded(
                            child: isWide
                                ? ListView.separated(
                                    padding: EdgeInsets.zero,
                                    itemCount: _closedAlerts.length,
                                    separatorBuilder: (_, __) => const Divider(color: kCardBorder, height: 1),
                                    itemBuilder: (ctx, i) {
                                      final a = _closedAlerts[i];
                                      return _ClosedAlertRow(
                                        alert: a,
                                        sevColor: _sevColor(a.severity),
                                        onTap: () => _openDetail(ctx, a, _sevColor(a.severity)),
                                      );
                                    },
                                  )
                                : ListView.separated(
                                    padding: const EdgeInsets.all(12),
                                    itemCount: _closedAlerts.length,
                                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                                    itemBuilder: (ctx, i) {
                                      final a = _closedAlerts[i];
                                      return _ClosedAlertCard(
                                        alert: a,
                                        sevColor: _sevColor(a.severity),
                                        onTap: () => _openDetail(ctx, a, _sevColor(a.severity)),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _openDetail(BuildContext ctx, ClosedAlert a, Color sevColor) {
    showDialog(
      context: ctx,
      barrierColor: Colors.black.withOpacity(0.55),
      builder: (_) => _AlertDetailDialog(alert: a, sevColor: sevColor),
    );
  }
}

class _HeaderText extends StatelessWidget {
  const _HeaderText();
  @override
  Widget build(BuildContext context) => const Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Closed Alerts History',
          style: TextStyle(color: kBodyText, fontSize: 16, fontWeight: FontWeight.w700)),
      SizedBox(height: 4),
      Text(
        'View all alerts that have been investigated and closed. Click on any alert to see full details.',
        style: TextStyle(color: kSubText, fontSize: 12),
      ),
    ],
  );
}

class _ResolvedBadge extends StatelessWidget {
  final int count;
  const _ResolvedBadge({required this.count});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: kLow.withOpacity(0.15),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: kLow.withOpacity(0.4)),
    ),
    child: Text(
      '$count alerts resolved',
      style: const TextStyle(color: kLow, fontSize: 12, fontWeight: FontWeight.w600),
    ),
  );
}

const _hS = TextStyle(color: kSubText, fontSize: 12, fontWeight: FontWeight.w700);

class _ClosedAlertRow extends StatefulWidget {
  final ClosedAlert alert;
  final Color sevColor;
  final VoidCallback onTap;
  const _ClosedAlertRow({required this.alert, required this.sevColor, required this.onTap});
  @override
  State<_ClosedAlertRow> createState() => _ClosedAlertRowState();
}

class _ClosedAlertRowState extends State<_ClosedAlertRow> {
  bool _hovered = false;
  @override
  Widget build(BuildContext context) {
    final a = widget.alert;
    final isTP = a.resolution == 'TP';
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          color: _hovered ? kFieldBg.withOpacity(0.35) : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            SizedBox(width: 70,  child: Text(a.id, style: const TextStyle(color: kSubText, fontSize: 12))),
            Expanded(child: Text(a.rule, style: const TextStyle(color: kBodyText, fontSize: 13, fontWeight: FontWeight.w600))),
            SizedBox(width: 100, child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: widget.sevColor, borderRadius: BorderRadius.circular(8)),
              child: Text(a.severity, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
            )),
            SizedBox(width: 130, child: Text(a.type,       style: const TextStyle(color: kSubText, fontSize: 12))),
            SizedBox(width: 110, child: Text(a.date,       style: const TextStyle(color: kSubText, fontSize: 12))),
            SizedBox(width: 90,  child: Container(
              width: 38, height: 38,
              decoration: BoxDecoration(color: isTP ? kCritical : kLow, borderRadius: BorderRadius.circular(8)),
              child: Center(child: Text(a.resolution, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800))),
            )),
          ]),
        ),
      ),
    );
  }
}

class _ClosedAlertCard extends StatelessWidget {
  final ClosedAlert alert;
  final Color sevColor;
  final VoidCallback onTap;
  const _ClosedAlertCard({required this.alert, required this.sevColor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final a = alert;
    final isTP = a.resolution == 'TP';
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: kPageBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: kCardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(a.id, style: const TextStyle(color: kSubText, fontSize: 12)),
                Container(
                  width: 34, height: 34,
                  decoration: BoxDecoration(
                    color: isTP ? kCritical : kLow,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      a.resolution,
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(a.rule, style: const TextStyle(color: kBodyText, fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: sevColor, borderRadius: BorderRadius.circular(6)),
                  child: Text(a.severity, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                ),
                Text(a.type, style: const TextStyle(color: kSubText, fontSize: 12)),
                Text(a.date, style: const TextStyle(color: kSubText, fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AlertDetailDialog extends StatefulWidget {
  final ClosedAlert alert;
  final Color sevColor;
  const _AlertDetailDialog({required this.alert, required this.sevColor});
  @override
  State<_AlertDetailDialog> createState() => _AlertDetailDialogState();
}

class _AlertDetailDialogState extends State<_AlertDetailDialog> {
  int _tab = 0;
  static const _tabs = [
    _T(Icons.bar_chart_rounded,      'Overview'),
    _T(Icons.account_tree_outlined,  'Network'),
    _T(Icons.monitor_outlined,       'Endpoint'),
    _T(Icons.gps_fixed_outlined,     'Threat Intel'),
  ];

  @override
  Widget build(BuildContext context) {
    final a = widget.alert;
    final screenW = MediaQuery.of(context).size.width;
    final isWide = screenW >= 600;
    final hPad = isWide ? 60.0 : 12.0;
    final vPad = isWide ? 40.0 : 20.0;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 800,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: BoxDecoration(
          color: kCardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: kCardBorder),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 40)],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            Text(
                              'Alert #${a.id}',
                              style: const TextStyle(
                                color: kBodyText,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            _Tag(label: a.severity, color: widget.sevColor),
                            const _Tag(label: 'Malicious', color: kCritical),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 28, height: 28,
                          decoration: BoxDecoration(
                            color: kFieldBg,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: kCardBorder),
                          ),
                          child: const Icon(Icons.close, color: kSubText, size: 15),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(a.rule,
                      style: const TextStyle(
                          color: kBodyText,
                          fontSize: 14,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 3),
                  Text(a.description,
                      style: const TextStyle(color: kSubText, fontSize: 12)),
                  const SizedBox(height: 14),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: List.generate(_tabs.length, (i) {
                        final active = _tab == i;
                        return GestureDetector(
                          onTap: () => setState(() => _tab = i),
                          child: Container(
                            margin: const EdgeInsets.only(right: 4),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: active
                                  ? kAccent.withOpacity(0.15)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: active
                                    ? kAccent.withOpacity(0.5)
                                    : Colors.transparent,
                              ),
                            ),
                            child: Row(children: [
                              Icon(_tabs[i].icon,
                                  size: 13,
                                  color: active ? kAccent : kSubText),
                              const SizedBox(width: 5),
                              Text(
                                _tabs[i].label,
                                style: TextStyle(
                                  color: active ? kAccent : kSubText,
                                  fontSize: 12,
                                  fontWeight: active
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                ),
                              ),
                            ]),
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: kCardBorder, height: 1),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: _tab == 0
                    ? _OverviewContent(a: a)
                    : _tab == 1
                        ? _NetworkContent(a: a)
                        : _tab == 2
                            ? _EndpointContent(a: a)
                            : _ThreatIntelContent(a: a),
              ),
            ),
            const Divider(color: kCardBorder, height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: isWide
                  ? Row(
                      children: [
                        _FooterBtn(
                          label: 'Assign to me',
                          color: kAccent,
                          textColor: Colors.black,
                          onTap: () {
                            showStatusBar(
                              'iras.local/alerts/${a.id}/assign  →  Assigned to: analyst@iras.local',
                              seconds: 4,
                            );
                          },
                        ),
                        const SizedBox(width: 10),
                        _FooterBtn(
                          label: 'Close as True Positive',
                          color: kCritical,
                          textColor: Colors.white,
                          onTap: () {
                            Navigator.pop(context);
                            showStatusBar(
                              'iras.local/alerts/${a.id}/close  →  Closed as True Positive ✓',
                              seconds: 4,
                            );
                          },
                        ),
                        const SizedBox(width: 10),
                        _FooterBtn(
                          label: 'Close as False Positive',
                          color: const Color(0xFF2A9D5C),
                          textColor: Colors.white,
                          onTap: () {
                            Navigator.pop(context);
                            showStatusBar(
                              'iras.local/alerts/${a.id}/close  →  Closed as False Positive ✓',
                              seconds: 4,
                            );
                          },
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Text('Cancel',
                              style: TextStyle(color: kSubText, fontSize: 13)),
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _FooterBtn(
                          label: 'Assign to me',
                          color: kAccent,
                          textColor: Colors.black,
                          onTap: () {
                            showStatusBar(
                              'iras.local/alerts/${a.id}/assign  →  Assigned to: analyst@iras.local',
                              seconds: 4,
                            );
                          },
                        ),
                        const SizedBox(height: 8),
                        _FooterBtn(
                          label: 'Close as True Positive',
                          color: kCritical,
                          textColor: Colors.white,
                          onTap: () {
                            Navigator.pop(context);
                            showStatusBar(
                              'iras.local/alerts/${a.id}/close  →  Closed as True Positive ✓',
                              seconds: 4,
                            );
                          },
                        ),
                        const SizedBox(height: 8),
                        _FooterBtn(
                          label: 'Close as False Positive',
                          color: const Color(0xFF2A9D5C),
                          textColor: Colors.white,
                          onTap: () {
                            Navigator.pop(context);
                            showStatusBar(
                              'iras.local/alerts/${a.id}/close  →  Closed as False Positive ✓',
                              seconds: 4,
                            );
                          },
                        ),
                        const SizedBox(height: 8),
                        Center(
                          child: GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: const Text('Cancel',
                                style:
                                    TextStyle(color: kSubText, fontSize: 13)),
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _T {
  final IconData icon;
  final String label;
  const _T(this.icon, this.label);
}

class _Tag extends StatelessWidget {
  final String label;
  final Color color;
  const _Tag({required this.label, required this.color});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: color.withOpacity(0.2),
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: color.withOpacity(0.5)),
    ),
    child: Text(label,
        style: TextStyle(
            color: color, fontSize: 12, fontWeight: FontWeight.w700)),
  );
}

class _FooterBtn extends StatefulWidget {
  final String label;
  final Color color, textColor;
  final VoidCallback onTap;
  const _FooterBtn(
      {required this.label,
      required this.color,
      required this.textColor,
      required this.onTap});
  @override
  State<_FooterBtn> createState() => _FooterBtnState();
}

class _FooterBtnState extends State<_FooterBtn> {
  bool _hovered = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          decoration: BoxDecoration(
            color: _hovered
                ? Color.lerp(widget.color, Colors.white, 0.12)!
                : widget.color,
            borderRadius: BorderRadius.circular(50),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              color: widget.textColor,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final String label, value;
  final Color? valueColor;
  final bool mono;
  const _Field(
      {required this.label,
      required this.value,
      this.valueColor,
      this.mono = false});
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(color: kSubText, fontSize: 11)),
      const SizedBox(height: 4),
      Text(
        value,
        style: TextStyle(
          color: valueColor ?? kBodyText,
          fontSize: mono ? 13 : 14,
          fontWeight: FontWeight.w600,
          fontFamily: mono ? 'monospace' : null,
        ),
      ),
    ],
  );
}

class _OverviewContent extends StatelessWidget {
  final ClosedAlert a;
  const _OverviewContent({required this.a});
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final isWide = constraints.maxWidth >= 420;
      final content = [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _Field(label: 'Alert ID', value: a.id),
          const SizedBox(height: 16),
          _Field(label: 'Status', value: a.status, valueColor: kSubText),
        ]),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _Field(label: 'Type', value: a.type),
          const SizedBox(height: 16),
          _Field(label: 'Timestamp', value: a.timestamp),
        ]),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _Field(label: 'Date', value: a.date),
          const SizedBox(height: 16),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: const [
              Icon(Icons.warning_amber_rounded, color: kCritical, size: 13),
              SizedBox(width: 4),
              Text('Threat Score', style: TextStyle(color: kSubText, fontSize: 11)),
            ]),
            const SizedBox(height: 6),
            Row(children: [
              Text('${a.threatScore}/100',
                  style: const TextStyle(
                      color: kBodyText,
                      fontSize: 13,
                      fontWeight: FontWeight.w700)),
              const SizedBox(width: 8),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: a.threatScore / 100,
                    backgroundColor: kCardBorder,
                    color: kCritical,
                    minHeight: 6,
                  ),
                ),
              ),
            ]),
          ]),
        ]),
      ];
      if (isWide) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: content.map((w) => Expanded(child: w)).toList(),
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: content
            .expand((w) => [w, const SizedBox(height: 16)])
            .toList()
          ..removeLast(),
      );
    });
  }
}

class _NetworkContent extends StatelessWidget {
  final ClosedAlert a;
  const _NetworkContent({required this.a});
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final isWide = constraints.maxWidth >= 400;
      final srcBox = Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: kPageBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: kCardBorder),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(color: kLow, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            const Text('Source',
                style: TextStyle(
                    color: kLow, fontSize: 13, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 12),
          _Field(label: 'IP Address',  value: a.srcIp.isEmpty ? '—' : a.srcIp),
          const SizedBox(height: 10),
          _Field(
              label: 'MAC Address',
              value: a.macAddress.isEmpty ? '—' : a.macAddress,
              mono: true),
        ]),
      );
      final dstBox = Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: kPageBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: kCritical.withOpacity(0.35)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
                width: 8,
                height: 8,
                decoration:
                    const BoxDecoration(color: kCritical, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            const Text('Destination',
                style: TextStyle(
                    color: kCritical,
                    fontSize: 13,
                    fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 12),
          _Field(label: 'IP Address', value: a.dstIp.isEmpty ? '—' : a.dstIp),
        ]),
      );
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          isWide
              ? Row(children: [
                  Expanded(child: srcBox),
                  const SizedBox(width: 14),
                  Expanded(child: dstBox),
                ])
              : Column(children: [
                  srcBox,
                  const SizedBox(height: 12),
                  dstBox,
                ]),
          const SizedBox(height: 16),
          _Field(label: 'Protocol', value: a.protocol),
        ],
      );
    });
  }
}

class _EndpointContent extends StatelessWidget {
  final ClosedAlert a;
  const _EndpointContent({required this.a});
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final isWide = constraints.maxWidth >= 400;
      final row1 = [
        _Field(label: 'Hostname', value: a.hostname),
        _Field(label: 'Username', value: a.username),
      ];
      final row2 = [
        _Field(label: 'Process Name', value: a.processName, mono: true, valueColor: kAccent),
        _Field(label: 'Process ID',   value: a.processId),
      ];
      Widget buildRow(List<Widget> items) => isWide
          ? Row(children: items.map((w) => Expanded(child: w)).toList())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: items
                  .expand((w) => [w, const SizedBox(height: 14)])
                  .toList()
                ..removeLast(),
            );

      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        buildRow(row1),
        const SizedBox(height: 16),
        buildRow(row2),
        const SizedBox(height: 16),
        _Field(label: 'File Hash', value: a.fileHash.isEmpty ? '—' : a.fileHash, mono: true),
        const SizedBox(height: 16),
        _Field(label: 'File Path', value: a.filePath.isEmpty ? '—' : a.filePath, mono: true),
      ]);
    });
  }
}

class _ThreatIntelContent extends StatelessWidget {
  final ClosedAlert a;
  const _ThreatIntelContent({required this.a});
  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Threat Score',
          style: TextStyle(color: kAccent, fontSize: 14, fontWeight: FontWeight.w700)),
      const SizedBox(height: 12),
      Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        RichText(
          text: TextSpan(children: [
            TextSpan(
              text: '${a.threatScore}',
              style: const TextStyle(
                  color: kBodyText, fontSize: 44, fontWeight: FontWeight.w800),
            ),
            const TextSpan(
                text: ' / 100',
                style: TextStyle(color: kSubText, fontSize: 14)),
          ]),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: a.threatScore / 100,
              backgroundColor: kCardBorder,
              color: kCritical,
              minHeight: 10,
            ),
          ),
        ),
      ]),
      const SizedBox(height: 20),
      const Text('IOC Matches (1)',
          style: TextStyle(color: kAccent, fontSize: 14, fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      Row(children: [
        Container(
            width: 6,
            height: 6,
            decoration:
                const BoxDecoration(color: kCritical, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Expanded(
            child: Text(a.iocMatch,
                style: const TextStyle(color: kBodyText, fontSize: 13))),
      ]),
      const SizedBox(height: 20),
      const Text('MITRE ATT&CK Techniques',
          style: TextStyle(color: kAccent, fontSize: 14, fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      Container(
        width: double.infinity,
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: kPageBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: kCardBorder),
        ),
        child: Text(
          '${a.mitreId}  –  ${a.mitreName}',
          style: const TextStyle(
              color: kBodyText, fontSize: 12, fontFamily: 'monospace'),
        ),
      ),
    ]);
  }
}