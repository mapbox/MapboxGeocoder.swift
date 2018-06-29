import XCTest
import OHHTTPStubs
import CoreLocation
@testable import MapboxGeocoder

class BatchForwardGeocodingTests: XCTestCase {
    override func tearDown() {
        OHHTTPStubs.removeAllStubs()
        super.tearDown()
    }
    
    func testValidForwardSingleBatchGeocode() {
        let expectation = self.expectation(description: "forward batch geocode with single query should return results")
        
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
        
            XCTAssertEqual(results.count, 5, "single forward batch geocode should have 5 results")
            
            XCTAssertEqual(attribution, "© 2017 Mapbox and its suppliers. All rights reserved. Use of this data is subject to the Mapbox Terms of Service. (https://www.mapbox.com/about/maps/)")
            
            expectation.fulfill()
        }
        XCTAssertNotNil(task)
        
        waitForExpectations(timeout: 1) { (error) in
            XCTAssertNil(error, "Error: \(error!)")
            XCTAssertEqual(task.state, URLSessionTask.State.completed)
        }
    }
    
    func testValidForwardMultipleBatchGeocode() {
        let expectation = self.expectation(description: "forward batch geocode with multiple queries should return results")
        
        _ = stub(condition: isHost("api.mapbox.com")
            && isPath("/geocoding/v5/mapbox.places-permanent/20001;20001;20001.json")
            && containsQueryParams(["country": "us", "access_token": BogusToken])) { _ in
                let path = Bundle(for: type(of: self)).path(forResource: "permanent_forward_multiple_valid", ofType: "json")
                return OHHTTPStubsResponse(fileAtPath: path!, statusCode: 200, headers: ["Content-Type": "application/vnd.geo+json"])
        }
        
        let geocoder = Geocoder(accessToken: BogusToken)
        
        let options = ForwardBatchGeocodeOptions(queries: ["20001", "20001", "20001"])
        options.allowedISOCountryCodes = ["US"]
        
        let task = geocoder.batchGeocode(options) { (placemarks, attribution, error) in
            
            let queries = placemarks!
            let attribution = attribution![0]
            
            XCTAssertEqual(queries.count, 3, "forward batch geocode should have 3 queries")
            
            for result in queries {
                XCTAssertEqual(result.count, 5, "each forward batch geocode query should have 5 found results")
                XCTAssertEqual(attribution, "© 2017 Mapbox and its suppliers. All rights reserved. Use of this data is subject to the Mapbox Terms of Service. (https://www.mapbox.com/about/maps/)")
            }
            
            let sampleResult = queries[0][0]
            
            XCTAssertEqual(sampleResult.qualifiedName, "Washington, District of Columbia 20001, United States")

            expectation.fulfill()
        }
        XCTAssertNotNil(task)
        
        waitForExpectations(timeout: 1) { (error) in
            XCTAssertNil(error, "Error: \(error!)")
            XCTAssertEqual(task.state, URLSessionTask.State.completed)
        }
    }
    
    func testInvalidForwardSingleBatchGeocode() {
        _ = stub(condition: isHost("api.mapbox.com")
            && isPath("/geocoding/v5/mapbox.places-permanent/%23M%40Pb0X.json")
            && containsQueryParams(["access_token": BogusToken])) { _ in
                let path = Bundle(for: type(of: self)).path(forResource: "permanent_forward_single_invalid", ofType: "json")
                return OHHTTPStubsResponse(fileAtPath: path!, statusCode: 200, headers: ["Content-Type": "application/vnd.geo+json"])
        }
        
        let expectation = self.expectation(description: "single forward batch geocode execute completion handler for invalid query")
        let geocoder = Geocoder(accessToken: BogusToken)
        let options = ForwardBatchGeocodeOptions(query: "#M@Pb0X")
        let task = geocoder.batchGeocode(options) { (placemarks, attribution, error) in
            
//            let results = placemarks![0]
//            let attribution = attribution![0]
//
//            XCTAssertEqual(results.count, 0, "single forward batch geocode should return no results for invalid query")
//
//            XCTAssertEqual(attribution, "© 2017 Mapbox and its suppliers. All rights reserved. Use of this data is subject to the Mapbox Terms of Service. (https://www.mapbox.com/about/maps/")
            
            expectation.fulfill()
        }
        XCTAssertNotNil(task)
        
        waitForExpectations(timeout: 1) { (error) in
            XCTAssertNil(error, "Error: \(error!)")
            XCTAssertEqual(task.state, URLSessionTask.State.completed)
        }
    }
    
    func testInvalidForwardMultipleBatchGeocode() {
        _ = stub(condition: isHost("api.mapbox.com")
            && isPath("/geocoding/v5/mapbox.places-permanent/%23M%40Pb0X%3B%20%24C00L!.json")
            && containsQueryParams(["access_token": BogusToken])) { _ in
                let path = Bundle(for: type(of: self)).path(forResource: "permanent_forward_multiple_invalid", ofType: "json")
                return OHHTTPStubsResponse(fileAtPath: path!, statusCode: 200, headers: ["Content-Type": "application/vnd.geo+json"])
        }
        
        let expectation = self.expectation(description: "multiple forward batch geocode execute completion handler for invalid query")
        let geocoder = Geocoder(accessToken: BogusToken)
        let options = ForwardBatchGeocodeOptions(queries: ["#M@Pb0X", "$C00L!"])
        let task = geocoder.batchGeocode(options) { (placemarks, attribution, error) in
            
            //            let results = placemarks![0]
            //            let attribution = attribution![0]
            //
            //            XCTAssertEqual(results.count, 0, "multiple forward batch geocode should return no results for invalid query")
            //
            //            XCTAssertEqual(attribution, "© 2017 Mapbox and its suppliers. All rights reserved. Use of this data is subject to the Mapbox Terms of Service. (https://www.mapbox.com/about/maps/")
            
            expectation.fulfill()
        }
        XCTAssertNotNil(task)
        
        waitForExpectations(timeout: 1) { (error) in
            XCTAssertNil(error, "Error: \(error!)")
            XCTAssertEqual(task.state, URLSessionTask.State.completed)
        }
    }
}
