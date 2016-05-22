#if !os(tvOS)
    import Contacts
#endif

/**
 A structure that specifies the criteria for results returned by the Mapbox Geocoding API.
 
 You do not create instances of `GeocodeOptions` directly. Instead, you create instances of `ForwardGeocodeOptions` and `ReverseGeocodeOptions`, depending on the kind of geocoding you want to perform:
 
 - _Forward geocoding_ takes a human-readable query, such as a place name or address, and produces any number of geographic coordinates that correspond to that query. To perform forward geocoding, use a `ForwardGeocodeOptions` object.
 - _Reverse geocoding_ takes a geographic coordinate and produces a hierarchy of places, often beginning with an address, that describes the coordinate’s location. To perform reverse geocoding, use a `ReverseGeocodeOptions` object.
 
 Pass an instance of either class into the `Geocoder.geocode(options:completionHandler:)` method.
 */
@objc(MBGeocodeOptions)
public class GeocodeOptions: NSObject {
    /**
     An array of [ISO 3166-1 alpha-2](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2) country codes specifying the countries in which the results may lie. The codes may appear in any order and are case-insensitive.
     
     By default, no country codes are specified.
     */
    public var allowedISOCountryCodes: [String]?
    
    /**
     A loation to use as a hint when looking up the specified address.
     
     This property prioritizes results that are close to a specific location, which is typically the user’s current location. If the value of this property is `nil` – which it is by default – no specific location is prioritized.
     */
    public var focalLocation: CLLocation?
    
    /**
     The bitmask of placemark scopes, such as country and neighborhood, to include in the results.
     
     The default value of this property is `PlacemarkScope.All`, which includes all scopes.
     */
    public var allowedScopes: PlacemarkScope = [.All]
    
    /**
     The region in which each resulting placemark must be located.
     
     By default, no region is specified, so results may be located anywhere in the world.
     */
    public var allowedRegion: RectangularRegion?
    
    private override init() {}
    
    /**
     An array of geocoding query strings to include in the request URL.
     */
    internal var queries: [String] = []
    
    /**
     An array of URL parameters to include in the request URL.
     */
    internal var params: [NSURLQueryItem] {
        var params: [NSURLQueryItem] = []
        if let allowedISOCountryCodes = allowedISOCountryCodes {
            assert(allowedISOCountryCodes.filter {
                $0.characters.count != 2 || $0.containsString("-")
            }.isEmpty, "Only ISO 3166-1 alpha-2 codes are allowed.")
            let codeList = allowedISOCountryCodes.joinWithSeparator(",").lowercaseString
            params.append(NSURLQueryItem(name: "country", value: codeList))
        }
        if let focalLocation = focalLocation {
            params.append(NSURLQueryItem(name: "proximity", value: "\(focalLocation.coordinate.longitude),\(focalLocation.coordinate.latitude)"))
        }
        if !allowedScopes.isEmpty && allowedScopes != .All {
            params.append(NSURLQueryItem(name: "types", value: String(allowedScopes)))
        }
        if let allowedRegion = allowedRegion {
            params.append(NSURLQueryItem(name: "bbox", value: String(allowedRegion)))
        }
        return params
    }
}

/**
 A structure that specifies the criteria for forward geocoding results. Forward geocoding takes a human-readable query, such as a place name or address, and produces any number of geographic coordinates that correspond to that query.
 */
@objc(MBForwardGeocodeOptions)
public class ForwardGeocodeOptions: GeocodeOptions {
    /**
     A Boolean value that determines whether the results may include placemarks whose names match must match the whole query string exactly.
     
     If true, a resulting placemark’s name may contain a word that begins with the query string. If false, the query string must match a whole word or phrase in the placemark’s name. The default value of this property is true, which is best suited for continuous search fields.
     */
    public var autocompletesQuery = true
    
    private init(queries: [String]) {
        super.init()
        self.queries = queries
    }
    
    /**
     Initializes a forward geocode options object with the given query string.
     
     - parameter query: A place name or address to search for.
     */
    public convenience init(query: String) {
        self.init(queries: [query])
    }
    
