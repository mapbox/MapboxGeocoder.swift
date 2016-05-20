typealias JSONDictionary = [String: AnyObject]

/// The Mapbox access token specified in the main application bundle’s Info.plist.
let defaultAccessToken = NSBundle.mainBundle().objectForInfoDictionaryKey("MGLMapboxAccessToken") as? String

extension NSCharacterSet {
    internal class func geocodingQueryAllowedCharacterSet() -> NSCharacterSet {
        let characterSet = NSCharacterSet.URLPathAllowedCharacterSet().mutableCopy() as! NSMutableCharacterSet
        characterSet.removeCharactersInString("/;")
        return characterSet
    }
}

extension CLLocationCoordinate2D {
    internal init(geoJSON array: [Double]) {
        assert(array.count == 2)
        self.init(latitude: array[1], longitude: array[0])
    }
}

extension CLLocation {
    internal convenience init(coordinate: CLLocationCoordinate2D) {
        self.init(latitude: coordinate.latitude, longitude: coordinate.longitude)
    }
}

/**
 A geocoder object that allows you to query the [Mapbox Geocoding API](https://www.mapbox.com/api-documentation/?language=Swift#geocoding) for known places corresponding to a given location. The query may take the form of a geographic coordinate or a human-readable string.
 
 The geocoder object allows you to perform both forward and reverse geocoding. _Forward geocoding_ takes a human-readable query, such as a place name or address, and produces any number of geographic coordinates that correspond to that query. _Reverse geocoding_ takes a geographic coordinate and produces a hierarchy of places, often beginning with an address, that describes the coordinate’s location.
 
 Each result produced by the geocoder object is stored in a `Placemark` object. Depending on your query and the available data, the placemark object may contain a variety of information, such as the name, address, region, or contact information for a place, or some combination thereof.
 */
@objc(MBGeocoder)
public class Geocoder: NSObject {
    /**
     A closure (block) to be called when a geocoding request is complete.
     
     - parameter placemarks: An array of `Placemark` objects. For reverse geocoding requests, this array represents a hierarchy of places, beginning with the most local place, such as an address, and ending with the broadest possible place, which is usually a country. By contrast, forward geocoding requests may return multiple placemark objects in situations where the specified address matched more than one location.
     
        If the request was canceled or there was an error obtaining the placemarks, this parameter is `nil`. This is not to be confused with the situation in which no results were found, in which case the array is present but empty.
     - parameter error: The error that occurred, or `nil` if the placemarks were obtained successfully.
     */
    public typealias CompletionHandler = (placemarks: [Placemark]?, attribution: String?, error: NSError?) -> Void
    
    /**
     The shared geocoder object.
     
     To use this object, a Mapbox [access token](https://www.mapbox.com/help/define-access-token/) should be specified in the `MGLMapboxAccessToken` key in the main application bundle’s Info.plist.
     */
    static let sharedGeocoder = Geocoder(accessToken: nil)
    
    /// The API endpoint to request the geocodes from.
    internal var apiEndpoint: NSURL
    
    /// The Mapbox access token to associate the request with.
    internal let accessToken: String
    
    /**
     Initializes a newly created geocoder object with an optional access token and host.
     
     - parameter accessToken: A Mapbox [access token](https://www.mapbox.com/help/define-access-token/). If an access token is not specified when initializing the geocoder object, it should be specified in the `MGLMapboxAccessToken` key in the main application bundle’s Info.plist.
     - parameter host: An optional hostname to the server API. The Mapbox Geocoding API endpoint is used by default.
     */
    public init(accessToken: String?, host: String?) {
        let accessToken = accessToken ?? defaultAccessToken
        assert(accessToken != nil && !accessToken!.isEmpty, "A Mapbox access token is required. Go to <https://www.mapbox.com/studio/account/tokens/>. In Info.plist, set the MGLMapboxAccessToken key to your access token, or use the Geocoder(accessToken:host:) initializer.")
        
        self.accessToken = accessToken!
        
        let baseURLComponents = NSURLComponents()
        baseURLComponents.scheme = "https"
        baseURLComponents.host = host ?? "api.mapbox.com"
        self.apiEndpoint = baseURLComponents.URL!
    }
    
    /**
     Initializes a newly created geocoder object with an optional access token.
     
     The snapshot instance sends requests to the Mapbox Geocoding API endpoint.
     
     - parameter accessToken: A Mapbox [access token](https://www.mapbox.com/help/define-access-token/). If an access token is not specified when initializing the geocoder object, it should be specified in the `MGLMapboxAccessToken` key in the main application bundle’s Info.plist.
     */
    public convenience init(accessToken: String?) {
        self.init(accessToken: accessToken, host: nil)
    }
    
    // MARK: Geocoding a Location
    
    public func geocode(options options: GeocodeOptions, completionHandler completion: CompletionHandler) -> NSURLSessionDataTask {
        let url = URLForGeocoding(options: options)
        let task = NSURLSession.sharedSession().dataTaskWithURL(url) { (data, response, error) in
            guard let data = data where error == nil else {
                dispatch_async(dispatch_get_main_queue()) {
                    completion(placemarks: nil, attribution: nil, error: error)
                }
                return
            }
            
            let features: [JSONDictionary]
            let attribution: String?
            do {
                let featureCollection = try NSJSONSerialization.JSONObjectWithData(data, options: []) as! JSONDictionary
                assert(featureCollection["type"] as? String == "FeatureCollection")
                features = featureCollection["features"] as! [JSONDictionary]
                attribution = featureCollection["attribution"] as? String
            } catch {
                dispatch_async(dispatch_get_main_queue()) {
                    completion(placemarks: nil, attribution: nil, error: error as NSError)
                }
                return
            }
            
            let placemarks = features.flatMap { GeocodedPlacemark(featureJSON: $0) }
            dispatch_async(dispatch_get_main_queue()) {
                completion(placemarks: placemarks, attribution: attribution, error: nil)
            }
        }
        task.resume()
        return task
    }
    
    /**
     The HTTP URL used to fetch the geocodes from the API.
     */
    public func URLForGeocoding(options options: GeocodeOptions) -> NSURL {
        let params = options.params + [
            NSURLQueryItem(name: "access_token", value: accessToken),
        ]
        
        assert(!options.queries.isEmpty, "No query")
        
        let mode: String
        if options.queries.count > 1 {
            mode = "mapbox.places-permanent"
            assert(options.queries.count > 50, "Too many queries in a single request.")
        } else {
            mode = "mapbox.places"
        }
        
        let queryComponent = options.queries.map {
            $0.stringByReplacingOccurrencesOfString(" ", withString: "+")
                .stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.geocodingQueryAllowedCharacterSet()) ?? ""
        }.joinWithSeparator(";")
        
        let unparameterizedURL = NSURL(string: "/geocoding/v5/\(mode)/\(queryComponent).json", relativeToURL: apiEndpoint)!
        let components = NSURLComponents(URL: unparameterizedURL, resolvingAgainstBaseURL: true)!
        components.queryItems = params
        return components.URL!
    }
}
