// ══════════════════════════════════════════════════════════════
//  api_service.dart  —  Real API only (no mock data)
//  Base URL : https://python-model-v8dl.vercel.app
//  pubspec  : dio: ^5.4.0
// ══════════════════════════════════════════════════════════════

import 'dart:typed_data';
import 'package:dio/dio.dart';

// ─────────────────────────────────────────────
// CONFIG
// ─────────────────────────────────────────────
const String kBaseUrl = 'https://python-model-v8dl.vercel.app';

// ─────────────────────────────────────────────
// DIO SINGLETON
// ─────────────────────────────────────────────
class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  late final Dio _dio = Dio(BaseOptions(
    baseUrl:        kBaseUrl,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 30),
    headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
  ))..interceptors.add(LogInterceptor(requestBody: true, responseBody: true, error: true));

  Dio get dio => _dio;
}

// ─────────────────────────────────────────────
// API EXCEPTION
// ─────────────────────────────────────────────
class ApiException implements Exception {
  final String message;
  final int?   statusCode;
  ApiException(this.message, {this.statusCode});

  @override String toString() => 'ApiException($statusCode): $message';

  static ApiException fromDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiException('Connection timeout. Please check your network.', statusCode: 408);
      case DioExceptionType.connectionError:
        return ApiException('Cannot connect to server. Make sure the server is running.', statusCode: 503);
      case DioExceptionType.badResponse:
        final code = e.response?.statusCode ?? 0;
        final msg  = e.response?.data?['detail'] ?? e.response?.data?['message'] ?? 'Server error';
        return ApiException('$msg', statusCode: code);
      default:
        return ApiException(e.message ?? 'Unknown error occurred.');
    }
  }
}

// ══════════════════════════════════════════════════════════════
//  MODELS
// ══════════════════════════════════════════════════════════════

class DashboardStats {
  final int totalAlerts, closedAlerts, closedAsTP, closedAsFP, incomingAlerts;
  DashboardStats({required this.totalAlerts, required this.closedAlerts,
      required this.closedAsTP, required this.closedAsFP, required this.incomingAlerts});
  factory DashboardStats.fromJson(Map<String, dynamic> j) => DashboardStats(
    totalAlerts: j['totalAlerts'] ?? 0, closedAlerts: j['closedAlerts'] ?? 0,
    closedAsTP: j['closedAsTP'] ?? 0, closedAsFP: j['closedAsFP'] ?? 0,
    incomingAlerts: j['incomingAlerts'] ?? 0);
}

class DashboardAlert {
  final String id, rule, severity, type;
  DashboardAlert({required this.id, required this.rule, required this.severity, required this.type});
  factory DashboardAlert.fromJson(Map<String, dynamic> j) => DashboardAlert(
    id: j['id'] ?? '', rule: j['rule'] ?? '', severity: j['severity'] ?? '', type: j['type'] ?? '');
}

class ChartSegment {
  final String label, color;
  final int value;
  ChartSegment({required this.label, required this.value, required this.color});
  factory ChartSegment.fromJson(Map<String, dynamic> j) =>
      ChartSegment(label: j['label'] ?? '', value: j['value'] ?? 0, color: j['color'] ?? '#FFFFFF');
}

class AlertItem {
  final String id, rule, severity, type, date, status;
  final String description, timestamp, firstSeen, lastSeen;
  final int    eventCount, threatScore;
  final String srcIp, dstIp, hostname, processName, protocol;
  final int?   ttl, ipLength;

  AlertItem({
    required this.id, required this.rule, required this.severity,
    required this.type, required this.date, required this.status,
    this.description = 'Suspicious activity detected on the network.',
    this.timestamp = '', this.firstSeen = '', this.lastSeen = '',
    this.eventCount = 1, this.threatScore = 75,
    this.srcIp = '', this.dstIp = '',
    this.hostname = '', this.processName = 'unknown',
    this.protocol = 'TCP', this.ttl, this.ipLength,
  });

  // ✅ يحوّل WiFi log entry لـ AlertItem
  factory AlertItem.fromWifiLog(Map<String, dynamic> j, {int index = 0}) {
    final srcIp    = j['src_ip']   ?? j['SourceIP']  ?? '';
    final dstIp    = j['dst_ip']   ?? j['DestIP']    ?? '';
    final protocol = j['protocol'] ?? 'TCP';
    final timestamp = j['timestamp'] ?? '';
    final ttl      = _parseInt(j['TTL']      ?? j['ttl']);
    final ipLength = _parseInt(j['IPLength'] ?? j['ip_length'] ?? j['length']);

    return AlertItem(
      id:          'WiFi-${index.toString().padLeft(4, '0')}',
      rule:        _buildRule(protocol, srcIp, dstIp),
      severity:    _inferSeverity(protocol),
      type:        'Network',
      date:        _formatDate(timestamp),
      status:      'Open',
      description: _buildDescription(srcIp, dstIp, protocol, ttl, ipLength),
      timestamp:   timestamp,
      firstSeen:   timestamp,
      lastSeen:    timestamp,
      srcIp:       srcIp,
      dstIp:       dstIp,
      hostname:    srcIp,
      processName: protocol.toLowerCase(),
      protocol:    protocol,
      threatScore: _inferThreatScore(_inferSeverity(protocol)),
      ttl:         ttl,
      ipLength:    ipLength,
    );
  }

