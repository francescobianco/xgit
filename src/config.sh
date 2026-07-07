
XGIT_HOME="$HOME/.xgit"
XGIT_IDENTITIES_DIR="$XGIT_HOME/identities"
XGIT_IDENTITIES_FILE="$XGIT_IDENTITIES_DIR/identities.conf"
XGIT_RUNTIME_DIR="$XGIT_HOME/runtime"
XGIT_CACHE_DIR="$XGIT_HOME/cache"
XGIT_DOCKER_DIR="$XGIT_HOME/docker"
XGIT_SSH_DIR="$XGIT_HOME/ssh"

xgit_config_ensure_dirs() {
    mkdir -p "$XGIT_IDENTITIES_DIR" "$XGIT_RUNTIME_DIR" "$XGIT_CACHE_DIR" "$XGIT_DOCKER_DIR" "$XGIT_SSH_DIR"
    if [ ! -f "$XGIT_IDENTITIES_FILE" ]; then
        touch "$XGIT_IDENTITIES_FILE"
    fi
}

xgit_config_read_xgitconf() {
    if [ ! -f ".xgitconf" ]; then
        echo "Error: this repository is not managed by xgit."
        echo "Missing .xgitconf file."
        echo "Use \`xgit clone\` or \`xgit init\` first."
        exit 1
    fi

    local managed
    managed=$(xgit_config_ini_get ".xgitconf" "xgit" "managed")
    if [ "$managed" != "true" ]; then
        echo "Error: this repository is not managed by xgit."
        echo "Missing .xgitconf file."
        echo "Use \`xgit clone\` or \`xgit init\` first."
        exit 1
    fi

    local identity
    identity=$(xgit_config_ini_get ".xgitconf" "xgit" "identity")
    local name
    name=$(xgit_config_ini_get ".xgitconf" "user" "name")
    local email
    email=$(xgit_config_ini_get ".xgitconf" "user" "email")

    echo "$identity|$name|$email"
}

xgit_config_write_xgitconf() {
    local identity
    identity="$1"
    local name
    name="$2"
    local email
    email="$3"

    cat > .xgitconf << XEOF
[xgit]
managed = true
identity = $identity

[user]
name = $name
email = $email
XEOF
}

xgit_config_ini_get() {
    local file
    file="$1"
    local section
    section="$2"
    local key
    key="$3"

    awk -F ' *= *' -v section="$section" -v key="$key" '
        /^\[/ { in_section = ($0 == "[" section "]") }
        in_section && $1 == key { gsub(/^[[:space:]]+|[[:space:]]+$/, "", $2); print $2; found=1 }
        END { if (!found) exit 1 }
    ' "$file" 2>/dev/null
}

xgit_config_list_identities() {
    if [ ! -f "$XGIT_IDENTITIES_FILE" ] || [ ! -s "$XGIT_IDENTITIES_FILE" ]; then
        echo "No identities found."
        return 1
    fi

    local labels
    labels=$(awk -F '"' '/^\[identity / { print $2 }' "$XGIT_IDENTITIES_FILE")

    if [ -z "$labels" ]; then
        echo "No identities found."
        return 1
    fi

    local i
    i=1
    local old_ifs
    old_ifs="$IFS"
    IFS='
'
    for label in $labels; do
        local name
        name=$(xgit_config_ini_get "$XGIT_IDENTITIES_FILE" "identity \"$label\"" "name")
        local email
        email=$(xgit_config_ini_get "$XGIT_IDENTITIES_FILE" "identity \"$label\"" "email")
        echo "${i}) ${label} <${email}>"
        i=$((i + 1))
    done
    IFS="$old_ifs"
    return 0
}

xgit_config_get_identity_info() {
    local label
    label="$1"

    local name
    name=$(xgit_config_ini_get "$XGIT_IDENTITIES_FILE" "identity \"$label\"" "name")
    local email
    email=$(xgit_config_ini_get "$XGIT_IDENTITIES_FILE" "identity \"$label\"" "email")

    if [ -z "$name" ] || [ -z "$email" ]; then
        echo "Error: identity '$label' not found in global identities."
        exit 1
    fi

    echo "$name|$email"
}

xgit_config_save_identity() {
    local label
    label="$1"
    local name
    name="$2"
    local email
    email="$3"

    if grep -q "^\[identity \"$label\"\]" "$XGIT_IDENTITIES_FILE" 2>/dev/null; then
        echo "Error: identity '$label' already exists."
        exit 1
    fi

    cat >> "$XGIT_IDENTITIES_FILE" << XEOF

[identity "$label"]
name = $name
email = $email
XEOF
}

xgit_config_identity_exists() {
    local label
    label="$1"
    grep -q "^\[identity \"$label\"\]" "$XGIT_IDENTITIES_FILE" 2>/dev/null
}

xgit_config_get_identity_label_by_index() {
    local idx
    idx="$1"
    local labels
    labels=$(awk -F '"' '/^\[identity / { print $2 }' "$XGIT_IDENTITIES_FILE")
    local i
    i=1
    local old_ifs
    old_ifs="$IFS"
    IFS='
'
    for label in $labels; do
        if [ "$i" -eq "$idx" ]; then
            echo "$label"
            IFS="$old_ifs"
            return 0
        fi
        i=$((i + 1))
    done
    IFS="$old_ifs"
    return 1
}

xgit_config_ensure_runtime_dir() {
    local identity
    identity="$1"
    local runtime_dir
    runtime_dir="$XGIT_RUNTIME_DIR/$identity"
    mkdir -p "$runtime_dir"

    local name
    name="$2"
    local email
    email="$3"

    cat > "$runtime_dir/.gitconfig" << XEOF
[user]
	name = $name
	email = $email

[core]
	hooksPath = /repo/.git/hooks
XEOF
}
