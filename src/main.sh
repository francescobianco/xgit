module config
module docker
module hooks
module commands

XGIT_VERSION="0.1.0"

xgit_print_usage() {
    echo "xgit v${XGIT_VERSION} - Git identity isolation through containerized execution"
    echo ""
    echo "Usage: xgit <command> [options]"
    echo ""
    echo "Commands:"
    echo "  clone   <repo-url> [dir]   Clone a repository with xgit identity"
    echo "  init                       Initialize a new managed repository"
    echo "  status                     Show working tree status"
    echo "  add     <files...>         Add file contents to the index"
    echo "  rm      <files...>         Remove files from the working tree"
    echo "  commit  [options]          Record changes to the repository"
    echo "  push    [options]          Update remote refs along with objects"
    echo "  pull    [options]          Fetch and integrate with another repository"
    echo "  log     [options]          Show commit logs"
    echo "  remote  [options]          Manage set of tracked repositories"
    echo "  shell                      Open an interactive shell in the container"
    echo "  auth    <token|ssh>        Configure GitHub authentication"
    echo ""
    echo "Any other git command (branch, diff, tag, stash, ...) is passed through."
    echo ""
    echo "For more info: https://github.com/user/xgit"
}

xgit_print_error_no_config() {
    echo "Error: this directory is not managed by xgit."
    echo "Missing ${XGIT_CONFIG_FILE} file."
    echo ""
    echo "Use one of:"
    echo "  xgit clone <repo-url>      Clone a repository"
    echo "  xgit init                  Initialize repository here"
    exit 1
}

main() {
    if [ $# -eq 0 ]; then
        xgit_print_usage
        exit 0
    fi

    local cmd
    cmd="$1"
    shift

    case "$cmd" in
        --help|-h|help)
            xgit_print_usage
            exit 0
            ;;
        --version|-V|version)
            echo "xgit v${XGIT_VERSION}"
            exit 0
            ;;
        clone)
            xgit_docker_check
            xgit_docker_image_ensure
            xgit_commands_clone "$@"
            ;;
        init)
            xgit_docker_check
            xgit_docker_image_ensure
            xgit_commands_init "$@"
            ;;
        status)
            [ ! -f "$XGIT_CONFIG_FILE" ] && xgit_print_error_no_config
            xgit_docker_check
            xgit_docker_image_ensure
            xgit_commands_status "$@"
            ;;
        add)
            [ ! -f "$XGIT_CONFIG_FILE" ] && xgit_print_error_no_config
            xgit_docker_check
            xgit_docker_image_ensure
            xgit_commands_add "$@"
            ;;
        commit|ci)
            [ ! -f "$XGIT_CONFIG_FILE" ] && xgit_print_error_no_config
            xgit_docker_check
            xgit_docker_image_ensure
            xgit_commands_commit "$@"
            ;;
        push)
            [ ! -f "$XGIT_CONFIG_FILE" ] && xgit_print_error_no_config
            xgit_docker_check
            xgit_docker_image_ensure
            xgit_commands_push "$@"
            ;;
        pull)
            [ ! -f "$XGIT_CONFIG_FILE" ] && xgit_print_error_no_config
            xgit_docker_check
            xgit_docker_image_ensure
            xgit_commands_pull "$@"
            ;;
        log)
            [ ! -f "$XGIT_CONFIG_FILE" ] && xgit_print_error_no_config
            xgit_docker_check
            xgit_docker_image_ensure
            xgit_commands_log "$@"
            ;;
        remote)
            [ ! -f "$XGIT_CONFIG_FILE" ] && xgit_print_error_no_config
            xgit_docker_check
            xgit_docker_image_ensure
            xgit_commands_remote "$@"
            ;;
        shell)
            [ ! -f "$XGIT_CONFIG_FILE" ] && xgit_print_error_no_config
            xgit_docker_check
            xgit_docker_image_ensure
            xgit_commands_shell "$@"
            ;;
        auth)
            [ ! -f "$XGIT_CONFIG_FILE" ] && xgit_print_error_no_config
            xgit_commands_auth "$@"
            ;;
        *)
            if [ -f "$XGIT_CONFIG_FILE" ]; then
                local info
                local identity_label
                local identity_name
                local identity_email
                info=$(xgit_config_read_xgitconf)
                identity_label=$(xgit_info_field "$info" 1)
                identity_name=$(xgit_info_field "$info" 2)
                identity_email=$(xgit_info_field "$info" 3)
                xgit_config_ensure_runtime_dir "$identity_label" "$identity_name" "$identity_email"
                xgit_docker_check
                xgit_docker_image_ensure
                xgit_hooks_verify
                xgit_docker_run "$identity_label" "$cmd" "$@"
            else
                echo "Error: unknown command '$cmd'"
                echo ""
                xgit_print_usage
                exit 1
            fi
            ;;
    esac
}
