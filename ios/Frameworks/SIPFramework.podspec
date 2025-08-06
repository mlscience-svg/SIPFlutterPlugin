Pod::Spec.new do |s|
  s.name             = 'SIPFramework'
  s.version          = '1.0.0'
  s.summary          = 'Local xcframework for SIP'
  s.description      = 'Local SIPFramework wrapped for CocoaPods'
  s.homepage         = 'https://example.com'
  s.license          = 'MIT'
  s.author           = { 'YourName' => 'yangtaotop@126.com' }
  s.platform         = :ios, '12.0'
  s.source           = { :path => '.' }
  s.vendored_frameworks = 'SIPFramework.xcframework'
  s.swift_version    = '5.0'
end
