source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '16.0'

workspace 'MAGE'
project 'MAGE.xcodeproj'

use_modular_headers!

def common_pods
  pod 'HexColors', '~> 4.0.0'
  pod 'libPhoneNumber-iOS', '~> 0.9.15'
  pod 'zxcvbn-ios'
  pod 'DateTools', '~> 2.0.0'
  pod 'PureLayout'
  pod "AFNetworking", "~> 4.0.1"
  pod "MagicalRecord", "~> 2.3.2"
  pod 'SSZipArchive', '~> 2.2.2'
end

def test_pods
  pod 'OCMock'
  pod 'OHHTTPStubs'
  pod 'OHHTTPStubs/Swift'
  pod 'Quick', '~> 6'
  pod 'Nimble', '~> 9'
  pod 'KIF'
end

target 'MAGE' do
    common_pods
    target 'MAGETests' do
      inherit! :search_paths
      common_pods
      test_pods
    end
    target 'MAGEGeoPackageTests' do
      inherit! :search_paths
      common_pods
      test_pods
    end
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings.delete 'IPHONEOS_DEPLOYMENT_TARGET'
    end
  end
end
