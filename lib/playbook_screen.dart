// playbooks_screen.dart
// ✅ FIXES:
//   1. Stat cards أكبر من الشاشة → childAspectRatio أصغر + IntrinsicHeight بدل GridView
//   2. Recent examples overflow → ClipRect + softWrap
//   3. Card overflow → clipBehavior: Clip.hardEdge
import 'package:flutter/material.dart';
import 'api_service.dart';

const Color kPageBg     = Color(0xFF030810);
const Color kCardBg     = Color(0xFF070F1E);
const Color kCardBorder = Color(0xFF0F1E35);
const Color kAccent     = Color(0xFFCAF135);
const Color kSubText    = Color(0xFF5C7A99);
const Color kFieldBg    = Color(0xFF040B14);

class PlaybooksScreen extends StatefulWidget {
  const PlaybooksScreen({super.key});
  @override
  State<PlaybooksScreen> createState() => _PlaybooksScreenState();
}

class _PlaybooksScreenState extends State<PlaybooksScreen> {
  final _service = PlaybooksService();

  String _selectedCategory = "All";
  String _searchQuery      = "";
  String? _expandedPlaybookId;

  List<PlaybookItem> _playbooks = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() { super.initState(); _loadPlaybooks(); }

  Future<void> _loadPlaybooks() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await _service.getPlaybooks(category: _selectedCategory, search: _searchQuery);
      setState(() { _playbooks = data; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  List<PlaybookItem> get _filtered => _playbooks.where((p) {
    final catOk  = _selectedCategory == 'All' || p.tag == _selectedCategory;
    final srchOk = _searchQuery.isEmpty || p.tag.toLowerCase().contains(_searchQuery.toLowerCase()) || p.id.toLowerCase().contains(_searchQuery.toLowerCase());
    return catOk && srchOk;
  }).toList();

  List<String> get _categories {
    final cats = _playbooks.map((p) => p.tag).toSet().toList()..sort();
    return ['All', ...cats];
  }

  @override
  Widget build(BuildContext context) {
    final display = _filtered;

    return Scaffold(
      backgroundColor: kPageBg,
      body: SafeArea(
        child: LayoutBuilder(builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 600;
          final hPad   = isWide ? 40.0 : 14.0;

          return Padding(
            padding: EdgeInsets.all(hPad),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

              Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 8, children: const [
                Text("Playbooks", style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
                Icon(Icons.menu_book_rounded, color: kAccent, size: 22),
              ]),
              const SizedBox(height: 4),
              const Text("Dynamic incident response procedures learned from real security alerts and cases", style: TextStyle(color: kSubText, fontSize: 13)),
              const SizedBox(height: 20),

              Expanded(child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: kCardBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: kCardBorder)),
                child: _loading
                    ? const Center(child: CircularProgressIndicator(color: kAccent))
                    : _error != null
                        ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                            const Icon(Icons.error_outline, color: Colors.red, size: 40),
                            const SizedBox(height: 12),
                            const Text('Failed to load playbooks', style: TextStyle(color: Colors.white, fontSize: 16)),
                            TextButton(onPressed: _loadPlaybooks, child: const Text('Retry', style: TextStyle(color: kAccent))),
                          ]))
                        : Scrollbar(
                            thumbVisibility: true,
                            child: SingleChildScrollView(
                              clipBehavior: Clip.hardEdge,
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                _StatCards(playbooks: _playbooks, isWide: isWide),
                                const SizedBox(height: 22),
                                _SearchBar(
                                  selectedCategory: _selectedCategory,
                                  categories: _categories,
                                  isWide: isWide,
                                  onSearchChanged: (v) => setState(() => _searchQuery = v),
                                  onCategoryChanged: (v) => setState(() => _selectedCategory = v),
                                  playbooks: _playbooks,
                                ),
                                const SizedBox(height: 18),
                                _PlaybookList(
                                  playbooks: display,
                                  expandedId: _expandedPlaybookId,
                                  isWide: isWide,
                                  onToggle: (id) => setState(() => _expandedPlaybookId = _expandedPlaybookId == id ? null : id),
                                ),
                              ]),
                            ),
                          ),
              )),
            ]),
          );
        }),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  STAT CARDS — ✅ FIX: بدل GridView استخدمنا Wrap عشان مانحتاجش childAspectRatio
