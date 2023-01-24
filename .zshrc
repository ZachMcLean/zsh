# Zach's config file for the Zoomer Shell
#!/bin/sh
export ZDOTDIR=$HOME/.config/zsh
# enable colors and change prompt
autoload -U colors && colors

#append
path+=('$HOME/.local/bin')
export PATH
#History in cache directory:
HISTSIZE=10000
SAVEHIST=10000
HISTFILE=~/.cache/zsh/history

# Basic auto/tab complete
autoload -U compinit
zstyle ':completion:*' menu select
zmodload zsh/complist
_comp_options+=(globdots)    # Include hidden files.

autoload -U up-line-or-beginning-search
autoload -U down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search

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
pfetch
$HOME/bin/startup
