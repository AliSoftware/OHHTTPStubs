# Build & test OHHTTPStubs lib from the CLI

desc 'Build an iOS scheme'
task :ios, [:scheme, :device, :ios_version, :action, :additional_args] do |_,args|
  destination = "name=#{args.device},OS=#{args.ios_version}"
  build("OHHTTPStubs #{args.scheme}", "iphonesimulator", destination, args.action, args.additional_args)
end

desc 'Build an OSX scheme'
task :osx, [:scheme, :arch, :action, :additional_args] do |_,args|
  destination = "arch=#{args.arch}"
  build("OHHTTPStubs #{args.scheme}", "macosx", destination, args.action, args.additional_args)
end

desc 'Build a tvOS scheme'
task :tvos, [:scheme, :tvos_version, :action, :additional_args] do |_,args|
  destination = "name=Apple TV,OS=#{args.tvos_version}"
  build("OHHTTPStubs #{args.scheme}", "appletvsimulator", destination, args.action, args.additional_args)
end

desc 'Test Using Swift Package Manager'
task :spm_test, [:additional_args] do |_,args|
  sh 'swift test -Xcc -DOHHTTPSTUBS_SKIP_REDIRECT_TESTS'
end

desc 'List installed simulators'
task :simlist do
  sh 'xcrun simctl list'
end

desc 'Build Example Project'
task :build_example_apps do
  build_pod_example("Examples/ObjC")
  build_pod_example("Examples/Swift")
  build_example("Examples/SwiftPackageManager")
end

# Updates Local Pods, Then Builds
def build_pod_example(dir)
  sh "pod install --project-directory=#{dir}"
  build_example(dir)
end

# Builds The Example Project
def build_example(dir)
  sh "xcodebuild -workspace #{dir}/OHHTTPStubsDemo.xcworkspace -scheme OHHTTPStubsDemo build CODE_SIGNING_ALLOWED=NO"
end

desc 'Run all travis env tasks locally'
task :travis do
  require 'YAML'
  travis = YAML.load_file('.travis.yml')
  travis['matrix']['include'].each do |matrix|
    env = matrix['env']
    arg = env.split('=')[1..-1].join('=')
    puts "\n" + ('-'*80) + "\n\n"
    sh "rake #{arg}"
  end
end


# Build the xcodebuild command and run it
def build(scheme, sdk, destination, action, additional_args)
  puts <<-ANNOUNCE
  =============================
  | Action     : #{action}
  | SDK        : #{sdk}
  | Scheme     : "#{scheme}"
  | Destination: #{destination}
  | args       : "#{additional_args}"
  =============================

  ANNOUNCE

  cmd  = %W(
    xcodebuild
    -workspace OHHTTPStubs.xcworkspace
    -scheme "#{scheme}"
    -sdk #{sdk}
    -configuration Debug
    ONLY_ACTIVE_ARCH=NO
    #{additional_args}
    -destination '#{destination}'
    clean #{action}
  )

  sh "set -o pipefail && #{cmd.join(' ')} | xcpretty -c"
end
