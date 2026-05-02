import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import 'package:medisom_device/app/device_controller.dart';
import 'package:medisom_device/theme.dart';

class ConfigForm extends StatefulWidget {
  const ConfigForm({super.key, required this.enabled});
  final bool enabled;

  @override
  State<ConfigForm> createState() => _ConfigFormState();
}

class _ConfigFormState extends State<ConfigForm> {
  final _fwVersionCtrl = TextEditingController();
  final _nomeCtrl = TextEditingController();
  final _ssidCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _diaCtrl = TextEditingController();
  final _tempoLeqCtrl = TextEditingController();
  final _ajusteCtrl = TextEditingController();
  final _limitePercentualCtrl = TextEditingController();
  final _percentualMovelCtrl = TextEditingController();

  bool _showPassword = false;
  bool _didInit = false;
  int _syncedDeviceReadRevision = -1;

  bool _firmwareBusy = false;

  InputDecoration _dec(String label, {String? errorText, Widget? suffixIcon}) => InputDecoration(
    // IMPORTANTE: `labelText` costuma truncar com "…" em telas estreitas.
    // Usamos `label` como Widget para permitir quebra de linha.
    label: Text(label, softWrap: true, maxLines: 3, overflow: TextOverflow.visible),
    alignLabelWithHint: true,
    errorText: errorText,
    suffixIcon: suffixIcon,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // IMPORTANTE: não use `watch()` aqui para não ressincronizar controllers a cada
    // `notifyListeners()` disparado por onChanged (isso quebra o cursor/teclado).
    // Em vez disso, sincronizamos apenas quando houver um READ do dispositivo.
    final deviceReadRevision = context.select((DeviceController c) => c.deviceReadRevision);
    if (!_didInit || deviceReadRevision != _syncedDeviceReadRevision) {
      final c = context.read<DeviceController>();
      final cfg = c.config;
      _didInit = true;
      _syncedDeviceReadRevision = deviceReadRevision;

      _fwVersionCtrl.text = cfg.fwVersion?.trim().isNotEmpty == true ? cfg.fwVersion!.trim() : '—';
      _nomeCtrl.text = cfg.nome;
      _ssidCtrl.text = cfg.ssid ?? '';
      _passwordCtrl.text = cfg.password ?? '';
      _diaCtrl.text = cfg.dia.toString();
      _tempoLeqCtrl.text = cfg.tempoLeq.toString();
      _ajusteCtrl.text = cfg.ajuste.toStringAsFixed(1);
      _limitePercentualCtrl.text = cfg.limitePercentual.toString();
      _percentualMovelCtrl.text = cfg.percentualMovel.toString();
    }
  }

