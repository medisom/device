import 'package:flutter/foundation.dart';

@immutable
class DiscoveredDevice {
  const DiscoveredDevice({required this.deviceId, required this.name, this.rssi});
  final String deviceId;
  final String name;
  final int? rssi;

  @override
  bool operator ==(Object other) => other is DiscoveredDevice && other.deviceId == deviceId;

  @override
  int get hashCode => deviceId.hashCode;
}

enum ConnectionBadge { disconnected, scanning, connecting, connected }

enum FlowStatus {
  idle,
  bluetoothOff,
  requestingPermissions,
  scanning,
  deviceFound,
  connecting,
  connected,
  reading,
  ready,
  saving,
  saved,
  error,
}

extension FlowStatusUi on FlowStatus {
  String get label {
    switch (this) {
      case FlowStatus.idle:
        return 'Pronto';
      case FlowStatus.bluetoothOff:
        return 'Bluetooth desligado';
      case FlowStatus.requestingPermissions:
        return 'Solicitando permissões';
      case FlowStatus.scanning:
        return 'Procurando sensores';
      case FlowStatus.deviceFound:
        return 'Sensor encontrado';
      case FlowStatus.connecting:
        return 'Conectando';
      case FlowStatus.connected:
        return 'Conectado';
      case FlowStatus.reading:
        return 'Lendo configuração';
      case FlowStatus.ready:
        return 'Pronto para editar';
      case FlowStatus.saving:
        return 'Salvando';
      case FlowStatus.saved:
        return 'Configurações enviadas';
      case FlowStatus.error:
        return 'Erro';
    }
  }
}
