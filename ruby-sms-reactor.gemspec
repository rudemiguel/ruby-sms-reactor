Gem::Specification.new do |s|
  s.name          = 'ruby-sms-reactor'
  s.has_rdoc      = 'yard'
  s.version       = '0.0.1'
  s.date          = '2013-07-10'
  s.summary       = "sms-reactor.ru integration for ruby"
  s.description   = "Send SMS via sms-reactor.ru service easy!"
  s.authors       = ["Miguel Sanches"]
  s.email         = 'rude.miguel@gmail.com'
  s.files         = ["lib/ruby-sms-reactor.rb"]
  s.homepage      = 'http://sms-reactor.ru'
  s.require_paths = ["lib"]
  s.add_runtime_dependency("json")
end