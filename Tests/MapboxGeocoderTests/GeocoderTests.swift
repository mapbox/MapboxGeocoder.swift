import XCTest
import OHHTTPStubs
@testable import MapboxGeocoder

let BogusToken = "pk.feedCafeDadeDeadBeef-BadeBede.FadeCafeDadeDeed-BadeBede"

#if !SWIFT_PACKAGE
extension Bundle {
    static var module: Bundle {
        return Bundle(for: GeocoderTests.self)
    }
}
#endif

class GeocoderTests: XCTestCase {
    
    override func setUp() {
        // Make sure tests run in all time zones
        NSTimeZone.default = TimeZone(secondsFromGMT: 0)!
    }
    
    override func tearDown() {
        HTTPStubs.removeAllStubs()
        super.tearDown()
    }
    
    func testConfiguration() {
        let geocoder = Geocoder(accessToken: BogusToken)
        XCTAssertEqual(geocoder.accessToken, BogusToken)
        XCTAssertEqual(geocoder.apiEndpoint.absoluteString, "https://api.mapbox.com")
    }
    
    func testRateLimitErrorParsing() {
        let json = ["message" : "Hit rate limit"]
        
        let url = URL(string: "https://api.mapbox.com")!
        let headerFields = ["X-Rate-Limit-Interval" : "60", "X-Rate-Limit-Limit" : "600", "X-Rate-Limit-Reset" : "1479460584"]
        let response = HTTPURLResponse(url: url, statusCode: 429, httpVersion: nil, headerFields: headerFields)
        
        let error: NSError? = nil
        
        let resultError = Geocoder.descriptiveError(json, response: response, underlyingError: error)
        
        XCTAssertEqual(resultError.localizedFailureReason, "More than 600 requests have been made with this access token within a period of 1 minute.")
        XCTAssertEqual(resultError.localizedRecoverySuggestion, "Wait until November 18, 2016 at 9:16:24 AM GMT before retrying.")
    }
}
