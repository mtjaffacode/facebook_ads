#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#
Pod::Spec.new do |s|
  s.name             = 'facebook_ads'
  s.version          = '0.0.1'
  s.summary          = 'A new flutter plugin project.'
  s.description      = <<-DESC
A new flutter plugin project.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'
  s.dependency 'Flutter'
  s.dependency 'FBAudienceNetwork', '5.3.1'
  s.dependency 'AdColony'
  s.dependency 'UnityAds'
#  s.dependency 'StartAppSDK'
#  s.vendored_frameworks = 'StartApp.framework'
#  s.module_map = 'Other/facebook_ads.modulemap'
#  s.xcconfig = { 'HEADER_SEARCH_PATHS' => '"${PODS_ROOT}/StartAppSDK"' }
#  s.preserve_path = 'Other/facebook_ads-umbrella.h'

#  s.xcconfig = { 'SWIFT_OBJC_BRIDGING_HEADER' => 'Other/BridgingHeader.h' }

  s.ios.deployment_target = '10.0'
  s.static_framework = true
end

