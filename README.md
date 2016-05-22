# MapboxGeocoder.swift

[![Build Status](https://www.bitrise.io/app/6cae401ec4c1d406.svg?token=MJnXK0c2x2tmTnmHSPtcFA&branch=master)](https://www.bitrise.io/app/6cae401ec4c1d406)

MapboxGeocoder.swift makes it easy to connect your iOS or OS X application to the [Mapbox Geocoding API](https://www.mapbox.com/api-documentation/?language=Swift#geocoding). MapboxGeocoder.swift exposes the power of the [Carmen](https://github.com/mapbox/carmen) geocoder through a simple API similar to Core Location’s CLGeocoder.

MapboxGeocoder.swift pairs well with [MapboxDirections.swift](https://github.com/mapbox/MapboxDirections.swift), [MapboxStatic.swift](https://github.com/mapbox/MapboxStatic.swift), and the [Mapbox iOS SDK](https://www.mapbox.com/ios-sdk/) or [OS X SDK](https://github.com/mapbox/mapbox-gl-native/tree/master/platform/osx).

## Getting started

Import `MapboxGeocoder.framework` into your project, then `import MapboxGeocoder` or `@import MapboxGeocoder;`. Alternatively, specify the following dependencies in your [CocoaPods](http://cocoapods.org/) Podfile:

```podspec
pod 'MapboxGeocoder.swift', :git => 'https://github.com/mapbox/MapboxGeocoder.swift.git', :tag => 'master'
```

This repository includes example applications written in both Swift and Objective-C showing use of the framework (as well as a comparison of writing apps in either language). More examples are available in the [Mapbox API Documentation](https://www.mapbox.com/api-documentation/?language=Swift#geocoding).

## Usage

You will need a [Mapbox access token](https://www.mapbox.com/developers/api/#access-tokens) in order to use the API. If you’re already using the [Mapbox iOS SDK](https://www.mapbox.com/ios-sdk/) or [OS X SDK](https://github.com/mapbox/mapbox-gl-native/tree/master/platform/osx), MapboxGeocoder.swift automatically recognizes your access token, as long as you’ve placed it in the `MGLMapboxAccessToken` key of your application’s Info.plist file.

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
let geocoder = Geocoder.sharedGeocoder
```

```objc
// main.m
MBGeocoder *geocoder = [MBGeocoder sharedGeocoder];
```

With the geocoder in hand, construct a geocode options object and pass it into the `Geocoder.geocode(options:completionHandler:)` method.

### Forward geocoding

_Forward geocoding_ takes a human-readable query, such as a place name or address, and produces any number of geographic coordinates that correspond to that query. To perform forward geocoding, use ForwardGeocodeOptions in Swift or MBForwardGeocodeOptions in Objective-C.

```swift
// main.swift
import Contacts

let options = ForwardGeocodeOptions(query: "200 queen street")

// To refine the search, you can set various properties on the options object.
options.allowedISOCountryCodes = ["CA"]
options.focalLocation = CLLocation(latitude: 45.3, longitude: -66.1)
options.allowedScopes = [.Address, .PointOfInterest]

let task = geocoder.geocode(options: options) { (placemarks, attribution, error) in
    let placemark = placemarks[0]
    print(placemark.name)
        // 200 Queen St
    print(placemark.qualifiedName)
        // 200 Queen St, Saint John, New Brunswick E2L 2X1, Canada
    
    let coordinate = placemark.location!.coordinate
    print("\(coordinate.latitude), \(coordinate.longitude)")
        // 45.270093, -66.050985
    
    let formatter = CNPostalAddressFormatter()
    print(formatter.stringFromPostalAddress(placemark.postalAddress))
        // 200 Queen St
        // Saint John New Brunswick E2L 2X1
        // Canada
}
```

```objc
// main.m
@import Contacts;

MBForwardGeocodeOptions *options = [[MBForwardGeocodeOptions alloc] initWithQuery:@"200 queen street"];

// To refine the search, you can set various properties on the options object.
options.allowedISOCountryCodes = @[@"CA"];
options.focalLocation = [[CLLocation alloc] initWithLatitude:45.3 longitude:-66.1];
options.allowedScopes = MBPlacemarkScopeAddress | MBPlacemarkScopePointOfInterest;

NSURLSessionDataTask *task = [geocoder geocodeWithOptions:options
                                        completionHandler:^(NSArray<MBPlacemark *> * _Nullable placemarks,
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
    
    CNPostalAddressFormatter *formatter = [[CNPostalAddressFormatter alloc] init];
    NSLog(@"%@", [formatter stringFromPostalAddress:placemark.postalAddress]);
        // 200 Queen St
        // Saint John New Brunswick E2L 2X1
        // Canada
}];
```

### Reverse geocoding

_Reverse geocoding_ takes a geographic coordinate and produces a hierarchy of places, often beginning with an address, that describes the coordinate’s location. To perform reverse geocoding, use ReverseGeocodeOptions in Swift or MBReverseGeocodeOptions in Objective-C.

```swift
// main.swift
let options = ReverseGeocodeOptions(coordinate: CLLocationCoordinate2D(latitude: 40.733, longitude: -73.989))
// Or perhaps: ReverseGeocodeOptions(location: locationManager.location)

let task = geocoder.geocode(options: options) { (placemarks, attribution, error) in
    let placemark = placemarks[0]
    print(placemark.imageName)
        // telephone
    print(placemark.genres?.joinWithSeparator(", "))
        // computer, electronic
    print(placemark.region?.name)
        // New York
    print(placemark.region?.code)
        // US-NY
    print(placemark.place?.wikidataItemIdentifier)
        // Q60
}
```

```objc
// main.m
MBReverseGeocodeOptions *options = [[MBReverseGeocodeOptions alloc] initWithCoordinate: CLLocationCoordinate2DMake(40.733, -73.989)];
// Or perhaps: [[MBReverseGeocodeOptions alloc] initWithLocation:locationManager.location]

NSURLSessionDataTask *task = [geocoder geocodeWithOptions:options
                                        completionHandler:^(NSArray<MBPlacemark *> * _Nullable placemarks,
                                                            NSString * _Nullable attribution,
                                                            NSError * _Nullable error) {
    MBPlacemark *placemark = placemarks[0];
    NSLog(@"%@", placemark.imageName);
        // telephone
    NSLog(@"%@", [placemark.genres componentsJoinedByString:@", "]);
        // computer, electronic
    NSLog(@"%@", placemark.region.name);
        // New York
    NSLog(@"%@", placemark.region.code);
        // US-NY
    NSLog(@"%@", placemark.place.wikidataItemIdentifier);
        // Q60
}];
```

## Tests

To run the included unit tests, you need to use [CocoaPods](http://cocoapods.org) to install the dependencies. 

1. `pod install`
1. `open MapboxGeocoder.xcworkspace`
1. Switch to the MapboxGeocoder scheme and go to Product ‣ Test.
