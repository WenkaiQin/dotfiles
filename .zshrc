# Autocomplete fixing.
autoload -Uz compinit && compinit
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}' 'r:|[._-]=* r:|=*'

setopt noautomenu
setopt nomenucomplete

# Additional arguments for common commands.
alias grep='grep --color=auto'
alias ls='ls --color=auto'
alias latexindent='~/latexindent-macos'
alias find='find 2>/dev/null'

# Sublime Text alias (cross-platform)
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    alias subl="/Applications/Sublime\ Text.app/Contents/SharedSupport/bin/subl"
elif command -v subl &>/dev/null; then
    # Linux with subl in PATH
    alias subl="subl"
elif [[ -x "/opt/sublime_text/sublime_text" ]]; then
    # Linux default install path
    alias subl="/opt/sublime_text/sublime_text"
fi

# Pangea stuff.
export BIBINPUTS=~/Workspace/pangea/:
export BSTINPUTS=~/Workspace/pangea/texStyleFiles:
export TEXINPUTS=~/Workspace/pangea/texStyleFiles:

# Source prompt.
# source ~/agkozak-zsh-prompt.plugin.zsh

# Add Pure prompt path depending on platform
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS (Homebrew install path)
    fpath+=("/opt/homebrew/share/zsh/site-functions")
elif [[ -d "$HOME/.zsh/pure" ]]; then
    # Linux manual install path
    fpath+=("$HOME/.zsh/pure")
fi

if command -v brew &>/dev/null; then
  fpath+=("$(brew --prefix)/share/zsh/site-functions")
fi

autoload -U promptinit; promptinit
prompt pure

autoload -U promptinit; promptinit;
zstyle :prompt:pure:git:stash show yes
prompt pure

# Syntax highlighting.
if [[ -f /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]]; then
  source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
elif [[ -f /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]]; then
  source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi

# History settings.
export HISTSIZE=10000
export SAVEHIST=10000
export HISTFILE=~/.zhistory
setopt INC_APPEND_HISTORY
setopt HIST_IGNORE_DUPS
setopt EXTENDED_HISTORY

# Allow for changing of title.
DISABLE_AUTO_TITLE="true"

function set_terminal_title() {
  echo -en "\e]2;$@\a"
}

# Misellaneous paths.
export SL_AWS=s3://ssa-external-upload-mini-gnss-production

# Amazon-specific.
if [[ "$(hostname)" == "842f572ea37e" ]]; then
  export PATH=$HOME/.toolbox/bin:$PATH
fi

# Fix Ctrl+Arrow and Alt+Arrow keys in zsh
autoload -Uz select-word-style
select-word-style bash

bindkey "^[[1;5D" backward-word       # Ctrl+Left
bindkey "^[[1;5C" forward-word        # Ctrl+Right
bindkey "^[^[[D" backward-word        # Alt+Left
bindkey "^[^[[C" forward-word         # Alt+Right