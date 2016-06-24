extension PlacemarkScope: CustomStringConvertible {
    /**
     Initializes a placemark scope bitmask corresponding to the given array of string representations of scopes.
     */
    public init(descriptions: [String]) {
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
            case "poi":
                scope.update(with: .pointOfInterest)
            default:
                break
            }
        }
        self.init(rawValue: scope.rawValue)
    }
    
    public var description: String {
        var descriptions: [String] = []
        if contains(PlacemarkScope.country) {
            descriptions.append("country")
        }
        if contains(PlacemarkScope.region) {
            descriptions.append("region")
        }
        if contains(PlacemarkScope.district) {
            descriptions.append("district")
        }
        if contains(PlacemarkScope.postalCode) {
            descriptions.append("postcode")
        }
        if contains(PlacemarkScope.place) {
            descriptions.append("place")
        }
        if contains(PlacemarkScope.locality) {
            descriptions.append("locality")
        }
        if contains(PlacemarkScope.neighborhood) {
            descriptions.append("neighborhood")
        }
        if contains(PlacemarkScope.address) {
            descriptions.append("address")
        }
        if contains(PlacemarkScope.pointOfInterest) {
            descriptions.append("poi")
        }
        return descriptions.joined(separator: ",")
    }
}
