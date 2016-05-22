import XCTest
import OHHTTPStubs
@testable import MapboxGeocoder

let BogusToken = "pk.feedCafeDadeDeadBeef-BadeBede.FadeCafeDadeDeed-BadeBede"

class GeocoderTests: XCTestCase {
    override func tearDown() {
        OHHTTPStubs.removeAllStubs()
        super.tearDown()
    }
    
    func testConfiguration() {
        let geocoder = Geocoder(accessToken: BogusToken)
        XCTAssertEqual(geocoder.accessToken, BogusToken)
        XCTAssertEqual(geocoder.apiEndpoint.absoluteString, "https://api.mapbox.com")
    }
}
