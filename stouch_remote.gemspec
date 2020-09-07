lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'stouch_remote/version'

Gem::Specification.new do |spec|
  spec.name          = 'stouch_remote'
  spec.version       = STouchRemote::VERSION
  spec.authors       = ['Sylvain Daubert']
  spec.email         = ['sylvain.daubert@laposte.net']

  spec.summary       = %q(SoundTouch Remote Control)
  #spec.homepage      = "TODO: Put your gem's website or public repo URL here."

  spec.metadata['allowed_push_host'] = 'http://rubygems.org'

  # TODO
  #spec.metadata['homepage_uri'] = spec.homepage
  #spec.metadata['source_code_uri'] = "TODO: Put your gem's public repo URL here."
  #spec.metadata['changelog_uri'] = "TODO: Put your gem's CHANGELOG.md URL here."

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'nokogiri', '~> 1.10'
  spec.add_dependency 'websocket-driver', '~> 0.7'
  spec.add_dependency 'gtk3'

  spec.add_development_dependency 'bundler', '~> 2.0'
  spec.add_development_dependency 'rake', '~> 10.0'
end
