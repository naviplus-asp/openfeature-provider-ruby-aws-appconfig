# frozen_string_literal: true

require "net/http"
require "uri"
require "json"

module Openfeature
  module Provider
    module Ruby
      module Aws
        module Appconfig
          # Client for AWS AppConfig Agent HTTP API
          # Handles configuration retrieval via local AppConfig Agent endpoint
          # Provides efficient local access to AWS AppConfig configurations
          class AgentClient
            # Initializes the AppConfig Agent client
            # @param application [String] AWS AppConfig application name
            # @param environment [String] AWS AppConfig environment name
            # @param configuration_profile [String] AWS AppConfig configuration profile name
            # @param agent_endpoint [String] AppConfig Agent endpoint URL (default: "http://localhost:2772")
            # @param agent_http_client [Class] Custom HTTP client class for testing (default: Net::HTTP)
            def initialize(application:, environment:, configuration_profile:, agent_endpoint: "http://localhost:2772",
                           agent_http_client: nil)
              @application = application
              @environment = environment
              @configuration_profile = configuration_profile
              @agent_endpoint = agent_endpoint
              @agent_http_client = agent_http_client || Net::HTTP
            end

            # Retrieves configuration value for the specified flag key via AppConfig Agent
            # @param flag_key [String] The feature flag key to retrieve
            # @return [Object] The configuration value for the flag key
            # @raise [StandardError] When configuration cannot be retrieved or parsed
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

            # Creates HTTP client for the agent endpoint
            # @param uri [URI] The agent endpoint URI
            # @return [Net::HTTP] Configured HTTP client
            def create_http_client(uri)
              http = @agent_http_client.new(uri.host, uri.port)
              http.use_ssl = uri.scheme == "https"
              http
            end

            # Creates HTTP request for the agent endpoint
            # @param uri [URI] The agent endpoint URI
            # @return [Net::HTTP::Get] Configured HTTP GET request
            def create_request(uri)
              request = Net::HTTP::Get.new(uri)
              request["Content-Type"] = "application/json"
              request
            end

            # Sends HTTP request and validates response
            # @param http [Net::HTTP] The HTTP client
            # @param request [Net::HTTP::Get] The HTTP request
            # @return [Net::HTTPResponse] The HTTP response
            # @raise [Net::HTTPError] When response is not successful
            def send_request(http, request)
              response = http.request(request)
              unless response.is_a?(Net::HTTPSuccess)
                raise Net::HTTPError.new("HTTP #{response.code}: #{response.body}", response)
              end

              response
            end

            # Parses HTTP response and extracts flag value
            # @param response [Net::HTTPResponse] The HTTP response
            # @param flag_key [String] The feature flag key to extract
            # @return [Object] The configuration value for the flag key
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
