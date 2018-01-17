#if !os(tvOS)
    import Contacts
#endif

/**
 A structure that specifies the criteria for results returned by the Mapbox Geocoding API.
 
 You do not create instances of `GeocodeOptions` directly. Instead, you create instances of `ForwardGeocodeOptions` and `ReverseGeocodeOptions`, depending on the kind of geocoding you want to perform:
 
 - _Forward geocoding_ takes a human-readable query, such as a place name or address, and produces any number of geographic coordinates that correspond to that query. To perform forward geocoding, use a `ForwardGeocodeOptions` object.
 - _Reverse geocoding_ takes a geographic coordinate and produces a hierarchy of places, often beginning with an address, that describes the coordinate’s location. To perform reverse geocoding, use a `ReverseGeocodeOptions` object.
 
 Pass an instance of either class into the `Geocoder.geocode(_:completionHandler:)` method.
 */
@objc(MBGeocodeOptions)
open class GeocodeOptions: NSObject {
    // MARK: Specifying the Search Criteria
    
    /**
     An array of [ISO 3166-1 alpha-2](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2) country codes specifying the countries in which the results may lie. The codes may appear in any order and are case-insensitive.
     
     By default, no country codes are specified.
     
     To find out what kinds of results are available for a particular country, consult [the Geocoding API’s coverage map](https://www.mapbox.com/geocoding/#coverage).
     */
    @objc open var allowedISOCountryCodes: [String]?
    
    /**
     A location to use as a hint when looking up the specified address.
     
     This property prioritizes results that are close to a specific location, which is typically the user’s current location. If the value of this property is `nil` – which it is by default – no specific location is prioritized.
     */
    @objc open var focalLocation: CLLocation?
    
    /**
     The bitmask of placemark scopes, such as country and neighborhood, to include in the results.
     
     The default value of this property is `PlacemarkScope.all`, which includes all scopes.
     */
    @objc open var allowedScopes: PlacemarkScope = [.all]
    
    /**
     The region in which each resulting placemark must be located.
     
     By default, no region is specified, so results may be located anywhere in the world.
     */
    @objc open var allowedRegion: RectangularRegion?
    
    /**
     Limit the number of results returned. For forward geocoding, the default is `5` and the maximum is `10`. For reverse geocoding, the default is `1` and the maximum is `5`.
     */
    @objc public var maximumResultCount: UInt

    // MARK: Specifying the Output Format
    
    /**
     The locale in which results should be returned.
     
     This property affects the language of returned results; generally speaking, it does not determine which results are found. If the Geocoding API does not recognize the language code, it may fall back to another language or the default language. Components other than the language code, such as the country and script codes, are ignored.
     
     By default, this property is set to `nil`, causing results to be in the default language.
     
     - experiment: This option is experimental.
     */
    @objc open var locale: Locale?
    
    fileprivate override init() {
        self.maximumResultCount = 0
        super.init()
    }
    
    /**
     An array of geocoding query strings to include in the request URL.
     */
    internal var queries: [String] = []
    
    /**
     An array of URL parameters to include in the request URL.
     */
    internal var params: [URLQueryItem] {
        var params: [URLQueryItem] = []
        if let allowedISOCountryCodes = allowedISOCountryCodes {
            assert(allowedISOCountryCodes.filter {
                $0.count != 2 || $0.contains("-")
            }.isEmpty, "Only ISO 3166-1 alpha-2 codes are allowed.")
            let codeList = allowedISOCountryCodes.joined(separator: ",").lowercased()
            params.append(URLQueryItem(name: "country", value: codeList))
        }
        if let focalLocation = focalLocation {
            params.append(URLQueryItem(name: "proximity", value: "\(focalLocation.coordinate.longitude),\(focalLocation.coordinate.latitude)"))
        }
        if !allowedScopes.isEmpty && allowedScopes != .all {
            params.append(URLQueryItem(name: "types", value: String(describing: allowedScopes)))
        }
        if let allowedRegion = allowedRegion {
            params.append(URLQueryItem(name: "bbox", value: String(describing: allowedRegion)))
        }
        if maximumResultCount > 0 {
            params.append(URLQueryItem(name: "limit", value: String(maximumResultCount)))
        }
        if let languageCode = (locale as NSLocale?)?.object(forKey: .languageCode) as? String {
            params.append(URLQueryItem(name: "language", value: languageCode))
        }
        return params
    }
}

/**
 A structure that specifies the criteria for forward geocoding results. Forward geocoding takes a human-readable query, such as a place name or address, and produces any number of geographic coordinates that correspond to that query.
 */
