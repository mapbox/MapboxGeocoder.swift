import XCTest
import MapboxGeocoder

class PlacemarkScopeTests: XCTestCase {
    func testContainment() {
        
        
        XCTAssert(PlacemarkScope.all.contains(.country))
        XCTAssert(PlacemarkScope.all.contains(.region))
        XCTAssert(PlacemarkScope.all.contains(.district))
        XCTAssert(PlacemarkScope.all.contains(.postalCode))
        XCTAssert(PlacemarkScope.all.contains(.place))
        XCTAssert(PlacemarkScope.all.contains(.locality))
        XCTAssert(PlacemarkScope.all.contains(.neighborhood))
        XCTAssert(PlacemarkScope.all.contains(.address))
        XCTAssert(PlacemarkScope.pointOfInterest.contains(.landmark))
        XCTAssert(PlacemarkScope.all.contains(.pointOfInterest))
        
        XCTAssertEqual(PlacemarkScope.all.description.components(separatedBy: ",").count, 9, "testContainment() needs to be updated.")
        
        XCTAssertLessThanOrEqual(PlacemarkScope.all.rawValue, PlacemarkScope.RawValue.max)
        XCTAssertLessThanOrEqual(PlacemarkScope(descriptions: PlacemarkScope.all.description.components(separatedBy: ","))?.rawValue ?? .max, PlacemarkScope.all.rawValue)
    }
    
    func testDescriptions() {
        XCTAssertNil(PlacemarkScope(descriptions: ["neighbourhood"]))
        XCTAssertEqual(PlacemarkScope(descriptions: PlacemarkScope.all.description.components(separatedBy: ","))?.description, PlacemarkScope.all.description)
        
        XCTAssertEqual(PlacemarkScope(descriptions: ["poi"]), .pointOfInterest)
        XCTAssertEqual(PlacemarkScope(descriptions: ["poi.landmark"]), .landmark)
        XCTAssertEqual(PlacemarkScope(descriptions: ["poi", "poi.landmark"]), .pointOfInterest)
    }
}
