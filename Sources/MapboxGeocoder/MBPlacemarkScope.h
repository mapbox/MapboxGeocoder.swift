/**
 Each of these options specifies a kind of administrative area, settlement, or addressable location.
 
 Every placemark has a scope. The scope offers a general indication of the size or importance of the feature represented by the placemark – in other words, how local the feature is.
 
 You can also limit geocoding to a scope or set of scopes using this type.
 */
typedef NS_OPTIONS(NSUInteger, MBPlacemarkScope) {
    /// A country or dependent territory, for example Switzerland or New Caledonia.
    MBPlacemarkScopeCountry = (1 << 1),
    /// A top-level administrative region within a country, such as a state or province.
    MBPlacemarkScopeRegion = (1 << 2),
    /// A subdivision of a top-level administrative region, used for various administrative units in China.
    MBPlacemarkScopeDistrict = (1 << 3),
    /// A region defined by a postal code.
    MBPlacemarkScopePostalCode = (1 << 4),
    /// A municipality, such as a city or village.
    MBPlacemarkScopePlace = (1 << 5),
    /// A major subdivision within a municipality.
    MBPlacemarkScopeLocality = (1 << 6),
    /// A minor subdivision within a municipality.
    MBPlacemarkScopeNeighborhood = (1 << 7),
    /// A physical address, such as to a business or residence.
    MBPlacemarkScopeAddress = (1 << 8),
    
    /// A particularly notable or long-lived point of interest, such as a park, museum, or place of worship.
    MBPlacemarkScopeLandmark = (1 << 10),
    /// A point of interest, such as a business or store.
    MBPlacemarkScopePointOfInterest = MBPlacemarkScopeLandmark | (1 << 9),
    
    /// All scopes.
    MBPlacemarkScopeAll = 0x0ffffUL,
};
