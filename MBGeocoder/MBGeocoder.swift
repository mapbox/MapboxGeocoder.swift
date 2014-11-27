import Foundation
import CoreLocation

public class MBGeocoder: NSObject, NSURLConnectionDelegate, NSURLConnectionDataDelegate {

    // MARK: -
    // MARK: Setup

    private var accessToken: NSString
    
    public init(accessToken: NSString) {
        self.accessToken = accessToken
    }
    
    public typealias MBGeocodeCompletionHandler = CLGeocodeCompletionHandler

    private var connection: NSURLConnection?
    private var completionHandler: MBGeocodeCompletionHandler?
    private var receivedData: NSMutableData?
    
    private let MBGeocoderErrorDomain = "MBGeocoderErrorDomain"

    private enum MBGeocoderErrorCode: Int {
        case ConnectionError = -1000
        case HTTPError       = -1001
        case ParseError      = -1002
    }
    
    // MARK: -
    // MARK: Public API

    public var geocoding: Bool {
        return (connection != nil)
    }
    
    public func reverseGeocodeLocation(location: CLLocation!, completionHandler: MBGeocodeCompletionHandler!) {
        if !geocoding {
            self.completionHandler = completionHandler
            let requestString = "https://api.tiles.mapbox.com/v4/geocode/mapbox.places-v1/" +
                                "\(location.coordinate.longitude),\(location.coordinate.latitude).json" +
                                "?access_token=" + accessToken
            let request = NSURLRequest(URL: NSURL(string: requestString)!)
            connection = NSURLConnection(request: request, delegate: self)
        }
    }

    public func geocodeAddressDictionary(addressDictionary: [NSObject : AnyObject]!,
        completionHandler: MBGeocodeCompletionHandler!) {

    }
    
    public func geocodeAddressString(addressString: String!,
        completionHandler: MBGeocodeCompletionHandler!) {
        if !geocoding {
            self.completionHandler = completionHandler
            let requestString = "https://api.tiles.mapbox.com/v4/geocode/mapbox.places-v1/" +
                                addressString.stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)! +
                                ".json?access_token=" + accessToken
            let request = NSURLRequest(URL: NSURL(string: requestString)!)
            connection = NSURLConnection(request: request, delegate: self)
        }
    }

    public func geocodeAddressString(addressString: String!,
        inRegion region: CLRegion!,
        completionHandler: MBGeocodeCompletionHandler!) {
            
    }
    
    public func cancelGeocode() {
        connection?.cancel()
        connection = nil
    }
    
    // MARK: -
    // MARK: NSURLConnection Delegates

    public func connection(connection: NSURLConnection!, didFailWithError error: NSError!) {
        self.connection = nil
        completionHandler?(nil, NSError(domain: MBGeocoderErrorDomain,
                                        code: MBGeocoderErrorCode.ConnectionError.rawValue,
                                        userInfo: error.userInfo))
    }

    public func connection(connection: NSURLConnection!, didReceiveResponse response: NSURLResponse!) {
        let statusCode = (response as NSHTTPURLResponse).statusCode
        if statusCode != 200 {
            connection.cancel()
            self.connection = nil
            completionHandler?(nil, NSError(domain: MBGeocoderErrorDomain,
                                            code: MBGeocoderErrorCode.HTTPError.rawValue,
                                            userInfo: [ NSLocalizedDescriptionKey: "Received HTTP status code \(statusCode)" ]))
        } else {
            receivedData = NSMutableData()
        }
    }
    
    public func connection(connection: NSURLConnection!, didReceiveData data: NSData!) {
        receivedData!.appendData(data)
    }
    
    public func connectionDidFinishLoading(connection: NSURLConnection!) {
        var parseError: NSError?
        let response = NSJSONSerialization.JSONObjectWithData(receivedData!, options: nil, error: &parseError) as NSDictionary
        if parseError != nil {
            completionHandler?(nil, NSError(domain: MBGeocoderErrorDomain,
                                            code: MBGeocoderErrorCode.ParseError.rawValue,
                                            userInfo: [ NSLocalizedDescriptionKey: "Unable to parse results" ]))
        } else {
            let features = response["features"] as NSArray
            if features.count > 0 {
                var results = NSMutableArray()
                for feature in features {
                    results.addObject(MBPlacemark(featureJSON: feature as NSDictionary))
                }
                completionHandler?(NSArray(array: results), nil)
            } else {
                completionHandler?([], nil)
            }
        }
    }

}

// MARK: -

public class MBPlacemark: NSObject {
    
    private var featureJSON: NSDictionary
    
    private init(featureJSON: NSDictionary) {
        self.featureJSON = featureJSON
    }
    
    public var location: CLLocation! {
        let geometry = self.featureJSON["geometry"] as NSDictionary

        var coordinates: NSArray?

        if (geometry["type"] as String == "Point") {
            coordinates = geometry["coordinates"] as? NSArray
        }

        if (coordinates != nil) {
            return CLLocation(latitude:  coordinates![1].doubleValue,
                              longitude: coordinates![0].doubleValue)
        }

        return nil
    }

    public var name: String! {
        return featureJSON["place_name"] as NSString
    }
    
}