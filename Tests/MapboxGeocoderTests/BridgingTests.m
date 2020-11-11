#import <XCTest/XCTest.h>
@import MapboxGeocoder;

@interface BridgingTests : XCTestCase
@end

@implementation BridgingTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)testReverseGeocodingOptions {
    XCTAssertNotNil([[MBReverseGeocodeOptions alloc] initWithCoordinate:CLLocationCoordinate2DMake(0, 0)]);
}

- (void)testForwardGeocodingOptions {
    XCTAssertNotNil([[MBForwardGeocodeOptions alloc] initWithQuery:@"Golden Gate Bridge"]);
}

- (void)testMBGeocoder {
    XCTAssertNotNil([[MBGeocoder alloc] initWithAccessToken:@"pk.foo"]);
}

- (void)testMBPlacemark {
    XCTAssertNotNil([MBPlacemark alloc]);
}

@end
