import Foundation
import CoreLocation

public class MBRectangularRegion: CLRegion {
    /** Coordinate at the southwest corner. */
    public var southWest: CLLocationCoordinate2D = CLLocationCoordinate2D()
    /** Coordinate at the northeast corner. */
    public var northEast: CLLocationCoordinate2D = CLLocationCoordinate2D()
    
    public init(southWest: CLLocationCoordinate2D, northEast: CLLocationCoordinate2D) {
        self.southWest = southWest
        self.northEast = northEast
        super.init()
    }
    
    required public init?(coder decoder: NSCoder) {
        decoder.decodeValueOfObjCType("{dd}", at: &southWest)
        decoder.decodeValueOfObjCType("{dd}", at: &northEast)
        super.init(coder: decoder)
    }
    
    public override func encodeWithCoder(coder: NSCoder) {
        super.encodeWithCoder(coder)
        coder.encodeValueOfObjCType("{dd}", at: &southWest)
        coder.encodeValueOfObjCType("{dd}", at: &northEast)
    }
    
    public override func isEqual(object: AnyObject?) -> Bool {
        if let object = object as? MBRectangularRegion {
            return southWest == object.southWest && northEast == object.northEast
        }
        return false
    }
}
