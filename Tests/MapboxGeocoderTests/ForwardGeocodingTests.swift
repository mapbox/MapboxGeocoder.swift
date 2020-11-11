import XCTest
import OHHTTPStubs
#if SWIFT_PACKAGE
import OHHTTPStubsSwift
#endif
import CoreLocation
@testable import MapboxGeocoder

class ForwardGeocodingTests: XCTestCase {
    override func tearDown() {
        HTTPStubs.removeAllStubs()
        super.tearDown()
    }

    func testValidForwardGeocode() {
        let expectation = self.expectation(description: "forward geocode should return results")
        
        _ = stub(condition: isHost("api.mapbox.com")
            && isPath("/geocoding/v5/mapbox.places/1600+pennsylvania+ave.json")
            && containsQueryParams(["country": "ca", "access_token": BogusToken])) { _ in
            let path = Bundle.module.path(forResource: "forward_valid", ofType: "json")
            return HTTPStubsResponse(fileAtPath: path!, statusCode: 200, headers: ["Content-Type": "application/vnd.geo+json"])
        }
        
        let geocoder = Geocoder(accessToken: BogusToken)
        var addressPlacemark: GeocodedPlacemark! = nil
        let options = ForwardGeocodeOptions(query: "1600 pennsylvania ave")
        options.allowedISOCountryCodes = ["CA"]
        options.allowedRegion = RectangularRegion(southWest: CLLocationCoordinate2D(latitude: -85, longitude: -179), northEast: CLLocationCoordinate2D(latitude: 85, longitude: 179))
        let task = geocoder.geocode(options) { (placemarks, attribution, error) in
            XCTAssertEqual(placemarks?.count, 4, "forward geocode should have 4 results")
            addressPlacemark = placemarks![0]
            
            XCTAssertEqual(attribution, "NOTICE: © 2016 Mapbox and its suppliers. All rights reserved. Use of this data is subject to the Mapbox Terms of Service (https://www.mapbox.com/about/maps/). This response and the information it contains may not be retained.")
            
            expectation.fulfill()
        }
        XCTAssertNotNil(task)
        
        waitForExpectations(timeout: 1) { (error) in
            XCTAssertNil(error, "Error: \(error!)")
            XCTAssertEqual(task.state, URLSessionTask.State.completed)
        }
        
        XCTAssertEqual(addressPlacemark.routableLocations![0].coordinate.longitude, CLLocationDegrees(138.995284))
        XCTAssertEqual(addressPlacemark.routableLocations![0].coordinate.latitude, CLLocationDegrees(-34.470403))
        XCTAssertEqual(addressPlacemark.relevance, 0.39, "addressPlacemark.relevance should be 0.39")
        XCTAssertEqual(addressPlacemark.description, "Pennsylvania Ave", "forward geocode should populate description")
        XCTAssertEqual(addressPlacemark.qualifiedName!, "Pennsylvania Ave, Wasaga Beach, Ontario L9Z 3A8, Canada", "forward geocode should populate qualified name")
        XCTAssertEqual(addressPlacemark.name, "Pennsylvania Ave", "forward geocode should populate name")
        XCTAssertEqual(addressPlacemark.qualifiedNameComponents, ["Pennsylvania Ave", "Wasaga Beach", "Ontario L9Z 3A8", "Canada"], "forward geocode should populate name")
        XCTAssertEqual(addressPlacemark.qualifiedName, "Pennsylvania Ave, Wasaga Beach, Ontario L9Z 3A8, Canada", "forward geocode should populate name")
        XCTAssertEqual(addressPlacemark.superiorPlacemarks?.count, 4, "forward geocode should populate superior placemarks")
        XCTAssertEqual(addressPlacemark.location!.coordinate.latitude, 44.5047077, "forward geocode should populate location")
    
        XCTAssertEqual(addressPlacemark.location!.coordinate.longitude, -79.9850737, "forward geocode should populate location")
        XCTAssertEqual(addressPlacemark.scope, PlacemarkScope.address, "forward geocode should populate scope")
        XCTAssertEqual(addressPlacemark.country?.code, "CA", "forward geocode should populate ISO country code")
        XCTAssertEqual(addressPlacemark.country?.name, "Canada", "forward geocode should populate country")
        XCTAssertEqual(addressPlacemark.postalCode?.name, "L9Z 3A8", "forward geocode should populate postal code")
        XCTAssertEqual(addressPlacemark.administrativeRegion?.name, "Ontario", "forward geocode should populate administrative region")
        XCTAssertNil(addressPlacemark.district?.name, "forward geocode in Canada should not populate district area")
        XCTAssertEqual(addressPlacemark.place?.name, "Wasaga Beach", "forward geocode should populate locality")
        XCTAssertEqual(addressPlacemark.thoroughfare, "Pennsylvania Ave", "forward geocode should populate thoroughfare")
        XCTAssertNil(addressPlacemark.subThoroughfare, "forward geocode should not populate sub-thoroughfare for street-only result")
        
        XCTAssertNotNil(addressPlacemark.addressDictionary)
        let addressDictionary = addressPlacemark.addressDictionary!
        XCTAssertEqual(addressDictionary[MBPostalAddressStreetKey] as? String, "Pennsylvania Ave", "forward geocode should populate street in address dictionary")
        XCTAssertEqual(addressDictionary[MBPostalAddressCityKey] as? String, "Wasaga Beach", "forward geocode should populate city in address dictionary")
        XCTAssertEqual(addressDictionary[MBPostalAddressStateKey] as? String, "Ontario", "forward geocode should populate state in address dictionary")
        XCTAssertEqual(addressDictionary[MBPostalAddressCountryKey] as? String, "Canada", "forward geocode should populate country in address dictionary")
        XCTAssertEqual(addressDictionary[MBPostalAddressISOCountryCodeKey] as? String, "CA", "forward geocode should populate ISO country code in address dictionary")
    }
    
