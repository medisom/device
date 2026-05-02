import 'package:flutter/material.dart';
import 'package:medisom_device/features/ble/ble_models.dart';
import 'package:medisom_device/theme.dart';

class StatusPanel extends StatelessWidget {
  const StatusPanel({super.key, required this.status, required this.errorMessage, required this.deviceCount});

  final FlowStatus status;
  final String? errorMessage;
  final int deviceCount;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isError = status == FlowStatus.error;
    final bg = isError ? scheme.errorContainer : scheme.surfaceContainerHighest;
    final fg = isError ? scheme.onErrorContainer : scheme.onSurface;

    return Card(
      color: bg,
      child: Padding(
        padding: AppSpacing.paddingMd,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(isError ? Icons.warning_amber_rounded : Icons.bluetooth_searching, color: fg),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(status.label, style: context.textStyles.titleMedium?.withColor(fg)),
                  const SizedBox(height: AppSpacing.xs),
                  if (errorMessage != null)
                    Text(errorMessage!, style: context.textStyles.bodyMedium?.withColor(fg.withValues(alpha: 0.9)))
                  else
                    Text(
                      deviceCount == 0 ? 'Nenhum sensor selecionado.' : '$deviceCount compatível(is) encontrado(s).',
                      style: context.textStyles.bodyMedium?.withColor(fg.withValues(alpha: 0.85)),
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
