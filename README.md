MapboxGeocoder.swift
====================

[![Build Status](https://www.bitrise.io/app/6cae401ec4c1d406.svg?token=MJnXK0c2x2tmTnmHSPtcFA&branch=master)](https://www.bitrise.io/app/6cae401ec4c1d406)

[Mapbox Geocoder](https://www.mapbox.com/developers/api/geocoding/) in Swift. 

Import `MapboxGeocoder.framework` into your project, then use `MBGeocoder` as a drop-in replacement for Apple's `CLGeocoder`.

Includes example applications written in both Swift and Objective-C showing use of the framework (as well as a comparison of writing apps in either language). Before you can build either example project, you’ll need to save a plain text file named `.mapbox` to your home directory containing your [Mapbox access token](https://www.mapbox.com/studio/account/tokens/).

Head straight to [`MapboxGeocoder.swift`](https://github.com/incanus/GeocoderExample/blob/master/MBGeocoder/MapboxGeocoder.swift) if you want to see the guts of the library.

### Tests

To run the included unit tests, you need to use [CocoaPods](http://cocoapods.org) to install the dependencies. 

1. `pod install`
1. `open Geocoder Example.xcworkspace`
1. `Command+U` or `xcodebuild test`
