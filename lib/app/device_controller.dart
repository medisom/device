import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:medisom_device/features/ble/ble_models.dart';
import 'package:medisom_device/features/ble/ble_service.dart';
import 'package:medisom_device/features/config/sensor_config.dart';
import 'package:medisom_device/features/config/sensor_config_validator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:universal_ble/universal_ble.dart';

class DeviceController extends ChangeNotifier {
  final MedisomBleService _ble = MedisomBleService();

  MedisomBleService get ble => _ble;

  FlowStatus status = FlowStatus.idle;
  String? errorMessage;

  List<DiscoveredDevice> devices = const [];
  DiscoveredDevice? selected;

  bool isConnected = false;

  SensorConfig config = SensorConfig.empty();
  // Snapshot do modo reportado pelo ESP32 no último READ.
  // Usado para evitar exibir status/botões baseados em campos (ex.: `internet`)
  // quando o usuário alternou o modo no formulário, mas ainda não gravou/aplicou.
  bool? lastReportedModoWifi;
  Map<String, String> fieldErrors = const {};
  bool initialReadDone = false;

  /// Incrementado apenas quando uma configuração é carregada do dispositivo via READ.
  /// Útil para a UI sincronizar controllers sem brigar com o teclado durante edição.
  int deviceReadRevision = 0;

  StreamSubscription? _scanSub;
  // Nem todas as plataformas expõem stream de conexão (API varia por plugin).

  Future<void> init() async {
    _scanSub = _ble.scanResults.listen((d) {
      devices = d;
      if (status == FlowStatus.scanning && d.isNotEmpty) status = FlowStatus.deviceFound;
      notifyListeners();
    });

    // No Preview (web) do Dreamflow, BLE quase sempre não está disponível.
    // Trate isso explicitamente para evitar o estado enganoso de “Bluetooth desligado”.
    if (kIsWeb) {
      status = FlowStatus.error;
      errorMessage = 'BLE não está disponível no Preview Web. Para usar BLE, rode em Android/iOS.';
      notifyListeners();
      return;
    }

    await _refreshAdapterState();
  }

  Future<void> _refreshAdapterState() async {
    if (kIsWeb) {
      status = FlowStatus.error;
      errorMessage = 'BLE não está disponível no Preview Web. Para usar BLE, rode em Android/iOS.';
      notifyListeners();
      return;
    }
    try {
      final state = await UniversalBle.getBluetoothAvailabilityState();
      if (state == AvailabilityState.poweredOn) {
        if (status == FlowStatus.bluetoothOff) status = FlowStatus.idle;
        errorMessage = null;
      } else {
        // Mantém o label simples (compatível com o fluxo existente), mas detalha no painel.
        status = FlowStatus.bluetoothOff;
        errorMessage = switch (state) {
          AvailabilityState.poweredOff => 'Ative o Bluetooth do dispositivo para continuar.',
          AvailabilityState.unsupported => 'BLE não é suportado neste dispositivo.',
          AvailabilityState.unauthorized => 'Bluetooth sem permissão. Verifique as permissões do app.',
          _ => 'Bluetooth indisponível: ${state.name}',
        };
      }
      notifyListeners();
    } catch (e) {
      debugPrint('BLE availability check failed: $e');
      status = FlowStatus.error;
      errorMessage = 'Falha ao verificar estado do Bluetooth.';
      notifyListeners();
    }
  }

