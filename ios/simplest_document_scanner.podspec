Pod::Spec.new do |s|
  s.name             = 'simplest_document_scanner'
  s.version          = '0.0.1'
  s.summary          = 'Simplest document scanning plugin powered by VisionKit on iOS and MLKit on Android'
  s.description      = <<-DESC
Simplest document scanning plugin powered by VisionKit on iOS and MLKit on Android.
Currently only supports scanning documents in portrait mode.
                       DESC
  s.homepage         = 'https://github.com/sunderee/simplest-document-scanner'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Peter Aleksander Bizjak' => 'peter.aleksander@bizjak.dev' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '26.0'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '6.0'
  s.test_spec 'Tests' do |test_spec|
    test_spec.source_files = 'Tests/**/*'
  end
end
