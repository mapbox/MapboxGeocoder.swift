import Foundation
import CoreLocation

/**
 The `RectangularRegion` class defines a rectangular bounding box for a geographic region.
 */
@objc(MBRectangularRegion)
open class RectangularRegion: CLRegion, Codable {
    /** Coordinate at the southwest corner. */
    @objc open var southWest: CLLocationCoordinate2D = CLLocationCoordinate2D()
    /** Coordinate at the northeast corner. */
    @objc open var northEast: CLLocationCoordinate2D = CLLocationCoordinate2D()
    
    private enum CodingKeys: String, CodingKey {
        case southWest
        case northEast
    }
    
    /**
     Creates a rectangular region with the given southwest and northeast corners.
     
     `southWest` must be to the southwest of `northEast`. The region may not span the antimeridian. If you need to restrict a query to a region that spans the antimeridian, such as the region that encompasses Fiji, perform two queries each limited to the region on either side of the antimeridian, then combine the results.
     
     - parameter southWest: The southwesternmost geographic coordinate that lies within the region.
     - parameter northEast: The northeasternmost geographic coordinate that lies within the region.
     */
    @objc public init(southWest: CLLocationCoordinate2D, northEast: CLLocationCoordinate2D) {
        self.southWest = southWest
        self.northEast = northEast
        super.init()
    }
    
    @objc required public init?(coder decoder: NSCoder) {
        decoder.decodeValue(ofObjCType: "{dd}", at: &southWest)
        decoder.decodeValue(ofObjCType: "{dd}", at: &northEast)
        super.init(coder: decoder)
    }
    
    @objc open override func encode(with coder: NSCoder) {
        super.encode(with: coder)
        coder.encodeValue(ofObjCType: "{dd}", at: &southWest)
        coder.encodeValue(ofObjCType: "{dd}", at: &northEast)
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.southWest = try container.decode(CLLocationCoordinate2D.self, forKey: .southWest)
        self.northEast = try container.decode(CLLocationCoordinate2D.self, forKey: .northEast)
        super.init()
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(southWest, forKey: .southWest)
        try container.encode(northEast, forKey: .northEast)
    }
    
    #if swift(>=4.2)
    #else
    @objc open override var hashValue: Int {
        return (southWest.latitude.hashValue + southWest.longitude.hashValue + northEast.latitude.hashValue + northEast.longitude.hashValue)
    }
    #endif
    
    @objc open override func isEqual(_ object: Any?) -> Bool {
        guard let object = object as? RectangularRegion else {
            return false
        }
        return (southWest.latitude == object.southWest.latitude && southWest.longitude == object.southWest.longitude
            && northEast.latitude == object.northEast.latitude && northEast.longitude == object.northEast.longitude)
    }
    
    @objc open override var description: String {
        return "\(southWest.longitude),\(southWest.latitude),\(northEast.longitude),\(northEast.latitude)"
    }

    /**
     Returns a Boolean value indicating whether the bounding box contains the specified coordinate.
     */
    @objc open func containsLocationCoordinate2D(_ coordinate: CLLocationCoordinate2D) -> Bool {
        return (coordinate.latitude >= southWest.latitude && coordinate.latitude <= northEast.latitude
            && coordinate.longitude >= southWest.longitude && coordinate.longitude <= northEast.longitude)
    }
}
