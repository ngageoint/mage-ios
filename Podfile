source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '10.0'

workspace 'MAGE'
project 'MAGE.xcodeproj'

target 'MAGE' do
    pod 'FastImageCache', '~> 1.3'
    pod 'UIImage-Categories', '~> 0.0.1'
    pod 'HexColors', '~> 2.2.1'
    pod 'GoogleSignIn'
    #pod 'mage-ios-sdk', :git => 'https://github.com/ngageoint/mage-ios-sdk.git', :tag=> '2.0.1'
    pod 'mage-ios-sdk', :git => 'https://github.com/ngageoint/mage-ios-sdk.git', :branch=> 'develop'
    #pod 'mage-ios-sdk', :path => '../mage-ios-sdk'
    pod 'libPhoneNumber-iOS', '~> 0.8'
    pod 'tuneup_js'
    pod 'KTCenterFlowLayout'
    pod 'zxcvbn-ios'
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
  end
end
