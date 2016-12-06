$LOAD_PATH.unshift 'lib'
require 'rzwaveway/version'

Gem::Specification.new do |s|
  s.name = 'rzwaveway'
  s.version = RZWaveWay::VERSION
  s.authors = ['Vincent Touchard']
  s.date = %q{2014-02-18}
  s.summary = 'ZWave API for ZWay'
  s.description = 'A Ruby API to use the Razberry ZWave ZWay interface'
  s.email = 'touchardv@yahoo.com'
  s.homepage = 'https://github.com/touchardv/rzwaveway'
  s.files = `git ls-files`.split("\n")
  s.has_rdoc = false

  dependencies = [
    [:runtime, 'log4r', '~> 1.1.10'],
    [:runtime, 'faraday'],
    [:runtime, 'httpclient'],
    [:development, 'bundler', '~> 1.0'],
    [:development, 'rspec', '~> 3.0.0'],
    [:development, 'pry-byebug']
  ]

  dependencies.each do |type, name, version|
    if s.respond_to?("add_#{type}_dependency")
      s.send("add_#{type}_dependency", name, version)
    else
      s.add_dependency(name, version)
    end
  end
end