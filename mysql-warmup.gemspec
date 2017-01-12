# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'mysql_warmup/version'

Gem::Specification.new do |s|
  s.name     = 'mysql-warmup'
  s.version  = MysqlWarmup::VERSION
  s.author   = 'Manh Dao Van'
  s.email    = 'manhdaovan@gmail.com'
  s.homepage = 'https://github.com/manhdaovan/mysql_warmup'
  s.license  = 'MIT'

  s.summary     = 'A command line tool to warm up mysql instance after reboot or startup'
  s.description = <<-eos
    When you've just created new slave instance, first requests to DB (with InnoDB storage engine)
    will be hit on disk instead of buffer poll. So, the requests will be slow down.
    You can use this tool for warming up buffer poll before the first requests come.
    Please see document for other cases.
  eos

  s.platform              = Gem::Platform::RUBY
  s.required_ruby_version = '>= 2.0.0'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test}/*`.split("\n")
  s.require_paths = ['lib']

  s.executables        = s.files.grep(%r{^bin/}).map { |f| File.basename(f) }
  s.default_executable = 'mysql-warmup'
  s.bindir             = 'bin'

  s.add_dependency('mysql')
  s.add_development_dependency('rake')
end
