# -*- encoding: utf-8 -*-
# stub: rspec-eventually 0.2.0 ruby lib

Gem::Specification.new do |s|
  s.name = "rspec-eventually"
  s.version = "0.2.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["Hawk Newton"]
  s.date = "2016-08-29"
  s.description = "Enhances rspec DSL to include `eventually` and `eventually_not`"
  s.email = ["hawk.newton@gmail.com"]
  s.homepage = "https://github.com/hawknewton/rspec-eventually"
  s.licenses = ["MIT"]
  s.rubygems_version = "2.5.1"
  s.summary = "Make your matchers match eventually"

  s.installed_by_version = "2.5.1" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<bundler>, ["~> 1.7"])
      s.add_development_dependency(%q<rake>, ["~> 10.0"])
      s.add_development_dependency(%q<rspec>, ["~> 3.2"])
      s.add_development_dependency(%q<rubocop>, ["~> 0.27.1"])
    else
      s.add_dependency(%q<bundler>, ["~> 1.7"])
      s.add_dependency(%q<rake>, ["~> 10.0"])
      s.add_dependency(%q<rspec>, ["~> 3.2"])
      s.add_dependency(%q<rubocop>, ["~> 0.27.1"])
    end
  else
    s.add_dependency(%q<bundler>, ["~> 1.7"])
    s.add_dependency(%q<rake>, ["~> 10.0"])
    s.add_dependency(%q<rspec>, ["~> 3.2"])
    s.add_dependency(%q<rubocop>, ["~> 0.27.1"])
  end
end
