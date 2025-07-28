# frozen_string_literal: true

require_relative "lib/openfeature/provider/ruby/aws/appconfig/version"

Gem::Specification.new do |spec|
  spec.name = "openfeature-provider-ruby-aws-appconfig"
  spec.version = Openfeature::Provider::Ruby::Aws::Appconfig::VERSION
  spec.authors = ["Takahashi Masaki"]
  spec.email = ["masaki-takahashi@dgbt.jp"]

  spec.summary = "OpenFeature provider for AWS AppConfig integration"
  spec.description = "A Ruby provider for OpenFeature that integrates with AWS AppConfig for feature flag management"
  spec.homepage = "https://github.com/naviplus-asp/openfeature-provider-ruby-aws-appconfig"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.1.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/naviplus-asp/openfeature-provider-ruby-aws-appconfig"
  spec.metadata["changelog_uri"] = "https://github.com/naviplus-asp/openfeature-provider-ruby-aws-appconfig/blob/main/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # OpenFeature SDK dependency
  spec.add_dependency "openfeature-sdk", "~> 0.1"

  # AWS SDK dependency for AppConfig integration
  spec.add_dependency "aws-sdk-appconfig", "~> 1.0"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
