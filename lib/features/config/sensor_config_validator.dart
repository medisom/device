import 'package:medisom_device/features/config/sensor_config.dart';

class SensorConfigValidator {
  static Map<String, String> validate(SensorConfig c) {
    final errors = <String, String>{};

    if (c.nome.trim().isEmpty) errors['nome'] = 'Obrigatório.';
    if (c.nome.trim().length > 20) errors['nome'] = 'Máximo de 20 caracteres.';

    if (c.ponderacao != 'dBA' && c.ponderacao != 'dBC') errors['ponderacao'] = 'Selecione dBA ou dBC.';
    if (c.spectrum != 'dBA' && c.spectrum != 'dBC') errors['spectrum'] = 'Selecione dBA ou dBC.';

    if (c.dia < 40 || c.dia > 130) errors['dia'] = 'Valor entre 40 e 130.';
    if (c.tempoLeq < 1 || c.tempoLeq > 5) errors['tempo_leq'] = 'Valor entre 1 e 5 segundos.';
    if (c.ajuste < 0.0 || c.ajuste > 3.0) errors['ajuste'] = 'Valor entre 0.0 e 3.0.';

    if (c.limitePercentual < 1 || c.limitePercentual > 30) errors['limitePercentual'] = 'Valor entre 1 e 30.';
    if (c.percentualMovel < 0 || c.percentualMovel > 15) errors['percentual_movel'] = 'Valor entre 0 e 15.';

    if (c.modoWifi) {
      if ((c.ssid ?? '').trim().isEmpty) errors['ssid'] = 'Obrigatório para WiFi.';
      if ((c.password ?? '').trim().isEmpty) errors['password'] = 'Obrigatório para WiFi.';
    }

    return errors;
  }
}
