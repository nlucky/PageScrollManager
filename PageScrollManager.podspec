#
#  Be sure to run `pod spec lint PageScrollManager.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see http://docs.cocoapods.org/specification.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |s|


  s.name         = "PageScrollManager"
  s.version      = "0.2.1"
  s.summary      = "PageScrollManager is a library control PageViewController."

  s.homepage     = "https://github.com/nlucky/PageScrollManager"

  s.license      = 'MIT'

  s.author             = { "Cocoa" => "dcj0928@163.com" }

  s.ios.deployment_target = "8.0"

  s.source       = { :git => "https://github.com/nlucky/PageScrollManager.git", :tag => s.version.to_s }

  s.source_files = 'Sources/**/*.swift'
  s.requires_arc = true

end
