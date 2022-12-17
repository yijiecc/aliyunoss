# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'aliyunoss/version'

Gem::Specification.new do |spec|
  spec.name          = "aliyunoss"
  spec.version       = Aliyun::Oss::VERSION
  spec.authors       = ["yijiecc"]
  spec.email         = ["yijiecc@hotmail.com"]
  spec.summary       = %q{A gem for accessing Aliyun Open Storage Service.}
  spec.description   = %q{Access Aliyun-OSS service easily in ruby.}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency 'nokogiri', '~> 1.13'
  
  spec.add_development_dependency "bundler", "~> 2.3"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.12"

end
