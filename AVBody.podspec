Pod::Spec.new do |s|
  s.name             = "AVBody"
  s.summary          = "Framework using AVFoundation for ARBody recording and playback"
  s.version          = "0.0.1"
  s.homepage         = "https://github.com/deeje/AVBody"
  s.license          = 'MIT'
  s.author           = { "deeje" => "deeje@mac.com" }
  s.source           = {
    :git => "https://github.com/deeje/AVBody.git",
    :tag => s.version.to_s
  }

  s.ios.deployment_target = '15.0'

  s.source_files = 'Source/*.swift'

  s.ios.frameworks = 'AVFoundation', 'ARKit'

  s.swift_versions = [5.1]
#  s.documentation_url = 'http://cocoadocs.org/docsets/CloudCore/'
end
