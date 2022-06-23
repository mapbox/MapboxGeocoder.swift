import Foundation
import CoreLocation

typealias JSONDictionary = [String: Any]

/// Indicates that an error occurred in MapboxGeocoder.
public let MBGeocoderErrorDomain = "MBGeocoderErrorDomain"

/// The Mapbox access token specified in the main application bundle’s Info.plist.
let defaultAccessToken =
    Bundle.main.object(forInfoDictionaryKey: "MBXAccessToken") as? String ??
    Bundle.main.object(forInfoDictionaryKey: "MGLMapboxAccessToken") as? String

/// The user agent string for any HTTP requests performed directly within this library.
let userAgent: String = {
    var components: [String] = []

    if let appName = Bundle.main.infoDictionary?["CFBundleName"] as? String ?? Bundle.main.infoDictionary?["CFBundleIdentifier"] as? String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        components.append("\(appName)/\(version)")
    }

    let libraryBundle: Bundle? = Bundle(for: Geocoder.self)

    if let libraryName = libraryBundle?.infoDictionary?["CFBundleName"] as? String, let version = libraryBundle?.infoDictionary?["CFBundleShortVersionString"] as? String {
        components.append("\(libraryName)/\(version)")
    }

    let system: String
    #if os(macOS)
        system = "macOS"
    #elseif os(iOS)
        system = "iOS"
    #elseif os(watchOS)
        system = "watchOS"
    #elseif os(tvOS)
        system = "tvOS"
    #elseif os(Linux)
        system = "Linux"
    #else
        system = "unknown"
    #endif
    let systemVersion = ProcessInfo().operatingSystemVersion
    components.append("\(system)/\(systemVersion.majorVersion).\(systemVersion.minorVersion).\(systemVersion.patchVersion)")

    let chip: String
    #if arch(x86_64)
        chip = "x86_64"
    #elseif arch(arm)
        chip = "arm"
    #elseif arch(arm64)
        chip = "arm64"
    #elseif arch(i386)
        chip = "i386"
    #elseif os(watchOS) // Workaround for incorrect arch in machine.h for watch simulator  gen 4
        chip = "i386"
    #else
        chip = "unknown"
    #endif
    
    var simulator: String? = nil
    #if targetEnvironment(simulator)
        simulator = "Simulator"
    #endif

    let otherComponents = [
        chip,
        simulator
    ].compactMap({ $0 })

    components.append("(\(otherComponents.joined(separator: "; ")))")

    return components.joined(separator: " ")
}()

extension CharacterSet {
    /**
     Returns the character set including the characters allowed in the “geocoding query” (file name) part of a Geocoding API URL request.
     */
    internal static func geocodingQueryAllowedCharacterSet() -> CharacterSet {
        var characterSet = CharacterSet.urlPathAllowed
        characterSet.remove(charactersIn: "/;")
        return characterSet
    }
}

extension CLLocationCoordinate2D {
    /**
     Initializes a coordinate pair based on the given GeoJSON array.
     */
    internal init(geoJSON array: [CLLocationDegrees]) {
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

    /**
     Returns a GeoJSON compatible array of coordinates.
     */
    internal func geojson() -> [CLLocationDegrees] {
        return [coordinate.longitude, coordinate.latitude]
    }
}

/**
 A geocoder object that allows you to query the [Mapbox Geocoding API](https://www.mapbox.com/api-documentation/search/#geocoding) for known places corresponding to a given location. The query may take the form of a geographic coordinate or a human-readable string.

 The geocoder object allows you to perform both forward and reverse geocoding. _Forward geocoding_ takes a human-readable query, such as a place name or address, and produces any number of geographic coordinates that correspond to that query. _Reverse geocoding_ takes a geographic coordinate and produces a hierarchy of places, often beginning with an address, that describes the coordinate’s location.

 Each result produced by the geocoder object is stored in a `Placemark` object. Depending on your query and the available data, the placemark object may contain a variety of information, such as the name, address, region, or contact information for a place, or some combination thereof.
 */
@objc(MBGeocoder)
open class Geocoder: NSObject {
    /**
     A closure (block) to be called when a geocoding request is complete.

     - parameter placemarks: An array of `Placemark` objects. For reverse geocoding requests, this array represents a hierarchy of places, beginning with the most local place, such as an address, and ending with the broadest possible place, which is usually a country. By contrast, forward geocoding requests may return multiple placemark objects in situations where the specified address matched more than one location.

        If the request was canceled or there was an error obtaining the placemarks, this parameter is `nil`. This is not to be confused with the situation in which no results were found, in which case the array is present but empty.
     - parameter attribution: A legal notice indicating the source, copyright status, and terms of use of the placemark data.
     - parameter error: The error that occurred, or `nil` if the placemarks were obtained successfully.
     */
    public typealias CompletionHandler = (_ placemarks: [GeocodedPlacemark]?, _ attribution: String?, _ error: NSError?) -> Void

