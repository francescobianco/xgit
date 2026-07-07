
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

xgit_docker_run() {
    local identity
    identity="$1"
    shift
    local args
    args="$*"

    local runtime_dir
    runtime_dir="$XGIT_RUNTIME_DIR/$identity"

    mkdir -p "$runtime_dir"

    local git_env
    git_env=""

    if [ -f "$runtime_dir/.gitconfig" ]; then
        git_env="$git_env -e GIT_CONFIG_GLOBAL=/xgit-home/runtime/$identity/.gitconfig"
    fi

    local gitconfig_volume
    gitconfig_volume=""
    if [ -f "$runtime_dir/.gitconfig" ]; then
        gitconfig_volume="-v $runtime_dir/.gitconfig:/xgit-home/runtime/$identity/.gitconfig:ro"
    fi

    docker run --rm \
        --user "$(id -u):$(id -g)" \
        -v "$PWD:/repo" \
        -v "$XGIT_HOME:/xgit-home" \
        -e HOME="/xgit-home/runtime/$identity" \
        -e XGIT_ACTIVE=1 \
        -e GIT_CONFIG_GLOBAL="/xgit-home/runtime/$identity/.gitconfig" \
        -e GIT_CONFIG_NOSYSTEM=1 \
        -w /repo \
        $git_env \
        "$XGIT_DOCKER_IMAGE" \
        git $args
}

xgit_docker_shell() {
    local identity
    identity="$1"

    local runtime_dir
    runtime_dir="$XGIT_RUNTIME_DIR/$identity"

    mkdir -p "$runtime_dir"

    docker run --rm -it \
        --user "$(id -u):$(id -g)" \
        -v "$PWD:/repo" \
        -v "$XGIT_HOME:/xgit-home" \
        -e HOME="/xgit-home/runtime/$identity" \
        -e XGIT_ACTIVE=1 \
        -e GIT_CONFIG_GLOBAL="/xgit-home/runtime/$identity/.gitconfig" \
        -e GIT_CONFIG_NOSYSTEM=1 \
        -w /repo \
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

    docker run --rm \
        --user "$(id -u):$(id -g)" \
        -v "$PWD:/repo" \
        -v "$XGIT_HOME:/xgit-home" \
        -e HOME="/xgit-home/runtime/$identity" \
        -e XGIT_ACTIVE=1 \
        -e GIT_CONFIG_GLOBAL="/xgit-home/runtime/$identity/.gitconfig" \
        -e GIT_CONFIG_NOSYSTEM=1 \
        -w /repo \
        "$XGIT_DOCKER_IMAGE" \
        git clone "$repo_url" "/repo/$target_dir"
}
