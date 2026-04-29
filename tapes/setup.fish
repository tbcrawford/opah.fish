# Setup script for VHS demo recording.
# Sources opah functions directly (no fisher install required) and mocks the
# 1Password CLI so the tape runs without a real 1Password account.

# Load opah functions from the local repo
for f in functions/*.fish
    source $f
end
_opah_ui

# Mock 1Password CLI as a real executable so `command -q op` finds it
set -l _opah_mock_dir (mktemp -d)
printf '#!/bin/sh
case "$1" in
  --version) echo "2.26.1" ;;
  account)   echo '"'"'[{"email":"demo@example.com"}]'"'"' ;;
  read)      echo "mock_secret_value" ;;
  *)         exit 1 ;;
esac
' >"$_opah_mock_dir/op"
chmod +x "$_opah_mock_dir/op"
set -gx PATH "$_opah_mock_dir" $PATH

# Create a demo config file in a temp directory — never touch the real one
set -g _opah_demo_config_dir (mktemp -d)
printf "secrets:\n  API_KEY: op://Work/Keys/api_key\n  DATABASE_URL: op://Work/DB/url\n  GITHUB_TOKEN: op://Work/GitHub/token\n" >"$_opah_demo_config_dir/secrets.yaml"

# Override config path lookup so opah finds the demo file instead of the real one
function _opah_get_config_paths
    echo "$_opah_demo_config_dir/secrets.yaml"
end

# Start with a clean cache so refresh runs live in the recording
rm -f (_opah_get_cache_file)
