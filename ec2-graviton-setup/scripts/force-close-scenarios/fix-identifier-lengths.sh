#!/bin/bash

# Quick fix for identifier length issues in all force close scenario scripts

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Fixing identifier lengths in all force close scenario scripts..."

# Fix all TEST-FC-* identifiers to be shorter
for file in "$SCRIPT_DIR"/force-close-scenario-*.sh; do
    if [[ -f "$file" ]]; then
        echo "Fixing $file..."
        
        # Replace long identifiers with shorter ones
        sed -i '' 's/TEST-FC-PR/FC-PR/g' "$file"
        sed -i '' 's/TEST-FC-DR/FC-DR/g' "$file"
        sed -i '' 's/TEST-FC-PO/FC-PO/g' "$file"
        
        echo "✓ Fixed $(basename "$file")"
    fi
done

echo "✅ All identifier lengths fixed!"
echo "PR numbers, DR numbers, and PO numbers are now within database limits"
