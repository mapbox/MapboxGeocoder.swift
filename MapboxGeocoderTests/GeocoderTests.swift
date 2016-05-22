import XCTest
import Nocilla
@testable import MapboxGeocoder

let BogusToken = "pk.feedCafeDadeDeadBeef-BadeBede.FadeCafeDadeDeed-BadeBede"

class GeocoderTests: XCTestCase {
    override func setUp() {
        super.setUp()
        LSNocilla.sharedInstance().start()
    }
    
    override func tearDown() {
        LSNocilla.sharedInstance().clearStubs()
        LSNocilla.sharedInstance().stop()
        super.tearDown()
    }
    
    func testConfiguration() {
        let geocoder = Geocoder(accessToken: BogusToken)
        XCTAssertEqual(geocoder.accessToken, BogusToken)
        XCTAssertEqual(geocoder.apiEndpoint.absoluteString, "https://api.mapbox.com")
    }
}
