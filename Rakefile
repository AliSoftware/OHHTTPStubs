# Build & test OHHTTPStubs lib from the CLI

desc 'Build an iOS scheme'
task :ios, [:scheme, :ios_version, :action, :run_timing_tests] do |_,args|
  destination = "name=iPhone 5,OS=#{args.ios_version}"
  build("OHHTTPStubs #{args.scheme}", "iphonesimulator", destination, args.action, args.run_timing_tests)
end

desc 'Build an OSX scheme'
task :osx, [:scheme, :arch, :action, :run_timing_tests] do |_,args|
  destination = "arch=#{args.arch}"
  build("OHHTTPStubs #{args.scheme}", "macosx", destination, args.action, args.run_timing_tests)
end

desc 'Build a tvOS scheme'
task :tvos, [:scheme, :tvos_version, :action, :run_timing_tests] do |_,args|
  destination = "name=Apple TV 1080p,OS=#{args.tvos_version}"
  build("OHHTTPStubs #{args.scheme}", "appletvsimulator", destination, args.action, args.run_timing_tests)
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
    xcode = xcode_dev_dir(matrix['osx_image'])
    arg = env.split('=')[1..-1].join('=')
    puts "\n" + ('-'*80) + "\n\n"
    sh "#{xcode} rake #{arg}"
  end
end

def xcode_dev_dir(image)
  version = { 'xcode7.3' => '7.3', 'xcode8' => '8.*' }[image]
  found_xcodes = `mdfind 'kMDItemCFBundleIdentifier == "com.apple.dt.Xcode" && kMDItemVersion == "#{version}"'`.split("\n")
  xcode = found_xcodes.sort.reverse.first
  xcode.nil? ? '' : %Q(DEVELOPER_DIR="#{xcode}/Contents/Developer" )
end

# Build the xcodebuild command and run it
def build(scheme, sdk, destination, action, run_timing_tests)
  additional_args = ['true',1].include?(run_timing_tests.downcase) ? '' : 'GCC_PREPROCESSOR_DEFINITIONS=OHHTTPSTUBS_SKIP_TIMING_TESTS'
  puts <<-ANNOUNCE
  =============================
  | Xcode      : #{`xcodebuild -version`.chomp.gsub("\n",'; ')}
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
