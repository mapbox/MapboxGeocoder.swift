use_frameworks!

def shared_pods
  pod 'Mapbox-iOS-SDK', '~> 3.2.2'
end

def shared_test_pods
  pod 'OHHTTPStubs/Swift', '~> 5.0.0', :configurations => ['Debug']
end

target 'Example (Swift)' do
  platform :ios, '8.0'
  shared_pods
end

target 'Example (Objective-C)' do
  platform :ios, '8.0'
  shared_pods
end

target 'MapboxGeocoderTests' do
  platform :ios, '8.0'
  shared_test_pods
end

target 'MapboxGeocoderMacTests' do
  platform :osx, '10.10'
  shared_test_pods
end

target 'MapboxGeocoderTVTests' do
  platform :tvos, '9.0'
  shared_test_pods
end
