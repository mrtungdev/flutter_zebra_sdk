#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint flutter_zebra_sdk.podspec' to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'flutter_zebra_sdk'
  s.version          = '0.0.1'
  s.summary          = 'A new flutter plugin project.'
  s.description      = <<-DESC
A new flutter plugin project.
                       DESC
  s.homepage         = 'https://toilatung'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*.{swift,h,m}'
  s.public_header_files = 'Classes/**/*.h'
  s.dependency 'Flutter'
  s.platform = :ios, '9.0'
  s.ios.vendored_library = 'libZSDK_API.a'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', :modular_headers => true}
  s.swift_version = '5.0'
end
