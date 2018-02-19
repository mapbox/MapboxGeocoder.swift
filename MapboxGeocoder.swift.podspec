Pod::Spec.new do |s|

  # ―――  Spec Metadata  ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

  s.name         = "MapboxGeocoder.swift"
  s.version      = "0.8.0"
  s.summary      = "Mapbox Geocoding API for Swift and Objective-C."

  s.description  = <<-DESC
  MapboxGeocoder.swift makes it easy to connect your iOS, macOS, tvOS, or watchOS application to the Mapbox Geocoding API. MapboxGeocoder.swift exposes the power of the Carmen geocoder through a simple API similar to Core Location’s CLGeocoder.
                   DESC

  s.homepage     = "https://www.mapbox.com/geocoding/"

  # ―――  Spec License  ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

  s.license      = { :type => "ISC", :file => "LICENSE.md" }

  # ――― Author Metadata  ――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

  s.author             = { "Mapbox" => "mobile@mapbox.com" }
  s.social_media_url   = "https://twitter.com/mapbox"

  # ――― Platform Specifics ――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

  #  When using multiple platforms
  s.ios.deployment_target = "8.0"
  s.osx.deployment_target = "10.10"
  s.watchos.deployment_target = "2.0"
  s.tvos.deployment_target = "9.0"

  # ――― Source Location ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

  s.source       = { :git => "https://github.com/mapbox/MapboxGeocoder.swift.git", :tag => "v#{s.version.to_s}" }

  # ――― Source Code ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

  s.source_files  = "MapboxGeocoder"

  # ――― Project Settings ――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

  s.requires_arc = true
  s.module_name = "MapboxGeocoder"

  # The CocoaPods podspec spec is not backwards compatible, so, when they add new parameters
  # (like `swift_version` in 1.4.0), older versions of CocoaPods blow up in confusion.
  # Specifying a `cocoapods_version >= 1.4.0` does nothing to solve the problem, as Ruby
  # interprets unknown parameters as low-level syntax errors.
  #
  # Instead, we're forced to use Ruby's built-in semver comparison before declaring parameters
  # added in recent CocoaPods releases.
  if Version.new(Pod::VERSION) >= Version.new("1.4.0")
    s.swift_version = "4.0"
  end

end
