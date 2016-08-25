# -*- encoding: utf-8 -*-
# stub: wait_until 0.3.0 ruby lib

Gem::Specification.new do |s|
  s.name = "wait_until"
  s.version = "0.3.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["Matthew Ueckerman"]
  s.date = "2016-04-18"
  s.description = "Suspends execution until state changes via ::Wait.until! methods, timing-out after a configured period of time"
  s.email = "matthew.ueckerman@myob.com"
  s.homepage = "http://github.com/MYOB-Technology/wait_until"
  s.licenses = ["MIT"]
  s.required_ruby_version = Gem::Requirement.new(">= 1.9.3")
  s.rubyforge_project = "wait_until"
  s.rubygems_version = "2.5.1"
  s.summary = "Suspends execution until state changes via ::Wait.until! methods"

  s.installed_by_version = "2.5.1" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<travis-lint>, ["~> 2.0"])
      s.add_development_dependency(%q<rspec>, ["~> 3.4"])
      s.add_development_dependency(%q<rake>, ["~> 11.1"])
      s.add_development_dependency(%q<simplecov>, ["~> 0.11"])
    else
      s.add_dependency(%q<travis-lint>, ["~> 2.0"])
      s.add_dependency(%q<rspec>, ["~> 3.4"])
      s.add_dependency(%q<rake>, ["~> 11.1"])
      s.add_dependency(%q<simplecov>, ["~> 0.11"])
    end
  else
    s.add_dependency(%q<travis-lint>, ["~> 2.0"])
    s.add_dependency(%q<rspec>, ["~> 3.4"])
    s.add_dependency(%q<rake>, ["~> 11.1"])
    s.add_dependency(%q<simplecov>, ["~> 0.11"])
  end
end
