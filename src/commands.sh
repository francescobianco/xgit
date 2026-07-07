xgit_commands_clone() {
    local repo_url
    repo_url="$1"
    local target_dir
    target_dir="$2"

    if [ -z "$repo_url" ]; then
        echo "Usage: xgit clone <repository-url> [target-directory]"
        echo ""
        echo "Examples:"
        echo "  xgit clone git@github.com:user/repo.git"
        echo "  xgit clone git@github.com:user/repo.git my-project"
        exit 1
    fi

    xgit_config_ensure_dirs

    echo "=== xgit clone ==="
    echo "Repository: $repo_url"
    echo ""

    echo "Select Git identity:"
    echo ""
    echo "  1) Use existing identity"
    echo "  2) Create new identity"
    echo ""

    local choice
    echo -n "Choice [1-2]: "
    read choice

    local identity_label
    local identity_name
    local identity_email

    case "$choice" in
        1)
            xgit_commands_clone_with_existing_identity "$repo_url" "$target_dir"
            ;;
        2)
            xgit_commands_clone_with_new_identity "$repo_url" "$target_dir"
            ;;
        *)
            echo "Error: invalid choice."
            exit 1
            ;;
    esac
}

xgit_commands_clone_with_existing_identity() {
    local repo_url
    repo_url="$1"
    local target_dir
    target_dir="$2"

    echo ""
    echo "Available identities:"
    echo ""

    if ! xgit_config_list_identities; then
        echo ""
        echo "No identities configured. Creating a new one."
        xgit_commands_clone_with_new_identity "$repo_url" "$target_dir"
        return
    fi

    echo ""
    echo -n "Select identity number: "
    local idx
    read idx

    local identity_label
    identity_label=$(xgit_config_get_identity_label_by_index "$idx")

    if [ -z "$identity_label" ]; then
        echo "Error: invalid identity selection."
        exit 1
    fi

    local info
    info=$(xgit_config_get_identity_info "$identity_label")
    local identity_name
    identity_name="${info%%|*}"
    local identity_email
    identity_email="${info##*|}"

    echo ""
    echo "Using identity: $identity_label <$identity_email>"
    echo ""

    xgit_commands_clone_execute "$repo_url" "$target_dir" "$identity_label" "$identity_name" "$identity_email"
}

xgit_commands_clone_with_new_identity() {
    local repo_url
    repo_url="$1"
    local target_dir
    target_dir="$2"

    echo ""
    echo -n "Identity label (e.g. anonymous-01): "
    local identity_label
    read identity_label

    if [ -z "$identity_label" ]; then
        echo "Error: identity label cannot be empty."
        exit 1
    fi

    if xgit_config_identity_exists "$identity_label"; then
        echo "Error: identity '$identity_label' already exists."
        echo "Choose a different label or use existing identity option."
        exit 1
    fi

    echo -n "Git user.name: "
    local identity_name
    read identity_name

    if [ -z "$identity_name" ]; then
        echo "Error: user.name cannot be empty."
        exit 1
    fi

    echo -n "Git user.email: "
    local identity_email
    read identity_email

    if [ -z "$identity_email" ]; then
        echo "Error: user.email cannot be empty."
        exit 1
    fi

    echo ""
    echo "Saving new identity: $identity_label <$identity_email>"
    xgit_config_save_identity "$identity_label" "$identity_name" "$identity_email"

    xgit_commands_clone_execute "$repo_url" "$target_dir" "$identity_label" "$identity_name" "$identity_email"
}

xgit_commands_clone_execute() {
    local repo_url
    repo_url="$1"
    local target_dir
    target_dir="$2"
    local identity_label
    identity_label="$3"
    local identity_name
    identity_name="$4"
    local identity_email
    identity_email="$5"

    xgit_config_ensure_runtime_dir "$identity_label" "$identity_name" "$identity_email"

    echo "Cloning repository..."
    xgit_docker_clone "$identity_label" "$repo_url" "$target_dir"

    local actual_dir
    if [ -n "$target_dir" ]; then
        actual_dir="$target_dir"
    else
        actual_dir=$(basename "$repo_url" .git)
    fi

    if [ ! -d "$actual_dir" ]; then
        echo "Error: clone failed — directory '$actual_dir' not found."
        exit 1
    fi

    (
        cd "$actual_dir" || exit 1
        xgit_config_write_xgitconf "$identity_label" "$identity_name" "$identity_email"
        xgit_hooks_install
    )

    echo ""
    echo "Repository cloned successfully."
    echo "Identity: $identity_label <$identity_email>"
    echo ""
    echo "Run \`cd $actual_dir\` and use xgit commands."
}

