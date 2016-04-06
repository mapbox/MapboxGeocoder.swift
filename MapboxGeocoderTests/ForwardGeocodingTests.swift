import XCTest
import Nocilla
import CoreLocation
@testable import MapboxGeocoder

class ForwardGeocodingTests: XCTestCase {
    override func setUp() {
        super.setUp()
        LSNocilla.sharedInstance().start()
    }
    
    override func tearDown() {
        LSNocilla.sharedInstance().clearStubs()
        LSNocilla.sharedInstance().stop()
        super.setUp()
    }

    func testValidForwardGeocode() {
        let expectation = expectationWithDescription("forward geocode should return results")
        
        let json = Fixture.stringFromFileNamed("forward_valid")
        stubRequest("GET", "https://api.mapbox.com/geocoding/v5/mapbox.places/1600+pennsylvania+ave+nw.json?access_token=\(BogusToken)&country=ca").andReturn(200).withHeaders(["Content-Type": "application/json"]).withBody(json)
        
        let geocoder = MBGeocoder(accessToken: BogusToken)
        var addressPlacemark: MBPlacemark! = nil
        geocoder.geocodeAddressString("1600 pennsylvania ave nw", inCountries: ["CA"]) { (placemarks, error) in
            XCTAssertEqual(placemarks?.count, 5, "forward geocode should have 5 results")
            addressPlacemark = placemarks![0]
            
            expectation.fulfill()
        }
        
        waitForExpectationsWithTimeout(1) { (error) in
            XCTAssertNil(error, "Error: \(error)")
            XCTAssertFalse(geocoder.geocoding)
        }
        
        XCTAssertEqual(addressPlacemark.description, "Pennsylvania Ave, Stellarton, Nova Scotia B0K 1S0, Canada", "forward geocode should populate description")
        XCTAssertEqual(addressPlacemark.name, "Pennsylvania Ave", "forward geocode should populate name")
        XCTAssertEqual(addressPlacemark.location?.coordinate, CLLocationCoordinate2D(latitude: 45.5562851, longitude: -62.661944), "forward geocode should populate location")
        XCTAssertEqual(addressPlacemark.scope, .Address, "forward geocode should populate scope")
        XCTAssertEqual(addressPlacemark.ISOcountryCode, "CA", "forward geocode should populate ISO country code")
        XCTAssertEqual(addressPlacemark.country, "Canada", "forward geocode should populate country")
        XCTAssertEqual(addressPlacemark.postalCode, "B0K 1S0", "forward geocode should populate postal code")
        XCTAssertEqual(addressPlacemark.administrativeArea, "Nova Scotia", "forward geocode should populate administrative area")
        XCTAssertEqual(addressPlacemark.subAdministrativeArea, "Stellarton", "forward geocode should populate sub-administrative area")
        XCTAssertEqual(addressPlacemark.locality, "Stellarton", "forward geocode should populate locality")
        XCTAssertEqual(addressPlacemark.thoroughfare, "Pennsylvania Ave", "forward geocode should populate thoroughfare")
        XCTAssertNil(addressPlacemark.subThoroughfare, "forward geocode should not populate sub-thoroughfare for street-only result")
        
        XCTAssertNotNil(addressPlacemark.addressDictionary)
        let addressDictionary = addressPlacemark.addressDictionary!
        XCTAssertEqual(addressDictionary[MBPostalAddressStreetKey] as? String, "Pennsylvania Ave", "forward geocode should populate street in address dictionary")
        XCTAssertEqual(addressDictionary[MBPostalAddressCityKey] as? String, "Stellarton", "forward geocode should populate city in address dictionary")
        XCTAssertEqual(addressDictionary[MBPostalAddressStateKey] as? String, "Nova Scotia", "forward geocode should populate state in address dictionary")
        XCTAssertEqual(addressDictionary[MBPostalAddressCountryKey] as? String, "Canada", "forward geocode should populate country in address dictionary")
        XCTAssertEqual(addressDictionary[MBPostalAddressISOCountryCodeKey] as? String, "CA", "forward geocode should populate ISO country code in address dictionary")
    }
    
    func testInvalidForwardGeocode() {
        let json = Fixture.stringFromFileNamed("forward_invalid")
        stubRequest("GET", "https://api.mapbox.com/geocoding/v5/mapbox.places/Sandy+Island,+New+Caledonia.json?access_token=\(BogusToken)&country=fr&types=region%2Cplace%2Clocality%2Cpoi").andReturn(200).withHeaders(["Content-Type": "application/json"]).withBody(json)
        
        let expection = expectationWithDescription("forward geocode execute completion handler for invalid query")
        let geocoder = MBGeocoder(accessToken: BogusToken)
        geocoder.geocodeAddressString("Sandy Island, New Caledonia", withAllowedScopes: [.AdministrativeArea, .Place, .Locality, .PointOfInterest], inCountries: ["FR"]) { (placemarks, error) in
            XCTAssertEqual(placemarks?.count, 0, "forward geocode should return no results for invalid query")
            expection.fulfill()
        }
        
        waitForExpectationsWithTimeout(1) { (error) in
            XCTAssertNil(error, "Error: \(error)")
            XCTAssertFalse(geocoder.geocoding)
        }
    }
}
