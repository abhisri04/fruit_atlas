enum IndiaLocationKind { state, unionTerritory }

class IndiaLocation {
  final String id;
  final String name;
  final IndiaLocationKind kind;

  const IndiaLocation(this.id, this.name, this.kind);
}

abstract final class IndiaLocationRegistry {
  static const locations = <IndiaLocation>[
    IndiaLocation('andhra_pradesh', 'Andhra Pradesh', IndiaLocationKind.state),
    IndiaLocation(
      'arunachal_pradesh',
      'Arunachal Pradesh',
      IndiaLocationKind.state,
    ),
    IndiaLocation('assam', 'Assam', IndiaLocationKind.state),
    IndiaLocation('bihar', 'Bihar', IndiaLocationKind.state),
    IndiaLocation('chhattisgarh', 'Chhattisgarh', IndiaLocationKind.state),
    IndiaLocation('goa', 'Goa', IndiaLocationKind.state),
    IndiaLocation('gujarat', 'Gujarat', IndiaLocationKind.state),
    IndiaLocation('haryana', 'Haryana', IndiaLocationKind.state),
    IndiaLocation(
      'himachal_pradesh',
      'Himachal Pradesh',
      IndiaLocationKind.state,
    ),
    IndiaLocation('jharkhand', 'Jharkhand', IndiaLocationKind.state),
    IndiaLocation('karnataka', 'Karnataka', IndiaLocationKind.state),
    IndiaLocation('kerala', 'Kerala', IndiaLocationKind.state),
    IndiaLocation('madhya_pradesh', 'Madhya Pradesh', IndiaLocationKind.state),
    IndiaLocation('maharashtra', 'Maharashtra', IndiaLocationKind.state),
    IndiaLocation('manipur', 'Manipur', IndiaLocationKind.state),
    IndiaLocation('meghalaya', 'Meghalaya', IndiaLocationKind.state),
    IndiaLocation('mizoram', 'Mizoram', IndiaLocationKind.state),
    IndiaLocation('nagaland', 'Nagaland', IndiaLocationKind.state),
    IndiaLocation('odisha', 'Odisha', IndiaLocationKind.state),
    IndiaLocation('punjab', 'Punjab', IndiaLocationKind.state),
    IndiaLocation('rajasthan', 'Rajasthan', IndiaLocationKind.state),
    IndiaLocation('sikkim', 'Sikkim', IndiaLocationKind.state),
    IndiaLocation('tamil_nadu', 'Tamil Nadu', IndiaLocationKind.state),
    IndiaLocation('telangana', 'Telangana', IndiaLocationKind.state),
    IndiaLocation('tripura', 'Tripura', IndiaLocationKind.state),
    IndiaLocation('uttar_pradesh', 'Uttar Pradesh', IndiaLocationKind.state),
    IndiaLocation('uttarakhand', 'Uttarakhand', IndiaLocationKind.state),
    IndiaLocation('west_bengal', 'West Bengal', IndiaLocationKind.state),
    IndiaLocation(
      'andaman_nicobar',
      'Andaman and Nicobar Islands',
      IndiaLocationKind.unionTerritory,
    ),
    IndiaLocation('chandigarh', 'Chandigarh', IndiaLocationKind.unionTerritory),
    IndiaLocation(
      'dadra_nagar_haveli_daman_diu',
      'Dadra and Nagar Haveli and Daman and Diu',
      IndiaLocationKind.unionTerritory,
    ),
    IndiaLocation('delhi', 'Delhi', IndiaLocationKind.unionTerritory),
    IndiaLocation(
      'jammu_kashmir',
      'Jammu and Kashmir',
      IndiaLocationKind.unionTerritory,
    ),
    IndiaLocation('ladakh', 'Ladakh', IndiaLocationKind.unionTerritory),
    IndiaLocation(
      'lakshadweep',
      'Lakshadweep',
      IndiaLocationKind.unionTerritory,
    ),
    IndiaLocation('puducherry', 'Puducherry', IndiaLocationKind.unionTerritory),
  ];

  static final names = <String, String>{
    for (final location in locations) location.id: location.name,
  };
  static final stateIds = <String>{
    for (final location in locations)
      if (location.kind == IndiaLocationKind.state) location.id,
  };
  static final unionTerritoryIds = <String>{
    for (final location in locations)
      if (location.kind == IndiaLocationKind.unionTerritory) location.id,
  };
  static final allLocationIds = <String>{
    for (final location in locations) location.id,
  };

  static String nameFor(String id) => names[id] ?? id;
  static bool isState(String id) => stateIds.contains(id);
  static bool isUnionTerritory(String id) => unionTerritoryIds.contains(id);
}