  Future<bool> ensurePermissions() async {
    status = FlowStatus.requestingPermissions;
    errorMessage = null;
    notifyListeners();

    bool isOk(PermissionStatus s) => s.isGranted || s.isLimited;

    try {
      // iOS:
      // O iOS não usa o mesmo modelo de permissões do Android para BLE. Na prática,
      // a autorização efetiva vem do CoreBluetooth (e alguns plugins + permission_handler
      // podem reportar “denied” mesmo com o toggle ligado em Ajustes).
      // Então: no iOS, validamos via UniversalBle.getBluetoothAvailabilityState().
      if (Platform.isIOS) {
        final state = await UniversalBle.getBluetoothAvailabilityState();
        debugPrint('iOS bluetooth availability state: ${state.name}');

        if (state == AvailabilityState.unauthorized) {
          status = FlowStatus.error;
          errorMessage = 'Permissão de Bluetooth negada.';
          notifyListeners();
          try {
            await openAppSettings();
          } catch (e) {
            debugPrint('openAppSettings failed: $e');
          }
          return false;
        }

        // poweredOff/unsupported já é tratado antes do scan em _refreshAdapterState().
        return true;
      }

      // Android 12+: bluetoothScan/connect. Android <12: location.
      final req = <Permission>[Permission.bluetoothScan, Permission.bluetoothConnect, Permission.locationWhenInUse];

      final results = await req.request();
      debugPrint('Permission results: ${results.entries.map((e) => '${e.key}:${e.value}').join(', ')}');

      final deniedEntries = results.entries.where((e) => !isOk(e.value)).toList();
      if (deniedEntries.isNotEmpty) {
        debugPrint('Denied permissions: ${deniedEntries.map((e) => '${e.key}:${e.value}').join(', ')}');

        status = FlowStatus.error;
        errorMessage = 'Permissões de Bluetooth/Localização negadas.';
        notifyListeners();

        final anyPermanent = deniedEntries.any((e) => e.value.isPermanentlyDenied || e.value.isRestricted);
        if (anyPermanent) {
          try {
            await openAppSettings();
          } catch (e) {
            debugPrint('openAppSettings failed: $e');
          }
        }
        return false;
      }
      return true;
    } catch (e) {
      debugPrint('Permissions request error: $e');
      status = FlowStatus.error;
      errorMessage = 'Falha ao solicitar permissões.';
      notifyListeners();
      return false;
    } finally {
      if (status == FlowStatus.requestingPermissions) {
        status = FlowStatus.idle;
        notifyListeners();
      }
    }
  }

  Future<void> startScan() async {
    errorMessage = null;
    if (kIsWeb) {
      status = FlowStatus.error;
      errorMessage = 'BLE não está disponível no Preview Web. Para usar BLE, rode em Android/iOS.';
      notifyListeners();
      return;
    }

    await _refreshAdapterState();
    if (status == FlowStatus.bluetoothOff) return;

    final ok = await ensurePermissions();
    if (!ok) return;

    status = FlowStatus.scanning;
    devices = const [];
    notifyListeners();
    try {
      await _ble.startScan();
    } catch (e) {
      debugPrint('startScan error: $e');
      status = FlowStatus.error;
      errorMessage = 'Não foi possível iniciar a busca.';
      notifyListeners();
    }
  }

  Future<void> stopScan() async {
    try {
      await _ble.stopScan();
    } catch (e) {
      debugPrint('stopScan error: $e');
    }
  }

  Future<void> connectTo(DiscoveredDevice device) async {
    selected = device;
    initialReadDone = false;
    isConnected = false;
    status = FlowStatus.connecting;
    errorMessage = null;
    notifyListeners();

    try {
      await _ble.connect(device.deviceId);
      isConnected = true;
      status = FlowStatus.connected;
      notifyListeners();
      await readConfig();
    } catch (e) {
      debugPrint('connect error: $e');
      status = FlowStatus.error;
      errorMessage = 'Erro de conexão.';
      notifyListeners();
    }
  }

  bool _looksLikeDisconnectedError(Object e) {
    final s = e.toString().toLowerCase();
    return s.contains('disconnected') || s.contains('not connected') || s.contains('connection') || s.contains('device not found');
  }