    func testInvalidForwardGeocode() {
        _ = stub(condition: isHost("api.mapbox.com")
            && isPath("/geocoding/v5/mapbox.places/Sandy+Island,+New+Caledonia.json")
            && containsQueryParams(["country": "nc", "types": "region,place,locality,poi", "access_token": BogusToken])) { _ in
                let path = Bundle.module.path(forResource: "forward_invalid", ofType: "json")
                return HTTPStubsResponse(fileAtPath: path!, statusCode: 200, headers: ["Content-Type": "application/vnd.geo+json"])
        }
        
        let expectation = self.expectation(description: "forward geocode execute completion handler for invalid query")
        let geocoder = Geocoder(accessToken: BogusToken)
        let options = ForwardGeocodeOptions(query: "Sandy Island, New Caledonia")
        options.allowedScopes = [.region, .place, .locality, .pointOfInterest]
        options.allowedISOCountryCodes = ["NC"]
        let task = geocoder.geocode(options) { (placemarks, attribution, error) in
            XCTAssertEqual(placemarks?.count, 0, "forward geocode should return no results for invalid query")
            XCTAssertEqual(attribution, "NOTICE: © 2016 Mapbox and its suppliers. All rights reserved. Use of this data is subject to the Mapbox Terms of Service (https://www.mapbox.com/about/maps/). This response and the information it contains may not be retained.")
            
            expectation.fulfill()
        }
        XCTAssertNotNil(task)
        
        waitForExpectations(timeout: 1) { (error) in
            XCTAssertNil(error, "Error: \(error!)")
            XCTAssertEqual(task.state, URLSessionTask.State.completed)
        }
    }
    
