import XCTest
import Nocilla
import CoreLocation
@testable import MapboxGeocoder

class ReverseGeocodingTests: XCTestCase {

    override func setUp() {
        super.setUp()
        LSNocilla.sharedInstance().start()
    }
    
    override func tearDown() {
        LSNocilla.sharedInstance().clearStubs()
        LSNocilla.sharedInstance().stop()
        super.setUp()
    }

    func testValidReverseGeocode() {
        let expectation = expectationWithDescription("reverse geocode should return results")
        
        let json = Fixture.stringFromFileNamed("reverse_valid")
        stubRequest("GET", "https://api.mapbox.com/geocoding/v5/mapbox.places/-95.78558,37.13284.json?access_token=\(BogusToken)").andReturn(200).withHeaders(["Content-Type": "application/json"]).withBody(json)

        let geocoder = MBGeocoder(accessToken: BogusToken)
        var addressPlacemark: MBPlacemark! = nil
        var placePlacemark: MBPlacemark! = nil
        let task = geocoder.reverseGeocodeLocation(
          CLLocation(latitude: 37.13284000, longitude: -95.78558000)) { (placemarks, error) in
            XCTAssertEqual(placemarks?.count, 5, "reverse geocode should have 5 results")
            addressPlacemark = placemarks![0]
            placePlacemark = placemarks![1]
            
            expectation.fulfill()
        }
        XCTAssertNotNil(task)

        waitForExpectationsWithTimeout(1) { (error) in
            XCTAssertNil(error, "Error: \(error)")
            XCTAssertEqual(task?.state, .Completed)
        }
        
        XCTAssertEqual(addressPlacemark.description, "3099 3100 Rd, Independence, Kansas 67301, United States", "reverse geocode should populate description")
        XCTAssertEqual(addressPlacemark.name, "3099 3100 Rd", "reverse geocode should populate name")
        XCTAssertEqual(addressPlacemark.location?.coordinate, CLLocationCoordinate2D(latitude: 37.12787, longitude: -95.783074), "reverse geocode should populate location")
        XCTAssertEqual(addressPlacemark.scope, .Address, "reverse geocode should populate scope")
        XCTAssertEqual(addressPlacemark.ISOcountryCode, "US", "reverse geocode should populate ISO country code")
        XCTAssertEqual(addressPlacemark.country, "United States", "reverse geocode should populate country")
        XCTAssertEqual(addressPlacemark.postalCode, "67301", "reverse geocode should populate postal code")
        XCTAssertEqual(addressPlacemark.administrativeArea, "Kansas", "reverse geocode should populate administrative area")
        XCTAssertEqual(addressPlacemark.subAdministrativeArea, "Independence", "reverse geocode should populate sub-administrative area")
        XCTAssertEqual(addressPlacemark.locality, "Independence", "reverse geocode should populate locality")
        XCTAssertEqual(addressPlacemark.thoroughfare, "3100 Rd", "reverse geocode should populate thoroughfare")
        XCTAssertEqual(addressPlacemark.subThoroughfare, "3099", "reverse geocode should populate sub-thoroughfare")
        
        XCTAssertNotNil(addressPlacemark.addressDictionary)
        let addressDictionary = addressPlacemark.addressDictionary!
        XCTAssertEqual(addressDictionary[MBPostalAddressStreetKey] as? String, "3099 3100 Rd", "reverse geocode should populate street in address dictionary")
        XCTAssertEqual(addressDictionary[MBPostalAddressCityKey] as? String, "Independence", "reverse geocode should populate city in address dictionary")
        XCTAssertEqual(addressDictionary[MBPostalAddressStateKey] as? String, "Kansas", "reverse geocode should populate state in address dictionary")
        XCTAssertEqual(addressDictionary[MBPostalAddressCountryKey] as? String, "United States", "reverse geocode should populate country in address dictionary")
        XCTAssertEqual(addressDictionary[MBPostalAddressISOCountryCodeKey] as? String, "US", "reverse geocode should populate ISO country code in address dictionary")
        
        let southWest = CLLocationCoordinate2D(latitude: 37.033229992893, longitude: -95.927990005645)
        let northEast = CLLocationCoordinate2D(latitude: 37.35632800706, longitude: -95.594628992671)
        let region = placePlacemark.region
        XCTAssertNotNil(region, "reverse geocode should populate region")
        XCTAssertEqualWithAccuracy(region!.southWest.latitude, southWest.latitude, accuracy: 0.000000000001)
        XCTAssertEqualWithAccuracy(region!.southWest.longitude, southWest.longitude, accuracy: 0.000000000001)
        XCTAssertEqualWithAccuracy(region!.northEast.latitude, northEast.latitude, accuracy: 0.000000000001)
        XCTAssertEqualWithAccuracy(region!.northEast.longitude, northEast.longitude, accuracy: 0.000000000001)
    }

    func testInvalidReverseGeocode() {
        let json = Fixture.stringFromFileNamed("reverse_invalid")
        stubRequest("GET", "https://api.mapbox.com/geocoding/v5/mapbox.places/0.00000,0.00000.json?access_token=\(BogusToken)").andReturn(200).withHeaders(["Content-Type": "application/json"]).withBody(json)
        
        let expection = expectationWithDescription("reverse geocode execute completion handler for invalid query")
        let geocoder = MBGeocoder(accessToken: BogusToken)
        let task = geocoder.reverseGeocodeLocation(CLLocation(latitude: 0, longitude: 0)) { (placemarks, error) in
            XCTAssertEqual(placemarks?.count, 0, "reverse geocode should return no results for invalid query")
            expection.fulfill()
        }
        XCTAssertNotNil(task)

        waitForExpectationsWithTimeout(1) { (error) in
            XCTAssertNil(error, "Error: \(error)")
            XCTAssertEqual(task?.state, .Completed)
        }
    }
}
