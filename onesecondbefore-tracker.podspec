Pod::Spec.new do |s|
  s.name                  = 'onesecondbefore-tracker'
  s.version               = '2.0.2'
  s.summary               = "OSB Analytics Library for iOS"
  s.description           = 'Onesecondbefore Analytics Library for iOS'
  s.homepage              = "https://www.onesecondbefore.com/resources"
  s.license               = { :type => 'Copyright', :text => "Copyright 2023 Onesecondbefore" }
  s.author                = { 'Onesecondbefore' => 'info@onesecondbefore.com' }
  s.source                = { :git => "https://github.com/onesecondbefore/osb-pod-ios.git", :tag =>  s.version.to_s, :branch => "main" }
  s.ios.deployment_target = '11.0'
  s.swift_version         = "5.2"
  s.source_files          = 'onesecondbefore-tracker/Classes/**/*'
  s.resource_bundles      = { 'onesecondbefore-tracker' => ['onesecondbefore-tracker/Assets/*'] }
end
