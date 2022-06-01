#
# Be sure to run `pod lib lint ActiveLookSDK.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'ActiveLookSDK'
  s.version          = '4.2.4'
  s.summary          = 'An iOS library to interact with Active Look glasses'
  s.description      = <<-DESC
This CocoaPod provides the ability to connect to ActiveLook glasses running
a firmware >= 4.0.0  and send various commands
                       DESC

  s.homepage         = 'https://github.com/ActiveLook/ios-sdk'
  s.license          = { :type => 'Apache', :file => 'LICENSE' }
  s.author           = { "Sylvain Romillon" => "sylvain.romillon@microoled.net" }
  s.source           = { :git => 'https://github.com/ActiveLook/ios-sdk.git', :tag => s.version.to_s }
  s.source_files     = 'Classes/**/*'
  s.swift_version    = '5.0'

  s.ios.deployment_target       = '12.0'
  s.watchos.deployment_target   = '6.0'
end
