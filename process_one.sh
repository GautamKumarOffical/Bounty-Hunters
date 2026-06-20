#!/bin/bash
set -e

PR=$1
BRANCH=$2

echo "=== PR #$PR ($BRANCH) ==="

# Checkout branch
git checkout -b "work-$PR" "origin/$BRANCH" 2>&1 | tail -1

# Find provenance files
echo "Files in working tree:"
find . -name "*provenance*" -not -path "./.git/*" 2>/dev/null || true

# Check what commits touch provenance
echo "Commits with provenance:"
git log --all --oneline --name-only | grep -B1 provenance | head -10

# Remove provenance files from working tree and index
git rm --cached solidity/.provenance.json solidity/contracts/_provenance.json 2>/dev/null || true
rm -f solidity/.provenance.json solidity/contracts/_provenance.json 2>/dev/null || true

# Add to gitignore
GITIGNORE="solidity/.gitignore"
if [ -f "$GITIGNORE" ] && ! grep -q "provenance" "$GITIGNORE" 2>/dev/null; then
    echo -e "\n# Agent configuration\n.provenance.json\n_provenance.json" >> "$GITIGNORE"
fi

git add -A 2>/dev/null

# Check if there are changes to commit
if git diff --cached --quiet 2>/dev/null; then
    echo "No staged changes - provenance was only in parent commit"
    # Need to remove from parent commit too - use filter-branch on just the range
    # Actually let's just add a commit that removes the file
    git checkout HEAD -- . 2>/dev/null || true
    git rm --cached solidity/.provenance.json solidity/contracts/_provenance.json 2>/dev/null || true
    rm -f solidity/.provenance.json solidity/contracts/_provenance.json 2>/dev/null || true
    git add -A 2>/dev/null
    if [ ! -f "$GITIGNORE" ] || ! grep -q "provenance" "$GITIGNORE" 2>/dev/null; then
        echo -e "\n# Agent configuration\n.provenance.json\n_provenance.json" >> "$GITIGNORE"
        git add "$GITIGNORE"
    fi
    git commit -s -m "chore: remove .provenance.json and add to gitignore" 2>&1 | tail -1
else
    # Amend the HEAD commit to remove the file
    git commit --amend --no-edit -s 2>&1 | tail -1
fi

# Verify
echo "Post-check:"
find . -name "*provenance*" -not -path "./.git/*" 2>/dev/null || echo "  No provenance files in working tree"

# Force push
git push origin "work-$PR:$BRANCH" --force 2>&1 | tail -1

echo "=== PR #$PR DONE ==="
