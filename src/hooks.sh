xgit_hooks_install() {
    local hooks_dir
    hooks_dir=".git/hooks"

    if [ ! -d "$hooks_dir" ]; then
        echo "Error: not a git repository (.git/hooks not found)"
        exit 1
    fi

    local hook_script
    hook_script='#!/usr/bin/env sh

if [ "$XGIT_ACTIVE" != "1" ]; then
    echo "This repository is managed by xgit."
    echo "Use xgit instead of raw git."
    echo ""
    echo "Commands available:"
    echo "  xgit status"
    echo "  xgit add <files>"
    echo "  xgit commit -m \"message\""
    echo "  xgit push"
    echo "  xgit pull"
    echo "  xgit log"
    echo "  xgit shell"
    exit 1
fi
'

    local hooks
    hooks="pre-commit commit-msg pre-push pre-rebase prepare-commit-msg post-commit post-checkout post-merge"

    for hook in $hooks; do
        echo "$hook_script" > "$hooks_dir/$hook"
        chmod +x "$hooks_dir/$hook"
    done

    echo "xgit hooks installed successfully."
}

xgit_hooks_verify() {
    if [ ! -f ".git/hooks/pre-commit" ]; then
        xgit_hooks_install
        return 0
    fi

    if ! grep -q "XGIT_ACTIVE" ".git/hooks/pre-commit" 2>/dev/null; then
        xgit_hooks_install
    fi
}
