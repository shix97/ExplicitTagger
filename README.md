cd ~/Documents/Claude/Projects/ExplicitApp/AdvisoryTagger

# Create the .gitignore
cat > .gitignore << 'EOF'
.build/
.build-arm64/
.build-x86_64/
ExplicitTagger.app/
*.o
*.d
.DS_Store
EOF

# Initialize and push
git init
git add .
git commit -m "Initial commit — ExplicitTagger 1.1"
git branch -M main
git remote add origin https://github.com/shix97/ExplicitTagger.git
git push -u origin main