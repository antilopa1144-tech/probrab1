abstract final class RegionId {
  static const String moscow = 'moscow';
  static const String spb = 'spb';
  static const String ekaterinburg = 'ekaterinburg';
  static const String krasnodar = 'krasnodar';
  static const String novosibirsk = 'novosibirsk';
  static const String kazan = 'kazan';
  static const String nizhnyNovgorod = 'nizhny_novgorod';
  static const String chelyabinsk = 'chelyabinsk';
  static const String samara = 'samara';
  static const String regions = 'regions';
}

abstract final class RegionCatalog {
  static const String defaultId = RegionId.moscow;

  static const List<String> supported = [
    RegionId.moscow,
    RegionId.spb,
    RegionId.ekaterinburg,
    RegionId.krasnodar,
    RegionId.novosibirsk,
    RegionId.kazan,
    RegionId.nizhnyNovgorod,
    RegionId.chelyabinsk,
    RegionId.samara,
    RegionId.regions,
  ];

  static const Map<String, String> _legacyToId = {
    'Москва': RegionId.moscow,
    'moscow': RegionId.moscow,
    'Санкт-Петербург': RegionId.spb,
    'Санкт‑Петербург': RegionId.spb,
    'spb': RegionId.spb,
    'Екатеринбург': RegionId.ekaterinburg,
    'ekaterinburg': RegionId.ekaterinburg,
    'Краснодар': RegionId.krasnodar,
    'krasnodar': RegionId.krasnodar,
    'Новосибирск': RegionId.novosibirsk,
    'novosibirsk': RegionId.novosibirsk,
    'Казань': RegionId.kazan,
    'kazan': RegionId.kazan,
    'Нижний Новгород': RegionId.nizhnyNovgorod,
    'nizhny_novgorod': RegionId.nizhnyNovgorod,
    'Челябинск': RegionId.chelyabinsk,
    'chelyabinsk': RegionId.chelyabinsk,
    'Самара': RegionId.samara,
    'samara': RegionId.samara,
    'Регионы РФ': RegionId.regions,
    'regions': RegionId.regions,
  };

  static const Map<String, String> _idToLegacyName = {
    RegionId.moscow: 'Москва',
    RegionId.spb: 'Санкт‑Петербург',
    RegionId.ekaterinburg: 'Екатеринбург',
    RegionId.krasnodar: 'Краснодар',
    RegionId.novosibirsk: 'Новосибирск',
    RegionId.kazan: 'Казань',
    RegionId.nizhnyNovgorod: 'Нижний Новгород',
    RegionId.chelyabinsk: 'Челябинск',
    RegionId.samara: 'Самара',
    RegionId.regions: 'Регионы РФ',
  };

  static const Map<String, String> _idToPriceCode = {
    RegionId.moscow: 'moscow',
    RegionId.spb: 'spb',
    RegionId.ekaterinburg: 'ekaterinburg',
    RegionId.krasnodar: 'krasnodar',
    RegionId.novosibirsk: 'novosibirsk',
    RegionId.kazan: 'kazan',
    RegionId.nizhnyNovgorod: 'nizhny_novgorod',
    RegionId.chelyabinsk: 'chelyabinsk',
    RegionId.samara: 'samara',
    RegionId.regions: 'regions',
  };

  static String normalize(String? region) {
    final raw = (region ?? '').trim();
    if (raw.isEmpty) return defaultId;
    if (supported.contains(raw)) return raw;
    return _legacyToId[raw] ?? defaultId;
  }

  static bool isSupported(String? region) {
    return supported.contains(normalize(region));
  }

  static String legacyName(String? region) {
    final normalized = normalize(region);
    return _idToLegacyName[normalized] ?? _idToLegacyName[defaultId]!;
  }

  static String priceCode(String? region) {
    final normalized = normalize(region);
    return _idToPriceCode[normalized] ?? _idToPriceCode[defaultId]!;
  }

  static String laborLabelKey(String? region) {
    switch (normalize(region)) {
      case RegionId.moscow:
        return 'labor.region_value.moscow';
      case RegionId.spb:
        return 'labor.region_value.spb';
      case RegionId.ekaterinburg:
        return 'labor.region_value.ekaterinburg';
      case RegionId.krasnodar:
        return 'labor.region_value.krasnodar';
      case RegionId.regions:
        return 'labor.region_value.regions';
      default:
        return '';
    }
  }
}