  factory AlertItem.fromJson(Map<String, dynamic> j) {
    final srcIp    = j['srcIp']    ?? j['src_ip']    ?? '';
    final dstIp    = j['dstIp']    ?? j['dst_ip']    ?? '';
    final protocol = j['protocol'] ?? 'TCP';
    return AlertItem(
      id:          j['id']          ?? j['alert_id']   ?? '',
      rule:        j['rule']        ?? j['alert_type'] ?? _buildRule(protocol, srcIp, dstIp),
      severity:    j['severity']    ?? 'Medium',
      type:        j['type']        ?? 'Network',
      date:        j['date']        ?? j['timestamp']  ?? '',
      status:      j['status']      ?? 'Open',
      description: j['description'] ?? _buildDescription(srcIp, dstIp, protocol, null, null),
      timestamp:   j['timestamp']   ?? '',
      firstSeen:   j['firstSeen']   ?? j['first_seen'] ?? '',
      lastSeen:    j['lastSeen']    ?? j['last_seen']  ?? '',
      eventCount:  j['eventCount']  ?? 1,
      threatScore: j['threatScore'] ?? j['threat_score'] ?? 75,
      srcIp: srcIp, dstIp: dstIp,
      hostname:    j['hostname']    ?? srcIp,
      processName: j['processName'] ?? j['process_name'] ?? protocol.toLowerCase(),
      protocol:    protocol,
      ttl:         _parseInt(j['TTL'] ?? j['ttl']),
      ipLength:    _parseInt(j['IPLength'] ?? j['ip_length']),
    );
  }

  static int?   _parseInt(dynamic v)  { if (v == null) return null; if (v is int) return v; return int.tryParse(v.toString()); }
  static String _buildRule(String p, String src, String dst) {
    switch (p.toUpperCase()) {
      case 'ICMP':  return 'ICMP Ping: $src → $dst';
      case 'DNS':   return 'DNS Query from $src';
      case 'HTTP':  return 'HTTP Request from $src';
      case 'HTTPS': return 'HTTPS Traffic from $src';
      default:      return '$p Traffic: $src → $dst';
    }
  }
  static String _buildDescription(String src, String dst, String p, int? ttl, int? len) {
    final parts = <String>['Protocol: $p'];
    if (src.isNotEmpty) parts.add('Source IP: $src');
    if (dst.isNotEmpty) parts.add('Destination IP: $dst');
    if (ttl != null)    parts.add('TTL: $ttl');
    if (len != null)    parts.add('Length: $len bytes');
    return parts.join(' | ');
  }
  static String _inferSeverity(String p) {
    switch (p.toUpperCase()) {
      case 'ICMP': case 'DNS': return 'Low';
      case 'HTTP': case 'UDP': case 'TCP': return 'Medium';
      default: return 'High';
    }
  }
  static int _inferThreatScore(String sev) {
    switch (sev) { case 'Critical': return 90; case 'High': return 75; case 'Medium': return 55; default: return 30; }
  }
  static String _formatDate(String ts) {
    if (ts.isEmpty) return '';
    try { final d = DateTime.parse(ts); return '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}'; }
    catch (_) { return ts.length > 10 ? ts.substring(0, 10) : ts; }
  }
}

class ClosedAlert {
  final String id, rule, severity, type, date, resolution;
  final String description, timestamp, status;
  final int    threatScore;
  final String srcIp, dstIp, macAddress, protocol;
  final String hostname, username, processName, processId, fileHash, filePath;
  final String iocMatch, mitreId, mitreName;

  ClosedAlert({
    required this.id, required this.rule, required this.severity,
    required this.type, required this.date, required this.resolution,
    this.description = '', this.timestamp = '', this.status = 'Closed',
    this.threatScore = 80, this.srcIp = '', this.dstIp = '',
    this.macAddress = '', this.protocol = '', this.hostname = '',
    this.username = '', this.processName = '', this.processId = '',
    this.fileHash = '', this.filePath = '',
    this.iocMatch = '', this.mitreId = '', this.mitreName = '',
  });

  factory ClosedAlert.fromJson(Map<String, dynamic> j) => ClosedAlert(
    id:          j['id']          ?? j['alert_id']    ?? '',
    rule:        j['rule']        ?? j['alert_type']  ?? '',
    severity:    j['severity']    ?? '',
    type:        j['type']        ?? '',
    date:        j['date']        ?? j['timestamp']   ?? '',
    resolution:  j['resolution']  ?? j['status']      ?? '',
    description: j['description'] ?? '',
    timestamp:   j['timestamp']   ?? '',
    status:      j['status']      ?? 'Closed',
    threatScore: j['threatScore'] ?? j['threat_score'] ?? 0,
    srcIp:       j['srcIp']       ?? j['src_ip']      ?? '',
    dstIp:       j['dstIp']       ?? j['dst_ip']      ?? '',
    macAddress:  j['macAddress']  ?? j['mac_address'] ?? '',
    protocol:    j['protocol']    ?? '',
    hostname:    j['hostname']    ?? '',
    username:    j['username']    ?? '',
    processName: j['processName'] ?? j['process_name'] ?? '',
    processId:   j['processId']   ?? j['process_id']  ?? '',
    fileHash:    j['fileHash']    ?? j['file_hash']   ?? '',
    filePath:    j['filePath']    ?? j['file_path']   ?? '',
    iocMatch:    j['iocMatch']    ?? j['ioc_match']   ?? '',
    mitreId:     j['mitreId']     ?? j['mitre_id']    ?? '',
    mitreName:   j['mitreName']   ?? j['mitre_name']  ?? '',
  );
}

