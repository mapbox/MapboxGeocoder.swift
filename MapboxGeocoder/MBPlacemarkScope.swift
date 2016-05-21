extension PlacemarkScope: CustomStringConvertible {
    /**
     Initializes a placemark scope bitmask corresponding to the given array of string representations of scopes.
     */
    public init(descriptions: [String]) {
        var scope: PlacemarkScope = []
        for description in descriptions {
            switch description {
            case "country":
                scope.insert(.Country)
            case "region":
                scope.insert(.Region)
            case "district":
                scope.insert(.District)
            case "postcode":
                scope.insert(.PostalCode)
            case "place":
                scope.insert(.Place)
            case "locality":
                scope.insert(.Locality)
            case "neighborhood":
                scope.insert(.Neighborhood)
            case "address":
                scope.insert(.Address)
            case "poi":
                scope.insert(.PointOfInterest)
            default:
                break
            }
        }
        self.init(rawValue: scope.rawValue)
    }
    
    public var description: String {
        var descriptions: [String] = []
        if contains(PlacemarkScope.Country) {
            descriptions.append("country")
        }
        if contains(PlacemarkScope.Region) {
            descriptions.append("region")
        }
        if contains(PlacemarkScope.District) {
            descriptions.append("district")
        }
        if contains(PlacemarkScope.PostalCode) {
            descriptions.append("postcode")
        }
        if contains(PlacemarkScope.Place) {
            descriptions.append("place")
        }
        if contains(PlacemarkScope.Locality) {
            descriptions.append("locality")
        }
        if contains(PlacemarkScope.Neighborhood) {
            descriptions.append("neighborhood")
        }
        if contains(PlacemarkScope.Address) {
            descriptions.append("address")
        }
        if contains(PlacemarkScope.PointOfInterest) {
            descriptions.append("poi")
        }
        return descriptions.joinWithSeparator(",")
    }
}