  @override
  void dispose() {
    _fwVersionCtrl.dispose();
    _nomeCtrl.dispose();
    _ssidCtrl.dispose();
    _passwordCtrl.dispose();
    _diaCtrl.dispose();
    _tempoLeqCtrl.dispose();
    _ajusteCtrl.dispose();
    _limitePercentualCtrl.dispose();
    _percentualMovelCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<DeviceController>();
    final cfg = c.config;
    final errors = c.fieldErrors;
    final scheme = Theme.of(context).colorScheme;
    final connectivityMatchesDevice = c.lastReportedModoWifi == null || c.lastReportedModoWifi == cfg.modoWifi;

    return Column(
      children: [
        _SectionCard(
          title: '1. Dispositivo',
          subtitle: 'Identificação e local de instalação.',
          child: Column(
            children: [
              _ReadOnlyField(labelText: 'Número de série (token)', value: cfg.token),
              const SizedBox(height: AppSpacing.md),
              _ReadOnlyField(labelText: 'Versão de firmware', controller: _fwVersionCtrl),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _nomeCtrl,
                enabled: widget.enabled,
                maxLength: 20,
                decoration: _dec('Local (nome)', errorText: errors['nome']),
                onChanged: (v) => c.updateConfig(cfg.copyWith(nome: v)),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _SectionCard(
          title: '2. Conectividade',
          subtitle: 'Selecione o modo e, se necessário, informe credenciais.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Tipo de conexão', style: context.textStyles.labelLarge?.withColor(scheme.onSurfaceVariant)),
              const SizedBox(height: AppSpacing.sm),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: true, label: Text('WiFi'), icon: Icon(Icons.wifi)),
                  ButtonSegment(value: false, label: Text('4G'), icon: Icon(Icons.network_cell)),
                ],
                selected: {cfg.modoWifi},
                onSelectionChanged: widget.enabled
                    ? (s) {
                        final modoWifi = s.first;
                        c.updateConfig(
                          cfg.copyWith(
                            modoWifi: modoWifi,
                            ssid: modoWifi ? cfg.ssid : null,
                            password: modoWifi ? cfg.password : null,
                            // Wi‑Fi selecionado => modo pareado forçado para false.
                            modoPareado: modoWifi ? false : cfg.modoPareado,
                          ),
                        );
                      }
                    : null,
              ),
              const SizedBox(height: AppSpacing.md),
              _ProtocolBanner(
                modoWifi: cfg.modoWifi,
                simcardRemoved: cfg.simcardRemoved,
                fourGLabel: 'Protocolo 4G (LTE-FDD)',
                showSimWarning: true,
                internet: connectivityMatchesDevice ? cfg.internet : null,
                showInternetStatus: connectivityMatchesDevice,
              ),
              if (!cfg.modoWifi) ...[
                // Extra breathing room between protocol banner and cellular info fields.
                const SizedBox(height: AppSpacing.md),
                _CellularInfoPanel(
                  simcardRemoved: cfg.simcardRemoved,
                  iccid: cfg.iccid,
                  signalPercent: cfg.signalPercent,
                ),
              ],

              // O status de internet recebido do ESP32 reflete o modo atual dele.
              // Se o usuário alternar o modo no formulário, escondemos o botão
              // até que o modo selecionado volte a bater com o último READ.
              if (cfg.internet == true && connectivityMatchesDevice) ...[
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: scheme.primary,
                      foregroundColor: scheme.onPrimary,
                    ),
                    onPressed: (!widget.enabled || _firmwareBusy) ? null : () => _startFirmwareUpdateFlow(c),
                    icon: const Icon(Icons.system_update_alt),
                    label: Text(_firmwareBusy ? 'Verificando…' : 'Atualizar firmware'),
                  ),
                ),
              ],

