typealias JSONDictionary = [String: AnyObject]

public let MBGeocoderErrorDomain = "com.mapbox.MapboxGeocoder"

/// The Mapbox access token specified in the main application bundle’s Info.plist.
let defaultAccessToken = NSBundle.mainBundle().objectForInfoDictionaryKey("MGLMapboxAccessToken") as? String

extension NSCharacterSet {
    /**
     Returns the character set including the characters allowed in the “geocoding query” (file name) part of a Geocoding API URL request.
     */
    internal class func geocodingQueryAllowedCharacterSet() -> NSCharacterSet {
        let characterSet = NSCharacterSet.URLPathAllowedCharacterSet().mutableCopy() as! NSMutableCharacterSet
        characterSet.removeCharactersInString("/;")
        return characterSet
    }
}

extension CLLocationCoordinate2D {
    /**
     Initializes a coordinate pair based on the given GeoJSON array.
     */
    internal init(geoJSON array: [Double]) {
        assert(array.count == 2)
        self.init(latitude: array[1], longitude: array[0])
    }
}

extension CLLocation {
    /**
     Initializes a CLLocation object with the given coordinate pair.
     */
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
     - parameter attribution: A legal notice indicating the source, copyright status, and terms of use of the placemark data.
     - parameter error: The error that occurred, or `nil` if the placemarks were obtained successfully.
     */
    public typealias CompletionHandler = (placemarks: [GeocodedPlacemark]?, attribution: String?, error: NSError?) -> Void
    
    /**
     A closure (block) to be called when a geocoding request is complete.
     
     - parameter placemarksByQuery: An array of arrays of `Placemark` objects, one placemark array for each query. For reverse geocoding requests, these arrays represent hierarchies of places, beginning with the most local place, such as an address, and ending with the broadest possible place, which is usually a country. By contrast, forward geocoding requests may return multiple placemark objects in situations where the specified address matched more than one location.
        
        If the request was canceled or there was an error obtaining the placemarks, this parameter is `nil`. This is not to be confused with the situation in which no results were found, in which case the array is present but empty.
     - parameter attributionsByQuery: An array of legal notices indicating the sources, copyright statuses, and terms of use of the placemark data for each query.
     - parameter error: The error that occurred, or `nil` if the placemarks were obtained successfully.
     */
    public typealias BatchCompletionHandler = (placemarksByQuery: [[GeocodedPlacemark]]?, attributionsByQuery: [String]?, error: NSError?) -> Void
    
    /**
     The shared geocoder object.
     
     To use this object, a Mapbox [access token](https://www.mapbox.com/help/define-access-token/) should be specified in the `MGLMapboxAccessToken` key in the main application bundle’s Info.plist.
     */
    public static let sharedGeocoder = Geocoder(accessToken: nil)
    
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
    
    /**
     Submits a geocoding request to search for placemarks and delivers the results to the given closure.
     
     This method retrieves the placemarks asynchronously over a network connection. If a connection error or server error occurs, details about the error are passed into the given completion handler in lieu of the placemarks.
     
     Geocoding results may be displayed atop a Mapbox map. They may be cached but may not be stored permanently. To use the results in other contexts or store them permanently, use the `batchGeocode(options:completionHandler:)` method with a Mapbox enterprise plan.
     
     - parameter options: A `ForwardGeocodeOptions` or `ReverseGeocodeOptions` object indicating what to search for.
     - parameter completionHandler: The closure (block) to call with the resulting placemarks. This closure is executed on the application’s main thread.
     - returns: The data task used to perform the HTTP request. If, while waiting for the completion handler to execute, you no longer want the resulting placemarks, cancel this task.
     */
    public func geocode(options options: GeocodeOptions, completionHandler: CompletionHandler) -> NSURLSessionDataTask {
        let url = URLForGeocoding(options: options)
        let task = dataTaskWithURL(url, completionHandler: { (json) in
            let featureCollection = json as! JSONDictionary
            assert(featureCollection["type"] as? String == "FeatureCollection")
            let features = featureCollection["features"] as! [JSONDictionary]
            let attribution = featureCollection["attribution"] as? String
            
            let placemarks = features.flatMap { GeocodedPlacemark(featureJSON: $0) }
            completionHandler(placemarks: placemarks, attribution: attribution, error: nil)
        }) { (error) in
            completionHandler(placemarks: nil, attribution: nil, error: error)
        }
        task.resume()
        return task
    }
    
