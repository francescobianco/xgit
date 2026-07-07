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
    echo "  commit  [options]          Record changes to the repository"
    echo "  push    [options]          Update remote refs along with objects"
    echo "  pull    [options]          Fetch and integrate with another repository"
    echo "  log     [options]          Show commit logs"
    echo "  remote  [options]          Manage set of tracked repositories"
    echo "  shell                      Open an interactive shell in the container"
    echo "  auth    <token|ssh>        Configure GitHub authentication"
    echo ""
    echo "For more info: https://github.com/user/xgit"
}

xgit_print_error_no_config() {
    echo "Error: this directory is not managed by xgit."
    echo "Missing .xgitconf file."
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
            [ ! -f ".xgitconf" ] && xgit_print_error_no_config
            xgit_docker_check
            xgit_docker_image_ensure
            xgit_commands_status "$@"
            ;;
        add)
            [ ! -f ".xgitconf" ] && xgit_print_error_no_config
            xgit_docker_check
            xgit_docker_image_ensure
            xgit_commands_add "$@"
            ;;
        commit|ci)
            [ ! -f ".xgitconf" ] && xgit_print_error_no_config
            xgit_docker_check
            xgit_docker_image_ensure
            xgit_commands_commit "$@"
            ;;
        push)
            [ ! -f ".xgitconf" ] && xgit_print_error_no_config
            xgit_docker_check
            xgit_docker_image_ensure
            xgit_commands_push "$@"
            ;;
        pull)
            [ ! -f ".xgitconf" ] && xgit_print_error_no_config
            xgit_docker_check
            xgit_docker_image_ensure
            xgit_commands_pull "$@"
            ;;
        log)
            [ ! -f ".xgitconf" ] && xgit_print_error_no_config
            xgit_docker_check
            xgit_docker_image_ensure
            xgit_commands_log "$@"
            ;;
        remote)
            [ ! -f ".xgitconf" ] && xgit_print_error_no_config
            xgit_docker_check
            xgit_docker_image_ensure
            xgit_commands_remote "$@"
            ;;
        shell)
            [ ! -f ".xgitconf" ] && xgit_print_error_no_config
            xgit_docker_check
            xgit_docker_image_ensure
            xgit_commands_shell "$@"
            ;;
        auth)
            [ ! -f ".xgitconf" ] && xgit_print_error_no_config
            xgit_commands_auth "$@"
            ;;
        *)
            echo "Error: unknown command '$cmd'"
            echo ""
            xgit_print_usage
            exit 1
            ;;
    esac
}