              const SizedBox(height: AppSpacing.md),
              if (cfg.modoWifi) ...[
                TextFormField(
                  controller: _ssidCtrl,
                  enabled: widget.enabled,
                  keyboardType: TextInputType.text,
                  textCapitalization: TextCapitalization.none,
                  autocorrect: false,
                  enableSuggestions: false,
                  smartDashesType: SmartDashesType.disabled,
                  smartQuotesType: SmartQuotesType.disabled,
                  decoration: _dec('SSID', errorText: errors['ssid']),
                  onChanged: (v) => c.updateConfig(cfg.copyWith(ssid: v)),
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _passwordCtrl,
                  enabled: widget.enabled,
                  obscureText: !_showPassword,
                  keyboardType: TextInputType.visiblePassword,
                  textCapitalization: TextCapitalization.none,
                  autocorrect: false,
                  enableSuggestions: false,
                  smartDashesType: SmartDashesType.disabled,
                  smartQuotesType: SmartQuotesType.disabled,
                  decoration: _dec(
                    'Senha',
                    errorText: errors['password'],
                    suffixIcon: IconButton(
                      onPressed: widget.enabled ? () => setState(() => _showPassword = !_showPassword) : null,
                      icon: Icon(_showPassword ? Icons.visibility_off : Icons.visibility, color: scheme.onSurfaceVariant),
                    ),
                  ),
                  onChanged: (v) => c.updateConfig(cfg.copyWith(password: v)),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _SectionCard(
          title: '3. Parâmetros da medição',
          subtitle: 'Ajustes operacionais do sensor.',
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: DropdownMenu<String>(
                      key: ValueKey('ponderacao_${cfg.ponderacao}'),
                      enabled: widget.enabled,
                      initialSelection: cfg.ponderacao,
                      label: const Text('Ponderação'),
                      errorText: errors['ponderacao'],
                      dropdownMenuEntries: const [
                        DropdownMenuEntry(value: 'dBA', label: 'dBA'),
                        DropdownMenuEntry(value: 'dBC', label: 'dBC'),
                      ],
                      onSelected: (v) => c.updateConfig(cfg.copyWith(ponderacao: (v ?? 'dBA'))),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: DropdownMenu<String>(
                      key: ValueKey('spectrum_${cfg.spectrum}'),
                      enabled: widget.enabled,
                      initialSelection: cfg.spectrum,
                      label: const Text('Frequências'),
                      errorText: errors['spectrum'],
                      dropdownMenuEntries: const [
                        DropdownMenuEntry(value: 'dBA', label: 'dBA'),
                        DropdownMenuEntry(value: 'dBC', label: 'dBC'),
                      ],
                      onSelected: (v) => c.updateConfig(cfg.copyWith(spectrum: (v ?? 'dBA'))),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _diaCtrl,
                      enabled: widget.enabled,
                      keyboardType: TextInputType.number,
                      decoration: _dec('Limite (${cfg.ponderacao})', errorText: errors['dia']),
                      onChanged: (v) => c.updateConfig(cfg.copyWith(dia: int.tryParse(v) ?? cfg.dia)),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _IntStepper(
                      enabled: widget.enabled,
                      value: cfg.dia,
                      min: 40,
                      max: 130,
                      onChanged: (v) {
                        _diaCtrl.text = v.toString();
                        c.updateConfig(cfg.copyWith(dia: v));
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _tempoLeqCtrl,
                      enabled: widget.enabled,
                      keyboardType: TextInputType.number,
                      decoration: _dec('Leq (seg)', errorText: errors['tempo_leq']),
                      onChanged: (v) => c.updateConfig(cfg.copyWith(tempoLeq: int.tryParse(v) ?? cfg.tempoLeq)),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _IntStepper(
                      enabled: widget.enabled,
                      value: cfg.tempoLeq,
                      min: 1,
                      max: 5,
                      onChanged: (v) {
                        _tempoLeqCtrl.text = v.toString();
                        c.updateConfig(cfg.copyWith(tempoLeq: v));
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _ajusteCtrl,
                      enabled: widget.enabled,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: false),
                      decoration: _dec('Calibração', errorText: errors['ajuste']),
                      onChanged: (v) => c.updateConfig(cfg.copyWith(ajuste: double.tryParse(v.replaceAll(',', '.')) ?? cfg.ajuste)),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _AjusteStepper(
                      enabled: widget.enabled,
                      value: cfg.ajuste,
                      onChanged: (v) {
                        _ajusteCtrl.text = v.toStringAsFixed(1);
                        c.updateConfig(cfg.copyWith(ajuste: v));
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _SectionCard(
          title: '4. Percentual Acima do Limite',
          subtitle: 'Disparo/estatística por variação acima do limite configurado.',
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 420;
              final leftField = TextFormField(
                controller: _limitePercentualCtrl,
                enabled: widget.enabled,
                keyboardType: TextInputType.number,
                decoration: _dec('Percentual acima do limite (%) (1–30)', errorText: errors['limitePercentual']),
                onChanged: (v) => c.updateConfig(cfg.copyWith(limitePercentual: int.tryParse(v) ?? cfg.limitePercentual)),
              );

              final rightField = TextFormField(
                controller: _percentualMovelCtrl,
                enabled: widget.enabled,
                keyboardType: TextInputType.number,
                decoration: _dec('Percentual médio (minutos) (0–15)', errorText: errors['percentual_movel']),
                onChanged: (v) => c.updateConfig(cfg.copyWith(percentualMovel: int.tryParse(v) ?? cfg.percentualMovel)),
              );

              if (isNarrow) {
                return Column(
                  children: [
                    leftField,
                    const SizedBox(height: AppSpacing.md),
                    rightField,
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: leftField),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: rightField),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _SectionCard(
          title: '5. Comunicação com Monitor',
          subtitle: 'Parâmetros de protocolo e pareamento.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Protocolo', style: context.textStyles.labelLarge?.withColor(scheme.onSurfaceVariant)),
              const SizedBox(height: AppSpacing.sm),
              _ProtocolBanner(
                modoWifi: cfg.modoWifi,
                simcardRemoved: cfg.simcardRemoved,
                dense: true,
                fourGLabel: 'Protocolo Long Range (LR)',
                showSimWarning: false,
              ),
              const SizedBox(height: AppSpacing.md),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: cfg.modoPareado,
                onChanged: (widget.enabled && !cfg.modoWifi) ? (v) => c.updateConfig(cfg.copyWith(modoPareado: v)) : null,
                title: Text('Modo Pareado', style: context.textStyles.titleSmall),
                subtitle: Text(
                  cfg.modoWifi ? 'Disponível somente em 4G (Long Range).' : 'Habilita comunicação pareada com o monitor.',
                  style: context.textStyles.bodySmall?.withColor(scheme.onSurfaceVariant),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _startFirmwareUpdateFlow(DeviceController c) async {
    // 1) Popup padrão de advertência
    final proceed = await _showConfirmSheet(
      context,
      title: 'Atualização de firmware',
      message:
          'A atualização de firmware pode levar alguns minutos e pode interromper temporariamente a comunicação com o dispositivo.\n\nGaranta alimentação estável e não feche o app durante o processo.',
      confirmLabel: 'Entendi, continuar',
    );
    if (!mounted) return;
    if (proceed != true) return;

    setState(() => _firmwareBusy = true);
    try {
      final localRaw = (c.config.fwVersion ?? '').trim();
      final local = int.tryParse(localRaw);
      if (local == null) {
        await _showInfoSheet(context, title: 'Versão inválida', message: 'Não foi possível interpretar a versão atual do firmware do ESP32: "$localRaw".');
        return;
      }

      final latest = await _fetchLatestFirmwareVersion();
      if (!mounted) return;
      if (latest == null) {
        await _showInfoSheet(context, title: 'Falha ao verificar', message: 'Não foi possível obter a versão mais recente disponível.');
        return;
      }

      if (local >= latest) {
        await _showInfoSheet(context, title: 'Firmware atualizado', message: 'O dispositivo já está na versão mais recente.\n\nAtual: $local\nDisponível: $latest');
        return;
      }

      // 2) Confirmação final (comparação)
      final confirmUpdate = await _showConfirmSheet(
        context,
        title: 'Nova versão disponível',
        message: 'Atual: $local\nDisponível: $latest\n\nDeseja iniciar a atualização agora?',
        confirmLabel: 'Iniciar atualização',
      );
      if (!mounted) return;
      if (confirmUpdate != true) return;

      final ok = await c.requestFirmwareUpdate();
      if (!mounted) return;
      if (ok) {
        await _showInfoSheet(
          context,
          title: 'Comando enviado',
          message: 'O comando de atualização foi enviado ao ESP32. Aguarde a finalização do processo.',
        );
      } else {
        await _showInfoSheet(context, title: 'Falha', message: c.errorMessage ?? 'Não foi possível solicitar a atualização.');
      }
    } catch (e) {
      debugPrint('Firmware update flow error: $e');
      if (!mounted) return;
      await _showInfoSheet(context, title: 'Erro', message: 'Ocorreu um erro ao tentar atualizar o firmware.');
    } finally {
      if (mounted) setState(() => _firmwareBusy = false);
    }
  }

  Future<int?> _fetchLatestFirmwareVersion() async {
    const url = 'https://medisom.com.br/sowar_gsm_v5/version.txt';
    try {
      final res = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
      if (res.statusCode < 200 || res.statusCode >= 300) {
        debugPrint('Firmware version check failed: http ${res.statusCode}');
        return null;
      }
      final raw = res.body.trim();
      final v = int.tryParse(raw);
      if (v == null) debugPrint('Firmware version check invalid body: "$raw"');
      return v;
    } catch (e) {
      debugPrint('Firmware version check error: $e');
      return null;
    }
  }

  Future<bool?> _showConfirmSheet(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
  }) => showModalBottomSheet<bool>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (ctx) {
      final scheme = Theme.of(ctx).colorScheme;
      return _BottomSheetFrame(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: ctx.textStyles.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            Text(message, style: ctx.textStyles.bodyMedium?.withColor(scheme.onSurfaceVariant)),
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
                  child: FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: scheme.primary, foregroundColor: scheme.onPrimary),
                    onPressed: () => Navigator.of(ctx).pop(true),
                    child: Text(confirmLabel),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );

  Future<void> _showInfoSheet(
    BuildContext context, {
    required String title,
    required String message,
  }) => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (ctx) {
      final scheme = Theme.of(ctx).colorScheme;
      return _BottomSheetFrame(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: ctx.textStyles.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            Text(message, style: ctx.textStyles.bodyMedium?.withColor(scheme.onSurfaceVariant)),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(backgroundColor: scheme.primary, foregroundColor: scheme.onPrimary),
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Ok'),
              ),
            ),
          ],
        ),
      );
    },
  );
}

class _BottomSheetFrame extends StatelessWidget {
  const _BottomSheetFrame({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final maxHeight = MediaQuery.of(context).size.height * 0.90;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 16 + bottomInset),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: SingleChildScrollView(
            child: child,
          ),
        ),
      ),
    );
  }
}

class _ReadOnlyField extends StatelessWidget {
  const _ReadOnlyField({required this.labelText, this.value, this.controller}) : assert(value != null || controller != null);
  final String labelText;
  final String? value;
  final TextEditingController? controller;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return TextFormField(
      readOnly: true,
      canRequestFocus: false,
      controller: controller,
      initialValue: controller == null ? value : null,
      style: context.textStyles.bodyLarge?.withColor(scheme.onSurface.withValues(alpha: 0.92)),
      decoration: InputDecoration(
        label: Text(labelText, softWrap: true, maxLines: 3, overflow: TextOverflow.visible),
        alignLabelWithHint: true,
        // Mantém o aspecto de campo “normal”, mas sem interação.
        suffixIcon: Icon(Icons.lock_outline, size: 18, color: scheme.onSurfaceVariant),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.subtitle, required this.child});
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: AppSpacing.paddingMd,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: context.textStyles.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(subtitle, style: context.textStyles.bodySmall?.withColor(scheme.onSurfaceVariant)),
            const SizedBox(height: AppSpacing.md),
            child,
          ],
        ),
      ),
    );
  }
}

