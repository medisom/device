import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:medisom_device/app/device_controller.dart';
import 'package:medisom_device/features/ble/ble_models.dart';
import 'package:medisom_device/features/home/widgets/device_list_tile.dart';
import 'package:medisom_device/features/home/widgets/status_panel.dart';
import 'package:medisom_device/nav.dart';
import 'package:medisom_device/theme.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<DeviceController>();
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: Image.asset(AppAssets.logo, width: 28, height: 28, filterQuality: FilterQuality.high),
            ),
            Flexible(child: Text('Medisom Device', style: context.textStyles.titleLarge, overflow: TextOverflow.ellipsis)),
          ],
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: ListView(
          padding: AppSpacing.paddingLg,
          children: [
            Text('BLE de sensor de ruído Medisom', style: context.textStyles.bodyMedium?.withColor(Theme.of(context).colorScheme.onSurfaceVariant)),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton.icon(
              onPressed: c.status == FlowStatus.scanning ? null : () => c.startScan(),
              icon: Icon(Icons.radar, color: Theme.of(context).colorScheme.onPrimary),
              label: const Text('Buscar sensor'),
            ),
            const SizedBox(height: AppSpacing.md),
            StatusPanel(status: c.status, errorMessage: c.errorMessage, deviceCount: c.devices.length),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(child: Text('Sensores encontrados', style: context.textStyles.titleMedium)),
                if (c.status == FlowStatus.scanning)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            if (c.devices.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: Text(
                  c.status == FlowStatus.scanning ? 'Aguardando dispositivos MEDISOM_…' : 'Toque em “Buscar sensor” para iniciar.',
                  style: context.textStyles.bodyMedium?.withColor(Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              )
            else
              ...c.devices.map(
                (d) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: DeviceListTile(
                    device: d,
                    onTap: () async {
                      await c.connectTo(d);
                      if (c.isConnected && context.mounted) context.push(AppRoutes.config, extra: d);
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
