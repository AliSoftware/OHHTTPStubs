# Build & test OHHTTPStubs lib from the CLI

task :ios, [:scheme, :ios_version, :action] do |_,args|
  destination = "platform=iOS Simulator,name=iPhone 5,OS=#{args.ios_version}"
  build("OHHTTPStubs #{args.scheme}", "iphonesimulator", destination, args.action)
end


task :osx, [:scheme, :arch, :action] do |_,args|
  destination = "platform=OS X,arch=#{args.arch}"
  build("OHHTTPStubs #{args.scheme}", "macosx", destination, args.action)
end


# Build the xcodebuild command and run it
def build(scheme, sdk, destination, action)
  puts <<-ANNOUNCE
  =============================
  | Action: #{action} 
  | Scheme: "#{scheme}"
  | #{destination}
  =============================

  ANNOUNCE

  cmd  = %W(
    xcodebuild
    -workspace OHHTTPStubs.xcworkspace
    -scheme "#{scheme}"
    -sdk #{sdk}
    -configuration Release
    ONLY_ACTIVE_ARCH=NO
    -destination '#{destination}'
    #{action}
  )

  sh "set -o pipefail && #{cmd.join(' ')} | xcpretty -c"
end
