import XCTest
import OHHTTPStubs
#if SWIFT_PACKAGE
import OHHTTPStubsSwift
#endif
import CoreLocation
@testable import MapboxGeocoder

class BatchGeocodingTests: XCTestCase {
    override func tearDown() {
        HTTPStubs.removeAllStubs()
        super.tearDown()
    }
    
    /**
     Forward batch geocoding tests
     */
    
    func testValidForwardSingleBatchGeocode() {
        let expectation = self.expectation(description: "forward batch geocode with single query should return results")
        
        _ = stub(condition: isHost("api.mapbox.com")
            && isPath("/geocoding/v5/mapbox.places-permanent/85+2nd+st+san+francisco.json")
            && containsQueryParams(["country": "ca", "access_token": BogusToken])) { _ in
                let path = Bundle.module.path(forResource: "permanent_forward_single_valid", ofType: "json")
                return HTTPStubsResponse(fileAtPath: path!, statusCode: 200, headers: ["Content-Type": "application/vnd.geo+json"])
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
                let path = Bundle.module.path(forResource: "permanent_forward_multiple_valid", ofType: "json")
                return HTTPStubsResponse(fileAtPath: path!, statusCode: 200, headers: ["Content-Type": "application/vnd.geo+json"])
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
    
    func testNoResultsForwardSingleBatchGeocode() {
        _ = stub(condition: isHost("api.mapbox.com")
            && isPath("/geocoding/v5/mapbox.places-permanent/#M@Pb0X.json")
            && containsQueryParams(["access_token": BogusToken])) { _ in
                let path = Bundle.module.path(forResource: "permanent_forward_single_no_results", ofType: "json")
                return HTTPStubsResponse(fileAtPath: path!, statusCode: 200, headers: ["Content-Type": "application/vnd.geo+json"])
        }
        
        let expectation = self.expectation(description: "single forward batch geocode should not return results for an invalid location")
        let geocoder = Geocoder(accessToken: BogusToken)
        let options = ForwardBatchGeocodeOptions(query: "#M@Pb0X")
        let task = geocoder.batchGeocode(options) { (placemarks, attribution, error) in
            
            let results = placemarks![0]
            let attribution = attribution![0]

            XCTAssertEqual(results.count, 0, "single forward batch geocode should not return results for an invalid location")
            XCTAssertEqual(attribution, "© 2017 Mapbox and its suppliers. All rights reserved. Use of this data is subject to the Mapbox Terms of Service. (https://www.mapbox.com/about/maps/)")
            
            expectation.fulfill()
        }
        XCTAssertNotNil(task)
        
        waitForExpectations(timeout: 1) { (error) in
            XCTAssertNil(error, "Error: \(error!)")
            XCTAssertEqual(task.state, URLSessionTask.State.completed)
        }
    }
    
    func testNoResultsForwardMultipleBatchGeocode() {
        _ = stub(condition: isHost("api.mapbox.com")
            && isPath("/geocoding/v5/mapbox.places-permanent/#M@Pb0X;$C00L!.json")
            && containsQueryParams(["access_token": BogusToken])) { _ in
                let path = Bundle.module.path(forResource: "permanent_forward_multiple_no_results", ofType: "json")
                return HTTPStubsResponse(fileAtPath: path!, statusCode: 200, headers: ["Content-Type": "application/vnd.geo+json"])
        }
        
        let expectation = self.expectation(description: "multiple forward batch geocode should not return results for an invalid locations")
        let geocoder = Geocoder(accessToken: BogusToken)
        let options = ForwardBatchGeocodeOptions(queries: ["#M@Pb0X", "$C00L!"])
        let task = geocoder.batchGeocode(options) { (placemarks, attribution, error) in
            
            for result in placemarks! {
                XCTAssertTrue(result.isEmpty, "each individual geocode request should not return results")
            }
            
          XCTAssertEqual(attribution![0], "© 2017 Mapbox and its suppliers. All rights reserved. Use of this data is subject to the Mapbox Terms of Service. (https://www.mapbox.com/about/maps/)")
            
            expectation.fulfill()
        }
        XCTAssertNotNil(task)
        
        waitForExpectations(timeout: 1) { (error) in
            XCTAssertNil(error, "Error: \(error!)")
            XCTAssertEqual(task.state, URLSessionTask.State.completed)
        }
    }
    
    /**
     Reverse batch geocoding tests
     */
    
    func testValidReverseSingleBatchGeocode() {
        let expectation = self.expectation(description: "reverse batch geocode with single query should return results")
        
        _ = stub(condition: isHost("api.mapbox.com")
            && isPath("/geocoding/v5/mapbox.places-permanent/-77.01073,38.88887.json")
            && containsQueryParams(["access_token": BogusToken])) { _ in
                let path = Bundle.module.path(forResource: "permanent_reverse_single_valid", ofType: "json")
                return HTTPStubsResponse(fileAtPath: path!, statusCode: 200, headers: ["Content-Type": "application/vnd.geo+json"])
        }
        
        let geocoder = Geocoder(accessToken: BogusToken)
        
        let options = ReverseBatchGeocodeOptions(coordinate: CLLocationCoordinate2DMake(38.88887, -77.01073))
        
        let task = geocoder.batchGeocode(options) { (placemarks, attribution, error) in
            let results = placemarks![0]
            let attribution = attribution![0]
            
            XCTAssertEqual(results.count, 6, "single forward batch geocode should have 6 results")
            
            XCTAssertEqual(attribution, "© 2017 Mapbox and its suppliers. All rights reserved. Use of this data is subject to the Mapbox Terms of Service. (https://www.mapbox.com/about/maps/)")
            
            expectation.fulfill()
        }
        XCTAssertNotNil(task)
        
        waitForExpectations(timeout: 1) { (error) in
            XCTAssertNil(error, "Error: \(error!)")
            XCTAssertEqual(task.state, URLSessionTask.State.completed)
        }
    }
    
    func testValidReverseMultipleBatchGeocode() {
        let expectation = self.expectation(description: "forward batch geocode with multiple queries should return results")
        
        _ = stub(condition: isHost("api.mapbox.com")
            && isPath("/geocoding/v5/mapbox.places-permanent/-77.01073,38.88887;-77.01073,38.88887;-77.01073,38.88887.json")
            && containsQueryParams(["access_token": BogusToken])) { _ in
                let path = Bundle.module.path(forResource: "permanent_reverse_multiple_valid", ofType: "json")
                return HTTPStubsResponse(fileAtPath: path!, statusCode: 200, headers: ["Content-Type": "application/vnd.geo+json"])
        }
        
        let geocoder = Geocoder(accessToken: BogusToken)
        
        let queries = [
            CLLocationCoordinate2DMake(38.88887, -77.01073),
            CLLocationCoordinate2DMake(38.88887, -77.01073),
            CLLocationCoordinate2DMake(38.88887, -77.01073)
        ]
        
        let options = ReverseBatchGeocodeOptions(coordinates: queries)

        let task = geocoder.batchGeocode(options) { (placemarks, attribution, error) in
            
            let queries = placemarks!
            let attribution = attribution![0]
            
            XCTAssertEqual(queries.count, 3, "forward batch geocode should have 3 queries")
            
            for result in queries {
                XCTAssertEqual(result.count, 6, "each forward batch geocode query should have 6 found results")
                XCTAssertEqual(attribution, "© 2017 Mapbox and its suppliers. All rights reserved. Use of this data is subject to the Mapbox Terms of Service. (https://www.mapbox.com/about/maps/)")
            }
            
            let sampleResult = queries[0][0]
            
            XCTAssertEqual(sampleResult.qualifiedName, "South Capitol Circle Southwest, Washington, District of Columbia 20002, United States")
            
            expectation.fulfill()
        }
        XCTAssertNotNil(task)
        
        waitForExpectations(timeout: 1) { (error) in
            XCTAssertNil(error, "Error: \(error!)")
            XCTAssertEqual(task.state, URLSessionTask.State.completed)
        }
    }
    
    func testNoResultsReverseSingleBatchGeocode() {
        _ = stub(condition: isHost("api.mapbox.com")
            
            && isPath("/geocoding/v5/mapbox.places-permanent/100.00000,100.00000.json")
            && containsQueryParams(["access_token": BogusToken])) { _ in
                let path = Bundle.module.path(forResource: "permanent_reverse_single_no_results", ofType: "json")
                return HTTPStubsResponse(fileAtPath: path!, statusCode: 200, headers: ["Content-Type": "application/vnd.geo+json"])
        }
        
        let expectation = self.expectation(description: "single reverse batch geocode should not return results for an invalid location")
        let geocoder = Geocoder(accessToken: BogusToken)
        let options = ReverseBatchGeocodeOptions(coordinate: CLLocationCoordinate2DMake(100, 100))
        let task = geocoder.batchGeocode(options) { (placemarks, attribution, error) in
            
            let results = placemarks![0]
            let attribution = attribution![0]
            
            XCTAssertEqual(results.count, 0, "single reverse batch geocode should not return results for an invalid location")
            XCTAssertEqual(attribution, "© 2017 Mapbox and its suppliers. All rights reserved. Use of this data is subject to the Mapbox Terms of Service. (https://www.mapbox.com/about/maps/)")
            
            expectation.fulfill()
        }
        XCTAssertNotNil(task)
        
        waitForExpectations(timeout: 1) { (error) in
            XCTAssertNil(error, "Error: \(error!)")
            XCTAssertEqual(task.state, URLSessionTask.State.completed)
        }
    }
    
    func testNoResultsReverseMultipleBatchGeocode() {
        let expectation = self.expectation(description: "multiple reverse batch geocodes should not return results for invalid locations")
        
        _ = stub(condition: isHost("api.mapbox.com")
            && isPath("/geocoding/v5/mapbox.places-permanent/100.00000,100.00000;100.00000,100.00000;100.00000,100.00000.json")
            && containsQueryParams(["access_token": BogusToken])) { _ in
                let path = Bundle.module.path(forResource: "permanent_reverse_multiple_no_results", ofType: "json")
                return HTTPStubsResponse(fileAtPath: path!, statusCode: 200, headers: ["Content-Type": "application/vnd.geo+json"])
        }
        
        let geocoder = Geocoder(accessToken: BogusToken)
        
        let queries = [
            CLLocationCoordinate2DMake(100, 100),
            CLLocationCoordinate2DMake(100, 100),
            CLLocationCoordinate2DMake(100, 100)
        ]
        
        let options = ReverseBatchGeocodeOptions(coordinates: queries)
        
        let task = geocoder.batchGeocode(options) { (placemarks, attribution, error) in
            
            let queries = placemarks!
            let attribution = attribution![0]
            
            XCTAssertEqual(queries.count, 3, "reverse batch geocode should have 3 queries")
            
            for result in queries {
                XCTAssertEqual(result.count, 0, "each reverse batch geocode query should have 0 found results")
                XCTAssertEqual(attribution, "© 2017 Mapbox and its suppliers. All rights reserved. Use of this data is subject to the Mapbox Terms of Service. (https://www.mapbox.com/about/maps/)")
            }
            
            expectation.fulfill()
        }
        XCTAssertNotNil(task)
        
        waitForExpectations(timeout: 1) { (error) in
            XCTAssertNil(error, "Error: \(error!)")
            XCTAssertEqual(task.state, URLSessionTask.State.completed)
        }
    }
    
    /**
     General batch geocoding tests - invalid queries, invalid tokens, token scope checking, etc.
     */
    
    func testInvalidBatchGeocode() {
        _ = stub(condition: isHost("api.mapbox.com")
            && isPath("/geocoding/v5/mapbox.places-permanent////.json")
            && containsQueryParams(["access_token": BogusToken])) { _ in
                let path = Bundle.module.path(forResource: "permanent_invalid", ofType: "json")
                return HTTPStubsResponse(fileAtPath: path!, statusCode: 200, headers: ["Content-Type": "application/vnd.geo+json"])
        }
        
        let expectation = self.expectation(description: "invalid batch geocoding query should not return results")
        let geocoder = Geocoder(accessToken: BogusToken)
        let options = ForwardBatchGeocodeOptions(query: "///")
        let task = geocoder.batchGeocode(options) { (placemarks, attribution, error) in
            
            XCTAssertEqual(error!.localizedFailureReason, "Not Found")
            
            expectation.fulfill()
        }
        XCTAssertNotNil(task)
        
        waitForExpectations(timeout: 1) { (error) in
            XCTAssertNil(error, "Error: \(error!)")
            XCTAssertEqual(task.state, URLSessionTask.State.completed)
        }
    }
    
    func testInvalidTokenForBatchGeocode() {
        let invalidToken = "xyz"
        
        _ = stub(condition: isHost("api.mapbox.com")
            && isPath("/geocoding/v5/mapbox.places-permanent/85+2nd+st+san+francisco.json")
            && containsQueryParams(["access_token": invalidToken])) { _ in
                let path = Bundle.module.path(forResource: "permanent_invalid_token", ofType: "json")
                return HTTPStubsResponse(fileAtPath: path!, statusCode: 200, headers: ["Content-Type": "application/vnd.geo+json"])
        }
        
        let expectation = self.expectation(description: "invalid token use in batch geocoding query should return an error")
        let geocoder = Geocoder(accessToken: invalidToken)
        let options = ForwardBatchGeocodeOptions(query: "85 2nd st san francisco")
        let task = geocoder.batchGeocode(options) { (placemarks, attribution, error) in
            
            XCTAssertEqual(error!.localizedFailureReason, "Not Authorized - Invalid Token")
            
            expectation.fulfill()
        }
        XCTAssertNotNil(task)
        
        waitForExpectations(timeout: 1) { (error) in
            XCTAssertNil(error, "Error: \(error!)")
            XCTAssertEqual(task.state, URLSessionTask.State.completed)
        }
    }
    
    func testInvalidTokenScopeForBatchGeocoding() {
        let incorrectTokenScope = "pk.eyJ1IjoibWFwYm94IiwiYSI6ImNpejY4M29iazA2Z2gycXA4N2pmbDZmangifQ.-g_vE53SD2WrJ6tFX7QHmA"
        
        _ = stub(condition: isHost("api.mapbox.com")
            && isPath("/geocoding/v5/mapbox.places-permanent/85+2nd+st+san+francisco.json")
            && containsQueryParams(["access_token": incorrectTokenScope])) { _ in
                let path = Bundle.module.path(forResource: "permanent_invalid_token_scope", ofType: "json")
                return HTTPStubsResponse(fileAtPath: path!, statusCode: 200, headers: ["Content-Type": "application/vnd.geo+json"])
        }
        
        let expectation = self.expectation(description: "invalid token use in batch geocoding query should return an error")
        let geocoder = Geocoder(accessToken: incorrectTokenScope)
        let options = ForwardBatchGeocodeOptions(query: "85 2nd st san francisco")
        let task = geocoder.batchGeocode(options) { (placemarks, attribution, error) in
            
            XCTAssertEqual(error!.localizedFailureReason, "Permanent geocodes are not enabled for this account. Contact support@mapbox.com to enable this feature.")
            
            expectation.fulfill()
        }
        XCTAssertNotNil(task)
        
        waitForExpectations(timeout: 1) { (error) in
            XCTAssertNil(error, "Error: \(error!)")
            XCTAssertEqual(task.state, URLSessionTask.State.completed)
        }
    }
}
