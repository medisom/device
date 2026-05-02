import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:medisom_device/features/ble/ble_models.dart';
import 'package:universal_ble/universal_ble.dart';

class MedisomBleService {
  static const String devicePrefix = 'MEDISOM_';

  // Conforme requisito (UUIDs curtos). O plugin aceita UUID string.
  static const String serviceUuid = 'DEAD';
  static const String characteristicUuid = '1342';

  final _scanController = StreamController<List<DiscoveredDevice>>.broadcast();
  Stream<List<DiscoveredDevice>> get scanResults => _scanController.stream;

  final Map<String, DiscoveredDevice> _devices = {};
  StreamSubscription? _scanSub;

  String? connectedDeviceId;
  int? negotiatedMtu;

  Future<void> startScan() async {
    _devices.clear();
    _scanController.add(const []);
    await UniversalBle.startScan();
    _scanSub?.cancel();
    _scanSub = UniversalBle.scanStream.listen((d) {
      try {
        final name = (d.name ?? '').trim();
        if (!name.startsWith(devicePrefix)) return;
        final id = d.deviceId;
        if (id.isEmpty) return;
        _devices[id] = DiscoveredDevice(deviceId: id, name: name, rssi: d.rssi);
        _scanController.add(_devices.values.toList()..sort((a, b) => (b.rssi ?? -999).compareTo(a.rssi ?? -999)));
      } catch (e) {
        debugPrint('BLE scan parse error: $e');
      }
    });
  }

  Future<void> stopScan() async {
    try {
      await UniversalBle.stopScan();
    } catch (e) {
      debugPrint('BLE stopScan error: $e');
    }
    await _scanSub?.cancel();
    _scanSub = null;
  }

  Future<void> connect(String deviceId) async {
    connectedDeviceId = deviceId;
    negotiatedMtu = null;
    await stopScan();
    await UniversalBle.connect(deviceId);

    // Tentativa de MTU 512: se a plataforma não suportar, apenas ignora.
    try {
      final mtu = await UniversalBle.requestMtu(deviceId, 512);
      negotiatedMtu = mtu;
    } catch (e) {
      debugPrint('BLE requestMtu not supported or failed: $e');
    }
  }

  Future<void> disconnect() async {
    final id = connectedDeviceId;
    connectedDeviceId = null;
    negotiatedMtu = null;
    if (id == null) return;
    try {
      await UniversalBle.disconnect(id);
    } catch (e) {
      debugPrint('BLE disconnect error: $e');
    }
  }

  Future<void> _ensureServicesDiscovered(String deviceId) async {
    try {
      await UniversalBle.discoverServices(deviceId);
    } catch (e) {
      debugPrint('BLE discoverServices error: $e');
      rethrow;
    }
  }

  Future<String> readConfigJson(String deviceId) async {
    await _ensureServicesDiscovered(deviceId);
    final bytes = await UniversalBle.read(deviceId, serviceUuid, characteristicUuid);
    final raw = utf8.decode(bytes, allowMalformed: true);
    final sanitized = _sanitizeJsonString(raw);
    debugPrint('BLE read rawLen=${raw.length} sanitizedLen=${sanitized.length}');
    return sanitized;
  }

  /// Remove caracteres nulos/controle e tenta extrair o primeiro objeto JSON.
  /// Alguns firmwares enviam buffers com "lixo"/\u0000 no fim.
  static String _sanitizeJsonString(String input) {
    // Remove NUL e caracteres de controle comuns, mantendo \n/\r para depuração.
    var s = input.replaceAll('\u0000', '').trim();

    // Procura o primeiro '{' e o último '}' para isolar um objeto JSON.
    final start = s.indexOf('{');
    final end = s.lastIndexOf('}');
    if (start >= 0 && end > start) s = s.substring(start, end + 1);

    // Reparos conservadores para erros comuns de firmware.
    // Ex.: campo fw_version vindo como string sem aspas finais:
    // { ... ,"fw_version":"2026060630}
    s = _repairCommonJsonIssues(s);

    return s.trim();
  }

  /// Tenta corrigir *apenas* padrões bem conhecidos e de baixa ambiguidade.
  /// Se não bater com o padrão, retorna a string original.
  static String _repairCommonJsonIssues(String input) {
    var s = input;

    // 1) fw_version string sem aspa de fechamento antes de '}' ou ','
    // Captura o valor até encontrar '}' ou ',' e injeta a aspa faltante.
    final fwStart = s.indexOf('"fw_version"');
    if (fwStart >= 0) {
      final unterminated = RegExp(r'("fw_version"\s*:\s*")([^"\\]*?)(\s*)([},])');
      // Só aplica se a substring a partir de fw_version contém "fw_version":" e não tem outra aspa antes do delimitador.
      s = s.replaceAllMapped(unterminated, (m) {
        final keyAndOpenQuote = m.group(1) ?? '';
        final value = (m.group(2) ?? '').trim();
        final spacing = m.group(3) ?? '';
        final delimiter = m.group(4) ?? '';
        if (value.isEmpty) return m.group(0) ?? '';
        // Heurística: se o valor parece ser "inteiro" (ex.: build number), é seguro fechar.
        final looksLikeVersion = RegExp(r'^[0-9A-Za-z._-]+$').hasMatch(value);
        if (!looksLikeVersion) return m.group(0) ?? '';
        return '$keyAndOpenQuote$value"$spacing$delimiter';
      });
    }

    return s;
  }

  Future<void> writeConfigJson(String deviceId, String jsonCompact) async {
    await _ensureServicesDiscovered(deviceId);
    final bytes = utf8.encode(jsonCompact);

    // Fallback de escrita longa: tenta de uma vez; se falhar, fragmenta.
    try {
      await UniversalBle.write(deviceId, serviceUuid, characteristicUuid, bytes);
      return;
    } catch (e) {
      debugPrint('BLE single write failed, trying chunked write. Error: $e');
    }

    final mtu = negotiatedMtu ?? 185; // valor seguro cross-platform
    final chunkSize = (mtu - 3).clamp(20, 509); // ATT header ~3 bytes
    var offset = 0;
    while (offset < bytes.length) {
      final end = (offset + chunkSize) > bytes.length ? bytes.length : (offset + chunkSize);
      final chunk = bytes.sublist(offset, end);
      await UniversalBle.write(deviceId, serviceUuid, characteristicUuid, chunk);
      offset = end;
      // Pequena folga para stacks mais sensíveis.
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
  }

  Future<Map<String, dynamic>> parseJsonObject(String raw) async {
    try {
      if (raw.isEmpty) throw const FormatException('empty');
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (e) {
      debugPrint('BLE JSON parse error: $e');
      final looksLikeUnterminatedFwVersion = RegExp(r'"fw_version"\s*:\s*"[^"\\]*[},]').hasMatch(raw);
      if (looksLikeUnterminatedFwVersion) debugPrint('Hint: JSON parece ter fw_version mal formatado (string sem aspa de fechamento).');
      debugPrint('BLE JSON raw (first 220 chars): ${raw.length > 220 ? raw.substring(0, 220) : raw}');
    }
    throw const FormatException('invalid_json');
  }

  Future<void> dispose() async {
    await stopScan();
    await _scanController.close();
  }
}
