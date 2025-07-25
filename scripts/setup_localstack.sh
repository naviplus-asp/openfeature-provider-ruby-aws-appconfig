#!/bin/bash

# LocalStack setup script for OpenFeature AWS AppConfig Provider

set -e

echo "🚀 Setting up LocalStack for OpenFeature AWS AppConfig Provider..."

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker and try again."
    exit 1
fi

# Check if Docker Compose is available
if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose is not installed. Please install Docker Compose and try again."
    exit 1
fi

# Start LocalStack
echo "📦 Starting LocalStack..."
docker-compose up -d localstack

# Wait for LocalStack to be ready
echo "⏳ Waiting for LocalStack to be ready..."
timeout=60
counter=0
while [ $counter -lt $timeout ]; do
    if curl -s http://localhost:4566/_localstack/health > /dev/null 2>&1; then
        echo "✅ LocalStack is ready!"
        break
    fi
    echo "   Waiting... ($counter/$timeout)"
    sleep 1
    counter=$((counter + 1))
done

if [ $counter -eq $timeout ]; then
    echo "❌ LocalStack failed to start within $timeout seconds"
    exit 1
fi

# Test AWS AppConfig service
echo "🧪 Testing AWS AppConfig service..."
aws --endpoint-url=http://localhost:4566 appconfig list-applications > /dev/null 2>&1 || {
    echo "⚠️  AWS CLI test failed. Make sure you have AWS CLI installed and configured."
    echo "   You can still run the integration tests using Docker Compose."
}

echo "🎉 LocalStack setup complete!"
echo ""
echo "📋 Next steps:"
echo "   1. Run unit tests: bundle exec rake test:unit"
echo "   2. Run integration tests: bundle exec rake test:integration"
echo "   3. Run all tests with Docker: docker-compose up test-runner"
echo "   4. Stop LocalStack: docker-compose down"
echo ""
echo "🔗 LocalStack endpoint: http://localhost:4566"
