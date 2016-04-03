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
    
    public init(accessToken: String) {
        configuration = MBGeocoderConfiguration(accessToken)
    }
    
    private var task: NSURLSessionDataTask?
    
    private var errorForSimultaneousRequests: NSError {
        let userInfo = [
            NSLocalizedFailureReasonErrorKey: "Cannot geocode on an MBGeocoder object that is already geocoding.",
        ]
        return NSError(domain: MBGeocoderErrorDomain, code: -1, userInfo: userInfo)
    }
    
    public var geocoding: Bool {
        return task?.state == .Running
    }
    
    public func reverseGeocodeLocation(location: CLLocation, completionHandler: MBGeocodeCompletionHandler) {
        guard !geocoding else {
            completionHandler(nil, errorForSimultaneousRequests)
            return
        }
        
        let query = String(format: "%.5f,%.5f", location.coordinate.longitude, location.coordinate.latitude)
        let router = MBGeocoderRouter.V5(configuration, false, query, nil, nil, nil, nil)
        task = taskWithRouter(router, completionHandler: completionHandler)
    }

//    public func geocodeAddressDictionary(addressDictionary: [NSObject : AnyObject],
//        completionHandler: MBGeocodeCompletionHandler)
    
    public func geocodeAddressString(addressString: String, nearLocation focusLocation: CLLocation? = nil, inCountries ISOCountryCodes: [String]? = nil, completionHandler: MBGeocodeCompletionHandler) {
        guard !geocoding else {
            completionHandler(nil, errorForSimultaneousRequests)
            return
        }
        
        let router = MBGeocoderRouter.V5(configuration, false, addressString, ISOCountryCodes, focusLocation?.coordinate, nil, nil)
        task = taskWithRouter(router, completionHandler: completionHandler)
    }

//    public func geocodeAddressString(addressString: String, inRegion region: CLRegion, completionHandler: MBGeocodeCompletionHandler)
    
    private func taskWithRouter(router: MBGeocoderRouter, completionHandler completion: MBGeocodeCompletionHandler) -> NSURLSessionDataTask? {
        return router.loadJSON(JSON.self) { [weak self] (json, error) in
            guard let dataTaskSelf = self where dataTaskSelf.task?.state == .Completed
                else {
                    return
            }
            
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
        }
    }

    public func cancelGeocode() {
        task?.cancel()
    }
}
