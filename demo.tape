# VHS tape file for 1password-secrets.fish demo
# Showcases key features and workflow

Output demo.gif

Set Shell fish
Set FontSize 16
Set Width 1200
Set Height 700
Set TypingSpeed 40ms

# Initialize Fish with proper function paths
Hide
Type "set fish_function_path ~/.config/fish/.fisher/functions $fish_function_path"
Enter
Type "source ~/.config/fish/.fisher/functions/opah.fish"
Enter
Show

# Title
Type "# 🐠 1password-secrets.fish Demo"
Sleep 1.5s
Enter 2

# 1. Show configuration format
Type "# 1️⃣  View secrets.yaml configuration"
Enter
Sleep 500ms
Type "cat ~/.config/fish/secrets.yaml"
Enter
Sleep 2.5s
Ctrl+L

# 2. Check status
Type "# 2️⃣  Check secrets status"
Enter
Sleep 500ms
Type "opah status"
Enter
Sleep 3s
Ctrl+L

# 3. Show config validation
Type "# 3️⃣  Validate configuration"
Enter
Sleep 500ms
Type "opah config"
Enter
Sleep 4s
Ctrl+L

# 4. Run diagnostics
Type "# 4️⃣  Run comprehensive diagnostics"
Enter
Sleep 500ms
Type "opah doctor"
Enter
Sleep 5s
Ctrl+L

# 5. Refresh specific secret
Type "# 5️⃣  Refresh a specific secret"
Enter
Sleep 500ms
Type "opah refresh NEXUS_HOST"
Enter
Sleep 2.5s
Ctrl+L

# 6. Show help
Type "# 6️⃣  Available commands"
Enter
Sleep 500ms
Type "opah --help"
Enter
Sleep 3s
Ctrl+L

# Final summary
Type "# ✨ Key Features:"
Enter
Type "# • 🔐 Automatic secret loading on startup"
Enter
Type "# • 💾 Intelligent caching"
Enter
Type "# • ⚡ Selective refresh"
Enter
Type "# • 🔍 Comprehensive diagnostics"
Enter
Type "# • 🎨 Beautiful CLI with tab completion"
Enter
Sleep 3s
