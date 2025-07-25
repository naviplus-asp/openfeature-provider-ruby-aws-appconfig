# frozen_string_literal: true

require_relative "appconfig/provider"
require_relative "appconfig/localstack_helper"
require_relative "appconfig/version"

module Openfeature
  module Provider
    module Ruby
      module Aws
        # AWS AppConfig integration module for OpenFeature
        # Provides functionality to use AWS AppConfig as a feature flag provider
        module Appconfig
          class Error < StandardError; end

          # Convenience method to create a new provider
          def self.create_provider(config = {})
            Provider.new(config)
          end
        end
      end
    end
  end
end
