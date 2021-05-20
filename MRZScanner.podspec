#
# Be sure to run `pod lib lint MRZScanner.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'MRZScanner'
  s.version          = '1.0.3'
  s.summary          = 'Library for scan MRZ'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = 'Library for scan MRZ'
  s.homepage         = 'https://github.com/mobilestar0223/MRZScanner'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'mobilestar0223' => 'mstar0223@gmail.com' }
  s.source           = { :git => 'https://github.com/mobilestar0223/MRZScanner.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '12.0'

  s.source_files = 'MRZScanner/Classes/**/*'
  s.exclude_files = 'MRZScanner/**/*.plist'
  # s.resource_bundles = {
  #   'MRZScanner' => ['MRZScanner/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
   s.frameworks = 'UIKit', 'MRZEngine'
  # s.dependency 'AFNetworking', '~> 2.3'
end
