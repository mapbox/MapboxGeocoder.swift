platform :ios, '8.0'
use_frameworks!

def shared_pods
  pod 'NBNRequestKit', :git => 'https://github.com/1ec5/RequestKit.git', :branch => 'mapbox-podspec'
end

target 'MapboxGeocoder' do
  shared_pods
end

target 'MapboxGeocoderTests' do
  pod 'Nocilla'
  shared_pods
end