class AutoAction {
  final String alertId, actionType, category, status, duration, playbook;
  final int    apiCalls;
  AutoAction({required this.alertId, required this.actionType, required this.category,
      required this.status, required this.duration, required this.playbook, required this.apiCalls});
  factory AutoAction.fromJson(Map<String, dynamic> j) => AutoAction(
    alertId:    j['alertId']    ?? j['alert_id']    ?? '',
    actionType: j['actionType'] ?? j['action_type'] ?? '',
    category:   j['category']   ?? '',
    status:     j['status']     ?? '',
    duration:   j['duration']   ?? '0s',
    playbook:   j['playbook']   ?? '-',
    apiCalls:   j['apiCalls']   ?? j['api_calls']   ?? 0);
}

class AutomatedActionsStats {
  final int    total, success, pending, failed, partial, totalApiCalls;
  final double avgDuration;
  AutomatedActionsStats({required this.total, required this.success, required this.pending,
      required this.failed, required this.partial, required this.totalApiCalls, required this.avgDuration});
}

class PlaybookItem {
  final String id, tag, avgTime;
  final int    alerts, cases, critical, trueP, falseP;
  final List<String> detectionRules, mitreTechniques, commonSrcIps, commonDstIps;
  final List<Map<String, dynamic>> recentExamples;
  PlaybookItem({required this.id, required this.tag, required this.alerts,
      required this.cases, required this.critical, required this.trueP,
      required this.falseP, required this.avgTime,
      this.detectionRules = const [], this.mitreTechniques = const [],
      this.commonSrcIps = const [], this.commonDstIps = const [],
      this.recentExamples = const []});
  factory PlaybookItem.fromJson(Map<String, dynamic> j) => PlaybookItem(
    id: j['id'] ?? '', tag: j['tag'] ?? '', alerts: j['alerts'] ?? 0,
    cases: j['cases'] ?? 0, critical: j['critical'] ?? 0,
    trueP: j['true_p'] ?? 0, falseP: j['false_p'] ?? 0, avgTime: j['avg_time'] ?? 'N/A',
    detectionRules:  List<String>.from(j['detection_rules']        ?? []),
    mitreTechniques: List<String>.from(j['mitre_techniques']       ?? []),
    commonSrcIps:    List<String>.from(j['common_source_ips']      ?? []),
    commonDstIps:    List<String>.from(j['common_destination_ips'] ?? []),
    recentExamples:  List<Map<String, dynamic>>.from(j['recent_examples'] ?? []));
}

class CaseReport {
  final String caseId, alertRule, severity, type, status, resolved;
  CaseReport({required this.caseId, required this.alertRule, required this.severity,
      required this.type, required this.status, required this.resolved});
  factory CaseReport.fromJson(Map<String, dynamic> j) => CaseReport(
    caseId:    j['caseId']    ?? j['case_id']   ?? j['_id'] ?? '',
    alertRule: j['alertRule'] ?? j['alert_rule'] ?? j['rule'] ?? '',
    severity:  j['severity']  ?? '',
    type:      j['type']      ?? j['action_type'] ?? '',
    status:    j['status']    ?? '',
    resolved:  j['resolved']  ?? j['resolved_at'] ?? j['timestamp'] ?? '');
}

class SiemLog {
  final String time, level, message;
  SiemLog({required this.time, required this.level, required this.message});
  factory SiemLog.fromJson(Map<String, dynamic> j) =>
      SiemLog(time: j['time'] ?? j['timestamp'] ?? '', level: j['level'] ?? 'INFO', message: j['message'] ?? '');
}

class SiemStatus {
  final bool   isConnected;
  final String environment, url;
  SiemStatus({required this.isConnected, required this.environment, required this.url});
  factory SiemStatus.fromJson(Map<String, dynamic> j) => SiemStatus(
    isConnected: j['isConnected'] ?? j['connected'] ?? false,
    environment: j['environment'] ?? '', url: j['url'] ?? '');
}

class DetectionResult {
  final String  attackType, label;
  final double  confidence;
  final bool    isAttack;
  final String? blockedIp, action;
  DetectionResult({required this.attackType, required this.confidence,
      required this.label, required this.isAttack, this.blockedIp, this.action});
  factory DetectionResult.fromJson(Map<String, dynamic> j) => DetectionResult(
    attackType:  j['attack_type'] ?? j['label'] ?? 'unknown',
    confidence:  (j['confidence'] ?? 0.0).toDouble(),
    label:       j['label']       ?? '',
    isAttack:    j['is_attack']   ?? false,
    blockedIp:   j['blocked_ip'],
    action:      j['action']);
}

class AutomatedDetectionResult {
  final DetectionResult detection;
  final String? actionTaken, isolatedIp;
  final bool    ddosDetected, bruteForceDetected;
  AutomatedDetectionResult({required this.detection, this.actionTaken, this.isolatedIp,
      required this.ddosDetected, required this.bruteForceDetected});
  factory AutomatedDetectionResult.fromJson(Map<String, dynamic> j) => AutomatedDetectionResult(
    detection:          DetectionResult.fromJson(j['detection'] ?? j),
    actionTaken:        j['action_taken'],
    isolatedIp:         j['isolated_ip'],
    ddosDetected:       j['ddos_detected']        ?? false,
    bruteForceDetected: j['brute_force_detected'] ?? false);
}

