# Zach's config file for the Zoomer Shell

# enable colors and change prompt
autoload -U colors && colors

#History in cache directory:
HISTSIZE=100000
SAVEHIST=100000
HISTFILE="$XDG_CACHE_HOME/zsh/history"
[[ -d ${HISTFILE:h} ]] || mkdir -p ${HISTFILE:h}
setopt SHARE_HISTORY INC_APPEND_HISTORY HIST_IGNORE_ALL_DUPS HIST_IGNORE_SPACE HIST_REDUCE_BLANKS EXTENDED_HISTORY

# completion behavior
zmodload zsh/complist
autoload -Uz compinit
compinit -d "$ZDOTDIR/.zcompdump"

zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'   # case-insensitive
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"     # color the menu
zstyle ':completion:*' group-name ''                        # group by type
LISTMAX=50                                                  # cap the "show all 414?" prompt
_comp_options+=(globdots)    # Include hidden files.

autoload -U up-line-or-beginning-search
autoload -U down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search

bindkey '^[[A' up-line-or-beginning-search
bindkey '^[[B' down-line-or-beginning-search

setopt autocd extendedglob nomatch
setopt interactive_comments
stty stop undef # Disable ctrl-s to freeze terminal.
zle_highlight=('paste:none')

# Nobody likes beeping
unsetopt BEEP

# Useful Functions.
source "$ZDOTDIR/zsh-functions"

#Normal files to source
zsh_add_file "zsh-vim-mode"
zsh_add_file "zsh-prompt"
zsh_add_file "zsh-aliases"

# Plugins
zsh_add_plugin "zsh-users/zsh-autosuggestions"
zsh_add_plugin "zsh-users/zsh-syntax-highlighting"
zsh_add_plugin "hlissner/zsh-autopair"

# Edit line in vim with ctrl-e
autoload edit-command-line; zle -N edit-command-line
bindkey '^e' edit-command-line

#pfetch
command -v pfetch >/dev/null && pfetch
