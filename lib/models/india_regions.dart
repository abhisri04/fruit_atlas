/// Regions of India, following the zonal councils, with the island UTs
/// on their own. Every State and UT is in exactly one region.
class IndiaRegion {
  final String id;
  final String name;
  final List<String> locationIds;

  const IndiaRegion(this.id, this.name, this.locationIds);
}

abstract final class IndiaRegions {
  static const all = <IndiaRegion>[
    IndiaRegion('north', 'North', [
      'jammu_kashmir',
      'ladakh',
      'himachal_pradesh',
      'punjab',
      'chandigarh',
      'haryana',
      'delhi',
      'rajasthan',
    ]),
    IndiaRegion('central', 'Central', [
      'uttarakhand',
      'uttar_pradesh',
      'madhya_pradesh',
      'chhattisgarh',
    ]),
    IndiaRegion('east', 'East', [
      'bihar',
      'jharkhand',
      'odisha',
      'west_bengal',
    ]),
    IndiaRegion('northeast', 'Northeast', [
      'assam',
      'arunachal_pradesh',
      'manipur',
      'meghalaya',
      'mizoram',
      'nagaland',
      'sikkim',
      'tripura',
    ]),
    IndiaRegion('west', 'West', [
      'gujarat',
      'maharashtra',
      'goa',
      'dadra_nagar_haveli_daman_diu',
    ]),
    IndiaRegion('south', 'South', [
      'andhra_pradesh',
      'telangana',
      'karnataka',
      'kerala',
      'tamil_nadu',
      'puducherry',
    ]),
    IndiaRegion('islands', 'Islands', ['andaman_nicobar', 'lakshadweep']),
  ];

  static IndiaRegion forLocation(String id) =>
      all.firstWhere((r) => r.locationIds.contains(id));
}