xgit_commands_init() {
    xgit_config_ensure_dirs

    if [ -f ".xgitconf" ]; then
        echo "Error: this directory is already managed by xgit."
        exit 1
    fi

    echo "=== xgit init ==="
    echo ""

    echo "Select Git identity:"
    echo ""
    echo "  1) Use existing identity"
    echo "  2) Create new identity"
    echo ""

    local choice
    echo -n "Choice [1-2]: "
    read choice

    local identity_label
    local identity_name
    local identity_email

    case "$choice" in
        1)
            echo ""
            echo "Available identities:"
            echo ""

            if ! xgit_config_list_identities; then
                echo ""
                echo "No identities configured. Creating a new one."
                choice=2
            else
                echo ""
                echo -n "Select identity number: "
                local idx
                read idx

                identity_label=$(xgit_config_get_identity_label_by_index "$idx")

                if [ -z "$identity_label" ]; then
                    echo "Error: invalid identity selection."
                    exit 1
                fi

                local info
                info=$(xgit_config_get_identity_info "$identity_label")
                identity_name="${info%%|*}"
                identity_email="${info##*|}"
            fi
            ;;
    esac

    if [ "$choice" = "2" ]; then
        echo ""
        echo -n "Identity label (e.g. anonymous-01): "
        read identity_label

        if [ -z "$identity_label" ]; then
            echo "Error: identity label cannot be empty."
            exit 1
        fi

        if xgit_config_identity_exists "$identity_label"; then
            echo "Error: identity '$identity_label' already exists."
            exit 1
        fi

        echo -n "Git user.name: "
        read identity_name

        if [ -z "$identity_name" ]; then
            echo "Error: user.name cannot be empty."
            exit 1
        fi

        echo -n "Git user.email: "
        read identity_email

        if [ -z "$identity_email" ]; then
            echo "Error: user.email cannot be empty."
            exit 1
        fi

        xgit_config_save_identity "$identity_label" "$identity_name" "$identity_email"
    fi

    xgit_config_ensure_runtime_dir "$identity_label" "$identity_name" "$identity_email"

    echo ""
    echo "Initializing git repository..."

    xgit_docker_run "$identity_label" init

    xgit_config_write_xgitconf "$identity_label" "$identity_name" "$identity_email"
    xgit_hooks_install

    echo ""
    echo "Repository initialized successfully."
    echo "Identity: $identity_label <$identity_email>"
}

xgit_commands_status() {
    local info
    info=$(xgit_config_read_xgitconf)
    local identity_label
    identity_label="${info%%|*}"
    local rem
    rem="${info#*|}"
    local identity_name
    identity_name="${rem%%|*}"
    local identity_email
    identity_email="${rem##*|}"

    xgit_config_ensure_runtime_dir "$identity_label" "$identity_name" "$identity_email"
    xgit_hooks_verify

    xgit_docker_run "$identity_label" status "$@"
}

xgit_commands_add() {
    local info
    info=$(xgit_config_read_xgitconf)
    local identity_label
    identity_label="${info%%|*}"
    local rem
    rem="${info#*|}"
    local identity_name
    identity_name="${rem%%|*}"
    local identity_email
    identity_email="${rem##*|}"

    xgit_config_ensure_runtime_dir "$identity_label" "$identity_name" "$identity_email"

    xgit_docker_run "$identity_label" add "$@"
}

xgit_commands_commit() {
    local info
    info=$(xgit_config_read_xgitconf)
    local identity_label
    identity_label="${info%%|*}"
    local rem
    rem="${info#*|}"
    local identity_name
    identity_name="${rem%%|*}"
    local identity_email
    identity_email="${rem##*|}"

    xgit_config_ensure_runtime_dir "$identity_label" "$identity_name" "$identity_email"
    xgit_hooks_verify

    xgit_docker_run "$identity_label" commit "$@"
}

xgit_commands_push() {
    local info
    info=$(xgit_config_read_xgitconf)
    local identity_label
    identity_label="${info%%|*}"
    local rem
    rem="${info#*|}"
    local identity_name
    identity_name="${rem%%|*}"
    local identity_email
    identity_email="${rem##*|}"

    xgit_config_ensure_runtime_dir "$identity_label" "$identity_name" "$identity_email"
    xgit_hooks_verify

    xgit_docker_run "$identity_label" push "$@"
}

xgit_commands_pull() {
    local info
    info=$(xgit_config_read_xgitconf)
    local identity_label
    identity_label="${info%%|*}"
    local rem
    rem="${info#*|}"
    local identity_name
    identity_name="${rem%%|*}"
    local identity_email
    identity_email="${rem##*|}"

    xgit_config_ensure_runtime_dir "$identity_label" "$identity_name" "$identity_email"

    xgit_docker_run "$identity_label" pull "$@"
}

xgit_commands_log() {
    local info
    info=$(xgit_config_read_xgitconf)
    local identity_label
    identity_label="${info%%|*}"
    local rem
    rem="${info#*|}"
    local identity_name
    identity_name="${rem%%|*}"
    local identity_email
    identity_email="${rem##*|}"

    xgit_config_ensure_runtime_dir "$identity_label" "$identity_name" "$identity_email"

    xgit_docker_run "$identity_label" log "$@"
}

xgit_commands_remote() {
    local info
    info=$(xgit_config_read_xgitconf)
    local identity_label
    identity_label="${info%%|*}"
    local rem
    rem="${info#*|}"
    local identity_name
    identity_name="${rem%%|*}"
    local identity_email
    identity_email="${rem##*|}"

    xgit_config_ensure_runtime_dir "$identity_label" "$identity_name" "$identity_email"

    xgit_docker_run "$identity_label" remote "$@"
}

xgit_commands_shell() {
    local info
    info=$(xgit_config_read_xgitconf)
    local identity_label
    identity_label="${info%%|*}"
    local rem
    rem="${info#*|}"
    local identity_name
    identity_name="${rem%%|*}"
    local identity_email
    identity_email="${rem##*|}"

    xgit_config_ensure_runtime_dir "$identity_label" "$identity_name" "$identity_email"

    echo "Opening shell with identity: $identity_label <$identity_email>"
    echo "Type 'exit' to leave the shell."
    echo ""

    xgit_docker_shell "$identity_label"
}
