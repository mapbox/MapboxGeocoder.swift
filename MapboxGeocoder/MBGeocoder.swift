import Foundation
import CoreLocation

// like CLGeocodeCompletionHandler
public typealias MBGeocodeCompletionHandler = ([MBPlacemark]?, NSError?) -> Void
internal typealias JSON = [String: AnyObject]

extension CLLocationCoordinate2D: Equatable {}
public func ==(left: CLLocationCoordinate2D, right: CLLocationCoordinate2D) -> Bool {
    return (left.latitude == right.latitude && left.longitude == right.longitude)
}

public let MBGeocoderErrorDomain = "MBGeocoderErrorDomain"

public class MBGeocoder: NSObject {

    private let configuration: MBGeocoderConfiguration
    
    /**
     Initializes a newly created geocoder with the given access token and an optional host.
     
     - param accessToken: A Mapbox access token.
     - param host: An optional hostname to the server API. The Mapbox Geocoding API endpoint is used by default.
     */
    public init(accessToken: String, host: String?) {
        configuration = MBGeocoderConfiguration(accessToken, host: host)
    }
    
    /**
     Initializes a newly created geocoder with the given access token and the default host.
     
     - param accessToken: A Mapbox access token.
     */
    public convenience init(accessToken: String) {
        self.init(accessToken: accessToken, host: nil)
    }
    
    private static let sessionConfiguration = NSURLSessionConfiguration.defaultSessionConfiguration()
    public var session = NSURLSession(configuration: sessionConfiguration)
    
    public func reverseGeocodeLocation(location: CLLocation, completionHandler: MBGeocodeCompletionHandler) -> NSURLSessionDataTask? {
        let query = String(format: "%.5f,%.5f", location.coordinate.longitude, location.coordinate.latitude)
        let router = MBGeocoderRouter.V5(configuration, false, query, nil, nil, nil, nil)
        return taskWithRouter(router, completionHandler: completionHandler)
    }

//    public func geocodeAddressDictionary(addressDictionary: [NSObject : AnyObject],
//        completionHandler: MBGeocodeCompletionHandler)
    
    public func geocodeAddressString(addressString: String, withAllowedScopes scopes: [MBPlacemark.Scope]? = nil, nearLocation focusLocation: CLLocation? = nil, inCountries ISOCountryCodes: [String]? = nil, completionHandler: MBGeocodeCompletionHandler) -> NSURLSessionDataTask? {
        let router = MBGeocoderRouter.V5(configuration, false, addressString, ISOCountryCodes, focusLocation?.coordinate, scopes, nil)
        return taskWithRouter(router, completionHandler: completionHandler)
    }

//    public func geocodeAddressString(addressString: String, inRegion region: CLRegion, completionHandler: MBGeocodeCompletionHandler)
    
    private func taskWithRouter(router: MBGeocoderRouter, completionHandler completion: MBGeocodeCompletionHandler) -> NSURLSessionDataTask? {
        return router.loadJSON(session, expectedResultType: JSON.self) { (json, error) in
            guard error == nil && json != nil else {
                dispatch_sync(dispatch_get_main_queue()) {
                    completion(nil, error as? NSError)
                }
                return
            }
            
            let features = json!["features"] as! [JSON]
            let placemarks = features.flatMap { MBPlacemark(featureJSON: $0) }
            
            dispatch_sync(dispatch_get_main_queue()) {
                completion(placemarks, error as? NSError)
            }
        } as? NSURLSessionDataTask
    }

    public func cancelGeocode() {
        session.invalidateAndCancel()
        session = NSURLSession(configuration: MBGeocoder.sessionConfiguration)
    }
}
