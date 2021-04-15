Pod::Spec.new do |s|
    s.name         = "onesecondbefore-tracker"
    s.version      = "1.0.0"
    s.summary      = "A brief description of OSB project."
    s.description  = <<-DESC
    An extended description of OSB project.
    DESC
    s.homepage     = "http://onesecondbefore.com/"
    s.license = { :type => 'Copyright', :text => <<-LICENSE
                   Copyright 2020
                   Permission is granted to...
                  LICENSE
                }
    s.author             = { "$(git config user.name)" => "$(git config user.email)" }
    s.source       = { :git => "https://github.com/onesecondbefore/osb-pod-ios.git", :tag => "#{s.version}" }
    s.vendored_frameworks = "OSB.framework"
    s.platform = :ios
    s.swift_version = "5.2"
    s.ios.deployment_target  = '12.0'
    s.user_target_xcconfig = {
      'SWIFT_INCLUDE_PATHS' => '"\$(PODS_ROOT)/onesecondbefore-tracker/OSB.framework"'
    }
end