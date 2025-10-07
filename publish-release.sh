#!/bin/bash

set -e

# --- Help/Usage ---
usage() {
  echo "Usage: $0 <major|minor|patch>"
  echo "  Bumps the version from the latest git tag and creates a new tag."
  exit 1
}

# Check for argument
if [ -z "$1" ]; then
  usage
fi

# Get the latest tag, or default to v0.0.0 if no tags exist
LATEST_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "v0.0.0")

# Remove 'v' prefix
VERSION=${LATEST_TAG#v}

# Split into major, minor, patch
IFS='.' read -r -a VERSION_PARTS <<< "$VERSION"
MAJOR=${VERSION_PARTS[0]}
MINOR=${VERSION_PARTS[1]}
PATCH=${VERSION_PARTS[2]}

# Bump the version based on the argument
case "$1" in
  major)
    MAJOR=$((MAJOR + 1))
    MINOR=0
    PATCH=0
    ;;
  minor)
    MINOR=$((MINOR + 1))
    PATCH=0
    ;;
  patch)
    PATCH=$((PATCH + 1))
    ;;
  *)
    usage
    ;;
esac

# Construct the new version tag
NEW_TAG="v${MAJOR}.${MINOR}.${PATCH}"

echo "Latest tag: $LATEST_TAG"
echo "New tag:    $NEW_TAG"

# Ask for confirmation
read -p "Create and push new tag? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  echo "Creating and pushing tag $NEW_TAG..."
  git tag "$NEW_TAG"
  git push origin "$NEW_TAG"
  echo "Done."
else
  echo "Aborted."
fi