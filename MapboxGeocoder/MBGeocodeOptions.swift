@objc(MBGeocodeOptions)
public class GeocodeOptions: NSObject {
    public var allowedISOCountryCodes: [String]?
    
    /**
     A loation to use as a hint when looking up the specified address.
     
     This property prioritizes results that are close to a specific location, which is typically the user’s current location. If the value of this property is `nil` – which it is by default – no specific location is prioritized.
     */
    public var focalLocation: CLLocation?
    
    public var allowedScopes: PlacemarkScope = [.All]
    
    /**
     The region in which each resulting placemark must be located.
     
     By default, no region is specified, so results may be located anywhere in the world.
     */
    public var allowedRegion: RectangularRegion?
    
    private override init() {}
    
    internal var queries: [String] = []
    
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

@objc(MBForwardGeocodeOptions)
public class ForwardGeocodeOptions: GeocodeOptions {
    public init(queries: [String]) {
        super.init()
        self.queries = queries
    }
    
    public convenience init(query: String) {
        self.init(queries: [query])
    }
    
    override var params: [NSURLQueryItem] {
        var params = super.params
        if !autocompletesQuery {
            params.append(NSURLQueryItem(name: "autocomplete", value: String(autocompletesQuery)))
        }
        return params
    }
}

@objc(MBReverseGeocodeOptions)
public class ReverseGeocodeOptions: GeocodeOptions {
    public var coordinates: [CLLocationCoordinate2D]
    
    public init(coordinates: [CLLocationCoordinate2D]) {
        self.coordinates = coordinates
        super.init()
        queries = coordinates.map { String(format: "%.5f,%.5f", $0.longitude, $0.latitude) }
    }
    
    public convenience init(locations: [CLLocation]) {
        self.init(coordinates: locations.map { $0.coordinate })
    }
    
    public convenience init(coordinate: CLLocationCoordinate2D) {
        self.init(coordinates: [coordinate])
    }
    
    public convenience init(location: CLLocation) {
        self.init(locations: [location])
    }
}
