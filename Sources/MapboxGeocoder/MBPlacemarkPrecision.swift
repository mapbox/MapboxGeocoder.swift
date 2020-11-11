#if SWIFT_PACKAGE
/**
 An indication of a placemark’s precision.
 
 A placemark’s `MBPlacemarkScope` indicates a feature’s size or importance, whereas its precision indicates how far the reported location may be from the actual real-world location.
 */
public enum PlacemarkPrecision: String, Codable {
    /// The placemark represents a specific building with a location on the building’s rooftop or at one of its entrances.
    case building = "rooftop"
    
    /// The placemark represents a tract or parcel of land with a location at the centroid.
    case parcel
    
    /// The placemark represents an address that has been interpolated from an address range. The actual location is generally somewhere along the same block of the same street as the placemark’s location.
    case interpolated
    
    /// The placemark represents a block along a street or an intersection between two or more streets.
    case intersection
    
    /// The placemark represents an entire street with a location at its midpoint.
    case street
}
#else
public typealias PlacemarkPrecision = MBPlacemarkPrecision
#endif
