#if !os(tvOS)
    import Contacts
#endif
import CoreLocation

// MARK: Postal Address Properties

/**
 Street.
 
 This key takes a string value.
 
 - seealso: CNPostalAddressStreetKey
 */
public let MBPostalAddressStreetKey = "street"

/**
 City.
 
 This key takes a string value.
 
 - seealso: CNPostalAddressCityKey
 */
public let MBPostalAddressCityKey = "city"

/**
 State.
 
 This key takes a string value.
 
 - seealso: CNPostalAddressStateKey
 */
public let MBPostalAddressStateKey = "state"

/**
 Postal code.
 
 This key takes a string value.
 
 - seealso: CNPostalAddressPostalCodeKey
 */
public let MBPostalAddressPostalCodeKey = "postalCode"

/**
 Country.
 
 This key takes a string value.
 
 - seealso: CNPostalAddressCountryKey
 */
public let MBPostalAddressCountryKey = "country"

/**
 ISO country code.
 
 This key takes a string value.
 
 - seealso: CNPostalAddressISOCountryCodeKey
 */
public let MBPostalAddressISOCountryCodeKey = "ISOCountryCode"

/**
 A `Placemark` object represents a geocoder result. A placemark associates identifiers, geographic data, and contact information with a particular latitude and longitude. It is possible to explicitly create a placemark object from another placemark object; however, placemark objects are generally created for you via the `Geocoder.geocode(_:completionHandler:)` method.
 */
@objc(MBPlacemark)
open class Placemark: NSObject, Codable {
    
    private enum CodingKeys: String, CodingKey {
        case identifier = "id"
        case name = "text"
        case address
        case qualifiedName = "place_name"
        case superiorPlacemarks = "context"
        case centerCoordinate = "center"
        case code = "short_code"
        case wikidataItemIdentifier = "wikidata"
        case properties
        case boundingBox = "bbox"
    }
    
    /**
     Creates a placemark from the given [Carmen GeoJSON](https://github.com/mapbox/carmen/blob/master/carmen-geojson.md) feature.
     */
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        identifier = try container.decode(String.self, forKey: .identifier)
        name = try container.decode(String.self, forKey: .name)
        address = try container.decodeIfPresent(String.self, forKey: .address)
        qualifiedName = try container.decodeIfPresent(String.self, forKey: .qualifiedName)
        superiorPlacemarks = try container.decodeIfPresent([Placemark].self, forKey: .superiorPlacemarks)
        
        if let coordinates = try container.decodeIfPresent([CLLocationDegrees].self, forKey: .centerCoordinate) {
            let coordinate = CLLocationCoordinate2D(geoJSON: coordinates)
            location = CLLocation(coordinate: coordinate)
        }
        
        if let rawIdentifier = try container.decodeIfPresent(String.self, forKey: .wikidataItemIdentifier) {
            let identifier = rawIdentifier.trimmingCharacters(in: .whitespacesAndNewlines)
            assert(identifier.hasPrefix("Q"))
            wikidataItemIdentifier = identifier
        }
        
        properties = try container.decodeIfPresent(Properties.self, forKey: .properties)
        code = try container.decodeIfPresent(String.self, forKey: .code)?.uppercased()
        
        if let boundingBox = try container.decodeIfPresent([CLLocationDegrees].self, forKey: .boundingBox) {
            let southWest = CLLocationCoordinate2D(geoJSON: Array(boundingBox.prefix(2)))
            let northEast = CLLocationCoordinate2D(geoJSON: Array(boundingBox.suffix(2)))
            region = RectangularRegion(southWest: southWest, northEast: northEast)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(identifier, forKey: .identifier)
        try container.encode(name, forKey: .name)
        try container.encode(address, forKey: .address)
        try container.encode(qualifiedName, forKey: .qualifiedName)
        try container.encode(superiorPlacemarks, forKey: .superiorPlacemarks)
        try container.encode(code, forKey: .code)
        try container.encode(wikidataItemIdentifier, forKey: .wikidataItemIdentifier)
        try container.encode(properties, forKey: .properties)
        if let location = location {
            try container.encode([location.coordinate.longitude, location.coordinate.latitude], forKey: .centerCoordinate)
        }
    }
    
    @objc open override var hashValue: Int {
        return identifier.hashValue
    }
    
    @objc open override func isEqual(_ object: Any?) -> Bool {
        if let object = object as? Placemark {
            return identifier == object.identifier
        }
        return false
    }
    
    // MARK: Identifying the Placemark
    
