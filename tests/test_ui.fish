# Unit tests for _opah_ui.fish output primitives.
# Strips ANSI escape codes before asserting text content.

set repo_root (path dirname (status dirname))
set functions_dir "$repo_root/functions"

function run_ui -a script_body
    fish --no-config -C "set fish_function_path $functions_dir \$fish_function_path" \
        -c "$script_body" 2>&1 \
        | string replace --all --regex '\x1b\[[0-9;]*m' ''
end

@test "_opah_success prints bullet and message" \
    (run_ui '_opah_success "op is installed"') \
    = " ● op is installed"

@test "_opah_success prints detail line when provided" \
    (run_ui '_opah_success "op is installed" "version 2.26.1"' | string collect) \
    = " ● op is installed
     version 2.26.1"

@test "_opah_error prints X and message" \
    (run_ui '_opah_error "cache not found"') \
    = " ✕ cache not found"

@test "_opah_error prints detail line when provided" \
    (run_ui '_opah_error "cache not found" "run: opah refresh"' | string collect) \
    = " ✕ cache not found
     run: opah refresh"

@test "_opah_warning prints triangle and message" \
    (run_ui '_opah_warning "permissions should be 600"') \
    = " ▲ permissions should be 600"

@test "_opah_info prints diamond and message" \
    (run_ui '_opah_info "3 secrets defined"') \
    = " ◆ 3 secrets defined"

@test "_opah_section prints title with leading blank line" \
    (run_ui '_opah_section "Cache"' | string collect) \
    = "
Cache"

@test "_opah_hint prints indented dim text" \
    (run_ui '_opah_hint "run: opah refresh"') \
    = "     run: opah refresh"

@test "_opah_header prints opah and separator" \
    (run_ui '_opah_header' | string collect | string match -r 'opah') \
    = opah