@objc(MBForwardGeocodeOptions)
open class ForwardGeocodeOptions: GeocodeOptions {
    /**
     A Boolean value that determines whether the results may include placemarks whose names match must match the whole query string exactly.
     
     If true, a resulting placemark’s name may contain a word that begins with the query string. If false, the query string must match a whole word or phrase in the placemark’s name. The default value of this property is true, which is best suited for continuous search fields.
     */
    open var autocompletesQuery = true

    fileprivate init(queries: [String]) {
        super.init()
        self.queries = queries
        self.maximumResultCount = 5
    }
    
    /**
     Initializes a forward geocode options object with the given query string.
     
     - parameter query: A place name or address to search for. The query may have a maximum of 20 words or numbers; it may have up to 256 characters including spaces and punctuation.
     */
    @objc public convenience init(query: String) {
        self.init(queries: [query])
    }
    
    #if !os(tvOS)
    /**
     Initializes a forward geocode options object with the given postal address object.
     
     - parameter postalAddress: A `CNPostalAddress` object to search for.
     */
    @available(iOS 9.0, OSX 10.11, *)
    @objc public convenience init(postalAddress: CNPostalAddress) {
        let formattedAddress = CNPostalAddressFormatter().string(from: postalAddress)
        self.init(query: formattedAddress.replacingOccurrences(of: "\n", with: ", "))
    }
    #endif
    
    override var params: [URLQueryItem] {
        var params = super.params
        if !autocompletesQuery {
            params.append(URLQueryItem(name: "autocomplete", value: String(autocompletesQuery)))
        }
        return params
    }
}

/**
 A structure that specifies the criteria for reverse geocoding results. _Reverse geocoding_ takes a geographic coordinate and produces a hierarchy of places, often beginning with an address, that describes the coordinate’s location.
 */
@objc(MBReverseGeocodeOptions)
open class ReverseGeocodeOptions: GeocodeOptions {
    /**
     An array of coordinates to search for.
     */
    open var coordinates: [CLLocationCoordinate2D]

    fileprivate init(coordinates: [CLLocationCoordinate2D]) {
        self.coordinates = coordinates
        super.init()
        self.maximumResultCount = 1
        queries = coordinates.map { String(format: "%.5f,%.5f", $0.longitude, $0.latitude) }
    }
    
    /**
     Initializes a reverse geocode options object with the given coordinate pair.
     
     - parameter coordinate: A coordinate pair to search for.
     */
    @objc public convenience init(coordinate: CLLocationCoordinate2D) {
        self.init(coordinates: [coordinate])
    }
    
    /**
     Initializes a reverse geocode options object with the given `CLLocation` object.
     
     - parameter location: A `CLLocation` object to search for.
     */
    @objc public convenience init(location: CLLocation) {
        self.init(coordinate: location.coordinate)
    }
}

/**
 Objects that conform to the `BatchGeocodeOptions` protocol specify the criteria for batch geocoding results returned by the Mapbox Geocoding API.
 
 You can include up to 50 forward geocoding queries in a single request. Each query in a batch request counts individually against your account’s rate limits.
 
 Pass an object conforming to this protocol into the `Geocoder.batchGeocode(_:completionHandler:)` method.
 */
@objc(MBBatchGeocodeOptions)
public protocol BatchGeocodeOptions {}

/**
 A structure that specifies the criteria for forward batch geocoding results. Forward geocoding takes a human-readable query, such as a place name or address, and produces any number of geographic coordinates that correspond to that query.
 */
@objc(MBForwardBatchGeocodeOptions)
open class ForwardBatchGeocodeOptions: ForwardGeocodeOptions, BatchGeocodeOptions {
    /**
     Initializes a forward batch geocode options object with the given query strings.
     
     - parameter queries: An array of up to 50 place names or addresses to search for. An individual query may have a maximum of 20 words or numbers; it may have up to 256 characters including spaces and punctuation.
     */
    @objc public override init(queries: [String]) {
        super.init(queries: queries)
    }
}

/**
 A structure that specifies the criteria for reverse geocoding results. Reverse geocoding takes a geographic coordinate and produces a hierarchy of places, often beginning with an address, that describes the coordinate’s location.
 */
@objc(MBReverseBatchGeocodeOptions)
open class ReverseBatchGeocodeOptions: ReverseGeocodeOptions, BatchGeocodeOptions {
    /**
     Initializes a reverse batch geocode options object with the given coordinate pairs.
     
     - parameter coordinates: An array of up to 50 coordinate pairs to search for.
     */
    @objc public override init(coordinates: [CLLocationCoordinate2D]) {
        super.init(coordinates: coordinates)
    }
    
    /**
     Initializes a reverse batch geocode options object with the given `CLLocation` objects.
     
     - parameter location: An array of up to 50 `CLLocation` objects to search for.
     */
    @objc public convenience init(locations: [CLLocation]) {
        self.init(coordinates: locations.map { $0.coordinate })
    }
}
