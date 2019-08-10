Pod::Spec.new do |s|

  s.name         = "OHHTTPStubs"
  s.version      = "8.0.0"

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
  s.ios.deployment_target = '8.0'
  s.osx.deployment_target = '10.9'
  s.watchos.deployment_target = '2.0'
  s.tvos.deployment_target = '9.0'

  s.default_subspec = 'Default'
  # Default subspec that includes the most commonly-used components
  s.subspec 'Default' do |default|
    default.dependency 'OHHTTPStubs/Core'
    default.dependency 'OHHTTPStubs/NSURLSession'
    default.dependency 'OHHTTPStubs/JSON'
    default.dependency 'OHHTTPStubs/OHPathHelpers'
  end

  # The Core subspec, containing the library core needed in all cases
  s.subspec 'Core' do |core|
    core.source_files = "Sources/Core/*.{h,m}", "Sources/Core/include/*.h"
    core.public_header_files = "Sources/Core/include/*.h"
  end

  # Optional subspecs
  s.subspec 'NSURLSession' do |urlsession|
    urlsession.dependency 'OHHTTPStubs/Core'
    urlsession.source_files = "Sources/NSURLSession/*.{h,m}", "Sources/NSURLSession/include/OHHTTPStubsMethodSwizzling.h"
    urlsession.private_header_files = "Sources/NSURLSession/include/OHHTTPStubsMethodSwizzling.h"
  end

  s.subspec 'JSON' do |json|
    json.dependency 'OHHTTPStubs/Core'
    json.source_files = "Sources/JSON/*.{h,m}", "Sources/JSON/include/*.h"
    json.public_header_files = "Sources/JSON/include/*.h"
  end

  s.subspec 'HTTPMessage' do |httpmessage|
    httpmessage.dependency 'OHHTTPStubs/Core'
    httpmessage.source_files = "Sources/HTTPMessage/*.{h,m}", "Sources/HTTPMessage/include/*.h"
    httpmessage.public_header_files = "Sources/HTTPMessage/include/*.h"
  end

  s.subspec 'Mocktail' do |mocktail|
    mocktail.dependency 'OHHTTPStubs/Core'
    mocktail.source_files = "Sources/Mocktail/*.{h,m}", "Sources/Mocktail/include/*.h"
    mocktail.public_header_files = "Sources/Mocktail/include/*.h"
  end

  s.subspec 'OHPathHelpers' do |pathhelper|
    pathhelper.source_files = "Sources/OHPathHelpers/*.{h,m}", "Sources/Core/include/Compatibility.h", "Sources/OHPathHelpers/include/*.h"
    pathhelper.public_header_files = "Sources/OHPathHelpers/include/*.h", "Sources/Core/include/Compatibility.h"
  end

  s.subspec 'Swift' do |swift|
    swift.ios.deployment_target = '8.0'
    swift.osx.deployment_target = '10.9'
    swift.watchos.deployment_target = '2.0'
    swift.tvos.deployment_target = '9.0'

    swift.dependency 'OHHTTPStubs/Default'
    swift.source_files = "Sources/OHHTTPStubsSwift/*.swift"
  end

end
