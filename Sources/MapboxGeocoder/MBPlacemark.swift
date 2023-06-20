#if canImport(Contacts)
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
     Creates a placemark with the given name and identifier.
     
     Normally you do not call this method to obtain a placemark. Instead, you call the `Geocoder.geocode(_:completionHandler:)` method, which asynchronously returns placemarks that match certain criteria.
     
     - parameter identifier: A string that uniquely identifies the feature.
     - parameter name: The common name of the placemark.
     */
    @objc public init(identifier: String, name: String) {
        self.identifier = identifier
        self.name = name
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
        superiorPlacemarks = try container.decodeIfPresent([GeocodedPlacemark].self, forKey: .superiorPlacemarks)
        
        if let coordinates = try container.decodeIfPresent([CLLocationDegrees].self, forKey: .centerCoordinate) {
            let coordinate = CLLocationCoordinate2D(geoJSON: coordinates)
            location = CLLocation(coordinate: coordinate)
        }
        
        code = try container.decodeIfPresent(String.self, forKey: .code)?.uppercased()
        properties = try container.decodeIfPresent(Properties.self, forKey: .properties)
        
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
    
    #if swift(>=4.2)
    #else
    @objc open override var hashValue: Int {
        return identifier.hashValue
    }
    #endif
    
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
    fileprivate var properties: Properties?
    
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
    
    #if SWIFT_PACKAGE
    /**
     The placemark’s scope.
     
     The scope offers a general indication of the size or importance of the feature represented by the placemark – in other words, how local the feature is.
     */
    open var scope: PlacemarkScope {
        return PlacemarkScope(identifier: identifier)
    }
    #else
    /**
     The placemark’s scope.
     
     The scope offers a general indication of the size or importance of the feature represented by the placemark – in other words, how local the feature is.
     */
    @objc open var scope: PlacemarkScope {
        return PlacemarkScope(identifier: identifier)
    }
    #endif
    
    /**
     The identifier of the placemark’s [Wikidata](https://www.wikidata.org/) item, if known.
     
     The item identifier consists of “Q” followed by a number. Prepend `https://www.wikidata.org/wiki/` to get the URL to the Wikidata item page.
     
     The Wikidata item contains structured information about the feature represented by the placemark. It also links to corresponding entries in various free content or open data resources, including Wikipedia, Wikimedia Commons, Wikivoyage, and Freebase.
     */
    @objc open var wikidataItemIdentifier: String? {
        get {
            return properties?.wikidata
        }
    }
    
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
    
    /**
     The placemark’s full address in the customary local format, with each line in a separate string in the array.
     
     If you need to fit the same address on a single line, use the `qualifiedName` property, in which each line is separated by a comma instead of a line break.
     */
    fileprivate var formattedAddressLines: [String]? {
        return nil
    }
    
    #if canImport(Contacts)
    /**
     The placemark’s postal address.
     
     To format the postal address, use a `CNPostalAddressFormatter` object.
     */
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
 A subset of the `properties` object on a GeoJSON feature suited for Geocoding results.
 */
internal struct Properties: Codable {
    private enum CodingKeys: String, CodingKey {
        case shortCode = "short_code"
        case phoneNumber = "tel"
        case maki
        case address
        case precision = "accuracy"
        case category
        case wikidata
    }
    
    let shortCode: String?
    let maki: String?
    let phoneNumber: String?
    let address: String?
    let precision: String?
    let category: String?
    let wikidata: String?
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
 A concrete subclass of `Placemark` to represent results of geocoding requests.
 */
@objc(MBGeocodedPlacemark)
open class GeocodedPlacemark: Placemark {
    
    private enum CodingKeys: String, CodingKey {
        case routableLocations = "routable_points"
        case relevance
    }
    
    private enum PointsCodingKeys: String, CodingKey {
        case points
    }
    
    /**
     An array of locations that serve as hints for navigating to the placemark.
     
     If the `GeocodeOptions.includesRoutableLocations` property is set to `true`, this property contains locations that are suitable to use as a waypoint in a routing engine such as MapboxDirections.swift. Otherwise, if the `GeocodeOptions.includesRoutableLocations` property is set to `false`, this property is set to `nil`.
     
     For the placemark’s geographic center, use the `location` property. The routable locations may differ from the geographic center. For example, if a house’s driveway leads to a street other than the nearest street (by straight-line distance), then this property may contain the location where the driveway meets the street. A route to the placemark’s geographic center may be impassable, but a route to the routable location would end on the correct street with access to the house.
     */
    @objc open var routableLocations: [CLLocation]?
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        if let pointsContainer = try? container.nestedContainer(keyedBy: PointsCodingKeys.self, forKey: .routableLocations),
            var coordinatesContainer = try? pointsContainer.nestedUnkeyedContainer(forKey: .points) {
            
            if let routableLocation = try coordinatesContainer.decodeIfPresent(RoutableLocation.self),
                let coordinate = routableLocation.coordinate {
                routableLocations = [CLLocation(coordinate: coordinate)]
            }
        }
        
        relevance = try container.decodeIfPresent(Double.self, forKey: .relevance) ?? -1
        
        try super.init(from: decoder)
    }
    
    public override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encodeIfPresent(relevance, forKey: .relevance)
        
        if let routableLocations = routableLocations,
            !routableLocations.isEmpty {
            var pointsContainer = container.nestedContainer(keyedBy: PointsCodingKeys.self, forKey: .routableLocations)
            var coordinatesContainer = pointsContainer.nestedUnkeyedContainer(forKey: .points)
            let routableLocation = RoutableLocation(coordinates: [routableLocations[0].coordinate.longitude,
                                                                  routableLocations[0].coordinate.latitude])
            try coordinatesContainer.encode(routableLocation)
        }
        
        try super.encode(to: encoder)
    }
    
    @objc open override var debugDescription: String {
        return qualifiedName!
    }
    
    internal var qualifiedNameComponents: [String] {
        if qualifiedName!.contains(", ") {
            return qualifiedName!.components(separatedBy: ", ")
        }
        // Chinese addresses have no commas and are reversed.
        return (superiorPlacemarks?.map { $0.name } ?? []).reversed() + [name]
    }
    
    @objc open var formattedName: String {
        guard scope == .address else {
            return name
        }
        if precision == .intersection {
            // For intersection features, `name` is just the first street name. The first line of the fully qualified address contains the cross street too.
            return qualifiedNameComponents.first ?? name
        } else {
            return streetAddress ?? name
        }
    }
    
    @objc open override var genres: [String]? {
        return properties?.category?.components(separatedBy: ", ")
    }
    
    @objc open override var imageName: String? {
        return properties?.maki
    }
    
    /**
     A numerical score from 0 (least relevant) to 0.99 (most relevant) measuring
     how well each returned feature matches the query. Use this property to
     remove results that don’t fully match the query.
     */
    @objc open var relevance: Double
    
    private var clippedAddressLines: [String] {
        let lines = qualifiedNameComponents
        if scope == .address {
            return lines
        }
        
        guard let qualifiedName = qualifiedName,
            qualifiedName.contains(", ") else {
            // Chinese addresses have no commas and are reversed.
            return Array(lines.prefix(lines.count))
        }
        
        return Array(lines.suffix(from: 1))
    }
    
    override var formattedAddressLines: [String] {
        return clippedAddressLines
    }
    
    @objc open var streetAddress: String? {
        guard scope == .address else {
            return properties?.address ?? address
        }
        guard let address = address else {
            return name
        }
        // For address features, `address` is a house number and `name` is just a street name. Look through the fully-qualified address to determine whether to put the house number after or before the street name (i.e. Chinese addresses).
        let streetAddress = "\(name) \(address)"
        if qualifiedNameComponents.contains(streetAddress) {
            return streetAddress
        } else {
            return "\(address) \(name)"
        }
    }
    
    #if canImport(Contacts)
    @objc open override var postalAddress: CNPostalAddress? {
        let postalAddress = CNMutablePostalAddress()
        
        if scope == .address {
            postalAddress.street = name
        } else if let address = address {
            postalAddress.street = address.replacingOccurrences(of: ", ", with: "\n")
        }

        if let placeName = place?.name {
            postalAddress.city = placeName
        }
        if let regionName = administrativeRegion?.name {
            postalAddress.state = regionName
        }
        if let postalCode = postalCode?.name {
            postalAddress.postalCode = postalCode
        }
        if let countryName = country?.name {
            postalAddress.country = countryName
        }
        if let ISOCountryCode = country?.code {
            postalAddress.isoCountryCode = ISOCountryCode
        }
    
        return postalAddress
    }
    #endif
    
    @objc open override var addressDictionary: [AnyHashable: Any]? {
        var addressDictionary: [String: Any] = [:]
        if scope == .address {
            addressDictionary[MBPostalAddressStreetKey] = name
        } else if let address = properties?.address {
            addressDictionary[MBPostalAddressStreetKey] = address
        } else if let address = address {
            addressDictionary[MBPostalAddressStreetKey] = address
        }
        addressDictionary[MBPostalAddressCityKey] = place?.name
        addressDictionary[MBPostalAddressStateKey] = administrativeRegion?.name
        addressDictionary[MBPostalAddressPostalCodeKey] = postalCode?.name
        addressDictionary[MBPostalAddressCountryKey] = country?.name
        addressDictionary[MBPostalAddressISOCountryCodeKey] = country?.code
        addressDictionary["formattedAddressLines"] = clippedAddressLines
        addressDictionary["name"] = name
        addressDictionary["subAdministrativeArea"] = district?.name ?? place?.name
        addressDictionary["subLocality"] = neighborhood?.name
        addressDictionary["subThoroughfare"] = subThoroughfare
        addressDictionary["thoroughfare"] = thoroughfare
        return addressDictionary
    }
    
    /**
     The phone number to contact a business at this location.
     */
    @objc open override var phoneNumber: String? {
        return properties?.phoneNumber
    }
    
    #if SWIFT_PACKAGE
    /**
     The placemark’s precision.
     
     The precision offers a general indication of the potential distance between the `location` property and the feature’s actual real-world location.
     */
    open var precision: PlacemarkPrecision? {
        if let precision = properties?.precision {
            return PlacemarkPrecision(rawValue: precision)
        }
        return nil
    }
    #else
    /**
     The placemark’s precision.
     
     The precision offers a general indication of the potential distance between the `location` property and the feature’s actual real-world location.
     */
    @objc open var precision: PlacemarkPrecision? {
        if let precision = properties?.precision {
            return PlacemarkPrecision(rawValue: precision)
        }
        return nil
    }
    #endif
}

/**
 A concrete subclass of `Placemark` to represent entries in a `GeocodedPlacemark` object’s `superiorPlacemarks` property. These entries are like top-level geocoding results, except that they lack location information and are flatter, with properties directly at the top level.
 */
@objc(MBQualifyingPlacemark)
open class QualifyingPlacemark: Placemark {}
