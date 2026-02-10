#!/bin/bash

# FlowForge Git Initialization Script
# Run this after creating your Xcode project

echo "🎵 Initializing Git for FlowForge..."

# Initialize git repository
git init

# Add all files
git add .

# Create initial commit
git commit -m "Initial commit: FlowForge project structure

- Added README.md with development roadmap
- Added BRAINSTORM.md for ideas and experiments
- Added QUICKSTART.md for rapid prototyping
- Added .gitignore for Xcode
- Project ready for Phase 0 development"

echo "✅ Git initialized!"
echo ""
echo "Next steps:"
echo "1. Create Xcode project"
echo "2. Run: git add ."
echo "3. Run: git commit -m 'Add Xcode project'"
echo ""
echo "Optional: Create GitHub repo and push:"
echo "  git remote add origin <your-repo-url>"
echo "  git branch -M main"
echo "  git push -u origin main"
