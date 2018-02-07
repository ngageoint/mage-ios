source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '10.0'

workspace 'MAGE'
project 'MAGE.xcodeproj'

target 'MAGE' do
    pod 'FastImageCache', '~> 1.3'
    pod 'UIImage-Categories', '~> 0.0.1'
    pod 'HexColors', '~> 2.2.1'
    pod 'GoogleSignIn'
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