// ══════════════════════════════════════════════════════════════
class _StatCards extends StatelessWidget {
  final List<PlaybookItem> playbooks;
  final bool isWide;
  const _StatCards({required this.playbooks, required this.isWide});

  @override
  Widget build(BuildContext context) {
    final total    = playbooks.length;
    final alerts   = playbooks.fold(0, (s, p) => s + p.alerts);
    final cases    = playbooks.fold(0, (s, p) => s + p.cases);
    final learning = alerts + cases;

    // ✅ FIX: استخدمنا widget builder عادي بدون GridView
    Widget card(IconData icon, String title, String value, Color c) => Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
      decoration: BoxDecoration(color: kPageBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: kCardBorder)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Row(children: [Icon(icon, size: 15, color: c), const SizedBox(width: 7), Flexible(child: Text(title, style: const TextStyle(color: kSubText, fontSize: 12)))]),
        const SizedBox(height: 10),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
      ]),
    );

    final items = [
      card(Icons.menu_book_rounded,            'Total Playbooks',       '$total',    kAccent),
      card(Icons.warning_amber_rounded,        'Total Alerts Analyzed', '$alerts',   Colors.redAccent),
      card(Icons.check_circle_outline_rounded, 'Cases Resolved',        '$cases',    Colors.greenAccent),
      card(Icons.show_chart_rounded,           'Learning Sources',      '$learning', kAccent),
    ];

    if (isWide) {
      return IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: items.map((w) => Expanded(child: Padding(
            padding: EdgeInsets.only(right: items.indexOf(w) < items.length - 1 ? 12 : 0),
            child: w,
          ))).toList(),
        ),
      );
    }

    // ✅ FIX: على الموبايل نستخدم Column + Row بدل GridView
    // عشان نتجنب مشكلة الـ childAspectRatio
    return Column(children: [
      IntrinsicHeight(child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Expanded(child: items[0]),
        const SizedBox(width: 10),
        Expanded(child: items[1]),
      ])),
      const SizedBox(height: 10),
      IntrinsicHeight(child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Expanded(child: items[2]),
        const SizedBox(width: 10),
        Expanded(child: items[3]),
      ])),
    ]);
  }
}

// ══════════════════════════════════════════════════════════════
//  SEARCH BAR
// ══════════════════════════════════════════════════════════════
class _SearchBar extends StatelessWidget {
  final String selectedCategory;
  final List<String> categories;
  final List<PlaybookItem> playbooks;
  final bool isWide;
  final ValueChanged<String> onSearchChanged, onCategoryChanged;
  const _SearchBar({required this.selectedCategory, required this.categories, required this.playbooks, required this.isWide, required this.onSearchChanged, required this.onCategoryChanged});

  Widget _searchField() => Container(
    height: 38,
    decoration: BoxDecoration(color: kFieldBg, borderRadius: BorderRadius.circular(20), border: Border.all(color: kCardBorder)),
    child: TextField(
      style: const TextStyle(color: Colors.white, fontSize: 12),
      onChanged: onSearchChanged,
      decoration: const InputDecoration(
        prefixIcon: Icon(Icons.search_rounded, color: kSubText, size: 15),
        hintText: "Search playbooks...",
        hintStyle: TextStyle(color: kSubText, fontSize: 12),
        border: InputBorder.none,
        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
    ),
  );

  Widget _dropdown() => Container(
    height: 38,
    padding: const EdgeInsets.symmetric(horizontal: 14),
    decoration: BoxDecoration(color: kFieldBg, borderRadius: BorderRadius.circular(20), border: Border.all(color: kCardBorder)),
    child: DropdownButtonHideUnderline(child: DropdownButton<String>(
      value: selectedCategory,
      dropdownColor: kFieldBg,
      icon: const Icon(Icons.arrow_drop_down_rounded, color: kSubText, size: 18),
      style: const TextStyle(color: Colors.white, fontSize: 12),
      borderRadius: BorderRadius.circular(12),
      isExpanded: true,
      onChanged: (v) { if (v != null) onCategoryChanged(v); },
      items: categories.map((cat) {
        final count = cat == 'All' ? playbooks.length : playbooks.where((p) => p.tag == cat).length;
        final sel   = cat == selectedCategory;
        return DropdownMenuItem<String>(
          value: cat,
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Flexible(child: Text(cat, style: TextStyle(color: sel ? kAccent : Colors.white, fontWeight: sel ? FontWeight.bold : FontWeight.w400), overflow: TextOverflow.ellipsis)),
            Text('$count', style: TextStyle(color: sel ? kAccent : kSubText, fontWeight: FontWeight.bold)),
          ]),
        );
      }).toList(),
    )),
  );

  @override
  Widget build(BuildContext context) {
    if (isWide) {
      return Row(children: [Expanded(child: _searchField()), const SizedBox(width: 12), SizedBox(width: 220, child: _dropdown())]);
    }
    return Column(children: [_searchField(), const SizedBox(height: 10), _dropdown()]);
  }
}

