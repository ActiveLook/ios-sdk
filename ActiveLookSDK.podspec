#
# Be sure to run `pod lib lint ActiveLookSDK.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'ActiveLookSDK'
  s.version          = '0.1.0'
  s.summary          = 'A library to allow interaction between an iOS app and Active Look glasses'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
This CocoaPod provides the ability to connect to ActiveLook glasses and send various commands
                       DESC

  s.homepage         = 'https://git.rwigo.com/microoled/activelook-sdk'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'Apache', :file => 'LICENSE' }
  s.author           = { "Sylvain Romillon" => "sylvain.romillon@microoled.net" }
  s.source           = { :git => 'https://git.rwigo.com/microoled/activelook-sdk/demo-ios.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '10.0'
  s.watchos.deployment_target = '4.0'

  s.source_files = 'Classes/**/*'

  s.swift_version = '5.0'
  
  # s.resource_bundles = {
  #   'ActiveLookSDK' => ['ActiveLookSDK/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end