    #if !os(tvOS)
    /**
     Initializes a forward geocode options object with the given postal address object.
     
     - parameter postalAddress: A `CNPostalAddress` object to search for.
     */
    @available(iOS 9.0, OSX 10.11, *)
    public convenience init(postalAddress: CNPostalAddress) {
        let formattedAddress = CNPostalAddressFormatter().stringFromPostalAddress(postalAddress)
        self.init(query: formattedAddress.stringByReplacingOccurrencesOfString("\n", withString: ", "))
    }
    #endif
    
    override var params: [NSURLQueryItem] {
        var params = super.params
        if !autocompletesQuery {
            params.append(NSURLQueryItem(name: "autocomplete", value: String(autocompletesQuery)))
        }
        return params
    }
}

/**
 A structure that specifies the criteria for reverse geocoding results. _Reverse geocoding_ takes a geographic coordinate and produces a hierarchy of places, often beginning with an address, that describes the coordinate’s location.
 */
@objc(MBReverseGeocodeOptions)
public class ReverseGeocodeOptions: GeocodeOptions {
    /**
     An array of coordinates to search for.
     */
    public var coordinates: [CLLocationCoordinate2D]
    
    private init(coordinates: [CLLocationCoordinate2D]) {
        self.coordinates = coordinates
        super.init()
        queries = coordinates.map { String(format: "%.5f,%.5f", $0.longitude, $0.latitude) }
    }
    
    /**
     Initializes a reverse geocode options object with the given coordinate pair.
     
     - parameter coordinate: A coordinate pair to search for.
     */
    public convenience init(coordinate: CLLocationCoordinate2D) {
        self.init(coordinates: [coordinate])
    }
    
    /**
     Initializes a reverse geocode options object with the given `CLLocation` object.
     
     - parameter location: A `CLLocation` object to search for.
     */
    public convenience init(location: CLLocation) {
        self.init(coordinate: location.coordinate)
    }
}

/**
 Objects that conform to the `BatchGeocodeOptions` protocol specify the criteria for batch geocoding results returned by the Mapbox Geocoding API.
 
 You can include up to 50 forward geocoding queries in a single request. Each query in a batch request counts individually against your account’s rate limits.
 
 Pass an object conforming to this protocol into the `Geocoder.batchGeocode(options:completionHandler:)` method.
 */
@objc(MBBatchGeocodeOptions)
public protocol BatchGeocodeOptions {}

/**
 A structure that specifies the criteria for forward batch geocoding results. Forward geocoding takes a human-readable query, such as a place name or address, and produces any number of geographic coordinates that correspond to that query.
 */
@objc(MBForwardBatchGeocodeOptions)
public class ForwardBatchGeocodeOptions: ForwardGeocodeOptions, BatchGeocodeOptions {
    /**
     Initializes a forward batch geocode options object with the given query strings.
     
     - parameter queries: An array of up to 50 place names or addresses to search for.
     */
    public override init(queries: [String]) {
        super.init(queries: queries)
    }
}

/**
 A structure that specifies the criteria for reverse geocoding results. Reverse geocoding takes a geographic coordinate and produces a hierarchy of places, often beginning with an address, that describes the coordinate’s location.
 */
@objc(MBReverseBatchGeocodeOptions)
public class ReverseBatchGeocodeOptions: ReverseGeocodeOptions, BatchGeocodeOptions {
    /**
     Initializes a reverse batch geocode options object with the given coordinate pairs.
     
     - parameter coordinates: An array of up to 50 coordinate pairs to search for.
     */
    public override init(coordinates: [CLLocationCoordinate2D]) {
        super.init(coordinates: coordinates)
    }
    
    /**
     Initializes a reverse batch geocode options object with the given `CLLocation` objects.
     
     - parameter location: An array of up to 50 `CLLocation` objects to search for.
     */
    public convenience init(locations: [CLLocation]) {
        self.init(coordinates: locations.map { $0.coordinate })
    }
}
