# frozen_string_literal: true

$LOAD_PATH.push File.expand_path('lib', __dir__)
require 'sh/version'

Gem::Specification.new do |s|
  s.name        = 'sh'
  s.version     = Sh::VERSION
  s.authors     = ['Ben Marini']
  s.email       = ['bmarini@gmail.com']
  s.homepage    = ''
  s.summary     = 'A nice API for constructing complex shell commands'
  s.description = 'A nice API for constructing complex shell commands'

  s.rubyforge_project = 'sh'

  s.required_ruby_version = '>= 3.1'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map { |f| File.basename(f) }
  s.require_paths = ['lib']

  # specify any dependencies here; for example:
  # s.add_development_dependency "rspec"
  # s.add_runtime_dependency "rest-client"

  s.add_runtime_dependency 'escape'
  s.add_development_dependency 'minitest', '~> 2.8.1'
  s.add_development_dependency 'rake'
end
