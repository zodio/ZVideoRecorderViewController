Pod::Spec.new do |s|

  s.name         = "ZVideoRecorder"
  s.version      = "0.0.3"
  s.summary      = "A Video Recorder for the Zodio iPhone app."

  s.description  = <<-DESC
                   A Video Recorder for the Zodio iPhone app - to be used in the Zodio app only!
				   I haven't refactored to the point where it can run independently yet.
                   DESC

  s.homepage     = "https://github.com/zodio/ZVideoRecorderViewController"

  s.license      = "MIT"

  s.author             = { "Jai Govindani" => "jai@zodio.com" }
  s.social_media_url   = "http://twitter.com/govindani"

  s.platform     = :ios
  s.platform     = :ios, "6.0"

  s.source       = { :git => "https://github.com/zodio/ZVideoRecorderViewController.git", :tag => "0.0.3" }
  s.source_files = 'Classes/*.{h,m,xib}'
  s.exclude_files = "Classes/Exclude"
  s.resources = 'Assets'

  s.frameworks = "Accelerate", "CoreGraphics"
  s.requires_arc = true

  s.dependency 'ZTimer', '0.0.3'
  s.dependency "ZPopoverView", '0.0.1'
  s.dependency "PBJVision", '0.1.8'
  s.dependency "PBJVideoPlayer"
  s.dependency "AFNetworking", '1.3.3'
  s.dependency "ZProgressView", '0.2.1'
  

end