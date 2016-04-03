import XCTest
import Nocilla
@testable import MapboxGeocoder

let BogusToken = "pk.feedCafeDadeDeadBeef-BadeBede.FadeCafeDadeDeed-BadeBede"

class MBGeocoderConfigurationTests: XCTestCase {
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
        let subject = MBGeocoderConfiguration(BogusToken)
        XCTAssertEqual(subject.accessToken, BogusToken)
        XCTAssertEqual(subject.apiEndpoint, "https://api.mapbox.com")
    }
}
