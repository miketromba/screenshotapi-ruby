require_relative "lib/screenshotapi/version"

Gem::Specification.new do |spec|
  spec.name          = "screenshotapi_to"
  spec.version       = ScreenshotAPI::VERSION
  spec.authors       = ["ScreenshotAPI"]
  spec.email         = ["support@screenshotapi.to"]
  spec.summary       = "Official Ruby SDK for ScreenshotAPI"
  spec.description   = "Capture website screenshots with the ScreenshotAPI service. Simple, fast, and reliable."
  spec.homepage      = "https://screenshotapi.to"
  spec.license       = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata = {
    "allowed_push_host" => "https://rubygems.org",
    "bug_tracker_uri" => "https://github.com/miketromba/screenshotapi-ruby/issues",
    "changelog_uri" => "https://github.com/miketromba/screenshotapi-ruby/blob/main/CHANGELOG.md",
    "documentation_uri" => "https://screenshotapi.to/docs/sdks/ruby",
    "homepage_uri" => spec.homepage,
    "rubygems_mfa_required" => "true",
    "source_code_uri" => "https://github.com/miketromba/screenshotapi-ruby"
  }

  spec.files = Dir.chdir(__dir__) do
    Dir[
      "CHANGELOG.md",
      "LICENSE",
      "README.md",
      "examples/**/*.rb",
      "lib/**/*.rb"
    ]
  end
  spec.require_paths = ["lib"]

  spec.add_development_dependency "minitest", "~> 5.16"
  spec.add_development_dependency "rake", "~> 13.0"
end
