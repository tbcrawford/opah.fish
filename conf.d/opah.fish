# 1Password Secrets Auto-loader
# This configuration file automatically loads secrets from 1Password on shell startup.
# It will use cached secrets if available, or fetch from 1Password if cache is missing.

if status --is-interactive
    # Defer loading until after the first prompt is ready.
    #
    # During Fisher startup, conf.d files are sourced inside _init_fisher while Fish
    # is still executing embedded:config.fish. At that point fish_function_path may
    # not yet include the plugin's functions directory, so Fish cannot autoload
    # helper functions like _opah_get_cache_dir even though they exist on disk.
    #
    # Binding to fish_prompt guarantees the shell is fully initialised before
    # _opah_load is called.  The handler erases itself after the first invocation so
    # there is zero overhead on subsequent prompts.
    function _opah_startup --on-event fish_prompt
        functions --erase _opah_startup

        if not _opah_load
            _opah_error "failed to load 1password secrets" >&2
            _opah_hint "run: opah status to check configuration" >&2
        end
    end
else
    # Non-interactive shells load secrets only when OPAH_AUTOLOAD=1.
    if test "$OPAH_AUTOLOAD" = 1
        _opah_load
    end
end
