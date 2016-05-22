#if !os(tvOS)
    import Contacts
#endif

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
 A `Placemark` object represents a geocoder result. A placemark associates identifiers, geographic data, and contact information with a particular latitude and longitude. It is possible to explicitly create a placemark object from another placemark object; however, placemark objects are generally created for you via the `Geocoder.geocode(options:completionHandler:)` method.
 */
@objc(MBPlacemark)
public class Placemark: NSObject, NSCopying, NSSecureCoding {
    /**
     The GeoJSON feature dictionary containing the placemark’s data.
     */
    private let featureJSON: JSONDictionary
    
    /**
     Creates a placemark from the given [Carmen GeoJSON](https://github.com/mapbox/carmen/blob/master/carmen-geojson.md) feature.
     */
    internal init(featureJSON: JSONDictionary) {
        self.featureJSON = featureJSON
    }
    
    public convenience required init?(coder aDecoder: NSCoder) {
        guard let featureJSON = aDecoder.decodeObjectOfClass(NSDictionary.self, forKey: "featureJSON") as? JSONDictionary else {
            return nil
        }
        
        self.init(featureJSON: featureJSON)
    }
    
    /**
     Creates a placemark with the same data as another placemark object.
     */
    public convenience init(placemark: Placemark) {
        self.init(featureJSON: placemark.featureJSON)
    }
    
    public class func supportsSecureCoding() -> Bool {
        return true
    }
    
    public func copyWithZone(zone: NSZone) -> AnyObject {
        return Placemark(featureJSON: featureJSON)
    }
    
    public func encodeWithCoder(coder: NSCoder) {
        coder.encodeObject(featureJSON, forKey: "featureJSON")
    }
    
    public override var hashValue: Int {
        return identifier.hashValue
    }
    
    public override func isEqual(object: AnyObject?) -> Bool {
        if let object = object as? Placemark {
            return identifier == object.identifier
        }
        return false
    }
    
    // MARK: Identifying the Placemark
    
    public override var description: String {
        return name
    }
    
    /**
     A string that uniquely identifies the feature.
     
     The identifier takes the form <tt><var>index</var>.<var>id</var></tt>, where <var>index</var> corresponds to the `scope` property and <var>id</var> is a number that is unique to the feature but may change when the data source is updated.
     */
    private var identifier: String {
        return featureJSON["id"] as! String
    }
    
    /**
     The common name of the placemark.
     
     If the placemark represents an address, the value of this property consists of only the street address, not the full address. Otherwise, if the placemark represents a point of interest or other place, the value of this property consists of only the common name, not the names of any containing administrative areas.
     */
    public var name: String {
        return featureJSON["text"] as! String
    }
    
    /**
     The fully qualified name of the placemark.
     
     If the placemark represents an address or point of interest, the value of this property includes the full address. Otherwise, the value of this property includes any containing administrative areas.
     */
    public var qualifiedName: String? {
        return nil
    }
    
    /**
     A standard code uniquely identifying the placemark.
     
     If the placemark represents a country, the value of this property is the country’s [ISO 3166-1 alpha-2](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2) code. If the placemark represents a top-level subdivision of a country, such as a state or province, the value of this property is the subdivision’s [ISO 3166-2](https://en.wikipedia.org/wiki/ISO_3166-2) code. Otherwise, the value of this property is `nil`.
     */
    public var code: String? {
        return nil
    }
    
    /**
     The placemark’s scope.
     
     The scope offers a general indication of the size or importance of the feature represented by the placemark – in other words, how local the feature is.
     */
    public var scope: PlacemarkScope {
        let components = identifier.characters.split(".")
        assert(components.count == 2)
        let scopeCharacters = identifier.characters.split(".").first!
        return PlacemarkScope(descriptions: [String(scopeCharacters)])
    }
    
    /**
     The identifier of the placemark’s [Wikidata](https://www.wikidata.org/) item, if known.
     
     The item identifier consists of “Q” followed by a number. Prepend `https://www.wikidata.org/wiki/` to get the URL to the Wikidata item page.
     
     The Wikidata item contains structured information about the feature represented by the placemark. It also links to corresponding entries in various free content or open data resources, including Wikipedia, Wikimedia Commons, Wikivoyage, and Freebase.
     */
    public var wikidataItemIdentifier: String? {
        return nil
    }
    
    /**
     An array of keywords that describe the genre of the point of interest represented by the placemark.
     */
    public var genres: [String]? {
        return nil
    }
    
    /**
     Name of the [Maki](https://www.mapbox.com/maki/) icon that most precisely identifies the placemark.
     
     The icon is determined based on the placemark’s scope and any available genres.
     */
    public var imageName: String? {
        return nil
    }
    
    // MARK: Accessing Location Data
    
