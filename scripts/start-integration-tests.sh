#!/bin/bash

# Integration test setup script for OpenFeature AWS AppConfig Provider

set -e

echo "=== OpenFeature AWS AppConfig Provider Integration Test Setup ==="
echo

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker and try again."
    exit 1
fi

# Function to check if a port is available
check_port() {
    local port=$1
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
        echo "❌ Port $port is already in use. Please stop the service using this port and try again."
        exit 1
    fi
}

# Check if ports are available
echo "Checking port availability..."
check_port 2772
check_port 2773
echo "✅ Ports are available"

# Ask user which mode to use
echo
echo "Choose integration test mode:"
echo "1) Real AppConfig Agent (requires AWS credentials)"
echo "2) Mock server (no AWS credentials required)"
echo "3) Exit"
echo
read -p "Enter your choice (1-3): " choice

case $choice in
    1)
        echo
        echo "=== Starting Real AppConfig Agent ==="

        # Check if AWS credentials are available
        if [ -z "$AWS_ACCESS_KEY_ID" ] || [ -z "$AWS_SECRET_ACCESS_KEY" ]; then
            echo "❌ AWS credentials not found in environment variables."
            echo "Please set the following environment variables:"
            echo "  AWS_REGION"
            echo "  AWS_ACCESS_KEY_ID"
            echo "  AWS_SECRET_ACCESS_KEY"
            echo "  AWS_SESSION_TOKEN (optional)"
            echo
            echo "You can also create a .env file in the docker directory with these values."
            exit 1
        fi

        echo "✅ AWS credentials found"

        # Start the real AppConfig Agent
        docker-compose up -d appconfig-agent

        echo "⏳ Waiting for AppConfig Agent to start..."
        sleep 10

        # Check if agent is responding
        if curl -f http://localhost:2772/applications/test-integration-app/environments/test-integration-env/configurations/test-integration-profile > /dev/null 2>&1; then
            echo "✅ AppConfig Agent is running and responding"
        else
            echo "⚠️  AppConfig Agent is running but may not have the test configuration deployed"
            echo "Please ensure the following configuration is deployed in AWS AppConfig:"
            echo "  - Application: test-integration-app"
            echo "  - Environment: test-integration-env"
            echo "  - Configuration Profile: test-integration-profile"
            echo "  - Configuration data: See test/integration_test_helper.rb"
        fi
        ;;

    2)
        echo
        echo "=== Starting Mock AppConfig Server ==="

        # Start the mock server
        docker-compose -f docker-compose.mock.yml up -d

        echo "⏳ Waiting for mock server to start..."
        sleep 5

        # Check if mock server is responding
        if curl -f http://localhost:2772/applications/test-integration-app/environments/test-integration-env/configurations/test-integration-profile > /dev/null 2>&1; then
            echo "✅ Mock server is running and responding"
        else
            echo "❌ Mock server failed to start properly"
            exit 1
        fi
        ;;

    3)
        echo "Exiting..."
        exit 0
        ;;

    *)
        echo "Invalid choice. Please run the script again."
        exit 1
        ;;
esac

echo
echo "=== Integration Test Environment Ready ==="
echo
echo "You can now run integration tests:"
echo "  bundle exec rake test_integration"
echo
echo "Or run the integration test example:"
echo "  ruby examples/integration_test_example.rb"
echo
echo "To stop the services:"
echo "  docker-compose down"
echo "  # or for mock server:"
echo "  docker-compose -f docker-compose.mock.yml down"
