public typealias PlacemarkScope = MBPlacemarkScope

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
}
