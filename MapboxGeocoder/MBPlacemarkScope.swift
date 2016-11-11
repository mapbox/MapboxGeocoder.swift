public typealias PlacemarkScope = MBPlacemarkScope

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
            case "poi.landmark":
                scope.insert(.Landmark)
            default:
                break
            }
        }
        self.init(rawValue: scope.rawValue)
    }
    
    public var description: String {
        var descriptions: [String] = []
        if contains(.Country) {
            descriptions.append("country")
        }
        if contains(.Region) {
            descriptions.append("region")
        }
        if contains(.District) {
            descriptions.append("district")
        }
        if contains(.PostalCode) {
            descriptions.append("postcode")
        }
        if contains(.Place) {
            descriptions.append("place")
        }
        if contains(.Locality) {
            descriptions.append("locality")
        }
        if contains(.Neighborhood) {
            descriptions.append("neighborhood")
        }
        if contains(.Address) {
            descriptions.append("address")
        }
        if contains(.PointOfInterest) {
            descriptions.append("poi")
        }
        if contains(.Landmark) {
            descriptions.append("poi.landmark")
        }
        return descriptions.joinWithSeparator(",")
    }
}
