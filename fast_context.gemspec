$LOAD_PATH << File.join(File.dirname(__FILE__), 'lib')

Gem::Specification.new do |s|
  s.name        = 'fast_context'
  s.version     = "1.1.0"
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Pratik Naik", "Ed Schmalzle", "Nick Ewing"]
  s.email       = %q{support@thoughtbot.com}
  s.homepage    = %q{https://github.com/castlerock/fast_context}
  s.summary     = %q{Make your shoulda contexts faster}
  s.description = %q{Make your shoulda contexts faster}

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency("shoulda", "~> 3.0")
end
