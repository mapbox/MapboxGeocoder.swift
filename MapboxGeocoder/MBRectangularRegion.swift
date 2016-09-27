/**
 The `RectangularRegion` class defines a rectangular bounding box for a geographic region.
 */
@objc(MBRectangularRegion)
open class RectangularRegion: CLRegion {
    /** Coordinate at the southwest corner. */
    open var southWest: CLLocationCoordinate2D = CLLocationCoordinate2D()
    /** Coordinate at the northeast corner. */
    open var northEast: CLLocationCoordinate2D = CLLocationCoordinate2D()
    
    public init(southWest: CLLocationCoordinate2D, northEast: CLLocationCoordinate2D) {
        self.southWest = southWest
        self.northEast = northEast
        super.init()
    }
    
    required public init?(coder decoder: NSCoder) {
        decoder.decodeValue(ofObjCType: "{dd}", at: &southWest)
        decoder.decodeValue(ofObjCType: "{dd}", at: &northEast)
        super.init(coder: decoder)
    }
    
    open override func encode(with coder: NSCoder) {
        super.encode(with: coder)
        coder.encodeValue(ofObjCType: "{dd}", at: &southWest)
        coder.encodeValue(ofObjCType: "{dd}", at: &northEast)
    }
    
    open override var hashValue: Int {
        return (southWest.latitude.hashValue + southWest.longitude.hashValue
            + northEast.latitude.hashValue + northEast.longitude.hashValue)
    }
    
    open override func isEqual(_ object: Any?) -> Bool {
        guard let object = object as? RectangularRegion else {
            return false
        }
        return (southWest.latitude == object.southWest.latitude && southWest.longitude == object.southWest.longitude
            && northEast.latitude == object.northEast.latitude && northEast.longitude == object.northEast.longitude)
    }
    
    /**
     Returns a Boolean value indicating whether the bounding box contains the specified coordinate.
     */
    open func containsLocationCoordinate2D(_ coordinate: CLLocationCoordinate2D) -> Bool {
        return (coordinate.latitude >= southWest.latitude && coordinate.latitude <= northEast.latitude
            && coordinate.longitude >= southWest.longitude && coordinate.longitude <= northEast.longitude)
    }
}
