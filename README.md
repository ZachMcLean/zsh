# zsh

My zsh config. Runs on Jupiter (macOS) and sol (Ubuntu 26.04).

Philosophy: this config should teach me the shell, not hide it. Prefer real zsh
features — globs, ZLE keybinds, completion — over aliases that only exist on my
machines. If a habit doesn't transfer to a bare shell inside a Docker container,
it's a bad habit.

Guard on capability, never on platform. `command -v nvim` is durable;
`[[ $OSTYPE == darwin* ]]` breaks the day I install nvim on Linux too.

---

## Layout

| File | What it does |
|---|---|
| `~/.zshenv` | **Symlink to `zshenv.txt`.** The only file zsh finds by convention. Sets `ZDOTDIR`. |
| `zshenv.txt` | Env vars for *every* zsh invocation — PATH, EDITOR, XDG, homebrew. |
| `.zshrc` | Interactive shells only. Options, history, completion, keybinds, sources everything else. |
| `zsh-functions` | `zsh_add_file` / `zsh_add_plugin` loaders. Sourced first. |
| `zsh-prompt` | `vcs_info` git status + `PROMPT`. |
| `zsh-aliases` | Aliases. Deliberately few. |
| `zsh-vim-mode` | vi keybinds and cursor shape. |
| `plugins/` | Auto-cloned from GitHub on first run. Gitignored. |

`.zshenv` runs on every zsh invocation — including `ssh sol 'command'`, cron
jobs, and any zsh script. Nothing slow or display-dependent goes there
unguarded. `.zshrc` is interactive-only; that's where prompts, keybinds, and
completion belong.

---

## New machine setup

zsh reads `~/.zshenv` first, always, before anything else. That file sets
`ZDOTDIR`, which is how zsh knows to look in `~/.config/zsh` instead of `~`.
**Skip the symlink and nothing else loads.**

```
sudo apt install -y zsh git neovim        # or: brew install neovim
```

```
git clone https://github.com/ZachMcLean/zsh.git ~/.config/zsh && ln -sf ~/.config/zsh/zshenv.txt ~/.zshenv && mkdir -p ~/.cache/zsh
```

```
chsh -s "$(which zsh)" "$USER"
```

Log out and back in. Then run `exec zsh` **a second time** — `zsh_add_plugin`
clones missing plugins but doesn't source them on the same pass, so the first
launch always comes up bare.

Delete Ubuntu's skeleton `~/.zshrc` if present — with `ZDOTDIR` set it's dead
weight and will confuse future-me.

### If SSH'ing in from Ghostty

The server doesn't know what `xterm-ghostty` means, which breaks Backspace,
Delete, and arrow keys, and makes `git log` complain that the terminal isn't
fully functional. Run this **from the Mac**, not the server:

```
infocmp -x | ssh zach@sol -- tic -x -
```

Installs the terminfo entry to `~/.terminfo` on the server. No sudo needed. A
warning about the description field is normal. Verify with `infocmp $TERM`.

---

## Keybinds

| Key | Does |
|---|---|
| `Ctrl-E` | **Open the current command line in nvim.** Edit, `:wq`, it runs. |
| `↑` / `↓` | History search filtered by what's already typed |
| `→` | Accept the full autosuggestion (grey ghost text) |
| `Tab Tab` | Completion menu; `hjkl`/arrows to move, Enter to pick |
| `Esc` | Command mode (see below) |

`Ctrl-E` is the one I always forget. Any time I'm arrow-keying across a long
line, that's the wrong move.

`↑` with `git pu` already typed shows only `git push`, `git pull --rebase`. With
an empty line it behaves like normal history.

### vi mode

This config has vi mode on, so the command line has two modes. I forgot this
for over a year.

- `Esc` → command mode. `b`/`w` words, `0`/`$` line ends, `dd` clear line,
  `ci"` change inside quotes, `J` join lines, `u` undo.
- `i` / `a` → back to insert mode.
- `v` in command mode → opens the line in `$EDITOR`, same as `Ctrl-E`.
- `j`/`k` in command mode → history search (bound in `zsh-vim-mode`).

