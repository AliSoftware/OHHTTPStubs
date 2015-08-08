Pod::Spec.new do |s|

  s.name         = "OHHTTPStubs"
  s.version      = "4.1.0"

  s.summary      = "Framework to stub your network requests like HTTP and help you write network unit tests with XCTest."
  s.description  = <<-DESC.gsub(/^ +\|/,'')
                    |A class to stub network requests easily:
                    |
                    | * Test your apps with fake network data (stubbed from file)
                    | * You can also customize your response headers and status code
                    | * Use customized stubs depending on the requests
                    | * Use custom response time to simulate slow network.
                    | * This works with any request (HTTP, HTTPS, or any protocol) sent using
                    |   the iOS URL Loading System (NSURLConnection, NSURLSession, AFNetworking, …)
                    | * This is really useful in unit testing, when you need to test network features
                    |   but don't want to hit the real network and fake some response data instead.
                    | * Has useful convenience methods to stub JSON content or fixture from a file
                    | * Compatible with Swift
                 DESC

  s.homepage     = "https://github.com/AliSoftware/OHHTTPStubs"
  s.license      = "MIT"
  s.authors      = { 'Olivier Halligon' => 'olivier.halligon+ae@gmail.com' }

  s.source       = { :git => "https://github.com/AliSoftware/OHHTTPStubs.git", :tag => s.version.to_s }

  s.frameworks = 'Foundation', 'CFNetwork'

  s.requires_arc = true
  s.ios.deployment_target = '5.0'
  s.osx.deployment_target = '10.7'
  s.watchos.deployment_target = '2.0'
  s.default_subspec = 'Core'

  s.subspec 'Core' do |core|
  # subspec for users who don't want the Mocktail extension
      core.source_files = "OHHTTPStubs/Sources/*.{h,m}"
      core.public_header_files = "OHHTTPStubs/Sources/*.h"
  end
  
  s.subspec 'Mocktail' do |mocktail|
      mocktail.dependency 'OHHTTPStubs/Core'
      mocktail.source_files = "OHHTTPStubs/Sources/Mocktail/*.{h,m}"
      mocktail.public_header_files = "OHHTTPStubs/Mocktail/Mocktail/*.h"
  end

end
