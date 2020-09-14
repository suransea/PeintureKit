Pod::Spec.new do |s|
  s.name = 'PeintureKit'
  s.version = '0.0.1'
  s.summary = 'A DSL drawing toolkit'
  s.homepage = 'https://github.com/suransea/PeintureKit'
  s.authors = { 'sea' => 'simpleslight@icloud.com' }
  s.license = { :type => 'MIT' }
  s.source = { :git => 'https://github.com/suransea/PeintureKit.git', :tag => s.version }
  s.source_files = 'Sources/PeintureKit/*.swift'

  s.platform = :ios, '9.0'
  s.ios.deployment_target = '9.0'
  s.swift_version = '5.2'
end
