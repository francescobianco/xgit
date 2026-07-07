# xgit

**Git identity isolation through containerized execution.**

`xgit` is a shell-based wrapper for Git that runs every Git command inside a Docker container, providing identity isolation per repository.

## Philosophy

```text
xgit = Git identity isolation through containerized execution
```

Every repository managed by `xgit` works with an explicit, controlled Git identity. The host machine's Git configuration, SSH keys, GPG keys, and credential helpers are never exposed to the repository.

## Installation

### Prerequisites

- [Mush](https://mush.javanile.org) (shell package manager)
- Docker

### Build

```bash
git clone <this-repo>
cd xgit
mush build --release
```

Copy the resulting binary to your PATH, or run via:

```bash
mush run
```

## Quick Start

### Clone a repository

```bash
xgit clone git@github.com:user/repo.git
```

You will be guided through an interactive identity selection:
- Choose an existing identity from your global identity store
- Or create a new identity with a label, name, and email

After cloning, a `.git/xgitconf` file is created inside the repository, binding it to the chosen identity.

### Initialize a new repository

```bash
mkdir my-project && cd my-project
xgit init
```

### Daily workflow

```bash
xgit status
xgit add file1 file2
xgit commit -m "feat: add new feature"
xgit push
xgit pull
xgit log --oneline
xgit remote -v
```

### Interactive shell

```bash
xgit shell
```

Opens a bash shell inside the Docker container with the repository's identity already configured. Inside this shell you can use `git` directly.

## How it works

### .git/xgitconf

Each managed repository contains a `.git/xgitconf` file:

```ini
[xgit]
managed = true
identity = anonymous-01

[user]
name = Anonymous User
email = 12345678+anonymous@users.noreply.github.com
```

`xgit` refuses to operate in directories without this file (except for `clone` and `init`).

### Global identity store

Identities are stored in `~/.xgit/identities/identities.conf`:

```ini
[identity "anonymous-01"]
name = Anonymous User
email = 12345678+anonymous@users.noreply.github.com

[identity "work-client-a"]
name = Client A Bot
email = client-a@example.com
```

### Docker execution

Every Git command runs inside a Docker container:

```
docker run --rm \
  -v $PWD:/repo \
  -v ~/.xgit:/xgit-home \
  -e XGIT_ACTIVE=1 \
  -e HOME=/xgit-home/runtime/<identity> \
  -e GIT_CONFIG_GLOBAL=/xgit-home/runtime/<identity>/.gitconfig \
  -e GIT_CONFIG_NOSYSTEM=1 \
  -w /repo \
  xgit/git-runtime \
  git <command>
```

### Protection hooks

After clone or init, hooks are installed in `.git/hooks/` that block direct `git` usage:

```
$ git commit
This repository is managed by xgit.
Use xgit instead of raw git.
```

Hooks only allow operations when `XGIT_ACTIVE=1` (set by the xgit wrapper).

## Security

- No host `~/.gitconfig` exposed
- No host `~/.ssh` mounted
- No host `~/.gnupg` mounted
- No host credential helpers
- Each identity has its own isolated `HOME` inside the container
- System git config is disabled (`GIT_CONFIG_NOSYSTEM=1`)

## Commands

| Command | Description |
|---------|-------------|
| `xgit clone <url> [dir]` | Clone a repository interactively |
| `xgit init` | Initialize a managed repository |
| `xgit status` | Show working tree status |
| `xgit add <files>` | Add files to index |
| `xgit commit [opts]` | Commit changes |
| `xgit push [opts]` | Push to remote |
| `xgit pull [opts]` | Pull from remote |
| `xgit log [opts]` | View commit log |
| `xgit remote [opts]` | Manage remotes |
| `xgit shell` | Interactive container shell |

## License

MIT