  Future<void> _reconnectToSelected() async {
    final device = selected;
    if (device == null) return;

    status = FlowStatus.connecting;
    errorMessage = null;
    notifyListeners();

    try {
      // Garante uma desconexão limpa antes de reconectar (tolerante a falhas).
      await _ble.disconnect();
      await _ble.connect(device.deviceId);
      isConnected = true;
      status = FlowStatus.connected;
      notifyListeners();
    } catch (e) {
      debugPrint('reconnect error: $e');
      isConnected = false;
      status = FlowStatus.error;
      errorMessage = 'Não foi possível reconectar ao dispositivo.';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> disconnect() async {
    status = FlowStatus.idle;
    errorMessage = null;
    initialReadDone = false;
    isConnected = false;
    selected = null;
    notifyListeners();
    await _ble.disconnect();
  }

  /// Lê a configuração do dispositivo selecionado.
  ///
  /// Se [attemptReconnect] for true e o app estiver desconectado (ex.: após reboot do ESP32),
  /// tenta reconectar automaticamente antes de ler.
  Future<void> readConfig({bool attemptReconnect = false}) async {
    final device = selected;
    if (device == null) return;

    Future<void> runReadOnce() async {
      status = FlowStatus.reading;
      errorMessage = null;
      notifyListeners();
      final raw = await _ble.readConfigJson(device.deviceId);
      final obj = await _ble.parseJsonObject(raw);
      config = SensorConfig.fromBleJson(obj);
      lastReportedModoWifi = config.modoWifi;
      fieldErrors = SensorConfigValidator.validate(config);
      initialReadDone = true;
      deviceReadRevision++;
      status = FlowStatus.ready;
      notifyListeners();
    }

    // 1) Se o usuário pediu para "ler novamente" e já estamos marcados como desconectados,
    // tenta reconectar antes do primeiro read.
    if (attemptReconnect && !isConnected) {
      try {
        await _reconnectToSelected();
      } catch (_) {
        return;
      }
    }

    try {
      await runReadOnce();
    } on FormatException {
      status = FlowStatus.error;
      errorMessage = 'Não foi possível interpretar a configuração do sensor.';
      notifyListeners();
    } catch (e) {
      debugPrint('readConfig error: $e');

      // Caso clássico: o ESP32 reinicia e o stack BLE fica num estado "meio conectado".
      // Nessa situação, o read falha, mas o usuário ainda está na mesma tela.
      // Se o usuário apertou "Ler novamente", tentamos 1x reconectar e repetir o read.
      final shouldRetryByReconnect = attemptReconnect && (_looksLikeDisconnectedError(e) || isConnected);
      if (shouldRetryByReconnect) {
        debugPrint('readConfig: tentando reconectar e repetir leitura...');
        try {
          isConnected = false;
          await _reconnectToSelected();
          await runReadOnce();
          return;
        } catch (e2) {
          debugPrint('readConfig retry after reconnect failed: $e2');
        }
      }

      if (_looksLikeDisconnectedError(e)) isConnected = false;
      status = FlowStatus.error;
      errorMessage = 'Erro de leitura.';
      notifyListeners();
    }
  }

  void updateConfig(SensorConfig next) {
    // Regra: quando Wi‑Fi está ativo, modo_pareado deve ser sempre false.
    // Isso garante consistência mesmo se algum widget tentar habilitar indevidamente.
    if (next.modoWifi && next.modoPareado) next = next.copyWith(modoPareado: false);
    config = next;
    fieldErrors = SensorConfigValidator.validate(config);
    notifyListeners();
  }

  bool get canEdit => initialReadDone && isConnected && status != FlowStatus.saving;
  bool get canSave => canEdit && fieldErrors.isEmpty;

  Future<bool> saveConfig() async {
    final device = selected;
    if (device == null) return false;
    fieldErrors = SensorConfigValidator.validate(config);
    if (fieldErrors.isNotEmpty) {
      notifyListeners();
      return false;
    }

    status = FlowStatus.saving;
    errorMessage = null;
    notifyListeners();
    try {
      await _ble.writeConfigJson(device.deviceId, config.toBleSaveCompactJsonString());
      status = FlowStatus.saved;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('saveConfig error: $e');
      status = FlowStatus.error;
      errorMessage = 'Erro de gravação.';
      notifyListeners();
      return false;
    } finally {
      // após um curto intervalo, volta para "ready"
      if (status == FlowStatus.saved) {
        Future<void>.delayed(const Duration(milliseconds: 900), () {
          if (status == FlowStatus.saved) {
            status = FlowStatus.ready;
            notifyListeners();
          }
        });
      }
    }
  }

  Future<bool> requestFirmwareUpdate() async {
    final device = selected;
    if (device == null) return false;

    status = FlowStatus.saving;
    errorMessage = null;
    notifyListeners();

    try {
      await _ble.writeConfigJson(device.deviceId, '{"update":true}');
      status = FlowStatus.saved;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('requestFirmwareUpdate error: $e');
      status = FlowStatus.error;
      errorMessage = 'Erro ao solicitar atualização de firmware.';
      notifyListeners();
      return false;
    } finally {
      if (status == FlowStatus.saved) {
        Future<void>.delayed(const Duration(milliseconds: 900), () {
          if (status == FlowStatus.saved) {
            status = FlowStatus.ready;
            notifyListeners();
          }
        });
      }
    }
  }

  Future<bool> requestFactoryReset() async {
    final device = selected;
    if (device == null) return false;

    status = FlowStatus.saving;
    errorMessage = null;
    notifyListeners();

    try {
      await _ble.writeConfigJson(device.deviceId, '{"reset":"true"}');
      status = FlowStatus.saved;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('requestFactoryReset error: $e');
      status = FlowStatus.error;
      errorMessage = 'Erro ao solicitar reset de fábrica.';
      notifyListeners();
      return false;
    } finally {
      if (status == FlowStatus.saved) {
        Future<void>.delayed(const Duration(milliseconds: 900), () {
          if (status == FlowStatus.saved) {
            status = FlowStatus.ready;
            notifyListeners();
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _scanSub?.cancel();
    unawaited(_ble.dispose());
    super.dispose();
  }
}
