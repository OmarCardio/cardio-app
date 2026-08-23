class RuleEngine {
  /// Évalue les facteurs de risque et renvoie les identifiants des modules correspondants
  static List<String> evaluate({
    required bool hasHTA,
    required bool hasCoronary,
    required bool isRamadanPeriod,
  }) {
    List<String> selectedModules = [];

    if (hasHTA) {
      selectedModules.add('MOD_HTA_SEL');
    }
    if (isRamadanPeriod) {
      selectedModules.add('MOD_FIQH_RAMADAN');
    }

    return selectedModules;
  }
}
