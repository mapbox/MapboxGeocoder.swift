#if SWIFT_PACKAGE
/**
 Each of these options specifies a kind of administrative area, settlement, or addressable location.
 
 Every placemark has a scope. The scope offers a general indication of the size or importance of the feature represented by the placemark – in other words, how local the feature is.
 
 You can also limit geocoding to a scope or set of scopes using this type.
 */
public struct PlacemarkScope: OptionSet {
    public let rawValue: UInt
    
    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }
    
    /// A country or dependent territory, for example Switzerland or New Caledonia.
    public static let country = Self(rawValue: 1 << 1)
    
    /// A top-level administrative region within a country, such as a state or province.
    public static let region = Self(rawValue: 1 << 2)
    
    /// A subdivision of a top-level administrative region, used for various administrative units in China.
    public static let district = Self(rawValue: 1 << 3)
    
    /// A region defined by a postal code.
    public static let postalCode = Self(rawValue: 1 << 4)
    
    /// A municipality, such as a city or village.
    public static let place = Self(rawValue: 1 << 5)
    
    /// A major subdivision within a municipality.
    public static let locality = Self(rawValue: 1 << 6)
    
    /// A minor subdivision within a municipality.
    public static let neighborhood = Self(rawValue: 1 << 7)
    
    /// A physical address, such as to a business or residence.
    public static let address = Self(rawValue: 1 << 8)
    
    /// A particularly notable or long-lived point of interest, such as a park, museum, or place of worship.
    public static let landmark = Self(rawValue: 1 << 10)
    
    /// A point of interest, such as a business or store.
    public static let pointOfInterest: PlacemarkScope = [.landmark, Self(rawValue: 1 << 9)]
    
    /// All scopes.
    public static let all: PlacemarkScope = [.country, .region, district, postalCode, .place, .locality, .neighborhood, .address, .landmark, .pointOfInterest]
}
#else
public typealias PlacemarkScope = MBPlacemarkScope
#endif

extension PlacemarkScope: CustomStringConvertible {
    /**
     Initializes a placemark scope bitmask corresponding to the given array of string representations of scopes.
     */
    public init?(descriptions: [String]) {
        var scope: PlacemarkScope = []
        for description in descriptions {
            switch description {
            case "country":
                scope.update(with: .country)
            case "region":
                scope.update(with: .region)
            case "district":
                scope.update(with: .district)
            case "postcode":
                scope.update(with: .postalCode)
            case "place":
                scope.update(with: .place)
            case "locality":
                scope.update(with: .locality)
            case "neighborhood":
                scope.update(with: .neighborhood)
            case "address":
                scope.update(with: .address)
            case "poi.landmark":
                scope.update(with: .landmark)
            case "poi":
                scope.update(with: .pointOfInterest)
            default:
                return nil
            }
        }
        self.init(rawValue: scope.rawValue)
    }
    
    public var description: String {
        var descriptions: [String] = []
        if contains(.country) {
            descriptions.append("country")
        }
        if contains(.region) {
            descriptions.append("region")
        }
        if contains(.district) {
            descriptions.append("district")
        }
        if contains(.postalCode) {
            descriptions.append("postcode")
        }
        if contains(.place) {
            descriptions.append("place")
        }
        if contains(.locality) {
            descriptions.append("locality")
        }
        if contains(.neighborhood) {
            descriptions.append("neighborhood")
        }
        if contains(.address) {
            descriptions.append("address")
        }
        if contains(.landmark) {
            descriptions.append(contains(.pointOfInterest) ? "poi" : "poi.landmark")
        }
        return descriptions.joined(separator: ",")
    }
    
    init(identifier: String) {
        let components = identifier.components(separatedBy: ".")
        assert(components.count > 0)
        let scope = PlacemarkScope(descriptions: [components.prefix(2).joined(separator: ".")]) ?? PlacemarkScope(descriptions: [components.first!]) ?? []
        self.init(rawValue: scope.rawValue)
    }
}