class DeviceModel {
  final String id, name, ip, mac, type, status;
  DeviceModel({required this.id, required this.name, required this.ip,
      required this.mac, required this.type, required this.status});
  factory DeviceModel.fromJson(Map<String, dynamic> j) => DeviceModel(
    id: j['_id'] ?? j['id'] ?? '', name: j['name'] ?? '',
    ip: j['ip'] ?? '', mac: j['mac'] ?? '',
    type: j['type'] ?? '', status: j['status'] ?? 'active');
  Map<String, dynamic> toJson() =>
      {'name': name, 'ip': ip, 'mac': mac, 'type': type, 'status': status};
}

class AlertMongoModel {
  final String   id, alertType, severity, sourceIp, status;
  final DateTime? timestamp;
  final Map<String, dynamic> rawData;
  AlertMongoModel({required this.id, required this.alertType, required this.severity,
      required this.sourceIp, required this.status, this.timestamp, required this.rawData});
  factory AlertMongoModel.fromJson(Map<String, dynamic> j) => AlertMongoModel(
    id:        j['_id']        ?? j['id']     ?? '',
    alertType: j['alert_type'] ?? j['type']   ?? '',
    severity:  j['severity']   ?? 'Medium',
    sourceIp:  j['source_ip']  ?? j['src_ip'] ?? '',
    status:    j['status']     ?? 'Open',
    timestamp: j['timestamp'] != null ? DateTime.tryParse(j['timestamp'].toString()) : null,
    rawData:   Map<String, dynamic>.from(j));
}

class HealthModel {
  final bool   mongoConnected;
  final double ddosAccuracy, bruteForceAccuracy;
  final String status;
  HealthModel({required this.mongoConnected, required this.ddosAccuracy,
      required this.bruteForceAccuracy, required this.status});
  factory HealthModel.fromJson(Map<String, dynamic> j) => HealthModel(
    mongoConnected:     j['mongo_connected']       ?? j['db_connected'] ?? false,
    ddosAccuracy:       (j['ddos_accuracy']        ?? 0.0).toDouble(),
    bruteForceAccuracy: (j['brute_force_accuracy'] ?? 0.0).toDouble(),
    status:             j['status']                ?? 'unknown');
}

// ✅ WiFi Log Entry — يمثل سطر واحد من /logs/wifi
class WifiLogEntry {
  final String  timestamp, srcIp, dstIp, protocol;
  final int?    ttl, ipLength, sourcePort, destPort, tcpStream;
  final String? tcpFlags;

  WifiLogEntry({required this.timestamp, required this.srcIp,
      required this.dstIp, required this.protocol,
      this.ttl, this.ipLength, this.sourcePort,
      this.destPort, this.tcpStream, this.tcpFlags});

  factory WifiLogEntry.fromJson(Map<String, dynamic> j) => WifiLogEntry(
    timestamp:  j['timestamp']   ?? j['Timestamp']   ?? '',
    srcIp:      j['src_ip']      ?? j['SourceIP']    ?? '',
    dstIp:      j['dst_ip']      ?? j['DestIP']      ?? '',
    protocol:   j['protocol']    ?? j['Protocol']    ?? 'TCP',
    ttl:        _p(j['TTL']        ?? j['ttl']),
    ipLength:   _p(j['IPLength']   ?? j['ip_length'] ?? j['length']),
    sourcePort: _p(j['SourcePort'] ?? j['source_port']),
    destPort:   _p(j['DestPort']   ?? j['dest_port']),
    tcpStream:  _p(j['TCPStream']  ?? j['tcp_stream']),
    tcpFlags:   j['TCPFlags']?.toString() ?? j['tcp_flags']?.toString());

  static int? _p(dynamic v) { if (v == null) return null; if (v is int) return v; return int.tryParse(v.toString()); }

  AlertItem toAlertItem({int index = 0}) => AlertItem.fromWifiLog(toJson(), index: index);

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp, 'src_ip': srcIp,
    'dst_ip': dstIp, 'protocol': protocol,
    if (ttl        != null) 'TTL':        ttl,
    if (ipLength   != null) 'IPLength':   ipLength,
    if (sourcePort != null) 'SourcePort': sourcePort,
    if (destPort   != null) 'DestPort':   destPort,
    if (tcpStream  != null) 'TCPStream':  tcpStream,
    if (tcpFlags   != null) 'TCPFlags':   tcpFlags,
  };
}

class RealtimeEvent {
  final String  type, message, ip;
  final DateTime? timestamp;
  RealtimeEvent({required this.type, required this.message, required this.ip, this.timestamp});
  factory RealtimeEvent.fromJson(Map<String, dynamic> j) => RealtimeEvent(
    type:      j['type']      ?? '',
    message:   j['message']   ?? '',
    ip:        j['ip']        ?? '',
    timestamp: j['timestamp'] != null ? DateTime.tryParse(j['timestamp'].toString()) : null);
}

// ══════════════════════════════════════════════════════════════
//  SOC API SERVICE  — كل الـ endpoints
// ══════════════════════════════════════════════════════════════
class SocApiService {
  final _dio = ApiClient().dio;

  // ── Health ────────────────────────────────────────────────
  Future<HealthModel> getHealth() async {
    try { return HealthModel.fromJson((await _dio.get('/health')).data); }
    on DioException catch (e) { throw ApiException.fromDioException(e); }
  }

  Future<Map<String, dynamic>> getAccuracy() async {
    try { return (await _dio.get('/health/accuracy')).data as Map<String, dynamic>; }
    on DioException catch (e) { throw ApiException.fromDioException(e); }
  }

