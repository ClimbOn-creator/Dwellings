enum PlatformSide { property, business }

extension PlatformSideDetails on PlatformSide {
  String get label => switch (this) {
    PlatformSide.property => 'PropertyIQ',
    PlatformSide.business => 'DealIQ',
  };

  String get shortLabel => switch (this) {
    PlatformSide.property => 'PROPERTY',
    PlatformSide.business => 'BUSINESS',
  };

  String get queryValue => switch (this) {
    PlatformSide.property => 'property',
    PlatformSide.business => 'business',
  };
}
