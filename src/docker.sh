
XGIT_DOCKER_IMAGE="xgit/git-runtime"

xgit_docker_check() {
    if ! command -v docker >/dev/null 2>&1; then
        echo "Error: Docker is required but not installed."
        echo "Please install Docker first: https://docs.docker.com/engine/install/"
        exit 1
    fi

    if ! docker info >/dev/null 2>&1; then
        echo "Error: Docker is not running or not accessible."
        echo "Please start Docker and ensure your user has permissions."
        exit 1
    fi
}

xgit_docker_image_ensure() {
    if ! docker image inspect "$XGIT_DOCKER_IMAGE" >/dev/null 2>&1; then
        echo "Building xgit/git-runtime Docker image..."
        xgit_docker_build_default_image
    fi
}

xgit_docker_build_default_image() {
    docker build -t "$XGIT_DOCKER_IMAGE" - <<'XEOF'
FROM alpine:latest
RUN apk add --no-cache git openssh-client bash
RUN mkdir -p /xgit-home
VOLUME ["/repo", "/xgit-home"]
WORKDIR /repo
ENTRYPOINT ["/usr/bin/env"]
XEOF
}

xgit_docker_auth_env() {
    local identity
    identity="$1"
    local auth_env
    auth_env=""

    local ssh_dir
    ssh_dir=$(xgit_config_ssh_identity_dir "$identity")
    local ssh_mount
    ssh_mount=""

    if [ -d "$ssh_dir" ] && xgit_config_has_ssh_key "$identity"; then
        ssh_mount="-v $ssh_dir:/xgit-home/.ssh:ro"
        auth_env="$auth_env -e GIT_SSH_COMMAND=ssh -o StrictHostKeyChecking=accept-new -i /xgit-home/.ssh/id_ed25519 -i /xgit-home/.ssh/id_rsa -i /xgit-home/.ssh/id_ecdsa"
    fi

    local token
    token=$(xgit_config_get_token "$identity")
    if [ -n "$token" ]; then
        auth_env="$auth_env -e GITHUB_TOKEN=$token -e GH_TOKEN=$token"
    fi

    echo "$auth_env $ssh_mount"
}

xgit_docker_run() {
    local identity
    identity="$1"
    shift
    local args
    args="$*"

    local runtime_dir
    runtime_dir="$XGIT_RUNTIME_DIR/$identity"

    mkdir -p "$runtime_dir"

    local auth_opts
    auth_opts=$(xgit_docker_auth_env "$identity")

    docker run --rm \
        --user "$(id -u):$(id -g)" \
        -v "$PWD:/repo" \
        -v "$XGIT_HOME:/xgit-home" \
        -e HOME="/xgit-home/runtime/$identity" \
        -e XGIT_ACTIVE=1 \
        -e GIT_CONFIG_GLOBAL="/xgit-home/runtime/$identity/.gitconfig" \
        -e GIT_CONFIG_NOSYSTEM=1 \
        -w /repo \
        $auth_opts \
        "$XGIT_DOCKER_IMAGE" \
        git $args
}

xgit_docker_shell() {
    local identity
    identity="$1"

    local runtime_dir
    runtime_dir="$XGIT_RUNTIME_DIR/$identity"

    mkdir -p "$runtime_dir"

    local auth_opts
    auth_opts=$(xgit_docker_auth_env "$identity")

    docker run --rm -it \
        --user "$(id -u):$(id -g)" \
        -v "$PWD:/repo" \
        -v "$XGIT_HOME:/xgit-home" \
        -e HOME="/xgit-home/runtime/$identity" \
        -e XGIT_ACTIVE=1 \
        -e GIT_CONFIG_GLOBAL="/xgit-home/runtime/$identity/.gitconfig" \
        -e GIT_CONFIG_NOSYSTEM=1 \
        -w /repo \
        $auth_opts \
        "$XGIT_DOCKER_IMAGE" \
        /bin/bash
}

xgit_docker_clone() {
    local identity
    identity="$1"
    local repo_url
    repo_url="$2"
    local target_dir
    target_dir="$3"

    local runtime_dir
    runtime_dir="$XGIT_RUNTIME_DIR/$identity"

    mkdir -p "$runtime_dir"

    local clone_dir
    clone_dir=$(basename "$repo_url" .git)

    if [ -z "$target_dir" ]; then
        target_dir="$clone_dir"
    fi

    local actual_target
    actual_target="$PWD/$target_dir"

    local auth_opts
    auth_opts=$(xgit_docker_auth_env "$identity")

    docker run --rm \
        --user "$(id -u):$(id -g)" \
        -v "$PWD:/repo" \
        -v "$XGIT_HOME:/xgit-home" \
        -e HOME="/xgit-home/runtime/$identity" \
        -e XGIT_ACTIVE=1 \
        -e GIT_CONFIG_GLOBAL="/xgit-home/runtime/$identity/.gitconfig" \
        -e GIT_CONFIG_NOSYSTEM=1 \
        -w /repo \
        $auth_opts \
        "$XGIT_DOCKER_IMAGE" \
        git clone "$repo_url" "/repo/$target_dir"
}

xgit_docker_is_auth_error() {
    local output
    output="$1"

    local result
    result=1
    echo "$output" | grep -qiE \
        "could not read (Username|Password)"\
        "|Authentication failed"\
        "|fatal: Authentication failed"\
        "|remote: Invalid username or password"\
        "|Please make sure you have the correct access rights"\
        "|Permission denied \(publickey"\
        "|remote: Repository not found"\
        "|fatal: Could not read from remote repository" && result=0 || true
    return $result
}

xgit_docker_print_auth_help() {
    local identity
    identity="$1"

    echo ""
    echo "=== Authentication Required ==="
    echo ""
    echo "This operation needs authentication with the remote repository."
    echo "xgit supports two methods:"
    echo ""
    echo "  1) GitHub Personal Access Token (HTTPS repos)"
    echo "     Run:  xgit auth token"
    echo ""
    echo "  2) SSH Key (git@github.com repos)"
    echo "     Run:  xgit auth ssh"
    echo ""
    echo "Current identity: $identity"
    echo ""

    if xgit_config_has_token "$identity"; then
        echo "GitHub Token: configured (may be expired or invalid)"
        echo "To update:  xgit auth token"
        echo ""
    fi

    if xgit_config_has_ssh_key "$identity"; then
        echo "SSH Key: configured"
        echo ""
    fi

    xgit_config_print_auth_status "$identity"
}