// ══════════════════════════════════════════════════════════════
//  PLAYBOOK LIST
// ══════════════════════════════════════════════════════════════
class _PlaybookList extends StatelessWidget {
  final List<PlaybookItem> playbooks;
  final String? expandedId;
  final bool isWide;
  final ValueChanged<String> onToggle;
  const _PlaybookList({required this.playbooks, required this.expandedId, required this.isWide, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    if (playbooks.isEmpty) {
      return const Center(child: Padding(padding: EdgeInsets.only(top: 20), child: Text("No playbooks found", style: TextStyle(color: kSubText, fontSize: 14))));
    }
    return Column(children: playbooks.map((p) => _PlaybookCard(p: p, expanded: expandedId == p.id, isWide: isWide, onToggle: () => onToggle(p.id))).toList());
  }
}

// ══════════════════════════════════════════════════════════════
//  PLAYBOOK CARD
// ══════════════════════════════════════════════════════════════
class _PlaybookCard extends StatelessWidget {
  final PlaybookItem p;
  final bool expanded, isWide;
  final VoidCallback onToggle;
  const _PlaybookCard({required this.p, required this.expanded, required this.isWide, required this.onToggle});

  Widget _bullet(String text, bool bold) => Padding(
    padding: const EdgeInsets.only(bottom: 7, left: 8),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Padding(padding: EdgeInsets.only(top: 5), child: Icon(Icons.circle, color: kAccent, size: 5)),
      const SizedBox(width: 8),
      Expanded(child: Text(text, style: TextStyle(color: bold ? Colors.white : kSubText, fontSize: 13, fontWeight: bold ? FontWeight.bold : FontWeight.w400))),
    ]),
  );

  Widget _section(IconData icon, String title, {required Widget child}) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: [Icon(icon, size: 15, color: kAccent), const SizedBox(width: 8), Flexible(child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)))]),
    const SizedBox(height: 12),
    child,
  ]);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(color: kPageBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: kCardBorder)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // Header
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Flexible(child: Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 8, runSpacing: 6, children: [
            Text(p.tag, style: const TextStyle(color: kAccent, fontSize: 16, fontWeight: FontWeight.bold)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: kAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(4), border: Border.all(color: kAccent.withOpacity(0.3))),
              child: Text(p.tag, style: const TextStyle(color: kAccent, fontSize: 11, fontWeight: FontWeight.bold)),
            ),
          ])),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onToggle,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: kAccent.withOpacity(0.12), borderRadius: BorderRadius.circular(8), border: Border.all(color: kAccent.withOpacity(0.2))),
              child: Text(expanded ? "Hide" : "Details", style: const TextStyle(color: kAccent, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ),
        ]),
        const SizedBox(height: 8),
        Text("Learned from ${p.alerts} alerts and ${p.cases} resolved cases", style: const TextStyle(color: kSubText, fontSize: 13)),
        const SizedBox(height: 14),

        // Stats — ✅ Wrap بدل Row عشان مش بيخرج من الشاشة
        Wrap(spacing: 10, runSpacing: 10, children: [
          _SmallStat(title: "Critical/High",   value: '${p.critical}', color: Colors.redAccent),
          _SmallStat(title: "True Positives",  value: '${p.trueP}',   color: Colors.greenAccent),
          _SmallStat(title: "False Positives", value: '${p.falseP}',  color: Colors.orangeAccent),
          _SmallStat(title: "Avg. Resolution", value: p.avgTime,      color: kSubText),
        ]),

        if (expanded) ...[
          const SizedBox(height: 24),
          const Divider(color: kCardBorder, height: 1),
          const SizedBox(height: 20),

          _section(Icons.track_changes, "Detection Rules (${p.detectionRules.length})",
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: p.detectionRules.map((r) => _bullet(r, true)).toList())),
          const SizedBox(height: 16),

          _section(Icons.grid_view_rounded, "MITRE ATT&CK Techniques",
            child: p.mitreTechniques.isEmpty
                ? const Text("N/A", style: TextStyle(color: kSubText, fontSize: 13))
                : Wrap(spacing: 8, runSpacing: 8, children: p.mitreTechniques.map((t) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.redAccent.withOpacity(0.3))),
                    child: Text(t, style: const TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                  )).toList())),
          const SizedBox(height: 16),

          isWide
              ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(child: _section(Icons.router,   "Common Source IPs",      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: p.commonSrcIps.isEmpty ? [const Text("N/A", style: TextStyle(color: kSubText, fontSize: 13))] : p.commonSrcIps.map((ip) => _bullet(ip, false)).toList()))),
                  const SizedBox(width: 16),
                  Expanded(child: _section(Icons.language, "Common Destination IPs", child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: p.commonDstIps.isEmpty ? [const Text("N/A", style: TextStyle(color: kSubText, fontSize: 13))] : p.commonDstIps.map((ip) => _bullet(ip, false)).toList()))),
                ])
              : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _section(Icons.router,   "Common Source IPs",      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: p.commonSrcIps.isEmpty ? [const Text("N/A", style: TextStyle(color: kSubText, fontSize: 13))] : p.commonSrcIps.map((ip) => _bullet(ip, false)).toList())),
                  const SizedBox(height: 16),
                  _section(Icons.language, "Common Destination IPs", child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: p.commonDstIps.isEmpty ? [const Text("N/A", style: TextStyle(color: kSubText, fontSize: 13))] : p.commonDstIps.map((ip) => _bullet(ip, false)).toList())),
                ]),
          const SizedBox(height: 24),

          _section(Icons.access_time_rounded, "Recent Examples", child: _RecentExamples(examples: p.recentExamples)),
        ],
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  SMALL STAT
// ══════════════════════════════════════════════════════════════
class _SmallStat extends StatelessWidget {
  final String title, value; final Color color;
  const _SmallStat({required this.title, required this.value, required this.color});
  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minWidth: 90, maxWidth: 160),
    padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
    decoration: BoxDecoration(color: kFieldBg, borderRadius: BorderRadius.circular(10), border: Border.all(color: kCardBorder)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(color: kSubText, fontSize: 11)),
      const SizedBox(height: 6),
      Text(value, style: TextStyle(color: value == "N/A" ? kSubText : Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
    ]),
  );
}

