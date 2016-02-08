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
        let descriptionExpectation = expectationWithDescription("reverse geocode should populate description")
        let nameExpectation = expectationWithDescription("reverse geocode should populate name")
        let locationExpectation = expectationWithDescription("reverse geocode should populate location")
        let scopeExpectation = expectationWithDescription("reverse geocode should populate scope")
        let countryCodeExpectation = expectationWithDescription("reverse geocode should populate ISO country code")
        let countryExpectation = expectationWithDescription("reverse geocode should populate country")
        let postalCodeExpectation = expectationWithDescription("reverse geocode should populate postal code")
        let administrativeAreaExpectation = expectationWithDescription("reverse geocode should populate administrative area")
        let subAdministrativeAreaExpectation = expectationWithDescription("reverse geocode should populate sub-administrative area")
        let localityExpectation = expectationWithDescription("reverse geocode should populate locality")
        let thoroughfareExpectation = expectationWithDescription("reverse geocode should populate thoroughfare")
        let subThoroughfareExpectation = expectationWithDescription("reverse geocode should populate sub-thoroughfare")
        let regionExpectation = expectationWithDescription("reverse geocode should populate region")
        let addressStreetExpectation = expectationWithDescription("reverse geocode should populate street in address dictionary")
        let addressCityExpectation = expectationWithDescription("reverse geocode should populate city in address dictionary")
        let addressStateExpectation = expectationWithDescription("reverse geocode should populate state in address dictionary")
        let addressCountryExpectation = expectationWithDescription("reverse geocode should populate country in address dictionary")
        let addressISOCountryCodeExpectation = expectationWithDescription("reverse geocode should populate ISO country code in address dictionary")
        
        stub(isHost("api.mapbox.com")) { _ in
            let path = NSBundle(forClass: self.dynamicType).pathForResource("reverse_valid", ofType: "json")
            return OHHTTPStubsResponse(fileAtPath: path!, statusCode: 200, headers: nil)
        }

        MBGeocoder(accessToken: accessToken).reverseGeocodeLocation(
          CLLocation(latitude: 37.13284000, longitude: -95.78558000)) { (placemarks, error) in
            if let result = placemarks?.first where placemarks?.count > 0 {
                resultsExpectation.fulfill()
                if result.description == "3099 3100 Rd, Independence, Kansas 67301, United States" {
                    descriptionExpectation.fulfill()
                }
                if result.name == "3099 3100 Rd" {
                    nameExpectation.fulfill()
                }
                if let location = result.location where location.coordinate.latitude == 37.12787 &&
                  location.coordinate.longitude == -95.783074 {
                    locationExpectation.fulfill()
                }
                if result.scope == .Address {
                    scopeExpectation.fulfill()
                }
                if result.ISOcountryCode == "US" {
                    countryCodeExpectation.fulfill()
                }
                if result.country == "United States" {
                    countryExpectation.fulfill()
                }
                if result.postalCode == "67301" {
                    postalCodeExpectation.fulfill()
                }
                if result.administrativeArea == "Kansas" {
                    administrativeAreaExpectation.fulfill()
                }
                if result.subAdministrativeArea == "Independence" {
                    subAdministrativeAreaExpectation.fulfill()
                }
                if result.locality == "Independence" {
                    localityExpectation.fulfill()
                }
                if result.thoroughfare == "3100 Rd" {
                    thoroughfareExpectation.fulfill()
                }
                if result.subThoroughfare == "3099" {
                    subThoroughfareExpectation.fulfill()
                }
                let southWest = CLLocationCoordinate2D(latitude: 37.109405, longitude: -95.783365)
                let northEast = CLLocationCoordinate2D(latitude: 37.208643, longitude: -95.781811)
                if result.region == MBRectangularRegion(southWest: southWest, northEast: northEast) {
                    regionExpectation.fulfill()
                }
                if let street = result.addressDictionary?[MBPostalAddressStreetKey] as? String where street == "3099 3100 Rd" {
                    addressStreetExpectation.fulfill()
                }
                if let city = result.addressDictionary?[MBPostalAddressCityKey] as? String where city == "Independence" {
                    addressCityExpectation.fulfill()
                }
                if let state = result.addressDictionary?[MBPostalAddressStateKey] as? String where state == "Kansas" {
                    addressStateExpectation.fulfill()
                }
                if let country = result.addressDictionary?[MBPostalAddressCountryKey] as? String where country == "United States" {
                    addressCountryExpectation.fulfill()
                }
                if let countryCode = result.addressDictionary?[MBPostalAddressISOCountryCodeKey] as? String where countryCode == "US" {
                    addressISOCountryCodeExpectation.fulfill()
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