  // ── WiFi Logs ─────────────────────────────────────────────

  /// GET /logs/wifi  — يجيب الـ packet logs
  Future<List<WifiLogEntry>> getWifiLogs({int? tail}) async {
    try {
      final res  = await _dio.get('/logs/wifi', queryParameters: tail != null ? {'tail': tail} : null);
      final data = res.data;
      final list = data is List ? data : (data['logs'] ?? data['lines'] ?? data['data'] ?? []) as List;
      return list.whereType<Map<String, dynamic>>().map(WifiLogEntry.fromJson).toList();
    } on DioException catch (e) { throw ApiException.fromDioException(e); }
  }

  /// GET /logs/wifi/list
  Future<List<String>> getWifiLogFiles() async {
    try {
      final res  = await _dio.get('/logs/wifi/list');
      final data = res.data;
      return data is List ? List<String>.from(data) : List<String>.from(data['files'] ?? []);
    } on DioException catch (e) { throw ApiException.fromDioException(e); }
  }

  /// POST /logs/wifi/append
  Future<Map<String, dynamic>> appendWifiLogs(List<Map<String, dynamic>> lines) async {
    try { return (await _dio.post('/logs/wifi/append', data: {'lines': lines})).data as Map<String, dynamic>; }
    on DioException catch (e) { throw ApiException.fromDioException(e); }
  }

  // ── Detection ─────────────────────────────────────────────

  /// POST /detect  — 18 packet fields
  Future<DetectionResult> detect({required Map<String, dynamic> packetData}) async {
    try { return DetectionResult.fromJson((await _dio.post('/detect', data: packetData)).data); }
    on DioException catch (e) { throw ApiException.fromDioException(e); }
  }

  /// POST /automated-actions/detect
  Future<AutomatedDetectionResult> automatedDetect({required Map<String, dynamic> packetData}) async {
    try { return AutomatedDetectionResult.fromJson((await _dio.post('/automated-actions/detect', data: packetData)).data); }
    on DioException catch (e) { throw ApiException.fromDioException(e); }
  }

  /// GET /detect/packet-auto
  Future<DetectionResult> detectPacketAuto() async {
    try { return DetectionResult.fromJson((await _dio.get('/detect/packet-auto')).data); }
    on DioException catch (e) { throw ApiException.fromDioException(e); }
  }

  /// POST /detect/packet-auto/upload  — ✅ MultipartFile.fromBytes (Web + Mobile)
  Future<DetectionResult> uploadPcapFile({required Uint8List fileBytes, required String fileName}) async {
    try {
      final form = FormData.fromMap({'file': MultipartFile.fromBytes(fileBytes,
          filename: fileName, contentType: DioMediaType('application', 'octet-stream'))});
      return DetectionResult.fromJson(
          (await _dio.post('/detect/packet-auto/upload', data: form,
              options: Options(contentType: 'multipart/form-data'))).data);
    } on DioException catch (e) { throw ApiException.fromDioException(e); }
  }

  // ── Actions (Block / Isolate) ─────────────────────────────

  Future<List<String>> getBlockedIps() async {
    try {
      final d = (await _dio.get('/actions/blocked-ips')).data;
      return d is List ? List<String>.from(d) : List<String>.from(d['blocked_ips'] ?? []);
    } on DioException catch (e) { throw ApiException.fromDioException(e); }
  }

  Future<Map<String, dynamic>> blockIp(String ip, {String reason = 'Manual block'}) async {
    try { return (await _dio.post('/actions/block-ip', data: {'ip': ip, 'reason': reason})).data; }
    on DioException catch (e) { throw ApiException.fromDioException(e); }
  }

  Future<Map<String, dynamic>> unblockIp(String ip, {String reason = 'Manual unblock'}) async {
    try { return (await _dio.post('/actions/unblock-ip', data: {'ip': ip, 'reason': reason})).data; }
    on DioException catch (e) { throw ApiException.fromDioException(e); }
  }

  Future<Map<String, dynamic>> isolateIp(String ip) async {
    try { return (await _dio.post('/actions/isolate-ip', data: {'ip': ip})).data; }
    on DioException catch (e) { throw ApiException.fromDioException(e); }
  }

  Future<Map<String, dynamic>> unisolateIp(String ip) async {
    try { return (await _dio.post('/actions/unisolate-ip', data: {'ip': ip})).data; }
    on DioException catch (e) { throw ApiException.fromDioException(e); }
  }

  Future<List<String>> getIsolatedIps() async {
    try {
      final d = (await _dio.get('/actions/isolated-ips')).data;
      return d is List ? List<String>.from(d) : List<String>.from(d['isolated_ips'] ?? []);
    } on DioException catch (e) { throw ApiException.fromDioException(e); }
  }

  // ── MongoDB CRUD ──────────────────────────────────────────

  Future<List<DeviceModel>> getDevices() async {
    try {
      final res  = await _dio.get('/devices');
      final list = res.data is List ? res.data as List : (res.data['devices'] ?? []) as List;
      return list.map((e) => DeviceModel.fromJson(e)).toList();
    } on DioException catch (e) { throw ApiException.fromDioException(e); }
  }

  Future<DeviceModel> createDevice(DeviceModel device) async {
    try { return DeviceModel.fromJson((await _dio.post('/devices', data: device.toJson())).data); }
    on DioException catch (e) { throw ApiException.fromDioException(e); }
  }

