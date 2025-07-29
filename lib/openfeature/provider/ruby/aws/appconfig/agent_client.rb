# frozen_string_literal: true

require "net/http"
require "uri"
require "json"

module Openfeature
  module Provider
    module Ruby
      module Aws
        module Appconfig
          class AgentClient
            def initialize(application:, environment:, configuration_profile:, agent_endpoint: "http://localhost:2772",
                           agent_http_client: nil)
              @application = application
              @environment = environment
              @configuration_profile = configuration_profile
              @agent_endpoint = agent_endpoint
              @agent_http_client = agent_http_client || Net::HTTP
            end

            def get_configuration(flag_key)
              uri = build_agent_uri
              http = create_http_client(uri)
              request = create_request(uri)
              response = send_request(http, request)
              parse_response(response, flag_key)
            rescue Net::HTTPError => e
              raise StandardError, "Agent HTTP error: #{e.message}"
            rescue JSON::ParserError => e
              raise StandardError, "Failed to parse agent response: #{e.message}"
            end

            private

            def create_http_client(uri)
              http = @agent_http_client.new(uri.host, uri.port)
              http.use_ssl = uri.scheme == "https"
              http
            end

            def create_request(uri)
              request = Net::HTTP::Get.new(uri)
              request["Content-Type"] = "application/json"
              request
            end

            def send_request(http, request)
              response = http.request(request)
              unless response.is_a?(Net::HTTPSuccess)
                raise Net::HTTPError.new("HTTP #{response.code}: #{response.body}", response)
              end

              response
            end

            def parse_response(response, flag_key)
              config_data = JSON.parse(response.body)
              config_data[flag_key]
            end

            # Builds the URI for AppConfig Agent API
            # @return [URI] The agent API URI
            def build_agent_uri
              path = "/applications/#{@application}/environments/#{@environment}/" \
                     "configurations/#{@configuration_profile}"
              URI.parse("#{@agent_endpoint}#{path}")
            end
          end
        end
      end
    end
  end
end
