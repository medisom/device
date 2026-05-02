import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:medisom_device/app/device_controller.dart';
import 'package:medisom_device/features/ble/ble_models.dart';
import 'package:medisom_device/features/config/widgets/config_form.dart';
import 'package:medisom_device/theme.dart';

class ConfigPage extends StatelessWidget {
  const ConfigPage({super.key, required this.device});
  final DiscoveredDevice device;

  Future<bool?> _showFactoryResetConfirmSheet(BuildContext context) => showModalBottomSheet<bool>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (ctx) {
      final scheme = Theme.of(ctx).colorScheme;
      final bottomInset = MediaQuery.of(ctx).viewInsets.bottom;
      final maxHeight = MediaQuery.of(ctx).size.height * 0.90;
      return SafeArea(
        child: Padding(
          padding: EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 16 + bottomInset),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Reset padrão de fábrica', style: ctx.textStyles.titleMedium),
                  const SizedBox(height: AppSpacing.sm),
                  Card(
                    color: scheme.errorContainer,
                    child: Padding(
                      padding: AppSpacing.paddingMd,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.warning_amber_rounded, color: scheme.onErrorContainer),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Text(
                              'Este comando irá restaurar o dispositivo para as configurações de fábrica e pode reiniciar o ESP32. Use apenas se tiver certeza.',
                              style: ctx.textStyles.bodyMedium?.withColor(scheme.onErrorContainer),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(ctx).pop(false),
                          child: const Text('Cancelar'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(backgroundColor: scheme.error, foregroundColor: scheme.onError),
                          onPressed: () => Navigator.of(ctx).pop(true),
                          icon: Icon(Icons.restart_alt, color: scheme.onError),
                          label: const Text('Resetar'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );

  @override
  Widget build(BuildContext context) {
    final c = context.watch<DeviceController>();
    final scheme = Theme.of(context).colorScheme;

    Future<void> leavePage() async {
      await c.disconnect();
      if (context.mounted) context.pop();
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await leavePage();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            tooltip: 'Voltar',
            onPressed: () => leavePage(),
            icon: Icon(Icons.arrow_back, color: scheme.onSurface),
          ),
          title: Text(
            device.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.textStyles.titleMedium?.semiBold,
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.md),
              child: _ConnectionBadge(connected: c.isConnected, status: c.status),
            ),
          ],
        ),
        body: SafeArea(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
            child: ListView(
              padding: AppSpacing.paddingLg,
              children: [
              const SizedBox(height: AppSpacing.sm),
            if (c.errorMessage != null)
              Card(
                color: scheme.errorContainer,
                child: Padding(
                  padding: AppSpacing.paddingMd,
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: scheme.onErrorContainer),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(child: Text(c.errorMessage!, style: context.textStyles.bodyMedium?.withColor(scheme.onErrorContainer))),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: Tooltip(
                    message: 'Ler novamente',
                    child: Semantics(
                      button: true,
                      label: 'Ler novamente',
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: scheme.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          minimumSize: const Size.fromHeight(48),
                          foregroundColor: scheme.onPrimary,
                          disabledBackgroundColor: scheme.primary.withValues(alpha: 0.45),
                          disabledForegroundColor: scheme.onSurface.withValues(alpha: 0.5),
                        ),
                        onPressed: (c.status == FlowStatus.reading || c.status == FlowStatus.connecting) ? null : () => c.readConfig(attemptReconnect: true),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 180),
                          switchInCurve: Curves.easeOut,
                          switchOutCurve: Curves.easeIn,
                          transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: child),
                          child: (c.status == FlowStatus.reading || c.status == FlowStatus.connecting)
                              ? SizedBox(
                                  key: const ValueKey('spin'),
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: scheme.onPrimary),
                                )
                              : Icon(key: const ValueKey('icon'), Icons.refresh_rounded, size: 24, color: scheme.onPrimary),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Tooltip(
                    message: 'Desconectar',
                    child: Semantics(
                      button: true,
                      label: 'Desconectar',
                      child: FilledButton(
                        style: FilledButton.styleFrom(backgroundColor: scheme.surfaceContainerHighest, padding: const EdgeInsets.symmetric(vertical: 14), minimumSize: const Size.fromHeight(48)),
                        onPressed: () async {
                          await leavePage();
                        },
                        child: Icon(Icons.logout_rounded, size: 24, color: scheme.onSurface),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            ConfigForm(enabled: c.canEdit),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton.icon(
              onPressed: c.canSave
                  ? () async {
                      final ok = await c.saveConfig();
                      if (!context.mounted) return;
                      if (ok) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Configurações enviadas! O dispositivo irá reiniciar.')),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Revise os campos antes de salvar.')),
                        );
                      }
                    }
                  : null,
              icon: Icon(Icons.save, color: scheme.onPrimary),
              label: c.status == FlowStatus.saving ? const _SavingLabel() : const Text('Salvar'),
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: scheme.error, foregroundColor: scheme.onError),
              onPressed: (!c.isConnected || c.status == FlowStatus.saving)
                  ? null
                  : () async {
                      final confirm = await _showFactoryResetConfirmSheet(context);
                      if (confirm != true) return;
                      if (!context.mounted) return;
                      final ok = await c.requestFactoryReset();
                      if (!context.mounted) return;
                      if (ok) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Comando de reset de fábrica enviado. O dispositivo pode reiniciar.')),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(c.errorMessage ?? 'Falha ao enviar reset de fábrica.')),
                        );
                      }
                    },
              icon: Icon(Icons.restart_alt, color: scheme.onError),
              label: const Text('Reset Padrão de Fábrica'),
            ),
            const SizedBox(height: AppSpacing.md),
            if (!c.initialReadDone)
              Text(
                'A edição fica disponível após a leitura inicial.',
                style: context.textStyles.bodySmall?.withColor(scheme.onSurfaceVariant),
              ),
            ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SavingLabel extends StatelessWidget {
  const _SavingLabel();

  @override
  Widget build(BuildContext context) {
    final fg = Theme.of(context).colorScheme.onPrimary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: fg)),
        const SizedBox(width: 10),
        const Text('Salvando…'),
      ],
    );
  }
}

class _ConnectionBadge extends StatelessWidget {
  const _ConnectionBadge({required this.connected, required this.status});
  final bool connected;
  final FlowStatus status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isConnecting = status == FlowStatus.connecting || status == FlowStatus.reading;
    final label = connected ? (isConnecting ? 'Conectando…' : 'Conectado') : 'Desconectado';
    final bg = connected ? scheme.primary.withValues(alpha: 0.18) : scheme.surfaceContainerHighest;
    final fg = connected ? scheme.primary : scheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999), border: Border.all(color: fg.withValues(alpha: 0.35))),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(connected ? Icons.bluetooth_connected : Icons.bluetooth_disabled, size: 16, color: fg),
          const SizedBox(width: 6),
          Text(label, style: context.textStyles.labelMedium?.withColor(fg)),
        ],
      ),
    );
  }
}
