import Foundation
import CoreLocation

public typealias MBGeocodeCompletionHandler = CLGeocodeCompletionHandler

// MARK: - Geocoder

public class MBGeocoder: NSObject,
                         NSURLConnectionDelegate,
                         NSURLConnectionDataDelegate {

    // MARK: - Setup

    private let accessToken: NSString
    
    public init(accessToken: NSString) {
        self.accessToken = accessToken
        super.init()
    }

    private var connection: NSURLConnection?
    private var completionHandler: MBGeocodeCompletionHandler?
    private var receivedData: NSMutableData?
    
    private let MBGeocoderErrorDomain = "MBGeocoderErrorDomain"

    private enum MBGeocoderErrorCode: Int {
        case ConnectionError = -1000
        case HTTPError       = -1001
        case ParseError      = -1002
    }
    
    // MARK: - Public API

    public var geocoding: Bool {
        return (self.connection != nil)
    }
    
    public func reverseGeocodeLocation(location: CLLocation, completionHandler: MBGeocodeCompletionHandler) {
        if (!self.geocoding) {
            self.completionHandler = completionHandler
            let requestString = "https://api.tiles.mapbox.com/v4/geocode/mapbox.places/" +
                "\(location.coordinate.longitude),\(location.coordinate.latitude).json" +
                "?access_token=\(accessToken)"
            let request = NSURLRequest(URL: NSURL(string: requestString)!)
            self.connection = NSURLConnection(request: request, delegate: self)
        }
    }

//    public func geocodeAddressDictionary(addressDictionary: [NSObject : AnyObject],
//        completionHandler: MBGeocodeCompletionHandler)
    
    public func geocodeAddressString(addressString: String, proximity: CLLocationCoordinate2D? = nil, completionHandler: MBGeocodeCompletionHandler) {
        if (!self.geocoding) {
            self.completionHandler = completionHandler
            var requestString = "https://api.tiles.mapbox.com/v4/geocode/mapbox.places/" +
                addressString.stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)! +
                ".json?access_token=\(accessToken)"
            if let proximityCoordinate = proximity {
                requestString += "&proximity=\(proximityCoordinate.longitude),\(proximityCoordinate.latitude)"
            }
            let request = NSURLRequest(URL: NSURL(string: requestString)!)
            self.connection = NSURLConnection(request: request, delegate: self)
        }
    }

//    public func geocodeAddressString(addressString: String, inRegion region: CLRegion, completionHandler: MBGeocodeCompletionHandler)

    public func cancelGeocode() {
        self.connection?.cancel()
        self.connection = nil
    }
    
    // MARK: - NSURLConnection Delegates

    public func connection(connection: NSURLConnection, didFailWithError error: NSError) {
        self.connection = nil
        self.completionHandler?(nil, NSError(domain: MBGeocoderErrorDomain,
            code: MBGeocoderErrorCode.ConnectionError.rawValue,
            userInfo: error.userInfo))
    }

    public func connection(connection: NSURLConnection, didReceiveResponse response: NSURLResponse) {
        let statusCode = (response as! NSHTTPURLResponse).statusCode
        if (statusCode != 200) {
            self.connection?.cancel()
            self.connection = nil
            self.completionHandler?(nil, NSError(domain: MBGeocoderErrorDomain,
                code: MBGeocoderErrorCode.HTTPError.rawValue,
                userInfo: [ NSLocalizedDescriptionKey: "Received HTTP status code \(statusCode)" ]))
        } else {
            self.receivedData = NSMutableData()
        }
    }
    
    public func connection(connection: NSURLConnection, didReceiveData data: NSData) {
        self.receivedData!.appendData(data)
    }
    
    public func connectionDidFinishLoading(connection: NSURLConnection) {
        var parseError: NSError?
        let response = NSJSONSerialization.JSONObjectWithData(self.receivedData!, options: nil, error: &parseError) as? NSDictionary
        if (parseError != nil) {
            self.completionHandler?(nil, NSError(domain: MBGeocoderErrorDomain,
                code: MBGeocoderErrorCode.ParseError.rawValue,
                userInfo: [ NSLocalizedDescriptionKey: "Unable to parse results" ]))
        } else if let features = response?["features"] as? NSArray {
            var results: [MBPlacemark] = []
            for feature in features {
                if let feature = feature as? NSDictionary {
                    if let placemark = MBPlacemark(featureJSON: feature) {
                        results.append(placemark)
                    }
                }
            }
            self.completionHandler?(results, nil)
        } else {
            self.completionHandler?([], nil)
        }
    }

}

// MARK: - Placemark

// Based on CLPlacemark, which can't be reliably subclassed in Swift.

public class MBPlacemark: NSObject, NSCopying, NSSecureCoding {

    private var featureJSON: NSDictionary?

    required public init(coder aDecoder: NSCoder) {
        featureJSON = aDecoder.decodeObjectOfClass(NSDictionary.self, forKey: "featureJSON") as? NSDictionary
    }
    
    public override init() {
        super.init()
    }

    public convenience init(placemark: MBPlacemark) {
        self.init()
        featureJSON = placemark.featureJSON
    }

    internal convenience init?(featureJSON: NSDictionary) {
        var valid = false
        if let geometry = featureJSON["geometry"] as? NSDictionary {
            if geometry["type"] as? String == "Point" {
                if geometry["coordinates"] as? NSArray != nil {
                    if featureJSON["place_name"] as? String != nil {
                        valid = true
                    }
                }
            }
        }
        if (valid) {
            self.init()
            self.featureJSON = featureJSON
        } else {
            self.init()
            self.featureJSON = nil
            return nil
        }
    }
    
    public class func supportsSecureCoding() -> Bool {
        return true
    }
    
    public func copyWithZone(zone: NSZone) -> AnyObject {
        return MBPlacemark(featureJSON: featureJSON!)!
    }
    
    public func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(featureJSON, forKey: "featureJSON")
    }

    public var location: CLLocation! {
        let coordinates = (self.featureJSON!["geometry"] as! NSDictionary)["coordinates"] as! NSArray

        return CLLocation(latitude: coordinates[1].doubleValue, longitude: coordinates[0].doubleValue)
    }

    public var name: String! {
        return self.featureJSON!["place_name"] as! String
    }

    public var addressDictionary: [NSObject: AnyObject]! {
        return [:]
    }

    public var ISOcountryCode: String! {
        return ""
    }

    public var country: String! {
        return ""
    }

    public var postalCode: String! {
        return ""
    }

    public var administrativeArea: String! {
        return ""
    }

    public var subAdministrativeArea: String! {
        return ""
    }

    public var locality: String! {
        return ""
    }

    public var subLocality: String! {
        return ""
    }

    public var thoroughfare: String! {
        return ""
    }

    public var subThoroughfare: String! {
        return ""
    }

    public var region: CLRegion! {
        return CLRegion()
    }

    public var inlandWater: String! {
        return ""
    }

    public var ocean: String! {
        return ""
    }

    public var areasOfInterest: [AnyObject]! {
        return []
    }

}
