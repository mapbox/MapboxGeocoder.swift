import XCTest
import OHHTTPStubs
import CoreLocation
@testable import MapboxGeocoder

class BatchForwardGeocodingTests: XCTestCase {
    override func tearDown() {
        OHHTTPStubs.removeAllStubs()
        super.tearDown()
    }
    
    func testValidForwardGeocode() {
        let expectation = self.expectation(description: "forward batch geocode should return results")
        
        _ = stub(condition: isHost("api.mapbox.com")
            && isPath("/geocoding/v5/mapbox.places-permanent/85+2nd+st+san+francisco.json")
            && containsQueryParams(["country": "ca", "access_token": BogusToken])) { _ in
                let path = Bundle(for: type(of: self)).path(forResource: "permanent_forward_single_valid", ofType: "json")
                return OHHTTPStubsResponse(fileAtPath: path!, statusCode: 200, headers: ["Content-Type": "application/vnd.geo+json"])
        }
        
        let geocoder = Geocoder(accessToken: BogusToken)

        let options = ForwardBatchGeocodeOptions(query: "85 2nd st san francisco")
        options.allowedISOCountryCodes = ["CA"]

        let task = geocoder.batchGeocode(options) { (placemarks, attribution, error) in
            let results = placemarks![0]
            let attribution = attribution![0]
        
            XCTAssertEqual(results.count, 5, "forward batch geocode should have 5 results")
            
            XCTAssertEqual(attribution, "NOTICE: © 2017 Mapbox and its suppliers. All rights reserved. Use of this data is subject to the Mapbox Terms of Service (https://www.mapbox.com/about/maps/). This response and the information it contains may not be retained.")
            
            expectation.fulfill()
        }
        XCTAssertNotNil(task)
        
        waitForExpectations(timeout: 1) { (error) in
            XCTAssertNil(error, "Error: \(error!)")
            XCTAssertEqual(task.state, URLSessionTask.State.completed)
        }
    }
}
