# Build & test OHHTTPStubs lib from the CLI

desc 'Build an iOS scheme'
task :ios, [:scheme, :ios_version, :action] do |_,args|
  destination = "platform=iOS Simulator,name=iPhone 5,OS=#{args.ios_version}"
  build("OHHTTPStubs #{args.scheme}", destination, args.action)
end

desc 'Build an OSX scheme'
task :osx, [:scheme, :arch, :action] do |_,args|
  destination = "platform=OS X,arch=#{args.arch}"
  build("OHHTTPStubs #{args.scheme}", destination, args.action)
end

desc 'Build a tvOS scheme'
task :tvos, [:scheme, :tvos_version, :action] do |_,args|
  destination = "platform=tvOS Simulator,name=Apple TV 1080p,OS=#{args.tvos_version}"
  build("OHHTTPStubs #{args.scheme}", destination, args.action)
end


desc 'List installed simulators'
task :simlist do
  sh 'xcrun simctl list'
end

desc 'Run all travis env tasks locally'
task :travis do
  require 'YAML'
  travis = YAML.load_file('.travis.yml')
  travis['env'].each do |env|
    arg = env.split('=')[1]
    puts "\n" + ('-'*80) + "\n\n"
    sh "rake #{arg}"
  end
end


# Build the xcodebuild command and run it
def build(scheme, destination, action)
  puts <<-ANNOUNCE
  =============================
  | Action: #{action} 
  | Scheme: "#{scheme}"
  | #{destination}
  =============================

  ANNOUNCE

  cmd  = %W(
    xcodebuild
    -workspace OHHTTPStubs/OHHTTPStubs.xcworkspace
    -scheme "#{scheme}"
    -configuration Debug
    ONLY_ACTIVE_ARCH=NO
    -destination '#{destination}'
    clean #{action}
  )

  sh "set -o pipefail && #{cmd.join(' ')} | xcpretty -c"
end