// ══════════════════════════════════════════════════════════════
//  RECENT EXAMPLES — ✅ OVERFLOW FIXED
// ══════════════════════════════════════════════════════════════
class _RecentExamples extends StatelessWidget {
  final List<Map<String, dynamic>> examples;
  const _RecentExamples({required this.examples});

  @override
  Widget build(BuildContext context) {
    if (examples.isEmpty) {
      return const Text("No recent examples available", style: TextStyle(color: kSubText, fontSize: 13));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: examples.map((ex) {
        final isCrit = ex['severity'] == "Critical";
        return Container(
          width: double.infinity,
          clipBehavior: Clip.hardEdge,
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: kFieldBg, borderRadius: BorderRadius.circular(10), border: Border.all(color: kCardBorder)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
              Flexible(child: Text("#${ex['id']}", style: const TextStyle(color: kSubText, fontSize: 12, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isCrit ? Colors.redAccent.withOpacity(0.12) : Colors.orangeAccent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: isCrit ? Colors.redAccent.withOpacity(0.4) : Colors.orangeAccent.withOpacity(0.4)),
                ),
                child: Text(ex['severity'], style: TextStyle(color: isCrit ? Colors.redAccent : Colors.orangeAccent, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
              const Spacer(),
              Text(ex['date'], style: const TextStyle(color: kSubText, fontSize: 11)),
            ]),
            const SizedBox(height: 10),
            Text(ex['rule'], style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold), softWrap: true),
            const SizedBox(height: 6),
            Text(ex['ip'], style: const TextStyle(color: kSubText, fontSize: 12), softWrap: true, overflow: TextOverflow.ellipsis, maxLines: 2),
          ]),
        );
      }).toList(),
    );
  }
}