class _AjusteStepper extends StatelessWidget {
  const _AjusteStepper({required this.enabled, required this.value, required this.onChanged});
  final bool enabled;
  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final canDec = enabled && value > 0.0;
    final canInc = enabled && value < 3.0;
    return Row(
      children: [
        Expanded(
          child: FilledButton(
            onPressed: canDec ? () => onChanged(_snap((value - 0.1).clamp(0.0, 3.0))) : null,
            child: Icon(Icons.remove, color: scheme.onSurface),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: FilledButton(
            onPressed: canInc ? () => onChanged(_snap((value + 0.1).clamp(0.0, 3.0))) : null,
            child: Icon(Icons.add, color: scheme.onSurface),
          ),
        ),
      ],
    );
  }

  double _snap(double v) => double.parse(v.toStringAsFixed(1));
}

class _IntStepper extends StatelessWidget {
  const _IntStepper({required this.enabled, required this.value, required this.min, required this.max, required this.onChanged});
  final bool enabled;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final canDec = enabled && value > min;
    final canInc = enabled && value < max;
    return Row(
      children: [
        Expanded(
          child: FilledButton(
            onPressed: canDec ? () => onChanged((value - 1).clamp(min, max)) : null,
            child: Icon(Icons.remove, color: scheme.onSurface),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: FilledButton(
            onPressed: canInc ? () => onChanged((value + 1).clamp(min, max)) : null,
            child: Icon(Icons.add, color: scheme.onSurface),
          ),
        ),
      ],
    );
  }
}

