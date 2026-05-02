import 'dart:convert';

import 'package:flutter/foundation.dart';

@immutable
class SensorConfig {
  const SensorConfig({
    required this.token,
    required this.fwVersion,
    required this.nome,
    required this.modoWifi,
    required this.internet,
    required this.ssid,
    required this.password,
    required this.simcardRemoved,
    required this.iccid,
    required this.signalPercent,
    required this.ponderacao,
    required this.spectrum,
    required this.dia,
    required this.tempoLeq,
    required this.ajuste,
    required this.limitePercentual,
    required this.percentualMovel,
    required this.modoPareado,
  });

  final String token;
  /// Versão de firmware reportada pelo ESP32 no READ (somente leitura no app).
  final String? fwVersion;
  final String nome;
  final bool modoWifi;

  /// Indica se o ESP32 está com conectividade com a internet.
  /// Campo de telemetria (somente leitura no app).
  final bool? internet;
  final String? ssid;
  final String? password;

  /// Apenas no modo 4G: indica SIM-card ausente ou com erro.
  /// Campo de advertência (somente leitura no app).
  final bool? simcardRemoved;

  /// Apenas no modo 4G: ICCID do SIM-card (somente leitura no app).
  final String? iccid;

  /// Apenas no modo 4G: qualidade de sinal em % (0-100, ou 99 = desconhecido).
  /// Campo de telemetria (somente leitura no app).
  final int? signalPercent;
  final String ponderacao; // dBA | dBC
  final String spectrum; // dBA | dBC
  final int dia;
  final int tempoLeq;
  final double ajuste;
  /// Percentual acima do limite (1–30).
  final int limitePercentual;
  /// Percentual médio (0–15).
  final int percentualMovel;
  /// Comunicação com monitor em modo pareado.
  final bool modoPareado;

  factory SensorConfig.empty({String token = ''}) => SensorConfig(token: token, fwVersion: null, nome: '', modoWifi: true, internet: null, ssid: null, password: null, simcardRemoved: null, iccid: null, signalPercent: null, ponderacao: 'dBA', spectrum: 'dBA', dia: 85, tempoLeq: 3, ajuste: 1.0, limitePercentual: 10, percentualMovel: 10, modoPareado: false);

  SensorConfig copyWith({
    String? token,
    String? fwVersion,
    String? nome,
    bool? modoWifi,
    bool? internet,
    String? ssid,
    String? password,
    bool? simcardRemoved,
    String? iccid,
    int? signalPercent,
    String? ponderacao,
    String? spectrum,
    int? dia,
    int? tempoLeq,
    double? ajuste,
    int? limitePercentual,
    int? percentualMovel,
    bool? modoPareado,
  }) => SensorConfig(
    token: token ?? this.token,
    fwVersion: fwVersion ?? this.fwVersion,
    nome: nome ?? this.nome,
    modoWifi: modoWifi ?? this.modoWifi,
    internet: internet ?? this.internet,
    ssid: ssid ?? this.ssid,
    password: password ?? this.password,
    simcardRemoved: simcardRemoved ?? this.simcardRemoved,
    iccid: iccid ?? this.iccid,
    signalPercent: signalPercent ?? this.signalPercent,
    ponderacao: ponderacao ?? this.ponderacao,
    spectrum: spectrum ?? this.spectrum,
    dia: dia ?? this.dia,
    tempoLeq: tempoLeq ?? this.tempoLeq,
    ajuste: ajuste ?? this.ajuste,
    limitePercentual: limitePercentual ?? this.limitePercentual,
    percentualMovel: percentualMovel ?? this.percentualMovel,
    modoPareado: modoPareado ?? this.modoPareado,
  );

  /// Tolerante a campos ausentes; ignora tipos inesperados.
  factory SensorConfig.fromBleJson(Map<String, dynamic> json) {
    String asString(String k) => json[k] is String ? json[k] as String : '';
    String? asNullableString(String k) => json[k] is String ? json[k] as String : null;
    bool asBool(String k, {required bool fallback}) => json[k] is bool ? json[k] as bool : fallback;
    bool? asNullableBool(String k) => json[k] is bool ? json[k] as bool : null;
    int? asIntFlexible(dynamic v) {
      if (v is num) return v.toInt();
      if (v is String) {
        final s = v.trim();
        if (s.isEmpty) return null;
        return int.tryParse(s);
      }
      return null;
    }

    int asInt(String k, {required int fallback}) => asIntFlexible(json[k]) ?? fallback;
    int? asNullableInt(String k) => asIntFlexible(json[k]);
    double asDouble(String k, {required double fallback}) => json[k] is num ? (json[k] as num).toDouble() : fallback;

    final token = asString('token');
    final modoWifi = asBool('modo_wifi', fallback: true);
    return SensorConfig(
      token: token,
      fwVersion: asNullableString('fw_version'),
      nome: asString('nome'),
      modoWifi: modoWifi,
      internet: asNullableBool('internet'),
      ssid: modoWifi ? (json['ssid'] is String ? json['ssid'] as String : null) : null,
      password: modoWifi ? (json['password'] is String ? json['password'] as String : null) : null,
      simcardRemoved: modoWifi ? null : asNullableBool('simcard_removed'),
      iccid: modoWifi ? null : asNullableString('iccid'),
      signalPercent: modoWifi ? null : asNullableInt('signal_percent'),
      ponderacao: _sanitizeDbWeight(asString('ponderacao')),
      spectrum: _sanitizeDbWeight(asString('spectrum')),
      dia: asInt('dia', fallback: 85),
      tempoLeq: asInt('tempo_leq', fallback: 3),
      ajuste: asDouble('ajuste', fallback: 1.0),
      limitePercentual: asInt('limitePercentual', fallback: 10),
      percentualMovel: asInt('percentual_movel', fallback: 10),
      modoPareado: asBool('modo_pareado', fallback: false),
    );
  }

  static String _sanitizeDbWeight(String v) => (v == 'dBC') ? 'dBC' : 'dBA';

  Map<String, dynamic> toJson() => {
    'token': token,
    'nome': nome,
    'modo_wifi': modoWifi,
    'ssid': ssid,
    'password': password,
    'ponderacao': ponderacao,
    'spectrum': spectrum,
    'dia': dia,
    'tempo_leq': tempoLeq,
    'ajuste': double.parse(ajuste.toStringAsFixed(1)),
    'limitePercentual': limitePercentual,
    'percentual_movel': percentualMovel,
    'modo_pareado': modoPareado,
  };

  /// JSON para o comando SAVE no ESP32.
  ///
  /// Regras do firmware:
  /// - Todos os `int` devem ser serializados como *string* (entre aspas).
  /// - Todos os `bool` devem ser serializados como "0"/"1" (também string).
  /// - O `ajuste` (float) também deve ser serializado como *string* (entre aspas).
  Map<String, dynamic> toBleSaveJson() {
    String b(bool v) => v ? '1' : '0';
    String i(int v) => v.toString();
    String f(double v) => v.toStringAsFixed(1);

    return {
      'token': token,
      'nome': nome,
      'modo_wifi': b(modoWifi),
      'ssid': ssid,
      'password': password,
      'ponderacao': ponderacao,
      'spectrum': spectrum,
      'dia': i(dia),
      'tempo_leq': i(tempoLeq),
      'ajuste': f(ajuste),
      'limitePercentual': i(limitePercentual),
      'percentual_movel': i(percentualMovel),
      'modo_pareado': b(modoPareado),
    };
  }

  /// JSON compacto (uma linha, sem espaços) para SAVE.
  String toBleSaveCompactJsonString() => jsonEncode(toBleSaveJson());
}
