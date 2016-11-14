# Build & test OHHTTPStubs lib from the CLI

desc 'Build an iOS scheme'
task :ios, [:scheme, :ios_version, :action, :additional_args] do |_,args|
  destination = "name=iPhone 5,OS=#{args.ios_version}"
  build("OHHTTPStubs #{args.scheme}", "iphonesimulator", destination, args.action, args.additional_args)
end

desc 'Build an OSX scheme'
task :osx, [:scheme, :arch, :action, :additional_args] do |_,args|
  destination = "arch=#{args.arch}"
  build("OHHTTPStubs #{args.scheme}", "macosx", destination, args.action, args.additional_args)
end

desc 'Build a tvOS scheme'
task :tvos, [:scheme, :tvos_version, :action, :additional_args] do |_,args|
  destination = "name=Apple TV 1080p,OS=#{args.tvos_version}"
  build("OHHTTPStubs #{args.scheme}", "appletvsimulator", destination, args.action, args.additional_args)
end


desc 'List installed simulators'
task :simlist do
  sh 'xcrun simctl list'
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
    -workspace OHHTTPStubs/OHHTTPStubs.xcworkspace
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
