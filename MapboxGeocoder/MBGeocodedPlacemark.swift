import Foundation


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
        let text = super.name
        // For address features, `text` is just the street name. Look through the fully-qualified address to determine whether to put the house number before or after the street name.
        if let houseNumber = address, scope == .address {
            let streetName = text
            let reversedAddress = "\(streetName) \(houseNumber)"
            if qualifiedNameComponents.contains(reversedAddress) {
                return reversedAddress
            } else {
                return "\(houseNumber) \(streetName)"
            }
        } else {
            return text
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
    
    /**
     The placemark’s full address in the customary local format, with each line in a separate string in the array.
     
     If you need to fit the same address on a single line, use the `qualifiedName` property, in which each line is separated by a comma instead of a line break.
     */
    var formattedAddressLines: [String]? {
        return clippedAddressLines
    }
    
    #if !os(tvOS)
    @available(iOS 9.0, OSX 10.11, *)
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
    
    open override var code: String? {
        get { return country?.code }
        set { country?.code = code }
    }
    
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
}
