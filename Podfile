source 'https://cdn.cocoapods.org/'

project 'OHHTTPStubs.xcodeproj'
inhibit_all_warnings!

DEPLOYMENT_TARGET = {
  IPHONEOS: '12.0',
  MACOSX: '10.13',
  TVOS: '12.0'
}

abstract_target 'TestingPods' do
  pod 'AFNetworking', '~> 3.0'

  target 'OHHTTPStubs iOS Lib Tests' do
    platform :ios, DEPLOYMENT_TARGET[:IPHONEOS]
  end

  target 'OHHTTPStubs iOS Fmk Tests' do
    platform :ios, DEPLOYMENT_TARGET[:IPHONEOS]
  end

  target 'OHHTTPStubs Mac Tests' do
    platform :osx, DEPLOYMENT_TARGET[:MACOSX]
  end

  target 'OHHTTPStubs tvOS Fmk Tests' do
    platform :tvos, DEPLOYMENT_TARGET[:TVOS]
  end
end

# Let Pods targets inherit deployment target from the app
# This solution is suggested here: https://github.com/CocoaPods/CocoaPods/issues/4859
post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |configuration|
      DEPLOYMENT_TARGET.each do |platform, version|
        build_setting_name = "#{platform}_DEPLOYMENT_TARGET"
        pod_deployment_target = Gem::Version.new(configuration.build_settings[build_setting_name])
        configuration.build_settings.delete build_setting_name if pod_deployment_target <= Gem::Version.new(version)
      end
    end
  end
end