    @objc open override var description: String {
        return name
    }
    
    /**
     A string that uniquely identifies the feature.
     
     The identifier takes the form <tt><var>index</var>.<var>id</var></tt>, where <var>index</var> corresponds to the `scope` property and <var>id</var> is a number that is unique to the feature but may change when the data source is updated.
     */
    fileprivate var identifier: String
    
    /**
     A subset of the `properties` object on a GeoJSON feature suited for Geocoding results.
     */
    public var properties: Properties?
    
    /**
     The common name of the placemark.
     
     If the placemark represents an address, the value of this property consists of only the street address, not the full address. Otherwise, if the placemark represents a point of interest or other place, the value of this property consists of only the common name, not the names of any containing administrative areas.
     */
    @objc open var name: String
    
    @objc open var address: String?
    
    /**
     A standard code uniquely identifying the placemark.
     
     If the placemark represents a country, the value of this property is the country’s [ISO 3166-1 alpha-2](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2) code. If the placemark represents a top-level subdivision of a country, such as a state or province, the value of this property is the subdivision’s [ISO 3166-2](https://en.wikipedia.org/wiki/ISO_3166-2) code. Otherwise, the value of this property is `nil`.
     */
    @objc open var code: String?
    
    /**
     The fully qualified name of the placemark.
     
     If the placemark represents an address or point of interest, the value of this property includes the full address. Otherwise, the value of this property includes any containing administrative areas.
     */
    @objc open var qualifiedName: String?
    
    /**
     The placemark’s scope.
     
     The scope offers a general indication of the size or importance of the feature represented by the placemark – in other words, how local the feature is.
     */
    @objc open var scope: PlacemarkScope {
        let components = identifier.components(separatedBy: ".")
        assert(components.count > 0)
        return PlacemarkScope(descriptions: [components.prefix(2).joined(separator: ".")]) ?? PlacemarkScope(descriptions: [components.first!]) ?? []
    }
    
    /**
     The identifier of the placemark’s [Wikidata](https://www.wikidata.org/) item, if known.
     
     The item identifier consists of “Q” followed by a number. Prepend `https://www.wikidata.org/wiki/` to get the URL to the Wikidata item page.
     
     The Wikidata item contains structured information about the feature represented by the placemark. It also links to corresponding entries in various free content or open data resources, including Wikipedia, Wikimedia Commons, Wikivoyage, and Freebase.
     */
    @objc open var wikidataItemIdentifier: String?
    
    /**
     An array of keywords that describe the genre of the point of interest represented by the placemark.
     */
    @objc open var genres: [String]? {
        return nil
    }
    
    /**
     Name of the [Maki](https://www.mapbox.com/maki/) icon that most precisely identifies the placemark.
     
     The icon is determined based on the placemark’s scope and any available genres.
     */
    @objc open var imageName: String? {
        return nil
    }
    
    // MARK: Accessing Location Data
    
    /**
     The placemark’s geographic center.
     */
    @objc open var location: CLLocation?
    
    /**
     A region object indicating in some fashion the geographic extents of the placemark.
     
     When this property is not `nil`, it is currently always a `RectangularRegion`. In the future, it may be another type of `CLRegion`.
     */
    @objc open var region: CLRegion?
    
    // MARK: Accessing Contact Information
    
    #if !os(tvOS)
    /**
     The placemark’s postal address.
     
     To format the postal address, use a `CNPostalAddressFormatter` object.
     */
    @available(iOS 9.0, OSX 10.11, *)
    @objc open var postalAddress: CNPostalAddress? {
        return nil
    }
    #endif
    
    /**
     A dictionary containing the Contacts keys and values for the placemark.
     
     The keys in this dictionary are those defined by the Contacts framework and used to access address information for a person or business. For a list of the keys that can be set in this dictionary, see the “Postal Address Properties” constants in _CNPostalAddress Reference_ and in this module.
     
     On iOS 9.0 and above, most of the information in this dictionary is also contained in the `CNPostalAddress` object stored in the `postalAddress` property.
     */
    @objc open var addressDictionary: [AnyHashable: Any]? {
        return nil
    }
    
    /**
     The phone number associated with the business represented by the placemark.
     */
    @objc open var phoneNumber: String? {
        return nil
    }
    
    // MARK: Accessing Containing Placemarks
    
    /**
     An array of placemarks representing the hierarchy of administrative areas containing the feature represented by this placemark.
     
     The array is sorted in order from the smallest, most local administrative area to the largest administrative area.
     */
    @objc open internal(set) var superiorPlacemarks: [Placemark]?
    