    /**
     A closure (block) to be called when a geocoding request is complete.

     - parameter placemarksByQuery: An array of arrays of `Placemark` objects, one placemark array for each query. For reverse geocoding requests, these arrays represent hierarchies of places, beginning with the most local place, such as an address, and ending with the broadest possible place, which is usually a country. By contrast, forward geocoding requests may return multiple placemark objects in situations where the specified address matched more than one location.

        If the request was canceled or there was an error obtaining the placemarks, this parameter is `nil`. This is not to be confused with the situation in which no results were found, in which case the array is present but empty.
     - parameter attributionsByQuery: An array of legal notices indicating the sources, copyright statuses, and terms of use of the placemark data for each query.
     - parameter error: The error that occurred, or `nil` if the placemarks were obtained successfully.
     */
    public typealias BatchCompletionHandler = (_ placemarksByQuery: [[GeocodedPlacemark]]?, _ attributionsByQuery: [String]?, _ error: NSError?) -> Void

    /**
     The shared geocoder object.

     To use this object, a Mapbox [access token](https://www.mapbox.com/help/define-access-token/) should be specified in the `MGLMapboxAccessToken` key in the main application bundle’s Info.plist.
     */
    @objc(sharedGeocoder)
    public static let shared = Geocoder(accessToken: nil)

    /// The API endpoint to request the geocodes from.
    internal var apiEndpoint: URL

    /// The Mapbox access token to associate the request with.
    internal let accessToken: String

    /**
     Initializes a newly created geocoder object with an optional access token and host.

     - parameter accessToken: A Mapbox [access token](https://www.mapbox.com/help/define-access-token/). If an access token is not specified when initializing the geocoder object, it should be specified in the `MGLMapboxAccessToken` key in the main application bundle’s Info.plist.
     - parameter host: An optional hostname to the server API. The Mapbox Geocoding API endpoint is used by default.
     */
    @objc public init(accessToken: String?, host: String?) {
        let accessToken = accessToken ?? defaultAccessToken
        assert(accessToken != nil && !accessToken!.isEmpty, "A Mapbox access token is required. Go to <https://www.mapbox.com/studio/account/tokens/>. In Info.plist, set the MGLMapboxAccessToken key to your access token, or use the Geocoder(accessToken:host:) initializer.")

        self.accessToken = accessToken!

        var baseURLComponents = URLComponents()
        baseURLComponents.scheme = "https"
        baseURLComponents.host = host ?? "api.mapbox.com"
        self.apiEndpoint = baseURLComponents.url!
    }

    /**
     Initializes a newly created geocoder object with an optional access token.

     The geocoder object sends requests to the Mapbox Geocoding API endpoint.

     - parameter accessToken: A Mapbox [access token](https://www.mapbox.com/help/define-access-token/). If an access token is not specified when initializing the geocoder object, it should be specified in the `MGLMapboxAccessToken` key in the main application bundle’s Info.plist.
     */
    @objc public convenience init(accessToken: String?) {
        self.init(accessToken: accessToken, host: nil)
    }

    // MARK: Geocoding a Location

