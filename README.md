GeocoderExample
===============

Simple Mapbox geocoder experimentation with Swift. 

The meat of what you want is in [`MapboxGeocoder.swift`](https://github.com/incanus/GeocoderExample/blob/master/Geocoder%20Example/MapboxGeocoder.swift). Import that file into your project and then use `MBGeocoder` as a drop-in replacement for Apple's `CLGeocoder` (at least for reverse geocoding... for now). 
