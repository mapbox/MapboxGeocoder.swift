MapboxGeocoder.swift
====================

[![Build Status](https://www.bitrise.io/app/6cae401ec4c1d406.svg?token=MJnXK0c2x2tmTnmHSPtcFA&branch=master)](https://www.bitrise.io/app/6cae401ec4c1d406)

MapboxGeocoder.swift makes it easy to connect your iOS or OS X application to the [Mapbox Geocoding API](https://www.mapbox.com/api-documentation/#geocoding). MapboxGeocoder.swift combines the power of the [Carmen](https://github.com/mapbox/carmen) geocoder with the simplicity of Core Location’s CLGeocoder API.

MapboxGeocoder.swift pairs well with [MapboxDirections.swift](https://github.com/mapbox/MapboxDirections.swift), [MapboxStatic.swift](https://github.com/mapbox/MapboxStatic.swift), and the [Mapbox iOS SDK](https://www.mapbox.com/ios-sdk/) or [OS X SDK](https://github.com/mapbox/mapbox-gl-native/tree/master/platform/osx).

### Getting started

Import `MapboxGeocoder.framework` into your project, then use `MBGeocoder` as a drop-in replacement for Apple's `CLGeocoder`. Alternatively, specify the following dependencies in your [CocoaPods](http://cocoapods.org/) Podfile:

```podspec
pod 'NBNRequestKit', :git => 'https://github.com/1ec5/RequestKit.git', :branch => 'mapbox-podspec' # temporarily until nerdishbynature/RequestKit#14 is merged
pod 'MapboxGeocoder.swift', :git => 'https://github.com/mapbox/MapboxGeocoder.swift.git', :tag => 'v0.4.2'
```

Includes example applications written in both Swift and Objective-C showing use of the framework (as well as a comparison of writing apps in either language). 

### Tests

To run the included unit tests, you need to use [CocoaPods](http://cocoapods.org) to install the dependencies. 

1. `pod install`
1. `open MapboxGeocoder.xcworkspace`
1. `Command+U` or `xcodebuild test`