    func testValidChineseForwardGeocode() {
        let expectation = self.expectation(description: "forward geocode should return results")
        
        _ = stub(condition: isHost("api.mapbox.com")
            && isPath("/geocoding/v5/mapbox.places/hainan.json")
            && containsQueryParams(["country": "cn", "language": "zh", "access_token": BogusToken])) { _ in
            let path = Bundle.module.path(forResource: "forward_valid_zh", ofType: "json")
            return HTTPStubsResponse(fileAtPath: path!, statusCode: 200, headers: ["Content-Type": "application/vnd.geo+json"])
        }
        
        let geocoder = Geocoder(accessToken: BogusToken)
        var placemark: GeocodedPlacemark! = nil
        let options = ForwardGeocodeOptions(query: "hainan")
        options.allowedISOCountryCodes = ["CN"]
        options.locale = Locale(identifier: "zh-Hans")
        let task = geocoder.geocode(options) { (placemarks, attribution, error) in
            XCTAssertEqual(placemarks?.count, 3)
            placemark = placemarks![0]
            
            XCTAssertEqual(attribution, "NOTICE: © 2016 Mapbox and its suppliers. All rights reserved. Use of this data is subject to the Mapbox Terms of Service (https://www.mapbox.com/about/maps/). This response and the information it contains may not be retained.")
            
            expectation.fulfill()
        }
        XCTAssertNotNil(task)
        
        waitForExpectations(timeout: 1) { (error) in
            XCTAssertNil(error, "Error: \(error!)")
            XCTAssertEqual(task.state, .completed)
        }
        
        XCTAssertEqual(placemark.description, "海南区", "forward geocode should populate description")
        XCTAssertEqual(placemark.qualifiedName!, "中国内蒙古乌海市海南区", "forward geocode should populate qualified name")
        XCTAssertEqual(placemark.name, "海南区", "forward geocode should populate name")
        XCTAssertEqual(placemark.qualifiedNameComponents, ["中国", "内蒙古", "乌海市", "海南区"], "forward geocode in Chinese should reverse address components")
        XCTAssertEqual(placemark.qualifiedName, "中国内蒙古乌海市海南区", "forward geocode should populate name")
        XCTAssertEqual(placemark.superiorPlacemarks?.count, 3, "forward geocode should populate superior placemarks")
        XCTAssertEqual(placemark.location!.coordinate.latitude, 39.458115, "forward geocode should populate location")
        
        XCTAssertEqual(placemark.location!.coordinate.longitude, 106.820552, "forward geocode should populate location")
        XCTAssertEqual(placemark.scope, PlacemarkScope.place, "forward geocode should populate scope")
        XCTAssertEqual(placemark.country?.code, "CN", "forward geocode should populate ISO country code")
        XCTAssertEqual(placemark.country?.name, "中国", "forward geocode should populate country")
        XCTAssertNil(placemark.postalCode, "forward geocode for place should not populate postal code")
        XCTAssertEqual(placemark.administrativeRegion?.name, "内蒙古", "forward geocode should populate administrative region")
        XCTAssertEqual(placemark.district?.name, "乌海市", "forward geocode should populate district area")
        XCTAssertNil(placemark.place?.name, "forward geocode for place should not populate locality")
        XCTAssertNil(placemark.thoroughfare, "forward geocode for place should not populate thoroughfare")
        XCTAssertNil(placemark.subThoroughfare, "forward geocode should not populate sub-thoroughfare for street-only result")
        
        XCTAssertNotNil(placemark.addressDictionary)
        let addressDictionary = placemark.addressDictionary!
        XCTAssertNil(addressDictionary[MBPostalAddressStreetKey])
        XCTAssertNil(addressDictionary[MBPostalAddressCityKey])
        XCTAssertEqual(addressDictionary[MBPostalAddressStateKey] as? String, "内蒙古", "forward geocode should populate state in address dictionary")
        XCTAssertEqual(addressDictionary[MBPostalAddressCountryKey] as? String, "中国", "forward geocode should populate country in address dictionary")
        XCTAssertEqual(addressDictionary[MBPostalAddressISOCountryCodeKey] as? String, "CN", "forward geocode should populate ISO country code in address dictionary")
    }
}
