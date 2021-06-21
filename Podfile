source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '13.0'

workspace 'MAGE'
project 'MAGE.xcodeproj'

use_frameworks!

def common_pods
  pod 'UIImage-Categories', '~> 0.0.1'
  pod 'HexColors', '~> 2.2.1'
  #pod 'mage-ios-sdk', :git => 'https://github.com/ngageoint/mage-ios-sdk.git', :tag=> '3.1.0'
  #pod 'mage-ios-sdk', :git => 'https://github.com/ngageoint/mage-ios-sdk.git', :branch=> 'develop'
  pod 'mage-ios-sdk', :path => '../mage-ios-sdk'
  pod 'mgrs', '~>0.1.0'
  pod 'libPhoneNumber-iOS', '~> 0.8'
  pod 'zxcvbn-ios'
  pod 'DateTools', '~> 2.0.0'
  pod 'MaterialComponents'
  pod 'MDFInternationalization'
  pod 'Kingfisher', '~> 6'
  pod 'PureLayout'
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
