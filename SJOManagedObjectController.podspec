Pod::Spec.new do |s|
  s.name             = "SJOManagedObjectController"
  s.version          = "0.1.0"
  s.summary          = "Monitor changes and deletions of NSManagedObjects."
  s.description      = <<-DESC
                       Monitor changes and deletions of NSManagedObjects.
                       DESC
  s.homepage         = "https://github.com/blork/SJOManagedObjectController"
  s.license          = 'MIT'
  s.author           = { "Sam Oakley" => "sam@blork.co.uk" }
  s.source           = { :git => "https://github.com/blork/SJOManagedObjectController.git", :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/Sam_Oakley'

  s.platform     = :ios, '6.0'
  s.ios.deployment_target = '6.0'
  s.requires_arc = true

  s.source_files = 'Classes/**/*.{h,m}'

  s.public_header_files = 'Classes/ios/SJOManagedObjectController.h'
  s.framework = 'CoreData'
end
