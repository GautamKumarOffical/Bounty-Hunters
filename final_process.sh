#!/bin/bash
set -e

PR=$1
BRANCH=$2
MODE=$3  # "amend" or "rebuild"

echo "=== PR #$PR ($BRANCH) mode=$MODE ==="

# Get original commit message
git checkout "origin/$BRANCH" 2>&1 | tail -1
MSG=$(git log -1 --format=%B)
HEAD_SHA=$(git rev-parse HEAD)
PARENT_SHA=$(git rev-parse HEAD^)

if [ "$MODE" = "amend" ]; then
    # Provenance is in HEAD commit - just amend to remove it
    git rm --cached solidity/.provenance.json 2>/dev/null || true
    rm -f solidity/.provenance.json
    
    # Add to gitignore
    if [ -f "solidity/.gitignore" ] && ! grep -q "provenance" "solidity/.gitignore" 2>/dev/null; then
        echo -e "\n# Agent configuration\n.provenance.json\n_provenance.json" >> "solidity/.gitignore"
    fi
    
    git add -A 2>/dev/null
    git commit --amend --no-edit -s 2>&1 | tail -1
    
    echo "Amended HEAD to remove .provenance.json"
    
else
    # Rebuild: provenance is in parent - create clean branch
    git checkout --orphan "rebuild-$PR" 2>&1 | tail -1
    git rm -rf . 2>/dev/null || true
    
    # Get tree from HEAD (includes all files)
    git checkout "$HEAD_SHA" -- . 2>/dev/null || true
    
    # Remove provenance files
    rm -f solidity/.provenance.json solidity/contracts/_provenance.json
    
    # Add to gitignore  
    if [ -f "solidity/.gitignore" ] && ! grep -q "provenance" "solidity/.gitignore" 2>/dev/null; then
        echo -e "\n# Agent configuration\n.provenance.json\n_provenance.json" >> "solidity/.gitignore"
    fi
    
    git add -A 2>/dev/null
    
    # Use the same commit message
    git commit -s -m "$MSG" 2>&1 | tail -1
    
    echo "Rebuilt commit without .provenance.json"
fi

# Verify
echo "Verification:"
find . -name "*provenance*" -not -path "./.git/*" 2>/dev/null || echo "  No provenance files in working tree"

# Force push
git push origin "HEAD:$BRANCH" --force 2>&1 | tail -1

echo "=== PR #$PR DONE ==="
