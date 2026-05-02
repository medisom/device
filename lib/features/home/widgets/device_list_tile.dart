import 'package:flutter/material.dart';
import 'package:medisom_device/features/ble/ble_models.dart';
import 'package:medisom_device/theme.dart';

class DeviceListTile extends StatelessWidget {
  const DeviceListTile({super.key, required this.device, required this.onTap});
  final DiscoveredDevice device;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final rssi = device.rssi;
    final bars = _barsForRssi(rssi);
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: AppSpacing.paddingMd,
          child: Row(
            children: [
              Icon(Icons.sensors, color: scheme.primary),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(device.name, style: context.textStyles.titleMedium),
                    const SizedBox(height: AppSpacing.xs),
                    Text(device.deviceId, style: context.textStyles.bodySmall?.withColor(scheme.onSurfaceVariant), overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Icon(_iconForBars(bars), color: scheme.onSurfaceVariant),
                  const SizedBox(height: 2),
                  Text(rssi == null ? '— dBm' : '$rssi dBm', style: context.textStyles.labelSmall?.withColor(scheme.onSurfaceVariant)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  int _barsForRssi(int? rssi) {
    if (rssi == null) return 0;
    if (rssi >= -60) return 3;
    if (rssi >= -75) return 2;
    if (rssi >= -90) return 1;
    return 0;
  }

  IconData _iconForBars(int bars) {
    switch (bars) {
      case 3:
        return Icons.signal_cellular_alt;
      case 2:
        return Icons.signal_cellular_alt_2_bar;
      case 1:
        return Icons.signal_cellular_alt_1_bar;
      default:
        return Icons.signal_cellular_0_bar;
    }
  }
}