  Future<List<AlertMongoModel>> getMongoAlerts() async {
    try {
      final res  = await _dio.get('/alerts');
      final list = res.data is List ? res.data as List : (res.data['alerts'] ?? []) as List;
      return list.map((e) => AlertMongoModel.fromJson(e)).toList();
    } on DioException catch (e) { throw ApiException.fromDioException(e); }
  }

  Future<AlertMongoModel> createAlert(Map<String, dynamic> data) async {
    try { return AlertMongoModel.fromJson((await _dio.post('/alerts', data: data)).data); }
    on DioException catch (e) { throw ApiException.fromDioException(e); }
  }

  Future<Map<String, dynamic>> closeAlertAsFP(String id) async {
    try { return (await _dio.patch('/alerts/$id/close-as-false-positive')).data; }
    on DioException catch (e) { throw ApiException.fromDioException(e); }
  }

  Future<Map<String, dynamic>> closeAlertAsTP(String id) async {
    try { return (await _dio.patch('/alerts/$id/close-as-true-positive')).data; }
    on DioException catch (e) { throw ApiException.fromDioException(e); }
  }

  Future<List<Map<String, dynamic>>> getMongoAutoActions() async {
    try {
      final res  = await _dio.get('/automated-actions');
      final list = res.data is List ? res.data as List : (res.data['actions'] ?? []) as List;
      return list.map((e) => e as Map<String, dynamic>).toList();
    } on DioException catch (e) { throw ApiException.fromDioException(e); }
  }

  Future<Map<String, dynamic>> createAutoAction(Map<String, dynamic> data) async {
    try { return (await _dio.post('/automated-actions', data: data)).data; }
    on DioException catch (e) { throw ApiException.fromDioException(e); }
  }

  // ── Realtime ──────────────────────────────────────────────

  /// GET /events/recent  — limit default 100, max 2000
  Future<List<RealtimeEvent>> getRecentEvents({int limit = 100}) async {
    try {
      final res  = await _dio.get('/events/recent', queryParameters: {'limit': limit});
      final list = res.data is List ? res.data as List : (res.data['events'] ?? []) as List;
      return list.map((e) => RealtimeEvent.fromJson(e)).toList();
    } on DioException catch (e) { throw ApiException.fromDioException(e); }
  }

  // ── Stats ─────────────────────────────────────────────────

  Future<List<String>> getClientIps() async {
    try {
      final d = (await _dio.get('/stats/client-ips')).data;
      return d is List ? List<String>.from(d) : List<String>.from(d['ips'] ?? []);
    } on DioException catch (e) { throw ApiException.fromDioException(e); }
  }

  Future<Map<String, dynamic>> getClientIpsDetail() async {
    try { return (await _dio.get('/stats/client-ips/detail')).data as Map<String, dynamic>; }
    on DioException catch (e) { throw ApiException.fromDioException(e); }
  }

  Future<Map<String, dynamic>> getIpActions() async {
    try { return (await _dio.get('/stats/ip-actions')).data as Map<String, dynamic>; }
    on DioException catch (e) { throw ApiException.fromDioException(e); }
  }
}

// ══════════════════════════════════════════════════════════════
//  APP SERVICES  — كلها تتكلم الـ API مباشرة
// ══════════════════════════════════════════════════════════════

// ─────────────────────────────────────────────────────────────
// DashboardService
// GET /logs/wifi  → DashboardAlerts
// GET /alerts     → stats
// ─────────────────────────────────────────────────────────────
class DashboardService {
  final _soc = SocApiService();

  Future<DashboardStats> getStats() async {
    final alerts = await _soc.getMongoAlerts();
    final total  = alerts.length;
    final closed = alerts.where((a) => a.status == 'Closed').length;
    final tp     = alerts.where((a) => a.status == 'true_positive').length;
    final fp     = alerts.where((a) => a.status == 'false_positive').length;
    return DashboardStats(
      totalAlerts: total, closedAlerts: closed,
      closedAsTP: tp, closedAsFP: fp,
      incomingAlerts: total - closed,
    );
  }

  Future<List<DashboardAlert>> getOpenAlerts() async {
    final logs = await _soc.getWifiLogs(tail: 50);
    return logs.asMap().entries.map((e) => DashboardAlert(
      id:       'WiFi-${e.key.toString().padLeft(4,'0')}',
      rule:     AlertItem._buildRule(e.value.protocol, e.value.srcIp, e.value.dstIp),
      severity: AlertItem._inferSeverity(e.value.protocol),
      type:     'Network',
    )).toList();
  }

  Future<List<ChartSegment>> getAlertsByType() async {
    final logs    = await _soc.getWifiLogs();
    final counts  = <String, int>{};
    for (final l in logs) {
      counts[l.protocol] = (counts[l.protocol] ?? 0) + 1;
    }
    final colors  = {'TCP':'#3B82F6','UDP':'#06B6D4','ICMP':'#10B981','DNS':'#84CC16','HTTP':'#F59E0B','HTTPS':'#8B5CF6'};
    return counts.entries.map((e) => ChartSegment(
      label: e.key, value: e.value,
      color: colors[e.key] ?? '#6B7280',
    )).toList();
  }

