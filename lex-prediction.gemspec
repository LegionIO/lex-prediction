# frozen_string_literal: true

require_relative 'lib/legion/extensions/prediction/version'

Gem::Specification.new do |spec|
  spec.name          = 'lex-prediction'
  spec.version       = Legion::Extensions::Prediction::VERSION
  spec.authors       = ['Esity']
  spec.email         = ['matthewdiverson@gmail.com']

  spec.summary       = 'LEX Prediction'
  spec.description   = 'Forward-model prediction engine (4 reasoning modes) for brain-modeled agentic AI'
  spec.homepage      = 'https://github.com/LegionIO/lex-prediction'
  spec.license       = 'MIT'
  spec.required_ruby_version = '>= 3.4'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/LegionIO/lex-prediction'
  spec.metadata['documentation_uri'] = 'https://github.com/LegionIO/lex-prediction'
  spec.metadata['changelog_uri'] = 'https://github.com/LegionIO/lex-prediction'
  spec.metadata['bug_tracker_uri'] = 'https://github.com/LegionIO/lex-prediction/issues'
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir.glob('{lib,spec}/**/*') + %w[lex-prediction.gemspec Gemfile]
  end
  spec.require_paths = ['lib']
end
