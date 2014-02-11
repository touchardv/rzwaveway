Gem::Specification.new do |s|
  s.name = "rzwaveway"
  s.version = "0.0.2"
  s.authors = ["Vincent Touchard"]
  s.date = %q{2014-02-08}
  s.summary = 'ZWave API for ZWay'
  s.description = 'A Ruby API to use the Razberry ZWave ZWay interface'
  s.email = 'vincentoo@yahoo.com'
  s.homepage = 'https://github.com/rzwaveway'
  s.files = `git ls-files`.split("\n")
  s.has_rdoc = false

  dependencies = [
    [:runtime,     "log4r",  "~> 1.1.10"]
  ]

  dependencies.each do |type, name, version|
    if s.respond_to?("add_#{type}_dependency")
      s.send("add_#{type}_dependency", name, version)
    else
      s.add_dependency(name, version)
    end
  end
end