    /**
     A placemark representing the country containing the feature represented by this placemark.
     
     To get the country’s name, use the `name` property of the object stored in this property.
     */
    @objc open var country: Placemark? {
        return superiorPlacemarks?.lazy.filter { $0.scope == .country }.first
    }
    
    /**
     A placemark representing the postal code area containing the feature represented by this placemark.
     
     To get the postal code itself, use the `name` property of the object stored in this property.
     */
    @objc open var postalCode: Placemark? {
        return superiorPlacemarks?.lazy.filter { $0.scope == .postalCode }.first
    }
    
    /**
     A placemark representing the region containing the feature represented by this placemark.
     
     To get the region’s name, use the `name` property of the object stored in this property.
     */
    @objc open var administrativeRegion: Placemark? {
        return superiorPlacemarks?.lazy.filter { $0.scope == .region }.last
    }
    
    /**
     A placemark representing the district containing the feature represented by this placemark.
     
     To get the district’s name, use the `name` property of the object stored in this property.
     */
    @objc open var district: Placemark? {
        return superiorPlacemarks?.lazy.filter { $0.scope == .district }.last
    }
    
    /**
     A placemark representing the place containing the feature represented by this placemark.
     
     To get the place’s name, use the `name` property of the object stored in this property.
     */
    @objc open var place: Placemark? {
        return superiorPlacemarks?.lazy.filter { $0.scope == .place }.last
    }
    
    /**
     A placemark representing the neighborhood containing the feature represented by this placemark.
     
     To get the neighborhood’s name, use the `name` property of the object stored in this property.
     */
    @objc open var neighborhood: Placemark? {
        return superiorPlacemarks?.lazy.filter { $0.scope == .neighborhood }.last
    }
    
    /**
     The name of the street associated with the placemark.
     */
    @objc open var thoroughfare: String? {
        guard scope == .address else {
            return nil
        }
        return name
    }
    
    /**
     An identifier indicating the location along the street at which you can find the feature represented by the placemark.
     
     Typically, this property contains the house number and/or unit number of a business or residence.
     */
    @objc open var subThoroughfare: String? {
        guard let houseNumber = address else {
            return nil
        }
        return String(describing: houseNumber)
    }
}

internal struct GeocodeResult: Codable {
    private enum CodingKeys: String, CodingKey {
        case placemarks = "features"
        case type
        case attribution
    }
    
    let type: String
    let attribution: String
    let placemarks: [GeocodedPlacemark]
}

/**
 An object describing the placemark. Only Carmen (https://github.com/mapbox/carmen) properties are guaranteed.
 */
public class Properties: Codable {
    private enum CodingKeys: String, CodingKey {
        case shortCode = "short_code"
        case phoneNumber = "tel"
        case maki
        case address
        case category
        case landmark
        case wikidata
    }
    
    // The ISO 3166-1 country and ISO 3166-2 region code for the returned feature.
    public let shortCode: String?
    
    // The name of a suggested Maki icon (https://www.mapbox.com/maki-icons/) to visualize a  poi feature based on its category.
    public let maki: String?
    
    // A formatted string of the telephone number for the returned  poi feature.
    public let phoneNumber: String?
    
    // A string of the full street address for the returned  poi feature.
    // Note that unlike the  address property for  address features, this property is inside the properties object.
    public let address: String?
    
    // A boolean value indicating whether a  poi feature is a landmark.
    // Landmarks are particularly notable or long-lived features like schools, parks, museums and places of worship.
    public let landmark: Bool?
    
    // A string of comma-separated categories for the returned  poi feature.
    public let category: String?
    
    // The Wikidata identifier for the returned feature.
    public let wikidata: String?
}

// Used internally for flattening and transforming routable_points.points.coordinates
internal struct RoutableLocation: Codable {
    internal let coordinates: [Double]
    
    internal var coordinate: CLLocationCoordinate2D? {
        if coordinates.count >= 2 {
            return CLLocationCoordinate2D(latitude: coordinates[1], longitude: coordinates[0])
        }
        return nil
    }
}

/**
 A concrete subclass of `Placemark` to represent entries in a `GeocodedPlacemark` object’s `superiorPlacemarks` property. These entries are like top-level geocoding results, except that they lack location information and are flatter, with properties directly at the top level.
 */
@objc(MBQualifyingPlacemark)
open class QualifyingPlacemark: Placemark {}
