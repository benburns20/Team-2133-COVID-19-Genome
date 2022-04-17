class Variant {
  final String accession;
  final String geoLocation;
  final int collectionDate;
  final String pinned;

  const Variant({
    required this.accession,
    required this.geoLocation,
    required this.collectionDate,
    required this.pinned,
  });

  Variant copy({
    String? firstName,
    String? lastName,
    int? age,
    String? pinned,
  }) =>
      Variant(
        accession: firstName ?? this.accession,
        geoLocation: lastName ?? this.geoLocation,
        collectionDate: age ?? this.collectionDate,
        pinned: pinned ?? this.pinned,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Variant &&
          runtimeType == other.runtimeType &&
          accession == other.accession &&
          geoLocation == other.geoLocation &&
          collectionDate == other.collectionDate;

  @override
  int get hashCode => accession.hashCode ^ geoLocation.hashCode ^ collectionDate.hashCode;
}
