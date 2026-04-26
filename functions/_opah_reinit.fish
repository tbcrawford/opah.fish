#
# Re-initialize the plugin after authentication changes.
# Clears cache, verifies auth, and reloads all secrets.
#
function _opah_reinit -d "Re-initialize plugin after authentication changes"
    if contains -- --help $argv; or contains -- -h $argv
        _opah_section Usage
        printf "  %sopah reinit%s\n" $__OPAH_COLOR_BOLD $__OPAH_COLOR_RESET
        _opah_section Examples
        printf "  %sopah reinit    # clear cache and reload all secrets%s\n" \
            $__OPAH_COLOR_DIM $__OPAH_COLOR_RESET
        return 0
    end

    # Step 1: Clear Cache
    _opah_section "Step 1  Clear Cache"
    _opah_clear --quiet 2>/dev/null
    or begin
        # _opah_clear handles its own output; just proceed
        true
    end

    # Step 2: Authenticate
    _opah_section "Step 2  Authenticate"
    if command -q op
        set -l accounts (op account list --format=json 2>/dev/null)
        if test -n "$accounts"; and test "$accounts" != "[]"
            _opah_success "Already signed in"
        else
            _opah_info "Signing in to 1password..."
            if not op signin 2>/dev/null
                _opah_error "Could not sign in to 1password"
                _opah_hint "run: op signin manually then retry opah reinit"
                return 1
            end
            _opah_success "Signed in"
        end
    else
        _opah_error "op is not installed"
        _opah_hint "install from: https://developer.1password.com/docs/cli/get-started/"
        return 1
    end

    # Step 3: Load Secrets
    _opah_section "Step 3  Load Secrets"
    if not _opah_load --force
        _opah_error "Could not reload secrets"
        _opah_hint "run: opah doctor to diagnose"
        return 1
    end

    _opah_section Summary
    _opah_success "Reinitialization complete"
    _opah_hint "run: opah status to verify loaded secrets"
end
