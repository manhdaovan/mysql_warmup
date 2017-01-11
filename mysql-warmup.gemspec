# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |s|
  s.name    = 'mysql-warmup'
  s.version = '0.0.1'
  s.author  = 'Manh Dao Van'
  s.email   = 'manhdaovan@gmail.com'

  s.platform              = Gem::Platform::RUBY
  s.required_ruby_version = '>= 2.0.0'

  s.files         = `git ls-files`.split('\n')
  s.test_files    = `git ls-files -- {test}/*`.split("\n")
  s.require_paths = ['lib']

  s.add_dependency('mysql')
  s.add_development_dependency('rake')
end