Three steps are needed to wire any ZLE feature, and missing the third is why
half this config was dormant for a year:

```zsh
autoload -U some-widget    # load the code
zle -N some-widget         # register it as a widget
bindkey '^[[A' some-widget # attach it to a key   <- the one I always missed
```

---

## Glob qualifiers

The highest-value thing in this config and the thing I use least. `extendedglob`
is on. `**/` recurses. The part in parentheses after a glob is a *qualifier*.

```
ls -lt **/*.cbz(.mm-30)      # cbz files modified in the last 30 min, recursive
ls -l *(.)                    # plain files only
ls -d *(/)                    # directories only
ls -l *(om[1,10])             # 10 most recently modified
ls -lh **/*(.Lm+500)          # files over 500MB — what's eating the disk
ls **/*~*/node_modules/*      # everything except node_modules
print -l ^*.cbz               # everything that isn't a cbz
```

Reference:

- `.` plain file, `/` directory, `@` symlink, `*` executable
- `m` mtime, `a` atime — `m-30` under 30 min, `m+2` over 2 days
  (`mm` minutes, `mh` hours, bare is days)
- `L` size — `Lm+100` over 100MB, `Lk-4` under 4KB
- `o` sort ascending, `O` descending: `om` mtime, `oL` size, `on` name
- `[1,10]` slice the result
- `N` don't error on no match, `D` include dotfiles

Combine freely: `*(.om[1,5])` = five most recent plain files.

This replaces most of what I'd otherwise write as `find`. `print -l <glob>`
lists the matches first when I'm about to do something destructive.

---

## Options that are on

- `autocd` — type a path, press enter, you're there. No `cd` needed.
- `extendedglob` — the qualifiers above, plus `^` negation and `~` exclusion.
- `interactive_comments` — `#` works at the prompt, so I can annotate a paste.
- `nomatch` — errors on an unmatched glob instead of passing it through literally.
- `_comp_options+=(globdots)` — completion sees dotfiles.
- `stty stop undef` — `Ctrl-S` no longer freezes the terminal.
- `SHARE_HISTORY` + `INC_APPEND_HISTORY` — all concurrent SSH sessions into sol
  read and write the same history file live, instead of last-to-exit winning.

---

## Completion

`compinit` must be **called**, not just `autoload`ed. Autoloading alone leaves
the entire completion system inert — every `zstyle` below it does nothing. This
was broken here for over a year and was invisible on Ubuntu, because
`/etc/zsh/zshrc` calls `compinit` for you. macOS doesn't.

Order matters: `zmodload zsh/complist` → `compinit` → the zstyles.
`menu select` depends on that module being loaded first.

`LISTMAX=50` caps the "do you wish to see all 414 possibilities" prompt —
without it, `systemctl restart <Tab>` on a server dumps an unusable wall.

---

## Plugins

Cloned into `plugins/` on first run by `zsh_add_plugin`.

- **zsh-autosuggestions** — grey ghost text from history. `→` accepts.
- **zsh-syntax-highlighting** — command name green if it resolves, red if not.
  A typo check *before* pressing enter. Actually look at it.
- **zsh-autopair** — auto-closes quotes and brackets; wraps a selection.

Update all:

```
find "$ZDOTDIR/plugins" -maxdepth 1 -type d -exec test -e '{}/.git' ';' -print0 | xargs -0 -I{} git -C {} pull -q
```

Add one: add `zsh_add_plugin "user/repo"` to `.zshrc`, then `exec zsh` twice.

---

## Prompt

`zsh-prompt` uses `vcs_info` for git state:

- `(master)` clean · `(!master)` untracked files · `%u`/`%c` unstaged/staged
- `%n` username, `%m` short hostname, `%c` current directory basename

`%n@%m` rather than hardcoded strings means the prompt is always honest about
which machine I'm on — the entire point when three SSH sessions into sol are
open. This was hardcoded to `Sol` for a year, on both machines.

