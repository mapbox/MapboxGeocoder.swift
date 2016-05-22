use_frameworks!

#def shared_pods
#end

#target 'MapboxGeocoder' do
#  shared_pods
#end

def shared_test_pods
  pod 'Nocilla', :configurations => ['Debug']
end

target 'MapboxGeocoderTests' do
  platform :ios, '8.0'
  shared_test_pods
end

target 'MapboxGeocoderMacTests' do
    platform :osx, '10.10'
  shared_test_pods
end
