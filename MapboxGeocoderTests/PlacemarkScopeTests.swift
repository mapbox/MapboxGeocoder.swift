import XCTest
import MapboxGeocoder

class PlacemarkScopeTests: XCTestCase {
    func testContainment() {
        XCTAssert(PlacemarkScope.All.contains(.Country))
        XCTAssert(PlacemarkScope.All.contains(.Region))
        XCTAssert(PlacemarkScope.All.contains(.District))
        XCTAssert(PlacemarkScope.All.contains(.PostalCode))
        XCTAssert(PlacemarkScope.All.contains(.Place))
        XCTAssert(PlacemarkScope.All.contains(.Locality))
        XCTAssert(PlacemarkScope.All.contains(.Neighborhood))
        XCTAssert(PlacemarkScope.All.contains(.Address))
        XCTAssert(PlacemarkScope.PointOfInterest.contains(.Landmark))
        XCTAssert(PlacemarkScope.All.contains(.PointOfInterest))
        
        XCTAssertEqual(PlacemarkScope.All.description.componentsSeparatedByString(",").count, 9, "testContainment() needs to be updated.")
        
        XCTAssertLessThanOrEqual(PlacemarkScope.All.rawValue, PlacemarkScope.RawValue.max)
        XCTAssertLessThanOrEqual(PlacemarkScope(descriptions: PlacemarkScope.All.description.componentsSeparatedByString(","))?.rawValue ?? .max, PlacemarkScope.All.rawValue)
    }
    
    func testDescriptions() {
        XCTAssertNil(PlacemarkScope(descriptions: ["neighbourhood"]))
        XCTAssertEqual(PlacemarkScope(descriptions: PlacemarkScope.All.description.componentsSeparatedByString(","))?.description, PlacemarkScope.All.description)
        
        XCTAssertEqual(PlacemarkScope(descriptions: ["poi"]), .PointOfInterest)
        XCTAssertEqual(PlacemarkScope(descriptions: ["poi.landmark"]), .Landmark)
        XCTAssertEqual(PlacemarkScope(descriptions: ["poi", "poi.landmark"]), .PointOfInterest)
    }
}