    /**
     Submits a batch geocoding request to search for placemarks and delivers the results to the given closure.
     
     This method retrieves the placemarks asynchronously over a network connection. If a connection error or server error occurs, details about the error are passed into the given completion handler in lieu of the placemarks.
     
     Batch geocoding requires a Mapbox enterprise plan and allows you to store the resulting placemark data as part of a private database.
     
     - parameter options: A `ForwardBatchGeocodeOptions` or `ReverseBatchGeocodeOptions` object indicating what to search for.
     - parameter completionHandler: The closure (block) to call with the resulting placemarks. This closure is executed on the application’s main thread.
     - returns: The data task used to perform the HTTP request. If, while waiting for the completion handler to execute, you no longer want the resulting placemarks, cancel this task.
     */
    public func batchGeocode<T: GeocodeOptions where T: BatchGeocodeOptions>(options options: T, completionHandler: BatchCompletionHandler) -> NSURLSessionDataTask {
        let url = URLForGeocoding(options: options)
        let task = dataTaskWithURL(url, completionHandler: { (json) in
            let featureCollections = json as! [JSONDictionary]
            let placemarksByQuery = featureCollections.map { (featureCollection) -> [GeocodedPlacemark] in
                assert(featureCollection["type"] as? String == "FeatureCollection")
                let features = featureCollection["features"] as! [JSONDictionary]
                return features.flatMap { GeocodedPlacemark(featureJSON: $0) }
            }
            let attributionsByQuery = featureCollections.map { $0["attribution"] as! String }
            completionHandler(placemarksByQuery: placemarksByQuery, attributionsByQuery: attributionsByQuery, error: nil)
        }) { (error) in
            completionHandler(placemarksByQuery: nil, attributionsByQuery: nil, error: error)
        }
        task.resume()
        return task
    }
    
    /**
     Returns a URL session task for the given URL that will run the given blocks on completion or error.
     
     - parameter url: The URL to request.
     - parameter completionHandler: The closure to call with the parsed JSON response dictionary.
     - parameter errorHandler: The closure to call when there is an error.
     - returns: The data task for the URL.
     - postcondition: The caller must resume the returned task.
     */
    private func dataTaskWithURL(url: NSURL, completionHandler: (json: AnyObject) -> Void, errorHandler: (error: NSError) -> Void) -> NSURLSessionDataTask {
        return NSURLSession.sharedSession().dataTaskWithURL(url) { (data, response, error) in
            var json: AnyObject = [:]
            if let data = data {
                do {
                    json = try NSJSONSerialization.JSONObjectWithData(data, options: [])
                } catch {
                    assert(false, "Invalid data")
                }
            }
            
            guard data != nil && error == nil else {
                // Supplement the error with additional information from the response body or headers.
                var userInfo = error?.userInfo ?? [:]
                if let json = json as? JSONDictionary, message = json["message"] as? String {
                    userInfo[NSLocalizedFailureReasonErrorKey] = message
                }
                if let response = response as? NSHTTPURLResponse where response.statusCode == 429 {
                    if let rolloverTimestamp = response.allHeaderFields["x-rate-limit-reset"] as? Double {
                        let date = NSDate(timeIntervalSince1970: rolloverTimestamp)
                        userInfo[NSLocalizedRecoverySuggestionErrorKey] = "Wait until \(date) before retrying."
                    }
                }
                let apiError = NSError(domain: error?.domain ?? MBGeocoderErrorDomain, code: error?.code ?? -1, userInfo: userInfo)
                
                dispatch_async(dispatch_get_main_queue()) {
                    errorHandler(error: apiError)
                }
                return
            }
            
            dispatch_async(dispatch_get_main_queue()) {
                completionHandler(json: json)
            }
        }
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
