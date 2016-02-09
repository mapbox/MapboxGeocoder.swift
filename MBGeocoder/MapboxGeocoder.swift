import Foundation
import CoreLocation

// like CLGeocodeCompletionHandler
public typealias MBGeocodeCompletionHandler = ([MBPlacemark]?, NSError?) -> Void
internal typealias JSON = [String: AnyObject]

extension CLLocationCoordinate2D: Equatable {}
public func ==(left: CLLocationCoordinate2D, right: CLLocationCoordinate2D) -> Bool {
    return (left.latitude == right.latitude && left.longitude == right.longitude)
}

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
        if !self.geocoding {
            self.completionHandler = completionHandler
            let requestString = String(format: "https://api.mapbox.com/geocoding/v5/mapbox.places/%.5f,%.5f.json?access_token=%@",
                round(location.coordinate.longitude * 1e5) / 1e5,
                round(location.coordinate.latitude * 1e5) / 1e5, accessToken)
            let request = NSURLRequest(URL: NSURL(string: requestString)!)
            self.connection = NSURLConnection(request: request, delegate: self)
        }
    }

//    public func geocodeAddressDictionary(addressDictionary: [NSObject : AnyObject],
//        completionHandler: MBGeocodeCompletionHandler)
    
    public func geocodeAddressString(addressString: String, proximity: CLLocationCoordinate2D? = nil, completionHandler: MBGeocodeCompletionHandler) {
        if !self.geocoding {
            self.completionHandler = completionHandler
            var requestString = "https://api.mapbox.com/geocoding/v5/mapbox.places/" +
                addressString.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLPathAllowedCharacterSet())! +
                ".json?access_token=\(accessToken)"
            if let proximityCoordinate = proximity {
                requestString += String(format: "&proximity=%.3f,%.3f",
                    round(proximityCoordinate.longitude * 1e3) / 1e3,
                    round(proximityCoordinate.latitude * 1e3) / 1e3)
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
        if statusCode != 200 {
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
        if let response = (try? NSJSONSerialization.JSONObjectWithData(self.receivedData!, options: [])) as? JSON {
            if let features = response["features"] as? [JSON] {
                var results: [MBPlacemark] = []
                for feature in features {
                    if let placemark = MBPlacemark(featureJSON: feature) {
                        results.append(placemark)
                    }
                }
                self.completionHandler?(results, nil)
            } else {
                self.completionHandler?([], nil)
            }
        } else {
            self.completionHandler?(nil, NSError(domain: MBGeocoderErrorDomain,
                code: MBGeocoderErrorCode.ParseError.rawValue,
                userInfo: [ NSLocalizedDescriptionKey: "Unable to parse results" ]))
        }
    }

}

// MARK: - Placemark

// Based on CNPostalAddress, the successor to ABPerson, which is used by CLPlacemark.

public let MBPostalAddressStreetKey = "street"
public let MBPostalAddressCityKey = "city"
public let MBPostalAddressStateKey = "state"
public let MBPostalAddressPostalCodeKey = "postalCode"
public let MBPostalAddressCountryKey = "country"
public let MBPostalAddressISOCountryCodeKey = "ISOCountryCode"

// Based on CLPlacemark, which can't be reliably subclassed in Swift.

public class MBPlacemark: NSObject, NSCopying, NSSecureCoding {

    private var featureJSON: JSON?
    
    public enum Scope: String {
        case Address = "address"
        case AdministrativeArea = "region"
        case Country = "country"
        case District = "district"
        case Locality = "locality"
        case Neighborhood = "neighborhood"
        case Place = "place"
        case PointOfInterest = "poi"
        case PostalCode = "postcode"
    }

    required public init?(coder aDecoder: NSCoder) {
        featureJSON = aDecoder.decodeObjectOfClass(NSDictionary.self, forKey: "featureJSON") as! JSON?
    }
    
    public override init() {
        super.init()
    }

    public convenience init(placemark: MBPlacemark) {
        self.init()
        featureJSON = placemark.featureJSON
    }

    internal convenience init?(featureJSON: JSON) {
        if let geometry = featureJSON["geometry"] as? NSDictionary,
          type = geometry["type"] as? String where type == "Point",
          let _ = geometry["coordinates"] as? NSArray,
          let _ = featureJSON["place_name"] as? String {
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
    
    var identifier: String? {
        return featureJSON?["id"] as? String
    }
    
    public override func isEqual(object: AnyObject?) -> Bool {
        if let object = object as? MBPlacemark {
            return identifier == object.identifier
        }
        return false
    }
    
    public override var description: String {
        return featureJSON?["place_name"] as? String ?? ""
    }

    public var location: CLLocation? {
        if let feature = featureJSON?["geometry"] as? JSON, coordinates = feature["coordinates"] as? [Double] {
            return CLLocation(latitude: coordinates.last!, longitude: coordinates.first!)
        }
        return nil
    }

    public var name: String? {
        if scope == .Address {
            return "\(subThoroughfare ?? "") \(thoroughfare ?? "")"
                .stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
        }
        
        let name = featureJSON?["text"] as? String ?? ""
        return !name.isEmpty ? name : description
    }
    
    public var scope: Scope? {
        if let identifier = featureJSON?["id"] as? String {
            if let scopeCharacters = identifier.characters.split(".").first {
                if let scope = Scope(rawValue: String(scopeCharacters)) {
                    return scope
                }
            }
        }
        return nil
    }
    
    var formattedAddressLines: [String]? {
        if let name = featureJSON?["place_name"] as? String {
            let lines = name.componentsSeparatedByString(", ")
            return scope == .Address ? lines : Array(lines.suffixFrom(1))
        }
        return nil
    }

    public var addressDictionary: [NSObject: AnyObject]? {
        guard featureJSON != nil else {
            return nil
        }
        
        var addressDictionary: [String: AnyObject] = [:]
        if scope == .Address {
            addressDictionary[MBPostalAddressStreetKey] = name
        } else if let address = properties?["address"] as? String {
            addressDictionary[MBPostalAddressStreetKey] = address
        }
        addressDictionary[MBPostalAddressCityKey] = locality
        addressDictionary[MBPostalAddressStateKey] = administrativeArea
        addressDictionary[MBPostalAddressPostalCodeKey] = postalCode
        addressDictionary[MBPostalAddressCountryKey] = country
        addressDictionary[MBPostalAddressISOCountryCodeKey] = ISOcountryCode
        addressDictionary["formattedAddressLines"] = formattedAddressLines
        addressDictionary["name"] = name
        addressDictionary["subAdministrativeArea"] = subAdministrativeArea
        addressDictionary["subLocality"] = subLocality
        addressDictionary["subThoroughfare"] = subThoroughfare
        addressDictionary["thoroughfare"] = thoroughfare
        return addressDictionary
    }
    
    var context: [JSON]? {
        return featureJSON?["context"] as? [JSON]
    }
    
    func contextItemsWithType(type: String) -> [JSON]? {
        return context?.filter({
            ($0["id"] as? String)?.hasPrefix("\(type).") ?? false
        })
    }
    
    var properties: JSON? {
        return featureJSON?["properties"] as? JSON
    }
    
    public var ISOcountryCode: String? {
        if let country = contextItemsWithType("country")?.first {
            return (country["short_code"] as? String)?.uppercaseString
        }
        return nil
    }

    public var country: String? {
        if let country = contextItemsWithType("country")?.first {
            return country["text"] as? String
        }
        return nil
    }

    public var postalCode: String? {
        if let country = contextItemsWithType("postcode")?.first {
            return country["text"] as? String
        }
        return nil
    }

    public var administrativeArea: String? {
        if let region = contextItemsWithType("region")?.last {
            return region["text"] as? String
        }
        return nil
    }

    public var subAdministrativeArea: String? {
        if let district = contextItemsWithType("district")?.last {
            return district["text"] as? String
        }
        if let place = contextItemsWithType("place")?.last {
            return place["text"] as? String
        }
        return nil
    }

    public var locality: String? {
        if let place = contextItemsWithType("place")?.last {
            return place["text"] as? String
        }
        return nil
    }

    public var subLocality: String? {
        if let country = contextItemsWithType("neighborhood")?.last {
            return country["text"] as? String
        }
        return nil
    }

    public var thoroughfare: String? {
        if scope == .Address {
            return featureJSON?["text"] as? String
        }
        return nil
    }

    public var subThoroughfare: String? {
        if let address = featureJSON?["address"] {
            return String(address)
        }
        return nil
    }

    public var region: MBRectangularRegion? {
        if let boundingBox = featureJSON?["bbox"] as? [Double] {
            return MBRectangularRegion(southWest: CLLocationCoordinate2D(latitude: boundingBox[1], longitude: boundingBox[0]),
                northEast: CLLocationCoordinate2D(latitude: boundingBox[3], longitude: boundingBox[2]))
        }
        return nil
    }
    
    public var timeZone: NSTimeZone? {
        return nil
    }

    public var inlandWater: String? {
        return nil
    }

    public var ocean: String? {
        return nil
    }

    public var areasOfInterest: [String]? {
        return nil
    }
    
    /// Maki image name. <https://www.mapbox.com/maki/>
    public var imageName: String? {
        if let maki = properties?["maki"] as? String {
            return maki
        }
        return nil
    }
    
    public var genres: [String]? {
        if let category = properties?["category"] as? String {
            return category.componentsSeparatedByString(", ")
        }
        return nil
    }
}

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
