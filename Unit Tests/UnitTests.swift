import XCTest
import MapboxGeocoder
import CoreLocation
import OHHTTPStubs

class UnitTests: XCTestCase {

    let accessToken = "pk.eyJ1IjoianVzdGluIiwiYSI6IlpDbUJLSUEifQ.4mG8vhelFMju6HpIY-Hi5A"

    override func tearDown() {
        super.tearDown()
        OHHTTPStubs.removeAllStubs()
    }

    func testValidReverseGeocode() {
        let resultsExpectation = expectationWithDescription("reverse geocode should return results")
        let nameExpectation = expectationWithDescription("reverse geocode should populate name")
        let locationExpectation = expectationWithDescription("reverse geocode should populate location")

        stub(isHost("api.mapbox.com")) { _ in
            let path = NSBundle(forClass: self.dynamicType).pathForResource("reverse_valid", ofType: "json")
            return OHHTTPStubsResponse(fileAtPath: path!, statusCode: 200, headers: nil)
        }

        MBGeocoder(accessToken: accessToken).reverseGeocodeLocation(
          CLLocation(latitude: 37.13284000, longitude: -95.78558000)) { (placemarks, error) in
            if let result = placemarks?.first where placemarks?.count > 0 {
                resultsExpectation.fulfill()
                if result.name == "3099 3100 Rd, Independence, Kansas 67301, United States" {
                    nameExpectation.fulfill()
                }
                if let location = result.location where location.coordinate.latitude == 37.12787 &&
                  location.coordinate.longitude == -95.783074 {
                    locationExpectation.fulfill()
                }
            }
        }

        waitForExpectationsWithTimeout(1, handler: nil)
    }

    func testInvalidReverseGeocode() {
        let resultsExpection = expectationWithDescription("reverse geocode should return no results for invalid query")

        stub(isHost("api.mapbox.com")) { _ in
            let path = NSBundle(forClass: self.dynamicType).pathForResource("reverse_invalid", ofType: "json")
            return OHHTTPStubsResponse(fileAtPath: path!, statusCode: 200, headers: nil)
        }

        MBGeocoder(accessToken: accessToken).reverseGeocodeLocation(CLLocation(latitude: 0, longitude: 0)) { (placemarks, error) in
            if placemarks?.count == 0 {
                resultsExpection.fulfill()
            }
        }

        waitForExpectationsWithTimeout(1, handler: nil)
    }

}
