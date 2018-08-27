#!/usr/bin/env bash

if [ "$TRAVIS_NODE_VERSION" == "lts/*" ]; then
	echo "Building Docker image from the present sources..."
	echo "Removing node_modules, as it fails the build due to permissions..."
	rm -rf node_modules
	echo "Starting image build..."
	docker build -f deploy/Dockerfile-development -t servicemap .
	# Building is the only non-interactive thing that works
	# at the moment. (browser tests are rather broken)
	echo "Testing that image is capable of static build..."
	docker run --rm servicemap npm run build
fi
