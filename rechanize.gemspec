# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{rechanize}
  s.date = %q{2010-02-16}
  s.summary = %q{Rechanize is a simple RETS client.}
  s.version = "0.0.1"
  s.authors = ["Jacob Basham"]
  s.email = %q{jacob@paperpigeons.net}
  s.homepage = %q{http://rechanize.paperpigeons.net}

  s.description = %q{
    Rechanize provides an interface for querying metadata, data and objects.
  }

  s.add_dependency('mechanize')
  
  s.require_paths = ["lib"]
  
  s.has_rdoc = true  
  s.extra_rdoc_files = ["README.rdoc", "LICENSE"]
  s.rdoc_options = ["--inline-source", "--charset=UTF-8"]
  
  s.files = [
    "LICENSE",
		"README.rdoc",
    "Rakefile",
		"lib/rechanize.rb",
    "lib/rechanize/array.rb",
		"lib/rechanize/client.rb",
		"lib/rechanize/errors.rb",
    "lib/rechanize/string.rb",
    "lib/rechanize/xml.rb",
		"test"
	]

end
