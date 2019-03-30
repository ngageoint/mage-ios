source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '11.0'

workspace 'MAGE'
project 'MAGE.xcodeproj'

use_frameworks!

target 'MAGE' do
    pod 'FastImageCache', '~> 1.3'
    pod 'UIImage-Categories', '~> 0.0.1'
    pod 'HexColors', '~> 2.2.1'
    pod 'GoogleSignIn'
    #pod 'mage-ios-sdk', :git => 'https://github.com/ngageoint/mage-ios-sdk.git', :tag=> '3.0.0'
    #pod 'mage-ios-sdk', :git => 'https://github.com/ngageoint/mage-ios-sdk.git', :branch=> 'develop'
    pod 'mage-ios-sdk', :path => '../mage-ios-sdk'
    pod 'mgrs', '~>0.1.0'
    pod 'libPhoneNumber-iOS', '~> 0.8'
    pod 'tuneup_js'
    pod 'KTCenterFlowLayout'
    pod 'zxcvbn-ios'
    pod 'SkyFloatingLabelTextField', '~> 3.6.0'
    pod 'DateTools', '~> 2.0.0'
    pod 'EDSunriseSet', '~> 1.0'
    target 'MAGETests' do
        inherit! :search_paths
        pod 'OCMock'
        pod 'OHHTTPStubs'
    end
end

post_install do |installer_representation|
  installer_representation.pods_project.targets.each do |target|
    if target.name == 'mage-ios-sdk'
      target.build_configurations.each do |config|
        config.build_settings['CLANG_ENABLE_CODE_COVERAGE'] = 'YES'
      end
    else
      target.build_configurations.each do |config|
        config.build_settings['CLANG_ENABLE_CODE_COVERAGE'] = 'NO'
      end
    end
    if target.name == 'SkyFloatingLabelTextField'
      target.build_configurations.each do |config|
        config.build_settings['SWIFT_VERSION'] = '4.2'
      end
    end
  end
end
