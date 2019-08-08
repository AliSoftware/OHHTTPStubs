source 'https://github.com/CocoaPods/Specs.git'

project 'OHHTTPStubs.xcodeproj'
inhibit_all_warnings!

abstract_target 'TestingPods' do
  pod 'AFNetworking', '~> 3.0'

  target 'OHHTTPStubs iOS Lib Tests' do
    platform :ios, '8.0'
  end

  target 'OHHTTPStubs iOS Fmk Tests' do
    platform :ios, '8.0'
  end

  target 'OHHTTPStubs Mac Tests' do
    platform :osx, '10.9'
  end

  target 'OHHTTPStubs tvOS Fmk Tests' do
    platform :tvos, '9.0'
  end
end
