#!/bin/bash
# Cleanup script to remove compiled binaries and build artifacts
# Run this before committing to keep the repository clean

echo "Cleaning up compiled binaries and build artifacts..."

# Remove compiled test binaries
echo "Removing test binaries..."
find tests/ -type f -executable -name "test_*" ! -name "*.nim" -delete 2>/dev/null
find tests/ -type f -name "test_*.exe" -delete 2>/dev/null

# Remove other compiled binaries in tests/
find tests/ -type f -executable ! -name "*.nim" ! -name "*.sh" -delete 2>/dev/null

# Remove compiled example binaries
echo "Removing example binaries..."
find examples/ -type f -executable ! -name "*.nim" ! -name "*.sh" -delete 2>/dev/null
find examples/ -type f -name "*.exe" -delete 2>/dev/null

# Remove nimcache directories
echo "Removing nimcache directories..."
find . -type d -name "nimcache" -exec rm -rf {} + 2>/dev/null

# Remove main compiled binaries
echo "Removing root-level binaries..."
rm -f nimini nimini.exe nimini.out test_all_features test_all_features.exe 2>/dev/null

# Remove object files and other artifacts
echo "Removing build artifacts..."
find . -type f -name "*.o" -delete 2>/dev/null
find . -type f -name "*.a" -delete 2>/dev/null

echo "Cleanup complete!"
