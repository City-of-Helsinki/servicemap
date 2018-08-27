#!/usr/bin/env bash

TIMESTAMP_FORMAT="+%Y-%m-%d %H:%M:%S"

function _log_header() {
    _log "**************************************************************"
    _log "* $@"
    _log "**************************************************************"
}

function _log () {
    echo "$(date "$TIMESTAMP_FORMAT"): $@"
}

_log_header "Starting Docker image build for servicemap"

if [ "$TRAVIS_NODE_VERSION" != "lts/*" ]; then
    _log "Aborting: will only build on lts version of node"
    exit 0
fi


if [ "$TRAVIS_BRANCH" == "production" ]; then
	_log_header "Building in production mode"
	DOCKERFILE="Dockerfile-production"
else
	_log_header "Building in development mode"
	DOCKERFILE="Dockerfile-development"
fi

# implicitly tags the image as "servicemap:latest"
# we still need to specifically upload it as such
# if we want to publish it
docker build -f deploy/$DOCKERFILE -t servicemap .

_log_header "Docker image build finished"

REPO="helsinki/servicemap"

# First 7 chars of commit hash
COMMIT=${TRAVIS_COMMIT::7}

# Escape slashes in branch names
BRANCH=${TRAVIS_BRANCH//\//_}

# TRAVIS_PULL_REQUEST is (the string) "false" if we are not building
# a pull request. Otherwise it is the Github pull request number
if [ -n "$TRAVIS_PULL_REQUEST" -a "$TRAVIS_PULL_REQUEST" != "false" ]; then
    BASE="$REPO:pr-$TRAVIS_PULL_REQUEST"
    _log_header "Uploading PR image tagged as $BASE"
    docker tag servicemap "$BASE"
    docker tag "$BASE" "$REPO-$TRAVIS_BUILD_NUMBER"
    docker push "$BASE"
    docker push "$REPO:travis-$TRAVIS_BUILD_NUMBER"
    exit 0
fi

# We want to upload builds from master branch as "latest"
# This actually means "default" ie. what is pulled if no
# tag is specified (or pushed for that matter)
if [ -n "$COMMIT" -a "$TRAVIS_BRANCH" == "master" ] ; then
    _log_header "Uploading master branch image tagged as latest"
    docker tag servicemap "$REPO:$COMMIT"
    docker tag "$REPO:$COMMIT" "$REPO:travis-$TRAVIS_BUILD_NUMBER"
    docker push "$REPO:$COMMIT"
    docker push "$REPO:latest"
    docker push "$REPO:travis-$TRAVIS_BUILD_NUMBER"
    exit 0
fi

if [ -n "$COMMIT" -a "$TRAVIS_BRANCH" ] ; then
    _log_header "Uploading $TRAVIS_BRANCH tagged as such"
    docker tag servicemap "$REPO:$COMMIT"
    docker tag "$REPO:$COMMIT" "$REPO:$BRANCH"
    docker tag "$REPO:$COMMIT" "$REPO:travis-$TRAVIS_BUILD_NUMBER"
    docker push "$REPO:$COMMIT"
    docker push "$REPO:travis-$TRAVIS_BUILD_NUMBER"
    docker push "$REPO:$BRANCH"
    exit 0
fi

_log_header "WARNING: unexpected Travis environment found. Image was not uploaded"