  Future<List<ChartSegment>> getAlertsBySeverity() async {
    final logs   = await _soc.getWifiLogs();
    final counts = <String, int>{'Low': 0, 'Medium': 0, 'High': 0, 'Critical': 0};
    for (final l in logs) {
      final sev = AlertItem._inferSeverity(l.protocol);
      counts[sev] = (counts[sev] ?? 0) + 1;
    }
    final colors = {'Low':'#4299E1','Medium':'#ECC94B','High':'#ED8936','Critical':'#E53E3E'};
    return counts.entries.map((e) => ChartSegment(
      label: e.key, value: e.value, color: colors[e.key]!,
    )).toList();
  }
}

// ─────────────────────────────────────────────────────────────
// AlertQueueService
// GET  /logs/wifi    → alerts list
// GET  /alerts       → MongoDB alerts
// PATCH /alerts/{id} → close as TP/FP
// POST  /alerts      → create
// ─────────────────────────────────────────────────────────────
class AlertQueueService {
  final _soc = SocApiService();

  /// بيجيب alerts من /logs/wifi ويحولهم لـ AlertItems
  Future<List<AlertItem>> getAlerts({String? severity, String? type, String? search}) async {
    final logs  = await _soc.getWifiLogs();
    final items = logs.asMap().entries
        .map((e) => e.value.toAlertItem(index: e.key))
        .toList();
    return items.where((a) {
      final sevOk  = severity == null || severity == 'All' || a.severity == severity;
      final typeOk = type     == null || type     == 'All' || a.type     == type;
      final srchOk = search   == null || search.isEmpty
          || a.rule.toLowerCase().contains(search.toLowerCase())
          || a.srcIp.contains(search)
          || a.dstIp.contains(search)
          || a.protocol.toLowerCase().contains(search.toLowerCase());
      return sevOk && typeOk && srchOk;
    }).toList();
  }

  /// بيجيب الـ alerts المحفوظة في MongoDB
  Future<List<AlertItem>> getMongoDbAlerts() async {
    final mongo = await _soc.getMongoAlerts();
    return mongo.map((a) => AlertItem(
      id:          a.id,
      rule:        a.alertType,
      severity:    a.severity,
      type:        a.alertType,
      date:        a.timestamp?.toIso8601String().substring(0, 10) ?? '',
      status:      a.status,
      description: 'Source IP: ${a.sourceIp}',
      srcIp:       a.sourceIp,
      timestamp:   a.timestamp?.toIso8601String() ?? '',
    )).toList();
  }

  Future<void> closeAlertAsTP(String alertId) async => _soc.closeAlertAsTP(alertId);
  Future<void> closeAlertAsFP(String alertId) async => _soc.closeAlertAsFP(alertId);

  Future<AlertMongoModel> createAlert({
    required String alertType,
    required String severity,
    required String sourceIp,
    String status = 'Open',
    Map<String, dynamic> extra = const {},
  }) => _soc.createAlert({
    'alert_type': alertType,
    'severity':   severity,
    'source_ip':  sourceIp,
    'status':     status,
    'timestamp':  DateTime.now().toIso8601String(),
    ...extra,
  });

  Future<void> assignAlert(String alertId) async {}
}

// ─────────────────────────────────────────────────────────────
// ActionsService
// GET /alerts  → closed alerts من MongoDB
// ─────────────────────────────────────────────────────────────
class ActionsService {
  final _soc = SocApiService();

  Future<List<ClosedAlert>> getClosedAlerts() async {
    final mongo  = await _soc.getMongoAlerts();
    final closed = mongo.where((a) =>
      a.status == 'Closed' ||
      a.status == 'true_positive' ||
      a.status == 'false_positive'
    );
    return closed.map((a) => ClosedAlert(
      id:         a.id,
      rule:       a.alertType,
      severity:   a.severity,
      type:       a.alertType,
      date:       a.timestamp?.toIso8601String().substring(0, 10) ?? '',
      resolution: a.status == 'true_positive' ? 'TP'
                : a.status == 'false_positive' ? 'FP' : 'Closed',
      description: a.rawData['description']?.toString() ?? '',
      timestamp:   a.timestamp?.toIso8601String() ?? '',
      status:      'Closed',
      srcIp:       a.sourceIp,
    )).toList();
  }
}

// ─────────────────────────────────────────────────────────────
// AutomatedActionsService
// GET  /automated-actions → list من MongoDB
// POST /automated-actions → create
// ─────────────────────────────────────────────────────────────
class AutomatedActionsService {
  final _soc = SocApiService();

  Future<List<AutoAction>> getActions({String? status, String? category, String? search}) async {
    final raw     = await _soc.getMongoAutoActions();
    final actions = raw.map(AutoAction.fromJson).toList();
    return actions.where((a) {
      final sOk = status   == null || status   == 'All Status'     || a.status   == status;
      final cOk = category == null || category == 'All Categories' || a.category == category;
      final qOk = search   == null || search.isEmpty
          || a.actionType.toLowerCase().contains(search.toLowerCase())
          || a.alertId.contains(search);
      return sOk && cOk && qOk;
    }).toList();
  }

  Future<AutomatedActionsStats> getStats() async {
    final raw     = await _soc.getMongoAutoActions();
    final actions = raw.map(AutoAction.fromJson).toList();
    final success = actions.where((a) => a.status == 'Success').length;
    final pending = actions.where((a) => a.status == 'Pending').length;
    final failed  = actions.where((a) => a.status == 'Failed').length;
    final partial = actions.where((a) => a.status == 'Partial').length;
    final apiTot  = actions.fold(0, (s, a) => s + a.apiCalls);
    double avgDur = 0;
    if (actions.isNotEmpty) {
      final durs = actions.map((a) => double.tryParse(a.duration.replaceAll('s', '')) ?? 0.0).toList();
      avgDur = durs.fold(0.0, (s, d) => s + d) / durs.length;
    }
    return AutomatedActionsStats(
      total: actions.length, success: success, pending: pending,
      failed: failed, partial: partial, totalApiCalls: apiTot, avgDuration: avgDur,
    );
  }

