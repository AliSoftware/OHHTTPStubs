source 'https://cdn.cocoapods.org/'

project 'OHHTTPStubs.xcodeproj'
inhibit_all_warnings!

abstract_target 'TestingPods' do
  pod 'AFNetworking', '~> 3.0'

  target 'OHHTTPStubs iOS Lib Tests' do
    platform :ios, '12.0'
  end

  target 'OHHTTPStubs iOS Fmk Tests' do
    platform :ios, '12.0'
  end

  target 'OHHTTPStubs Mac Tests' do
    platform :osx, '10.13'
  end

  target 'OHHTTPStubs tvOS Fmk Tests' do
    platform :tvos, '12.0'
  end
end

# Let Pods targets inherit deployment target from the app
# This solution is suggested here: https://github.com/CocoaPods/CocoaPods/issues/4859
APP_IOS_DEPLOYMENT_TARGET = Gem::Version.new('12.0')
post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |configuration|
      pod_ios_deployment_target = Gem::Version.new(configuration.build_settings['IPHONEOS_DEPLOYMENT_TARGET'])
      configuration.build_settings.delete 'IPHONEOS_DEPLOYMENT_TARGET' if pod_ios_deployment_target <= APP_IOS_DEPLOYMENT_TARGET
    end
  end
end
