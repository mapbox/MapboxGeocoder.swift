# MapboxGeocoder

[📱&nbsp;![iOS Build Status](https://www.bitrise.io/app/6cae401ec4c1d406.svg?token=MJnXK0c2x2tmTnmHSPtcFA&branch=master)](https://www.bitrise.io/app/6cae401ec4c1d406) &nbsp;&nbsp;&nbsp;
[🖥💻&nbsp;![macOS Build Status](https://www.bitrise.io/app/8413a6e577d6aa9a.svg?token=N1agv0mw75SOE_SykliueQ&branch=master)](https://www.bitrise.io/app/8413a6e577d6aa9a) &nbsp;&nbsp;&nbsp;
[📺&nbsp;![tvOS Build Status](https://www.bitrise.io/app/0a8b56775b94f3e3.svg?token=UgLmHNS_ALJLjJN8ebd4hA&branch=master)](https://www.bitrise.io/app/0a8b56775b94f3e3) &nbsp;&nbsp;&nbsp;
[⌚️&nbsp;![watchOS Build Status](https://www.bitrise.io/app/b2a0878fa4bddab4.svg?token=4wjvK6K92dNK2bOCuV9-Yg&branch=master)](https://www.bitrise.io/app/b2a0878fa4bddab4) &nbsp;&nbsp;&nbsp;
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage) &nbsp;&nbsp;&nbsp;
[![CocoaPods](https://img.shields.io/cocoapods/v/MapboxGeocoder.swift.svg)](http://cocoadocs.org/docsets/MapboxGeocoder.swift/)

MapboxGeocoder.swift makes it easy to connect your iOS, macOS, tvOS, or watchOS application to the [Mapbox Geocoding API](https://www.mapbox.com/geocoding/). MapboxGeocoder.swift exposes the power of the [Carmen](https://github.com/mapbox/carmen) geocoder through a simple API similar to Core Location’s CLGeocoder.

MapboxGeocoder.swift pairs well with [MapboxDirections.swift](https://github.com/mapbox/MapboxDirections.swift), [MapboxStatic.swift](https://github.com/mapbox/MapboxStatic.swift), and the [Mapbox Maps SDK for iOS](https://www.mapbox.com/ios-sdk/) or the [Mapbox Maps SDK for macOS](https://github.com/mapbox/mapbox-gl-native/tree/master/platform/macos).

## Getting started

Specify the following dependency in your [Carthage](https://github.com/Carthage/Carthage/) Cartfile:

```cartfile
github "mapbox/MapboxGeocoder.swift" ~> 0.8
```

Or in your [CocoaPods](http://cocoapods.org/) Podfile:

```podspec
pod 'MapboxGeocoder.swift', '~> 0.8'
```

Then `import MapboxGeocoder` or `@import MapboxGeocoder;`.

For Objective-C targets, it may be necessary to enable the `ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES` build setting.

v0.6.3 is the last release of MapboxGeocoder.swift written in Swift 3.2. The `swift3.2` branch corresponds to this release, plus any critical bug fixes that have been applied since. All subsequent releases will be based on the `master` branch, which is written in Swift 4. The Swift examples below are written in Swift 4; see the `swift3.2` branch’s readme for Swift 3.2 examples.

This repository includes example applications written in both Swift and Objective-C showing use of the framework (as well as a comparison of writing apps in either language). More examples and detailed documentation are available in the [Mapbox API Documentation](https://www.mapbox.com/api-documentation/?language=Swift#geocoding).

## Usage

You will need a [Mapbox access token](https://www.mapbox.com/developers/api/#access-tokens) in order to use the API. If you’re already using the [Mapbox Maps SDK for iOS](https://www.mapbox.com/ios-sdk/) or [Mapbox Maps SDK for macOS](https://github.com/mapbox/mapbox-gl-native/tree/master/platform/macos), MapboxGeocoder.swift automatically recognizes your access token, as long as you’ve placed it in the `MGLMapboxAccessToken` key of your application’s Info.plist file.

The examples below are each provided in Swift (denoted with `main.swift`) and Objective-C (`main.m`). For further details, see the [MapboxGeocoder.swift API reference](http://cocoadocs.org/docsets/MapboxGeocoder.swift/).

### Basics

The main geocoder class is Geocoder in Swift or MBGeocoder in Objective-C. Create a geocoder object using your access token:

```swift
// main.swift
import MapboxGeocoder

let geocoder = Geocoder(accessToken: "<#your access token#>")
```

```objc
// main.m
@import MapboxGeocoder;

MBGeocoder *geocoder = [[MBGeocoder alloc] initWithAccessToken:@"<#your access token#>"];
```

Alternatively, you can place your access token in the `MGLMapboxAccessToken` key of your application’s Info.plist file, then use the shared geocoder object:

```swift
// main.swift
let geocoder = Geocoder.shared
```

```objc
// main.m
MBGeocoder *geocoder = [MBGeocoder sharedGeocoder];
```

With the geocoder in hand, construct a geocode options object and pass it into the `Geocoder.geocode(_:completionHandler:)` method.

### Forward geocoding

_Forward geocoding_ takes a human-readable query, such as a place name or address, and produces any number of geographic coordinates that correspond to that query. To perform forward geocoding, use ForwardGeocodeOptions in Swift or MBForwardGeocodeOptions in Objective-C.

```swift
// main.swift
#if !os(tvOS)
    import Contacts
#endif

let options = ForwardGeocodeOptions(query: "200 queen street")

// To refine the search, you can set various properties on the options object.
options.allowedISOCountryCodes = ["CA"]
options.focalLocation = CLLocation(latitude: 45.3, longitude: -66.1)
options.allowedScopes = [.address, .pointOfInterest]

let task = geocoder.geocode(options) { (placemarks, attribution, error) in
    guard let placemark = placemarks?.first else {
        return
    }
    
    print(placemark.name)
        // 200 Queen St
    print(placemark.qualifiedName)
        // 200 Queen St, Saint John, New Brunswick E2L 2X1, Canada
    
    let coordinate = placemark.location.coordinate
    print("\(coordinate.latitude), \(coordinate.longitude)")
        // 45.270093, -66.050985
    
    #if !os(tvOS)
        let formatter = CNPostalAddressFormatter()
        print(formatter.string(from: placemark.postalAddress!))
            // 200 Queen St
            // Saint John New Brunswick E2L 2X1
            // Canada
    #endif
}
```

```objc
// main.m
#if !TARGET_OS_TV
@import Contacts;
#endif

MBForwardGeocodeOptions *options = [[MBForwardGeocodeOptions alloc] initWithQuery:@"200 queen street"];

// To refine the search, you can set various properties on the options object.
options.allowedISOCountryCodes = @[@"CA"];
options.focalLocation = [[CLLocation alloc] initWithLatitude:45.3 longitude:-66.1];
options.allowedScopes = MBPlacemarkScopeAddress | MBPlacemarkScopePointOfInterest;

NSURLSessionDataTask *task = [geocoder geocodeWithOptions:options
                                        completionHandler:^(NSArray<MBGeocodedPlacemark *> * _Nullable placemarks,
                                                            NSString * _Nullable attribution,
                                                            NSError * _Nullable error) {
    MBPlacemark *placemark = placemarks[0];
    NSLog(@"%@", placemark.name);
        // 200 Queen St
    NSLog(@"%@", placemark.qualifiedName);
        // 200 Queen St, Saint John, New Brunswick E2L 2X1, Canada
    
    CLLocationCoordinate2D coordinate = placemark.location.coordinate;
    NSLog(@"%f, %f", coordinate.latitude, coordinate.longitude);
        // 45.270093, -66.050985
    
#if !TARGET_OS_TV
    CNPostalAddressFormatter *formatter = [[CNPostalAddressFormatter alloc] init];
    NSLog(@"%@", [formatter stringFromPostalAddress:placemark.postalAddress]);
        // 200 Queen St
        // Saint John New Brunswick E2L 2X1
        // Canada
#endif
}];
```

### Reverse geocoding

_Reverse geocoding_ takes a geographic coordinate and produces a hierarchy of places, often beginning with an address, that describes the coordinate’s location. To perform reverse geocoding, use ReverseGeocodeOptions in Swift or MBReverseGeocodeOptions in Objective-C.

```swift
// main.swift
let options = ReverseGeocodeOptions(coordinate: CLLocationCoordinate2D(latitude: 40.733, longitude: -73.989))
// Or perhaps: ReverseGeocodeOptions(location: locationManager.location)

let task = geocoder.geocode(options) { (placemarks, attribution, error) in
    guard let placemark = placemarks?.first else {
        return
    }
    
    print(placemark.imageName ?? "")
        // telephone
    print(placemark.genres?.joined(separator: ", ") ?? "")
        // computer, electronic
    print(placemark.administrativeRegion?.name ?? "")
        // New York
    print(placemark.administrativeRegion?.code ?? "")
        // US-NY
    print(placemark.place?.wikidataItemIdentifier ?? "")
        // Q60
}
```

```objc
// main.m
MBReverseGeocodeOptions *options = [[MBReverseGeocodeOptions alloc] initWithCoordinate: CLLocationCoordinate2DMake(40.733, -73.989)];
// Or perhaps: [[MBReverseGeocodeOptions alloc] initWithLocation:locationManager.location]

NSURLSessionDataTask *task = [geocoder geocodeWithOptions:options
                                        completionHandler:^(NSArray<MBGeocodedPlacemark *> * _Nullable placemarks,
                                                            NSString * _Nullable attribution,
                                                            NSError * _Nullable error) {
    MBPlacemark *placemark = placemarks[0];
    NSLog(@"%@", placemark.imageName);
        // telephone
    NSLog(@"%@", [placemark.genres componentsJoinedByString:@", "]);
        // computer, electronic
    NSLog(@"%@", placemark.administrativeRegion.name);
        // New York
    NSLog(@"%@", placemark.administrativeRegion.code);
        // US-NY
    NSLog(@"%@", placemark.place.wikidataItemIdentifier);
        // Q60
}];
```

### Batch geocoding

With _batch geocoding_, you can perform up to 50 distinct forward or reverse geocoding requests simultaneously and store the results in a private database. Create a ForwardBatchGeocodingOptions or ReverseBatchGeocodingOptions object in Swift, or an MBForwardBatchGeocodingOptions or MBReverseBatchGeocodingOptions object in Objective-C, and pass it into the `Geocoder.batchGeocode(_:completionHandler:)` method.

```swift
// main.swift
let options = ForwardBatchGeocodeOptions(queries: ["skyline chili", "gold star chili"])
options.focalLocation = locationManager.location
options.allowedScopes = .pointOfInterest

let task = geocoder.batchGeocode(options) { (placemarksByQuery, attributionsByQuery, error) in
    guard let placemarksByQuery = placemarksByQuery else {
        return
    }
    
    let nearestSkyline = placemarksByQuery[0][0].location
    let distanceToSkyline = nearestSkyline.distance(from: locationManager.location)
    let nearestGoldStar = placemarksByQuery[1][0].location
    let distanceToGoldStar = nearestGoldStar.distance(from: locationManager.location)

    let distance = LengthFormatter().string(fromMeters: min(distanceToSkyline, distanceToGoldStar))
    print("Found a chili parlor \(distance) away.")
}
```

```objc
// main.m
MBForwardBatchGeocodeOptions *options = [[MBForwardBatchGeocodeOptions alloc] initWithQueries:@[@"skyline chili", @"gold star chili"]];
options.focalLocation = locationManager.location;
options.allowedScopes = MBPlacemarkScopePointOfInterest;

NSURLSessionDataTask *task = [geocoder batchGeocodeWithOptions:options
                                             completionHandler:^(NSArray<NSArray<MBGeocodedPlacemark *> *> * _Nullable placemarksByQuery,
                                                                 NSArray<NSString *> * _Nullable attributionsByQuery,
                                                                 NSError * _Nullable error) {
    if (!placemarksByQuery) {
        return;
    }
    
    MBPlacemark *nearestSkyline = placemarksByQuery[0][0].location;
    CLLocationDistance distanceToSkyline = [nearestSkyline distanceFromLocation:locationManager.location];
    MBPlacemark *nearestGoldStar = placemarksByQuery[1][0].location;
    CLLocationDistance distanceToGoldStar = [nearestGoldStar distanceFromLocation:locationManager.location];

    NSString *distance = [NSLengthFormatter stringFromMeters:MIN(distanceToSkyline, distanceToGoldStar)];
    NSLog(@"Found a chili parlor %@ away.", distance);
}];
```

Batch geocoding is available to Mapbox enterprise accounts. See the [Mapbox Geocoding](https://www.mapbox.com/geocoding/) website for more information.

## Tests

To run the included unit tests, you need to use [Carthage](https://github.com/Carthage/Carthage/) 0.19 or above to install the dependencies. 

1. `carthage bootstrap`
1. `open MapboxGeocoder.xcodeproj`
1. Switch to the “MapboxGeocoder iOS” scheme and go to Product ‣ Test.