  Future<void> createAction({
    required String alertId, required String actionType,
    required String category,
    String status = 'Success', String duration = '0s',
    String playbook = '-', int apiCalls = 0,
  }) => _soc.createAutoAction({
    'alert_id':    alertId,
    'action_type': actionType,
    'category':    category,
    'status':      status,
    'duration':    duration,
    'playbook':    playbook,
    'api_calls':   apiCalls,
    'timestamp':   DateTime.now().toIso8601String(),
  });
}

// ─────────────────────────────────────────────────────────────
// PlaybooksService  — بيانات ثابتة (الـ backend مفيهوش endpoint)
// ─────────────────────────────────────────────────────────────
class PlaybooksService {
  Future<List<PlaybookItem>> getPlaybooks({String? category, String? search}) async =>
      []; // أضيفي GET /playbooks لو ضفتيه للـ backend
}

// ─────────────────────────────────────────────────────────────
// CaseReportsService
// GET /automated-actions → حول لـ CaseReports
// ─────────────────────────────────────────────────────────────
class CaseReportsService {
  final _soc = SocApiService();

  Future<List<CaseReport>> getCases({
    String? severity, String? resolution,
    String? searchId, String? searchRule,
  }) async {
    final raw   = await _soc.getMongoAutoActions();
    final cases = raw.asMap().entries.map((e) {
      final j = e.value;
      return CaseReport(
        caseId:    j['_id']       ?? 'C-${e.key + 1000}',
        alertRule: '${j["alert_id"] ?? ""} - ${j["action_type"] ?? ""}',
        severity:  j['severity']  ?? 'Medium',
        type:      j['category']  ?? j['action_type'] ?? '',
        status:    j['status']    ?? 'TP',
        resolved:  j['timestamp'] != null
            ? j['timestamp'].toString().substring(0, 10)
            : DateTime.now().toIso8601String().substring(0, 10),
      );
    }).toList();

    return cases.where((c) {
      final sevOk  = severity   == null || c.severity.contains(severity);
      final resOk  = resolution == null || c.status == resolution;
      final idOk   = searchId   == null || searchId.isEmpty   || c.caseId.contains(searchId);
      final ruleOk = searchRule == null || searchRule.isEmpty || c.alertRule.toLowerCase().contains(searchRule.toLowerCase());
      return sevOk && resOk && idOk && ruleOk;
    }).toList();
  }
}

// ─────────────────────────────────────────────────────────────
// SiemService
// GET /logs/wifi  → SiemLog list
// GET /health     → SiemStatus
// ─────────────────────────────────────────────────────────────
class SiemService {
  final _soc = SocApiService();

  Future<List<SiemLog>> getLogs() async {
    final logs = await _soc.getWifiLogs(tail: 100);
    return logs.map((l) => SiemLog(
      time:    l.timestamp,
      level:   (l.protocol == 'ICMP' || l.protocol == 'UDP' || l.protocol == 'DNS') ? 'INFO' : 'WARN',
      message: '${l.protocol} | ${l.srcIp} → ${l.dstIp}'
               '${l.sourcePort != null ? " | src:${l.sourcePort}"   : ""}'
               '${l.destPort   != null ? " | dst:${l.destPort}"     : ""}'
               '${l.ipLength   != null ? " | ${l.ipLength} bytes"   : ""}'
               '${l.ttl        != null ? " | TTL:${l.ttl}"          : ""}',
    )).toList();
  }

  Future<SiemStatus> getStatus() async {
    final h = await _soc.getHealth();
    return SiemStatus(isConnected: h.mongoConnected, environment: h.status, url: kBaseUrl);
  }
}

// ─────────────────────────────────────────────────────────────
// DevicesService
// GET  /devices → list
// POST /devices → create
// ─────────────────────────────────────────────────────────────
class DevicesService {
  final _soc = SocApiService();

  Future<List<DeviceModel>> getDevices() => _soc.getDevices();

  Future<DeviceModel> addDevice({
    required String name, required String ip,
    required String mac,  required String type,
    String status = 'active',
  }) => _soc.createDevice(DeviceModel(id: '', name: name, ip: ip, mac: mac, type: type, status: status));
}

// ─────────────────────────────────────────────────────────────
// BlockedIpsService
// GET/POST /actions/blocked-ips, block-ip, unblock-ip
// GET/POST /actions/isolated-ips, isolate-ip, unisolate-ip
// ─────────────────────────────────────────────────────────────
class BlockedIpsService {
  final _soc = SocApiService();

  Future<List<String>> getBlockedIps()  => _soc.getBlockedIps();
  Future<List<String>> getIsolatedIps() => _soc.getIsolatedIps();

  Future<void> blockIp  (String ip, {String reason = 'Suspicious activity'}) => _soc.blockIp(ip, reason: reason);
  Future<void> unblockIp(String ip, {String reason = 'Cleared'})             => _soc.unblockIp(ip, reason: reason);
  Future<void> isolateIp  (String ip) => _soc.isolateIp(ip);
  Future<void> unisolateIp(String ip) => _soc.unisolateIp(ip);
}