class _ProtocolBanner extends StatelessWidget {
  const _ProtocolBanner({
    required this.modoWifi,
    required this.simcardRemoved,
    required this.fourGLabel,
    required this.showSimWarning,
    this.internet,
    this.showInternetStatus = false,
    this.dense = false,
  });
  final bool modoWifi;
  final bool? simcardRemoved;
  final String fourGLabel;
  final bool showSimWarning;
  final bool? internet;
  final bool showInternetStatus;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = modoWifi ? 'Protocolo Padrão (802.11 b/g/n)' : fourGLabel;
    final icon = modoWifi ? Icons.router : Icons.sensors;
    final shouldShowSimWarning = showSimWarning && !modoWifi && (simcardRemoved == true);

    final showInternetIcon = showInternetStatus;
    final internetValue = internet;
    final internetIcon = (internetValue == true)
        ? Icons.public
        : (internetValue == false)
            ? Icons.public_off
            : Icons.public_off;
    final internetColor = (internetValue == true)
        ? scheme.tertiary
        : (internetValue == false)
            ? scheme.onSurfaceVariant
            : scheme.onSurfaceVariant;

    return Container(
      width: double.infinity,
      padding: dense ? const EdgeInsets.symmetric(horizontal: 12, vertical: 10) : const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Icon(icon, color: scheme.primary, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: context.textStyles.bodyMedium?.withColor(scheme.onSurface),
                children: [
                  TextSpan(text: text),
                  if (shouldShowSimWarning)
                    TextSpan(text: '  •  SIM-card ausente ou com erro', style: context.textStyles.bodyMedium?.semiBold.withColor(scheme.error)),
                ],
              ),
            ),
          ),
          if (showInternetIcon) ...[
            const SizedBox(width: 10),
            Tooltip(
              message: internetValue == true ? 'Internet: conectado' : 'Internet: sem conexão',
              child: Icon(internetIcon, size: 18, color: internetColor),
            ),
          ],
        ],
      ),
    );
  }
}

class _CellularInfoPanel extends StatelessWidget {
  const _CellularInfoPanel({required this.simcardRemoved, required this.iccid, required this.signalPercent});

  final bool? simcardRemoved;
  final String? iccid;
  final int? signalPercent;

  @override
  Widget build(BuildContext context) {
    if (simcardRemoved == true) return const SizedBox.shrink();

    final hasIccid = (iccid ?? '').trim().isNotEmpty;
    final hasSignal = signalPercent != null;
    if (!hasIccid && !hasSignal) return const SizedBox.shrink();

    String signalText() {
      final v = signalPercent;
      if (v == null) return '—';
      if (v == 99) return 'Sinal desconhecido ou inexistente';
      return '$v%';
    }

    // Mantém o mesmo “formato de campo” do Grupo 1 (ex.: Versão de firmware):
    // label pequeno na borda + valor read-only.
    return Column(
      children: [
        if (hasIccid) _ReadOnlyField(labelText: 'Número do SIM card (ICCID)', value: iccid!.trim()),
        if (hasIccid && hasSignal) const SizedBox(height: AppSpacing.md),
        if (hasSignal) _ReadOnlyField(labelText: 'Qualidade do sinal', value: signalText()),
      ],
    );
  }
}
