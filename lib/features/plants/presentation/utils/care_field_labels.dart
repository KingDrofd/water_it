import 'package:water_it/features/plants/domain/entities/care_profile.dart';

extension LightingLevelLabel on LightingLevel {
  String get label {
    switch (this) {
      case LightingLevel.lowLight:
        return 'Low light';
      case LightingLevel.mediumIndirect:
        return 'Medium indirect';
      case LightingLevel.brightIndirect:
        return 'Bright indirect';
      case LightingLevel.fullSun:
        return 'Full sun';
    }
  }
}

extension WateringLevelLabel on WateringLevel {
  String get label {
    switch (this) {
      case WateringLevel.low:
        return 'Low';
      case WateringLevel.moderate:
        return 'Moderate';
      case WateringLevel.frequent:
        return 'Frequent';
    }
  }
}

extension SoilKindLabel on SoilKind {
  String get label {
    switch (this) {
      case SoilKind.allPurpose:
        return 'All-purpose';
      case SoilKind.wellDraining:
        return 'Well-draining';
      case SoilKind.cactusMix:
        return 'Cactus mix';
      case SoilKind.orchidMix:
        return 'Orchid mix';
    }
  }
}
