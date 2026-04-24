# Regression tests for the GitHub CI workflow.

set repo_root (path dirname (status dirname))
set workflow_file "$repo_root/.github/workflows/ci.yml"
set release_workflow "$repo_root/.github/workflows/release.yml"

function workflow_text -a file
    if test -f "$file"
        string collect <"$file"
    end
end

function workflow_contents
    workflow_text "$workflow_file"
end

function workflow_has_line -a expected_line
    if test -f "$workflow_file"
        if contains -- "$expected_line" (string split \n -- (workflow_contents))
            echo ok
        else
            echo missing
        end
    else
        echo missing
    end
end

function file_matches -a file pattern
    if test -f "$file"
        if string match -rq -- "$pattern" -- (string collect <"$file")
            echo ok
        else
            echo missing
        end
    else
        echo missing
    end
end

function workflow_matches -a pattern
    file_matches "$workflow_file" "$pattern"
end

function file_has_top_level_key -a file key
    file_matches "$file" "(?m)^$key:"
end

function workflow_has_top_level_key -a key
    file_has_top_level_key "$workflow_file" "$key"
end

@test "ci workflow: file exists" \
    (begin
        if test -f "$workflow_file"
            echo ok
        else
            echo missing
        end
    end) = ok

@test "ci workflow: uses a literal top-level on key" \
    (workflow_has_top_level_key on) = ok

@test "ci workflow: defines the ci job" \
    (workflow_matches '(?m)^  ci:$') = ok

@test "ci workflow: includes push trigger" \
    (workflow_has_line '  push:') = ok

@test "ci workflow: includes pull_request trigger" \
    (workflow_has_line '  pull_request:') = ok

@test "ci workflow: install fish step exists" \
    (workflow_has_line '      - name: Install fish') = ok

@test "ci workflow: install fish step installs fish" \
    (workflow_has_line '        run: sudo apt-get update && sudo apt-get install -y fish') = ok

@test "ci workflow: install fisher runs in fish" \
    (workflow_matches '(?ms)^      - name: Install fisher\n        shell: fish \{0\}\n        run: .*fisher install jorgebucaran/fisher$') = ok

@test "ci workflow: install fishtape runs in fish" \
    (workflow_matches '(?ms)^      - name: Install fishtape\n        shell: fish \{0\}\n        run: fisher install jorgebucaran/fishtape$') = ok

@test "ci workflow: runs just lint" \
    (workflow_has_line '        run: just lint') = ok

@test "ci workflow: run lint step uses fish" \
    (workflow_matches '(?ms)^      - name: Run lint\n        shell: fish \{0\}\n        run: just lint$') = ok

@test "ci workflow: runs just test" \
    (workflow_has_line '        run: just test') = ok

@test "ci workflow: run tests step uses fish" \
    (workflow_matches '(?ms)^      - name: Run tests\n        shell: fish \{0\}\n        run: just test$') = ok

@test "workflow helper: matches a literal top-level on key" \
    (begin
        set sample_file (mktemp)
        printf 'name: CI\non:\n  push:\n' >$sample_file
        set result (file_has_top_level_key $sample_file on)
        rm -f $sample_file
        echo $result
    end) = ok

@test "release workflow: file exists" \
    (begin
        if test -f "$release_workflow"
            echo ok
        else
            echo missing
        end
    end) = ok

@test "release workflow: uses a literal top-level on key" \
    (file_has_top_level_key "$release_workflow" on) = ok

@test "release workflow: triggers on v tags" \
    (begin
        set -l lines (string split \n -- (workflow_text "$release_workflow"))
        contains -- '    tags:' $lines
        and contains -- "      - 'v*'" $lines
        echo $status
    end) -eq 0

@test "release workflow: grants contents write permission" \
    (file_matches "$release_workflow" '(?m)^permissions:\n  contents: write$') = ok

@test "release workflow: runs just ci before publishing" \
    (file_matches "$release_workflow" '(?ms)^      - name: Run CI checks\n        shell: fish \{0\}\n        run: just ci$') = ok

@test "release workflow: creates tar.gz and zip archives in dist" \
    (file_matches "$release_workflow" '(?ms)^      - name: Create release archives\n        run: \|\n          mkdir -p dist\n          git archive --format=tar\.gz --prefix="opah\.fish-\$\{GITHUB_REF_NAME\}/" -o "dist/opah\.fish-\$\{GITHUB_REF_NAME\}\.tar\.gz" HEAD\n          git archive --format=zip --prefix="opah\.fish-\$\{GITHUB_REF_NAME\}/" -o "dist/opah\.fish-\$\{GITHUB_REF_NAME\}\.zip" HEAD$') = ok

@test "release workflow: publishes dist archives with GitHub release action" \
    (file_matches "$release_workflow" '(?ms)^      - name: Publish GitHub Release\n        uses: softprops/action-gh-release@v2\n        with:\n          generate_release_notes: true\n          files: \|\n            dist/\*\.tar\.gz\n            dist/\*\.zip$') = ok
