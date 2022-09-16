# MapboxGeocoder

[![CircleCI](https://circleci.com/gh/mapbox/MapboxGeocoder.swift.svg?style=svg)](https://circleci.com/gh/mapbox/MapboxGeocoder.swift)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![SPM compatible](https://img.shields.io/badge/SPM-compatible-4BC51D.svg?style=flat)](https://swift.org/package-manager/)
[![CocoaPods](https://img.shields.io/cocoapods/v/MapboxGeocoder.swift.svg)](http://cocoapods.org/pods/MapboxGeocoder.swift/)

MapboxGeocoder.swift makes it easy to connect your iOS, macOS, tvOS, or watchOS application to the [Mapbox Geocoding API](https://docs.mapbox.com/api/search/geocoding/). MapboxGeocoder.swift exposes the power of the [Carmen](https://github.com/mapbox/carmen) geocoder through a simple API similar to Core Location’s CLGeocoder.

Note that use of the Geocoding API via MapboxGeocoder.swift is billed by API requests. For more information, see the [Geocoding API pricing documentation](https://docs.mapbox.com/api/search/geocoding/#geocoding-api-pricing).

MapboxGeocoder.swift pairs well with [Mapbox Directions for Swift](https://github.com/mapbox/mapbox-directions-swift/), [MapboxStatic.swift](https://github.com/mapbox/MapboxStatic.swift), and the [Mapbox Maps SDK for iOS](https://docs.mapbox.com/ios/maps/) or the [Mapbox Maps SDK for macOS](https://mapbox.github.io/mapbox-gl-native/macos/).

## Getting started

Specify the following dependency in your [Carthage](https://github.com/Carthage/Carthage/) Cartfile:

```cartfile
github "mapbox/MapboxGeocoder.swift" ~> 0.15
```

Or in your [CocoaPods](http://cocoapods.org/) Podfile:

```podspec
pod 'MapboxGeocoder.swift', '~> 0.15'
```

Or in your [Swift Package Manager](https://swift.org/package-manager/) Package.swift:

```swift
.package(url: "https://github.com/mapbox/MapboxGeocoder.swift.git", from: "0.15.0")
```

Then `import MapboxGeocoder` or `@import MapboxGeocoder;`.

For Objective-C targets, it may be necessary to enable the `ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES` build setting.

This repository includes example applications written in both Swift and Objective-C showing use of the framework (as well as a comparison of writing apps in either language). The [Mapbox API Documentation](https://docs.mapbox.com/api/search/geocoding/) explains the underlying HTTP request and response format, as well as [relevant limits](https://docs.mapbox.com/api/search/#geocoding-restrictions-and-limits) that also apply when using this library.

## System requirements

* One of the following package managers:
   * CocoaPods 1.10 or above
   * Carthage 0.38 or above
   * Swift Package Manager 5.3 or above
* Xcode 12 or above
* One of the following operating systems:
   * iOS 12.0 or above
   * macOS 10.14 or above
   * tvOS 12.0 or above
   * watchOS 5.0 or above

## Usage

You will need a [Mapbox access token](https://docs.mapbox.com/api/overview/#access-tokens-and-token-scopes) in order to use the API. If you’re already using the [Mapbox Maps SDK for iOS](https://docs.mapbox.com/ios/maps/) or [Mapbox Maps SDK for macOS](https://mapbox.github.io/mapbox-gl-native/macos/), MapboxGeocoder.swift automatically recognizes your access token, as long as you’ve placed it in the `MGLMapboxAccessToken` key of your application’s Info.plist file.

The examples below are each provided in Swift (denoted with `main.swift`) and Objective-C (`main.m`). For further details about each class and method, use the Quick Help feature inside Xcode.

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
#if canImport(Contacts)
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

    #if canImport(Contacts)
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

Batch geocoding is available to Mapbox enterprise accounts. See the [Mapbox Geocoding](https://docs.mapbox.com/api/search/geocoding/) website for more information.

## Tests

To run the included unit tests, you need to use [Carthage](https://github.com/Carthage/Carthage/) 0.19 or above to install the dependencies.

1. `carthage bootstrap`
1. `open MapboxGeocoder.xcodeproj`
1. Switch to the “MapboxGeocoder iOS” scheme and go to Product ‣ Test.

Alternatively, open Package.swift in Xcode and go to Product ‣ Test, or run `swift test` on the command line.
