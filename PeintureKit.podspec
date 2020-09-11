Pod::Spec.new do |s|
  s.name = 'PeintureKit'
  s.version = '0.0.1'
  s.summary = 'A DSL drawing toolkit'
  s.homepage = 'https://github.com/suransea/PeintureKit'
  s.authors = { 'sea' => 'simpleslight@icloud.com' }
  s.license = { :type => 'MIT' }
  s.source = { :git => 'https://github.com/suransea/PeintureKit.git', :tag => '#{s.version}' }

  s.ios.deployment_target = '9.0'
  s.tvos.deployment_target = '9.0'

  s.source_files = 'Source/PeintureKit/*.swift'

  s.swift_version = '5.2'
end
