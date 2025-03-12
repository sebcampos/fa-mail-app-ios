# Uncomment the next line to define a global platform for your project
platform :ios, '18.2'

target 'fa-mail' do
  # Comment the next line if you don't want to use dynamic frameworks
 use_frameworks!

  pod 'KeychainAccess'

  # Pods for fa-mail
  pod 'mailcore2-ios'

  target 'fa-mailTests' do
    inherit! :search_paths
    # Pods for testing
  end

  target 'fa-mailUITests' do
    # Pods for testing
  end
#  post_install do |installer|
#    installer.pods_project.targets.each do |target|
#      target.build_configurations.each do |config|
#        # Force CocoaPods targets to always build for x86_64
#        config.build_settings['ARCHS[sdk=iphonesimulator*]'] = 'x86_64'
#      end
#    end
#  end
end
