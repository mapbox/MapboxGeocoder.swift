typedef NS_OPTIONS(NSUInteger, MBPlacemarkScope) {
    MBPlacemarkScopeCountry = (1 << 1),
    MBPlacemarkScopeRegion = (1 << 2),
    MBPlacemarkScopeDistrict = (1 << 3),
    MBPlacemarkScopePostalCode = (1 << 4),
    MBPlacemarkScopePlace = (1 << 5),
    MBPlacemarkScopeLocality = (1 << 6),
    MBPlacemarkScopeNeighborhood = (1 << 7),
    MBPlacemarkScopeAddress = (1 << 8),
    MBPlacemarkScopePointOfInterest = (1 << 9),
    
    MBPlacemarkScopeAll = 0x0ffffUL,
} NS_SWIFT_NAME(PlacemarkScope);
