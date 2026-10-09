#!/usr/bin/env bash
# One-command release: bumps the version, tags it and pushes.
# GitHub Actions then builds the APK and publishes it to Releases.
#
# Usage: ./scripts/release.sh [patch|minor|major|X.Y.Z]   (default: patch)
set -euo pipefail
cd "$(dirname "$0")/.."

BUMP="${1:-patch}"

if [ -n "$(git status --porcelain)" ]; then
  echo "Commit or stash your changes first."
  exit 1
fi

git checkout main
git pull --ff-only
git fetch --tags --quiet

PUB=$(grep -E '^version:' pubspec.yaml | sed -E 's/version:[[:space:]]*([0-9]+\.[0-9]+\.[0-9]+).*/\1/')
LATEST_TAG=$(git tag -l 'v[0-9]*' | sed 's/^v//' | sort -V | tail -n1)
CUR=$(printf '%s\n%s\n' "$PUB" "${LATEST_TAG:-0.0.0}" | sort -V | tail -n1)
IFS=. read -r MA MI PA <<< "$CUR"

case "$BUMP" in
  patch) PA=$((PA + 1)) ;;
  minor) MI=$((MI + 1)); PA=0 ;;
  major) MA=$((MA + 1)); MI=0; PA=0 ;;
  *)
    if [[ "$BUMP" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
      IFS=. read -r MA MI PA <<< "$BUMP"
    else
      echo "Use: patch | minor | major | X.Y.Z"
      exit 1
    fi
    ;;
esac

NEW="$MA.$MI.$PA"
CODE=$((MA * 10000 + MI * 100 + PA))

if git rev-parse "v$NEW" >/dev/null 2>&1; then
  echo "Tag v$NEW already exists."
  exit 1
fi

sed -i.bak -E "s/^version:.*/version: $NEW+$CODE/" pubspec.yaml
rm -f pubspec.yaml.bak

git add pubspec.yaml
git commit -m "chore(release): v$NEW"
git tag "v$NEW"
git push origin main "v$NEW"

echo "Released v$NEW. Watch the build: https://github.com/krut-tech/KishanSetu/actions"