    /**
     The placemark’s geographic center.
     */
    public var location: CLLocation? {
        return nil
    }
    
    /**
     A region object indicating in some fashion the geographic extents of the placemark.
     
     When this property is not `nil`, it is currently always a `RectangularRegion`. In the future, it may be another type of `CLRegion`.
     */
    public var region: CLRegion? {
        return nil
    }
    
    // MARK: Accessing Contact Information
    
    /**
     The placemark’s full address in the customary local format, with each line in a separate string in the array.
     
     If you need to fit the same address on a single line, use the `qualifiedName` property, in which each line is separated by a comma instead of a line break.
     */
    private var formattedAddressLines: [String]? {
        return nil
    }
    
    #if !os(tvOS)
    /**
     The placemark’s postal address.
     
     To format the postal address, use a `CNPostalAddressFormatter` object.
     */
    @available(iOS 9.0, OSX 10.11, *)
    public var postalAddress: CNPostalAddress? {
        return nil
    }
    #endif
    
    /**
     A dictionary containing the Contacts keys and values for the placemark.
     
     The keys in this dictionary are those defined by the Contacts framework and used to access address information for a person or business. For a list of the keys that can be set in this dictionary, see the “Postal Address Properties” constants in _CNPostalAddress Reference_ and in this module.
     
     On iOS 9.0 and above, most of the information in this dictionary is also contained in the `CNPostalAddress` object stored in the `postalAddress` property.
     */
    public var addressDictionary: [NSObject: AnyObject]? {
        return nil
    }
    
    /**
     The phone number associated with the business represented by the placemark.
     */
    public var phoneNumber: String? {
        return nil
    }
    
    // MARK: Accessing Containing Placemarks
    
    /**
     An array of placemarks representing the hierarchy of administrative areas containing the feature represented by this placemark.
     
     The array is sorted in order from the smallest, most local administrative area to the largest administrative area.
     */
    public internal(set) var superiorPlacemarks: [Placemark]?
    
    /**
     A placemark representing the country containing the feature represented by this placemark.
     
     To get the country’s name, use the `name` property of the object stored in this property.
     */
    public var country: Placemark? {
        return superiorPlacemarks?.lazy.filter { $0.scope == .Country }.first
    }
    
    /**
     A placemark representing the postal code area containing the feature represented by this placemark.
     
     To get the postal code itself, use the `name` property of the object stored in this property.
     */
    public var postalCode: Placemark? {
        return superiorPlacemarks?.lazy.filter { $0.scope == .PostalCode }.first
    }
    
    /**
     A placemark representing the region containing the feature represented by this placemark.
     
     To get the region’s name, use the `name` property of the object stored in this property.
     */
    public var administrativeRegion: Placemark? {
        return superiorPlacemarks?.lazy.filter { $0.scope == .Region }.last
    }
    
    /**
     A placemark representing the district containing the feature represented by this placemark.
     
     To get the district’s name, use the `name` property of the object stored in this property.
     */
    public var district: Placemark? {
        return superiorPlacemarks?.lazy.filter { $0.scope == .District }.last
    }
    
    /**
     A placemark representing the place containing the feature represented by this placemark.
     
     To get the place’s name, use the `name` property of the object stored in this property.
     */
    public var place: Placemark? {
        return superiorPlacemarks?.lazy.filter { $0.scope == .Place }.last
    }
    
    /**
     A placemark representing the neighborhood containing the feature represented by this placemark.
     
     To get the neighborhood’s name, use the `name` property of the object stored in this property.
     */
    public var neighborhood: Placemark? {
        return superiorPlacemarks?.lazy.filter { $0.scope == .Neighborhood }.last
    }
    
    /**
     The name of the street associated with the placemark.
     */
    public var thoroughfare: String? {
        guard scope == .Address else {
            return nil
        }
        return featureJSON["text"] as? String
    }
    
    /**
     An identifier indicating the location along the street at which you can find the feature represented by the placemark.
     
     Typically, this property contains the house number and/or unit number of a business or residence.
     */
    public var subThoroughfare: String? {
        guard let houseNumber = featureJSON["address"] else {
            return nil
        }
        return String(houseNumber)
    }
}

/**
 A concrete subclass of `Placemark` to represent results of geocoding requests.
 */
@objc(MBGeocodedPlacemark)
public class GeocodedPlacemark: Placemark {
    private let propertiesJSON: JSONDictionary
    
    override init(featureJSON: JSONDictionary) {
        propertiesJSON = featureJSON["properties"] as? JSONDictionary ?? [:]
        
        super.init(featureJSON: featureJSON)
        
        assert(featureJSON["type"] as? String == "Feature")
        
        let contextJSON = featureJSON["context"] as? [JSONDictionary]
        superiorPlacemarks = contextJSON?.map { QualifyingPlacemark(featureJSON: $0) }
    }
    