Every non-printing escape must be wrapped in `%{` … `%}`. Get that wrong and zsh
miscounts the prompt width, which makes long lines scroll sideways instead of
wrapping. `%B` needs a closing `%b` or bold bleeds into command output.

---

## Aliases

Deliberately minimal. An alias earns its place only if it's a *safety* default
(`rm -i`) or a flag set I always want (`ls -la`). Aliases that rename a command
or hide a pipeline are banned — they don't exist inside a container, on a fresh
box, or in anyone else's shell, and they rot my recall of the real command.

`alias vim="nvim"` is guarded with `command -v nvim` — unguarded, it silently
breaks `vim` entirely on a machine without neovim. Use `\vim` or `command vim`
to bypass an alias.

---

## Troubleshooting

**Nothing loads on a new machine.** `~/.zshenv` symlink is missing. See setup.

**`locking failed for .../history: no such file or directory`.** The cache
directory doesn't exist. `mkdir -p ~/.cache/zsh`. The guard under `HISTFILE` in
`.zshrc` self-heals this now.

**Tab completion is dumb.** `compinit` isn't being called. See Completion above.

**Delete/Backspace inserts spaces, arrow keys don't move.** terminfo. The server
doesn't recognize `$TERM`. See the Ghostty section in setup.

**Errors on every shell start.** Something references a binary that doesn't
exist on this box. Guard it: `command -v <thing> >/dev/null && <thing>`.

**Changes to `.zshenv` don't take effect.** `exec zsh` does **not** re-read
`.zshenv` — only a genuinely new zsh process does. Full logout, or a new
terminal window.

**Slow shell / VS Code Remote SSH hangs on connect.** Remote SSH runs a login
shell, so a slow `.zshrc` looks like a hanging connection.

```
time zsh -i -c exit
```

Over ~300ms means something is doing real work at startup.

**Prompt garbled, or long lines scroll sideways.** Unwrapped escape in the
prompt. `print -P "$PROMPT" | cat -A` to inspect.

**A setting I removed keeps coming back.** Look for config files *outside* this
repo. See below.

---

## The `.zprofile` trap

Aug 2026: spent hours chasing a bug where `brew` and `nvim` worked sometimes and
vanished other times. Cause was `~/.zprofile` — a January 2025 file that
duplicated most of `zshenv.txt`, with its own `EDITOR`, `SHELL`, `TERMINAL`,
XDG paths, `ZDOTDIR`, and the homebrew `shellenv` line.

It only ran for **login** shells. So brew loaded in some shells and not others,
and no diff in this repo would ever show it, because the file lived outside the
repo.

Deleted. The homebrew and Python-framework lines moved into `zshenv.txt`,
guarded. If a setting behaves inconsistently, check for siblings:

```
ls -la ~/.zprofile ~/.zlogin ~/.zlogout ~/.profile ~/.bash_profile 2>/dev/null
```

The lesson: one config source, in git. A file that works by accident of load
order is worse than one that's broken outright.

---

## Deliberately not doing

- **Global aliases** (`alias -g G='| grep'`). Convenient, but the habit doesn't
  transfer anywhere my config isn't, and I'd rather know `grep`.
- **Named directories** (`hash -d media=/srv/media`). They collapse real paths
  in the prompt. I want to see where I actually am.
- **A framework** (oh-my-zsh, prezto). This config is ~60 lines I understand
  completely. That's the feature.
- **`zsh_add_completion`.** Came from the tutorial config, never called once,
  had an unterminated `if` throwing a parse error on every shell start. Most
  tools ship completions via brew/apt or print their own (`gh completion -s
  zsh`). If I ever need it manually: `fpath+=("$ZDOTDIR/plugins/x") && compinit`.

---

## Still to do

- [ ] `%b` to close the `%B` in `zsh-prompt`
- [ ] Decide whether pfetch is worth the startup cost (it runs on every shell)
- [ ] Try `fzf` for `Ctrl-R` fuzzy history — likely the next real upgrade
- [ ] SSH key + `~/.ssh/config` for sol so I stop typing the password
- [ ] tmux on sol for sessions that survive closing the laptop
