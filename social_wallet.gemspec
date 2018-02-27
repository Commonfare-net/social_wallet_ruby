# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'social_wallet/version'

Gem::Specification.new do |spec|
  spec.name          = 'social_wallet'
  spec.version       = SocialWallet::VERSION
  spec.authors       = ['pbmolini']
  spec.email         = ['pbmolini@fbk.eu']

  spec.summary       = %q{A simple client for the Social Wallet API}
  spec.description   = %q{A simple client for the Social Wallet API}
  spec.homepage      = 'https://github.com/Commonfare-net/social_wallet_ruby'

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "RubyGems 2.0"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  spec.files = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency('faraday', '>= 0.9.1')
  spec.add_dependency('multi_json', '>= 1.11.0')

  spec.add_development_dependency 'bundler', '~> 1.13'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.0'

  spec.add_development_dependency 'pry'

  spec.add_development_dependency 'rubocop'
  spec.add_development_dependency 'rubocop-rspec'
end
