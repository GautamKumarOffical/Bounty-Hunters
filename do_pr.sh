#!/bin/bash
set -e

PR=$1
BRANCH=$2

echo "=== PR #$PR ($BRANCH) ==="

# Fetch and checkout
git fetch origin "$BRANCH" 2>&1 | tail -1
git checkout "origin/$BRANCH" 2>&1 | tail -1

MSG=$(git log -1 --format=%B)
HEAD_SHA=$(git rev-parse HEAD)
PARENT_SHA=$(git rev-parse HEAD^)

# Remove provenance files
git rm --cached solidity/.provenance.json 2>/dev/null || true
git rm --cached solidity/contracts/_provenance.json 2>/dev/null || true
rm -f solidity/.provenance.json solidity/contracts/_provenance.json 2>/dev/null || true

# Add to gitignore if needed
if [ -f "solidity/.gitignore" ] && ! grep -q "provenance" "solidity/.gitignore" 2>/dev/null; then
    printf '\n# Agent configuration\n.provenance.json\n_provenance.json' >> "solidity/.gitignore"
fi

git add -A 2>/dev/null

if ! git diff --cached --quiet 2>/dev/null; then
    # There are staged changes from removing provenance - amend the commit
    git commit --amend --no-edit -s 2>&1 | tail -1
    echo "Amended commit to remove .provenance.json"
else
    echo "No changes to amend (provenance not in HEAD commit)"
fi

# Force push
git push origin "HEAD:$BRANCH" --force 2>&1 | tail -1

echo "=== PR #$PR DONE ==="
