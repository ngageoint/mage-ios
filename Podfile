source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '13.0'

workspace 'MAGE'
project 'MAGE.xcodeproj'

use_modular_headers!

def common_pods
  pod 'UIImage-Categories', '~> 0.0.1'
  pod 'HexColors', '~> 4.0.0'
  pod 'libPhoneNumber-iOS', '~> 0.9.15'
  pod 'zxcvbn-ios'
  pod 'DateTools', '~> 2.0.0'
  pod 'MaterialComponents'
  pod 'MDFInternationalization'
  pod 'Kingfisher', '~> 6'
  pod 'PureLayout'
  pod "AFNetworking", "~> 4.0.1"
  pod "DateTools", "~> 2.0.0"
  pod "MagicalRecord", "~> 2.3.2"
  pod 'geopackage-ios', '~> 7.3.0'
  pod 'mgrs-ios', '~> 1.1.1'
  pod 'gars-ios', '~> 1.1.1'
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
      pod 'Quick', :git=> 'https://github.com/Quick/Quick.git', :commit => 'a0a5fc857cea079fbe973e4faa80b6ceaf17bd46'
      pod 'Nimble', '~> 9'
#      pod 'Nimble-Snapshots', '~> 9'
      pod 'KIF'
    end
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings.delete 'ARCHS'
      config.build_settings.delete 'IPHONEOS_DEPLOYMENT_TARGET'
      config.build_settings['BITCODE_GENERATION_MODE'] = 'bitcode'
      config.build_settings['ENABLE_BITCODE'] = 'YES'
      # Fix Xcode 14 bundle code signing issue
      if target.respond_to?(:product_type) and target.product_type == "com.apple.product-type.bundle"
        target.build_configurations.each do |config|
          config.build_settings['CODE_SIGNING_ALLOWED'] = 'NO'
        end
      end
    end
  end
end

# This is a workaround for having tests work without useframeworks set
# it needs more work
# post_install do |installer|
#   def merge_and_link_dirs(source, destination)
#     system "echo source #{source}"
#     system "echo dest #{destination}"

#       system "echo source is symlink check"
#       if File.symlink?(source) then
#           system "echo source is symlink"
#           return
#       end

#       if File.directory?(source) then
#         system "echo source is a directory"
#           system "echo #{source}/* #{destination}"
#           system "mv #{source}/* #{destination}"
#           system "rmdir #{source}"
#       end
#       system "echo ln -s ../#{destination} #{source}"
#       # system "echo ln -s ../#{destination} #{source}"
#       File.symlink("../#{destination}", source)
#   end

#   headers_dir = installer.config.project_pods_root + 'Headers/'

#   # Work around for FBSnapshotTestCase with static linking.
#   # This is needed because of buggy handling of the differing module and project names.
#   # NOTE: Uncomment to resolve the build failure
#   system "echo headers dir"
#   system "echo #{headers_dir}"
#   Dir.chdir(headers_dir) do
#       merge_and_link_dirs('Public/FBSnapshotTestCase', 'Public/iOSSnapshotTestCase')
#       merge_and_link_dirs('Private/FBSnapshotTestCase', 'Private/iOSSnapshotTestCase')
#   end
# end
