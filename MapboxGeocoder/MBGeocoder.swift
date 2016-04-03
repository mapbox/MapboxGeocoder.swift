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
