# frozen_string_literal: true

require_relative "appconfig/version"
require_relative "appconfig/provider"

module Openfeature
  module Provider
    module Ruby
      module Aws
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
