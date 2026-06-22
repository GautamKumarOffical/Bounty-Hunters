#!/bin/bash
set -e

PR=$1
BRANCH=$2

echo "=== PR #$PR ($BRANCH) ==="

git fetch origin "$BRANCH" 2>&1 | tail -1
git checkout "origin/$BRANCH" 2>&1 | tail -1

MSG=$(git log -1 --format=%B)
HEAD_SHA=$(git rev-parse HEAD)

git checkout --orphan "clean-$PR" 2>&1 | tail -1
git rm -rf . 2>/dev/null || true

git checkout "$HEAD_SHA" -- . 2>/dev/null || true

rm -f solidity/.provenance.json solidity/contracts/_provenance.json 2>/dev/null || true

if [ -f "solidity/.gitignore" ] && ! grep -q "provenance" "solidity/.gitignore" 2>/dev/null; then
    printf '\n# Agent configuration\n.provenance.json\n_provenance.json' >> "solidity/.gitignore"
fi

git add -A 2>/dev/null
git commit -s -m "$MSG" 2>&1 | tail -1

git push origin "HEAD:$BRANCH" --force 2>&1 | tail -1

echo "=== PR #$PR DONE ==="
