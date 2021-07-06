source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '13.0'

workspace 'MAGE'
project 'MAGE.xcodeproj'

use_modular_headers!

def common_pods
  pod 'UIImage-Categories', '~> 0.0.1'
  pod 'HexColors', '~> 2.2.1'
  pod 'mgrs', '~>0.1.0'
  pod 'libPhoneNumber-iOS', '~> 0.8'
  pod 'zxcvbn-ios'
  pod 'DateTools', '~> 2.0.0'
  pod 'MaterialComponents'
  pod 'MDFInternationalization'
  pod 'Kingfisher', '~> 6'
  pod 'PureLayout'
  pod "AFNetworking", "~> 4.0.1"
  pod "DateTools", "~> 2.0.0"
  pod "MagicalRecord", "~> 2.3.2"
  pod 'geopackage-ios', '~> 5.0.0'
  pod 'SSZipArchive', '~> 2.2.2'
end

target 'MAGE' do
    common_pods
    target 'MAGETests' do
      inherit! :search_paths
      common_pods
      pod 'OCMock'
      pod 'OHHTTPStubs'
      pod 'OHHTTPStubs/Swift'
      pod 'Quick'
      pod 'Nimble', '~> 9'
      pod 'Nimble-Snapshots', '~> 9'
      pod 'KIF'
    end
end