    public override func copyWithZone(zone: NSZone) -> AnyObject {
        return GeocodedPlacemark(featureJSON: featureJSON)
    }
    
    public override var debugDescription: String {
        return qualifiedName
    }
    
    public override var qualifiedName: String! {
        return featureJSON["place_name"] as! String
    }
    
    public override var location: CLLocation {
        let centerCoordinate = CLLocationCoordinate2D(geoJSON: featureJSON["center"] as! [Double])
        return CLLocation(coordinate: centerCoordinate)
    }
    
    public override var region: CLRegion? {
        guard let boundingBox = featureJSON["bbox"] as? [Double] else {
            return nil
        }
        
        assert(boundingBox.count == 4)
        let southWest = CLLocationCoordinate2D(geoJSON: Array(boundingBox.prefix(2)))
        let northEast = CLLocationCoordinate2D(geoJSON: Array(boundingBox.suffix(2)))
        return RectangularRegion(southWest: southWest, northEast: northEast)
    }
    
    public override var name: String {
        let text = super.name
        
        // For address features, `text` is just the street name. Look through the fully-qualified address to determine whether to put the house number before or after the street name.
        if let houseNumber = featureJSON["address"] as? String where scope == .Address {
            let streetName = text
            let reversedAddress = "\(streetName) \(houseNumber)"
            if qualifiedName.componentsSeparatedByString(", ").contains(reversedAddress) {
                return reversedAddress
            } else {
                return "\(houseNumber) \(streetName)"
            }
        } else {
            return text
        }
    }
    
    public override var code: String? {
        return (propertiesJSON["short_code"] as? String)?.uppercaseString
    }
    
    public override var wikidataItemIdentifier: String? {
        let item = propertiesJSON["wikidata"] as? String
        if let item = item {
            assert(item.hasPrefix("Q"))
        }
        return item
    }
    
    public override var genres: [String]? {
        let categoryList = propertiesJSON["category"] as? String
        return categoryList?.componentsSeparatedByString(", ")
    }
    
    public override var imageName: String? {
        return propertiesJSON["maki"] as? String
    }
    
    override var formattedAddressLines: [String] {
        let lines = qualifiedName.componentsSeparatedByString(", ")
        return scope == .Address ? lines : Array(lines.suffixFrom(1))
    }
    
    #if !os(tvOS)
    @available(iOS 9.0, OSX 10.11, *)
    public override var postalAddress: CNPostalAddress? {
        let postalAddress = CNMutablePostalAddress()
        
        if scope == .Address {
            postalAddress.street = name
        } else if let address = propertiesJSON["address"] as? String {
            postalAddress.street = address.stringByReplacingOccurrencesOfString(", ", withString: "\n")
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
            postalAddress.ISOCountryCode = ISOCountryCode
        }
        
        return postalAddress
    }
    #endif
    
    public override var addressDictionary: [NSObject: AnyObject]? {
        var addressDictionary: [String: AnyObject] = [:]
        if scope == .Address {
            addressDictionary[MBPostalAddressStreetKey] = name
        } else if let address = propertiesJSON["address"] as? String {
            addressDictionary[MBPostalAddressStreetKey] = address
        }
        addressDictionary[MBPostalAddressCityKey] = place?.name
        addressDictionary[MBPostalAddressStateKey] = administrativeRegion?.name
        addressDictionary[MBPostalAddressPostalCodeKey] = postalCode?.name
        addressDictionary[MBPostalAddressCountryKey] = country?.name
        addressDictionary[MBPostalAddressISOCountryCodeKey] = country?.code
        let lines = qualifiedName.componentsSeparatedByString(", ")
        addressDictionary["formattedAddressLines"] = scope == .Address ? lines : Array(lines.suffixFrom(1))
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
    public override var phoneNumber: String? {
        return propertiesJSON["tel"] as? String
    }
}

/**
 A concrete subclass of `Placemark` to represent entries in a `GeocodedPlacemark` object’s `superiorPlacemarks` property. These entries are like top-level geocoding results, except that they lack location information and are flatter, with properties directly at the top level.
 */
@objc(MBQualifyingPlacemark)
public class QualifyingPlacemark: Placemark {
    public override func copyWithZone(zone: NSZone) -> AnyObject {
        return QualifyingPlacemark(featureJSON: featureJSON)
    }
    
    public override var code: String? {
        return (featureJSON["short_code"] as? String)?.uppercaseString
    }
    
    public override var wikidataItemIdentifier: String? {
        let item = featureJSON["wikidata"] as? String
        if let item = item {
            assert(item.hasPrefix("Q"))
        }
        return item
    }
}
