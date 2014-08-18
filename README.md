GeocoderExample
===============

Simple Mapbox geocoder experimentation with Swift. 

The meat of what you want is in [`MapboxGeocoder.swift`](https://github.com/incanus/GeocoderExample/blob/master/MBGeocoder/MBGeocoder.swift). Import that file into your project and then use `MBGeocoder` as a drop-in replacement for Apple's `CLGeocoder` (at least for reverse geocoding... for now). 