    /**
     Submits a geocoding request to search for placemarks and delivers the results to the given closure.

     This method retrieves the placemarks asynchronously over a network connection. If a connection error or server error occurs, details about the error are passed into the given completion handler in lieu of the placemarks.

     Geocoding results may be displayed atop a Mapbox map. They may be cached but may not be stored permanently. To use the results in other contexts or store them permanently, use the `batchGeocode(_:completionHandler:)` method with a Mapbox enterprise plan.

     - parameter options: A `ForwardGeocodeOptions` or `ReverseGeocodeOptions` object indicating what to search for.
     - parameter completionHandler: The closure (block) to call with the resulting placemarks. This closure is executed on the application’s main thread.
     - returns: The data task used to perform the HTTP request. If, while waiting for the completion handler to execute, you no longer want the resulting placemarks, cancel this task.
     */

    @discardableResult
    @objc(geocodeWithOptions:completionHandler:)
    open func geocode(_ options: GeocodeOptions, completionHandler: @escaping CompletionHandler) -> URLSessionDataTask {
        let url = urlForGeocoding(options)

        let task = dataTaskWithURL(url, completionHandler: { (data) in
            guard let data = data else { return }
            let decoder = JSONDecoder()
            do {
                let result = try decoder.decode(GeocodeResult.self, from: data)
                assert(result.type == "FeatureCollection")
                completionHandler(result.placemarks, result.attribution, nil)
            } catch {
                completionHandler(nil, nil, error as NSError)
            }
        }) { (error) in
            completionHandler(nil, nil, error)
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
    @discardableResult
    @objc(batchGeocodeWithOptions:completionHandler:)
    open func batchGeocode(_ options: GeocodeOptions & BatchGeocodeOptions, completionHandler: @escaping BatchCompletionHandler) -> URLSessionDataTask {
        let url = urlForGeocoding(options)

        let task = dataTaskWithURL(url, completionHandler: { (data) in
            guard let data = data else { return }
            let decoder = JSONDecoder()

            do {

                let result: [GeocodeResult]

                do {
                    // Decode multiple batch geocoding queries
                    result = try decoder.decode([GeocodeResult].self, from: data)
                } catch {
                    // Decode single batch geocding queries
                    result = [try decoder.decode(GeocodeResult.self, from: data)]
                }

                let placemarks = result.map { $0.placemarks }
                let attributionsByQuery = result.map { $0.attribution }
                completionHandler(placemarks, attributionsByQuery, nil)

            } catch {
                completionHandler(nil, nil, error as NSError)
            }

        }) { (error) in
            completionHandler(nil, nil, error)
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
    fileprivate func dataTaskWithURL(_ url: URL, completionHandler: @escaping (_ data: Data?) -> Void, errorHandler: @escaping (_ error: NSError) -> Void) -> URLSessionDataTask {
        var request = URLRequest(url: url)

        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        return URLSession.shared.dataTask(with: request) { (data, response, error) in

            guard let data = data else {
                DispatchQueue.main.async {
                    if let e = error as NSError? {
                        errorHandler(e)
                    } else {
                        let unexpectedError = NSError(domain: MBGeocoderErrorDomain, code: -1024, userInfo: [NSLocalizedDescriptionKey : "unexpected error", NSDebugDescriptionErrorKey : "this error happens when data task return nil data and nil error, which typically is not possible"])
                        errorHandler(unexpectedError)
                    }
                }
                return
            }
            let decoder = JSONDecoder()

            do {
                // Handle multiple batch geocoding queries
                let result = try decoder.decode([GeocodeAPIResult].self, from: data)

                // Check if any of the batch geocoding queries failed
                if let failedResult = result.first(where: { $0.message != nil }) {
                    let apiError = Geocoder.descriptiveError(["message": failedResult.message!], response: response, underlyingError: error as NSError?)
                    DispatchQueue.main.async {
                        errorHandler(apiError)
                    }
                    return
                }
                DispatchQueue.main.async {
                    completionHandler(data)
                }
            } catch {
                // Handle single & single batch geocoding queries
                do {
                    let result = try decoder.decode(GeocodeAPIResult.self, from: data)
                    // Check if geocoding query failed
                    if let message = result.message {
                        let apiError = Geocoder.descriptiveError(["message": message], response: response, underlyingError: error as NSError?)
                        DispatchQueue.main.async {
                            errorHandler(apiError)
                        }
                        return

                    }
                    DispatchQueue.main.async {
                        completionHandler(data)
                    }
                } catch {
                    // Handle errors that don't return a message (such as a server/network error)
                    DispatchQueue.main.async {
                        errorHandler(error as NSError)
                    }
                }
            }
        }
    }

    internal struct GeocodeAPIResult: Codable {
        let message: String?
    }

    /**
     The HTTP URL used to fetch the geocodes from the API.
     */
    @objc open func urlForGeocoding(_ options: GeocodeOptions) -> URL {
        let params = options.params + [
            URLQueryItem(name: "access_token", value: accessToken),
        ]

        assert(!options.queries.isEmpty, "No query")

        let mode = options.mode

        let queryComponent = options.queries.map {
            $0.replacingOccurrences(of: " ", with: "+")
                .addingPercentEncoding(withAllowedCharacters: CharacterSet.geocodingQueryAllowedCharacterSet()) ?? ""
        }.joined(separator: ";")

        let unparameterizedURL = URL(string: "/geocoding/v5/\(mode)/\(queryComponent).json", relativeTo: apiEndpoint)!
        var components = URLComponents(url: unparameterizedURL, resolvingAgainstBaseURL: true)!
        components.queryItems = params
        return components.url!
    }

    /**
     Returns an error that supplements the given underlying error with additional information from the an HTTP response’s body or headers.
     */
    static func descriptiveError(_ json: JSONDictionary, response: URLResponse?, underlyingError error: NSError?) -> NSError {
        var userInfo = error?.userInfo ?? [:]
        if let response = response as? HTTPURLResponse {
            var failureReason: String? = nil
            var recoverySuggestion: String? = nil
            switch response.statusCode {
            case 429:
                if let timeInterval = response.rateLimitInterval, let maximumCountOfRequests = response.rateLimit {
                    let intervalFormatter = DateComponentsFormatter()
                    intervalFormatter.unitsStyle = .full
                    let formattedInterval = intervalFormatter.string(from: timeInterval) ?? "\(timeInterval) seconds"
                    let formattedCount = NumberFormatter.localizedString(from: maximumCountOfRequests as NSNumber, number: .decimal)
                    failureReason = "More than \(formattedCount) requests have been made with this access token within a period of \(formattedInterval)."
                }
                if let rolloverTime = response.rateLimitResetTime {
                    let formattedDate = DateFormatter.localizedString(from: rolloverTime, dateStyle: .long, timeStyle: .long)
                    recoverySuggestion = "Wait until \(formattedDate) before retrying."
                }
            default:
                failureReason = json["message"] as? String
            }
            userInfo[NSLocalizedFailureReasonErrorKey] = failureReason ?? userInfo[NSLocalizedFailureReasonErrorKey] ?? HTTPURLResponse.localizedString(forStatusCode: error?.code ?? -1)
            userInfo[NSLocalizedRecoverySuggestionErrorKey] = recoverySuggestion ?? userInfo[NSLocalizedRecoverySuggestionErrorKey]
        }
        if let error = error {
            userInfo[NSUnderlyingErrorKey] = error
        }
        return NSError(domain: error?.domain ?? MBGeocoderErrorDomain, code: error?.code ?? -1, userInfo: userInfo)
    }
}

extension HTTPURLResponse {
    var rateLimit: UInt? {
        guard let limit = allHeaderFields["X-Rate-Limit-Limit"] as? String else {
            return nil
        }
        return UInt(limit)
    }

    var rateLimitInterval: TimeInterval? {
        guard let interval = allHeaderFields["X-Rate-Limit-Interval"] as? String else {
            return nil
        }
        return TimeInterval(interval)
    }

    var rateLimitResetTime: Date? {
        guard let resetTime = allHeaderFields["X-Rate-Limit-Reset"] as? String else {
            return nil
        }
        guard let resetTimeNumber = Double(resetTime) else {
            return nil
        }
        return Date(timeIntervalSince1970: resetTimeNumber)
    }

}
