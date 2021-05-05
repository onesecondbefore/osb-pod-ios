Pod::Spec.new do |s|
    s.name         = "onesecondbefore-tracker"
    s.version      = "1.0.3"
    s.summary      = "OSB Tracker Library for iOS"
    s.description  = "OSB Tracker Pod for iOS"
    s.homepage     = "https://www.onesecondbefore.com/resources"
    s.license = { :type => 'Copyright', :text => "Copyright 2021 Onesecondbefore" }
    s.author       = { "$(git config user.name)" => "$(git config user.email)" }
    s.source       = { :git => "https://github.com/onesecondbefore/osb-pod-ios.git", :tag => "#{s.version}" }
    s.vendored_frameworks = "OSB.framework"
    s.platform = :ios
    s.swift_version = "5.2"
    s.ios.deployment_target = '11.0'
    s.requires_arc = true
    s.user_target_xcconfig = {
      'SWIFT_INCLUDE_PATHS' => '$(PODS_ROOT)/onesecondbefore-tracker/OSB.framework'
    }
end
