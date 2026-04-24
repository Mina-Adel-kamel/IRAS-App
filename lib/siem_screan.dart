import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'api_service.dart';

class SiemScrean extends StatelessWidget {
  const SiemScrean({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SOC Simulation - SIEM',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(brightness: Brightness.dark, scaffoldBackgroundColor: const Color(0xFF0D1117), fontFamily: 'monospace'),
      home: const SiemPage(),
    );
  }
}

class SiemPage extends StatefulWidget {
  const SiemPage({super.key});
  @override
  State<SiemPage> createState() => _SiemPageState();
}

class _SiemPageState extends State<SiemPage> with SingleTickerProviderStateMixin {
  final _siemService = SiemService();

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  List<SiemLog> _logs        = [];
  bool   _isConnected        = false;
  String _splunkUrl          = 'https://your-splunk-instance.com';
  String _environment        = 'Production Instance';
  bool   _loadingLogs        = true;
  bool   _isHoveringDashboard = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _pulseAnimation  = Tween<double>(begin: 0.4, end: 1.0).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loadingLogs = true);
    try {
      final results = await Future.wait([_siemService.getLogs(), _siemService.getStatus()]);
      setState(() {
        _logs        = results[0] as List<SiemLog>;
        final status = results[1] as SiemStatus;
        _isConnected = status.isConnected;
        _splunkUrl   = status.url.isNotEmpty ? status.url : _splunkUrl;
        _environment = status.environment;
        _loadingLogs = false;
      });
    } catch (_) {
      setState(() => _loadingLogs = false);
    }
  }

  @override
  void dispose() { _pulseController.dispose(); super.dispose(); }

  Future<void> _launchSplunk() async {
    final uri = Uri.parse(_splunkUrl);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not open: $_splunkUrl'), backgroundColor: Colors.redAccent));
    }
  }

  void _showConfigureUrlDialog() {
    final controller = TextEditingController(text: _splunkUrl);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A2332),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Configure Splunk URL', style: TextStyle(color: Colors.white, fontSize: 16)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'https://your-splunk-instance.com',
            hintStyle: const TextStyle(color: Colors.white38),
            enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white24), borderRadius: BorderRadius.circular(8)),
            focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Color(0xFFB8FF00)), borderRadius: BorderRadius.circular(8)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFB8FF00), foregroundColor: Colors.black),
            onPressed: () { setState(() => _splunkUrl = controller.text.trim()); Navigator.pop(ctx); },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: SafeArea(child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildSplunkCard(),
          const SizedBox(height: 24),
          _buildLocalSiemLogs(),
        ]),
      )),
    );
  }

  Widget _buildHeader() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: [
      const Text('SIEM', style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
      const SizedBox(width: 10),
      Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(color: const Color(0xFF1E2D1E), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFB8FF00).withOpacity(0.3))),
        child: const Icon(Icons.rocket_launch_rounded, color: Color(0xFFB8FF00), size: 18),
      ),
    ]),
    const SizedBox(height: 4),
    const Text('Logs & dashboards', style: TextStyle(color: Colors.white54, fontSize: 13, letterSpacing: 0.5)),
  ]);

  Widget _buildSplunkCard() => Container(
    decoration: BoxDecoration(color: const Color(0xFF141D2B), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF1E2D40), width: 1), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 16, offset: const Offset(0, 4))]),
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // Header row
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          GestureDetector(
            onTap: _launchSplunk,
            child: Container(
              width: 46, height: 46,
              decoration: BoxDecoration(color: const Color(0xFF1E2D1A), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFB8FF00).withOpacity(0.4))),
              child: const Icon(Icons.storage_rounded, color: Color(0xFFB8FF00), size: 22),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Flexible(child: Text('Splunk Integration', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700))),
              const SizedBox(width: 8),
              AnimatedBuilder(animation: _pulseAnimation, builder: (_, __) => Opacity(opacity: _pulseAnimation.value, child: const Icon(Icons.show_chart_rounded, color: Color(0xFFB8FF00), size: 16))),
            ]),
            const SizedBox(height: 4),
            const Text('Access your Splunk SIEM platform for advanced log analysis and threat detection', style: TextStyle(color: Colors.white54, fontSize: 12, height: 1.4)),
          ])),
        ]),
        const SizedBox(height: 18),
        const Divider(color: Color(0xFF1E2D40), height: 1),
        const SizedBox(height: 18),

        // Status and Environment in proper containers
        LayoutBuilder(builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 360;

          Widget statusBox = Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF0D1117),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF1E2D40)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Status', style: TextStyle(color: Color(0xFF5B8DB8), fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () => setState(() => _isConnected = !_isConnected),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (_, __) => Container(
                      width: 10, height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isConnected ? Color.lerp(const Color(0xFF4CAF50), const Color(0xFFB8FF00), _pulseAnimation.value) : Colors.redAccent,
                        boxShadow: _isConnected ? [BoxShadow(color: const Color(0xFF4CAF50).withOpacity(_pulseAnimation.value * 0.6), blurRadius: 8, spreadRadius: 2)] : [],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isConnected ? 'Connected' : 'Disconnected',
                    style: TextStyle(color: _isConnected ? Colors.white : Colors.redAccent, fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ]),
              ),
              const SizedBox(height: 6),
              Text(_isConnected ? 'Splunk instance is reachable and active' : 'Cannot reach Splunk instance', style: TextStyle(color: _isConnected ? Colors.white38 : Colors.redAccent.withOpacity(0.6), fontSize: 11)),
            ]),
          );

          Widget envBox = Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF0D1117),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF1E2D40)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Environment', style: TextStyle(color: Color(0xFF5B8DB8), fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
              const SizedBox(height: 10),
              Text(_environment, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              const Text('Active deployment target', style: TextStyle(color: Colors.white38, fontSize: 11)),
            ]),
          );

          return isWide
              ? Row(children: [Expanded(child: statusBox), const SizedBox(width: 12), Expanded(child: envBox)])
              : Column(children: [statusBox, const SizedBox(height: 12), envBox]);
        }),
        const SizedBox(height: 18),

        // Buttons
        LayoutBuilder(builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 320;
          return isWide
              ? Row(children: [Expanded(child: _dashboardButton()), const SizedBox(width: 10), _configureButton()])
              : Column(children: [_dashboardButton(), const SizedBox(height: 10), _configureButton(fullWidth: true)]);
        }),
        const SizedBox(height: 14),

        // Current URL
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Current URL:', style: TextStyle(color: Colors.white54, fontSize: 12)),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: _launchSplunk,
            child: Text(_splunkUrl, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600, decoration: TextDecoration.underline, decorationColor: Color(0xFFB8FF00))),
          ),
        ]),
      ]),
    ),
  );

  Widget _dashboardButton() => MouseRegion(
    onEnter: (_) => setState(() => _isHoveringDashboard = true),
    onExit:  (_) => setState(() => _isHoveringDashboard = false),
    child: GestureDetector(
      onTap: _launchSplunk,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 48,
        decoration: BoxDecoration(
          color: _isHoveringDashboard ? const Color(0xFFCFFF3A) : const Color(0xFFB8FF00),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [BoxShadow(color: const Color(0xFFB8FF00).withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.open_in_new_rounded, color: Color(0xFF0D1117), size: 16),
          SizedBox(width: 8),
          Text('Open Splunk Dashboard', style: TextStyle(color: Color(0xFF0D1117), fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
        ]),
      ),
    ),
  );

  Widget _configureButton({bool fullWidth = false}) => GestureDetector(
    onTap: _showConfigureUrlDialog,
    child: Container(
      height: 48,
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(color: Colors.transparent, borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFF1E2D40))),
      alignment: Alignment.center,
      child: const Text('Configure URL', style: TextStyle(color: Color(0xFFB8FF00), fontSize: 13, fontWeight: FontWeight.w600)),
    ),
  );

  Widget _buildLocalSiemLogs() => Container(
    decoration: BoxDecoration(color: const Color(0xFF141D2B), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF1E2D40), width: 1)),
    padding: const EdgeInsets.all(18),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        AnimatedBuilder(animation: _pulseAnimation, builder: (_, __) => Icon(Icons.monitor_heart_rounded, color: Color.lerp(const Color(0xFFB8FF00), Colors.white70, 1 - _pulseAnimation.value), size: 18)),
        const SizedBox(width: 10),
        const Text('Local SIEM Logs', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
      ]),
      const SizedBox(height: 12),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: const Color(0xFF0D1117), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFF1E2D40))),
        child: _loadingLogs
            ? const Center(child: CircularProgressIndicator(color: Color(0xFFB8FF00), strokeWidth: 2))
            : _logs.isEmpty
                ? const Text('No logs available.', style: TextStyle(color: Colors.white54, fontSize: 13))
                : Column(crossAxisAlignment: CrossAxisAlignment.start, children: _logs.map((log) {
                    Color levelColor;
                    switch (log.level) {
                      case 'ERROR': levelColor = Colors.redAccent;    break;
                      case 'WARN':  levelColor = Colors.orangeAccent; break;
                      default:      levelColor = const Color(0xFFB8FF00);
                    }
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Wrap(crossAxisAlignment: WrapCrossAlignment.start, spacing: 8, runSpacing: 4, children: [
                        Text(log.time, style: const TextStyle(color: Colors.white38, fontSize: 11, fontFamily: 'monospace')),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(color: levelColor.withOpacity(0.12), borderRadius: BorderRadius.circular(4), border: Border.all(color: levelColor.withOpacity(0.4))),
                          child: Text(log.level, style: TextStyle(color: levelColor, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                        ),
                        Text(log.message, style: const TextStyle(color: Colors.white70, fontSize: 12, fontFamily: 'monospace')),
                      ]),
                    );
                  }).toList()),
      ),
    ]),
  );
}