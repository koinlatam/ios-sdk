Pod::Spec.new do |spec|
  spec.name         = 'KoinFingerprint'
  spec.version      = '1.2.0'
  spec.summary      = 'Koins iOS SDK for Mobile Fingerprinting.'
  spec.description  = <<-DESC 
  Koin iOS SDK provides a simple API to compute a unique device fingerpint to use it along with Koin Payments or Antifraud services. 
                   DESC
  spec.homepage     = 'https://www.koin.com.br'
  spec.license      = { :type => 'MIT', :file => 'LICENSE' }
  spec.author    = 'Koin'
  spec.social_media_url   = 'https://github.com/koinlatam'
  spec.platform     = :ios
  spec.swift_version = '5.5'
  spec.ios.deployment_target  = '12'
  spec.source       = { :git => 'https://github.com/koinlatam/ios-sdk.git', :tag => "#{spec.version}" }
  spec.vendored_frameworks = 'KoinFingerprint.xcframework'
end
