/// Structured care field vocabularies (Care System spec: "Structured +
/// notes"). Stored in the DB by enum name; free text lives in
/// `Plant.careNotes`.
enum LightingLevel { lowLight, mediumIndirect, brightIndirect, fullSun }

enum WateringLevel { low, moderate, frequent }

enum SoilKind { allPurpose, wellDraining, cactusMix, orchidMix }
