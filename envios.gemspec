Gem::Specification.new do |s|
  s.name        = 'envios'
  s.version     = '0.0.1'
  s.date        = '2016-02-17'
  s.summary     = "Environment variable loading for iOS"
  s.description = "Simple environment configuration loading"
  s.authors     = ["Justin Huang"]
  s.email       = 'justin@zumper.com'
  s.files       = `git ls-files`.split($\)
  s.homepage    =
    'http://rubygems.org/gems/envios'
  s.license       = 'MIT'

  s.add_dependency "thor", "~> 0.14"
  s.add_dependency "erubis", "~> 2.7"

  s.executables << "envios"

end
