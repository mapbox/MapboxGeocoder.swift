// Based on CNPostalAddress, the successor to ABPerson, which is used by CLPlacemark.

public let MBPostalAddressStreetKey = "street"
public let MBPostalAddressCityKey = "city"
public let MBPostalAddressStateKey = "state"
public let MBPostalAddressPostalCodeKey = "postalCode"
public let MBPostalAddressCountryKey = "country"
public let MBPostalAddressISOCountryCodeKey = "ISOCountryCode"

/**
 A `Placemark` object represents a geocoder result. A placemark associates identifiers, geographic data, and contact information with a particular latitude and longitude. It is possible to explicitly create a placemark object from another placemark object; however, placemark objects are generally created for you via the `Geocoder.geocode(options:completionHandler:)` method.
 */
@objc(MBPlacemark)
public class Placemark: NSObject, NSCopying, NSSecureCoding {
    private let featureJSON: JSONDictionary
    
    internal init(featureJSON: JSONDictionary) {
        self.featureJSON = featureJSON
    }
    
    public convenience required init?(coder aDecoder: NSCoder) {
        guard let featureJSON = aDecoder.decodeObjectOfClass(NSDictionary.self, forKey: "featureJSON") as? JSONDictionary else {
            return nil
        }
        
        self.init(featureJSON: featureJSON)
    }
    
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
    
    private var identifier: String {
        return featureJSON["id"] as! String
    }
    
    public var name: String {
        return featureJSON["text"] as! String
    }
    
    public var qualifiedName: String? {
        return nil
    }
    
    public var code: String? {
        return nil
    }
    
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
    
    public var location: CLLocation? {
        return nil
    }
    
    public var region: CLRegion? {
        return nil
    }
    
    // MARK: Accessing Contact Information
    
    public var formattedAddressLines: [String]? {
        return nil
    }
    
    public var addressDictionary: [NSObject: AnyObject]? {
        return nil
    }
    
    public var phoneNumber: String? {
        return nil
    }
    
    // MARK: Accessing Containing Placemarks
    
    public internal(set) var qualifiers: [Placemark]?
    
    public var country: Placemark? {
        return qualifiers?.lazy.filter { $0.scope == .Country }.first
    }
    
    public var postalCode: Placemark? {
        return qualifiers?.lazy.filter { $0.scope == .PostalCode }.first
    }
    
    public var administrativeRegion: Placemark? {
        return qualifiers?.lazy.filter { $0.scope == .Region }.last
    }
    
    public var district: Placemark? {
        return qualifiers?.lazy.filter { $0.scope == .District }.last
    }
    
    public var place: Placemark? {
        return qualifiers?.lazy.filter { $0.scope == .Place }.last
    }
    
    public var neighborhood: Placemark? {
        return qualifiers?.lazy.filter { $0.scope == .Neighborhood }.last
    }
    
    public var thoroughfare: String? {
        guard scope == .Address else {
            return nil
        }
        return featureJSON["text"] as? String
    }
    
    public var subThoroughfare: String? {
        guard let houseNumber = featureJSON["address"] else {
            return nil
        }
        return String(houseNumber)
    }
}

internal class GeocodedPlacemark: Placemark {
    private let propertiesJSON: JSONDictionary
    
    override init(featureJSON: JSONDictionary) {
        propertiesJSON = featureJSON["properties"] as? JSONDictionary ?? [:]
        
        super.init(featureJSON: featureJSON)
        
        assert(featureJSON["type"] as? String == "Feature")
        
        let contextJSON = featureJSON["context"] as? [JSONDictionary]
        qualifiers = contextJSON?.map { QualifyingPlacemark(featureJSON: $0) }
    }
    
    override func copyWithZone(zone: NSZone) -> AnyObject {
        return GeocodedPlacemark(featureJSON: featureJSON)
    }
    
    override var debugDescription: String {
        return qualifiedName
    }
    
    override var qualifiedName: String! {
        return featureJSON["place_name"] as! String
    }
    
    override var location: CLLocation {
        let centerCoordinate = CLLocationCoordinate2D(geoJSON: featureJSON["center"] as! [Double])
        return CLLocation(coordinate: centerCoordinate)
    }
    
    override var region: RectangularRegion? {
        guard let boundingBox = featureJSON["bbox"] as? [Double] else {
            return nil
        }
        
        assert(boundingBox.count == 4)
        let southWest = CLLocationCoordinate2D(geoJSON: Array(boundingBox.prefix(2)))
        let northEast = CLLocationCoordinate2D(geoJSON: Array(boundingBox.suffix(2)))
        return RectangularRegion(southWest: southWest, northEast: northEast)
    }
    
    override var name: String {
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
    
    override var code: String? {
        return (propertiesJSON["short_code"] as? String)?.uppercaseString
    }
    
    override var wikidataItemIdentifier: String? {
        let item = propertiesJSON["wikidata"] as? String
        if let item = item {
            assert(item.hasPrefix("Q"))
        }
        return item
    }
    
    override var genres: [String]? {
        let categoryList = propertiesJSON["category"] as? String
        return categoryList?.componentsSeparatedByString(", ")
    }
    
    override var formattedAddressLines: [String] {
        let lines = qualifiedName.componentsSeparatedByString(", ")
        return scope == .Address ? lines : Array(lines.suffixFrom(1))
    }
    
    override var addressDictionary: [NSObject: AnyObject]? {
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
    override var phoneNumber: String? {
        return propertiesJSON["tel"] as? String
    }
}

private class QualifyingPlacemark: Placemark {
    override func copyWithZone(zone: NSZone) -> AnyObject {
        return QualifyingPlacemark(featureJSON: featureJSON)
    }
    
    override var code: String? {
        return (featureJSON["short_code"] as? String)?.uppercaseString
    }
    
    override var wikidataItemIdentifier: String? {
        let item = featureJSON["wikidata"] as? String
        if let item = item {
            assert(item.hasPrefix("Q"))
        }
        return item
    }
}
