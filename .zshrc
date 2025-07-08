# Autocomplete tweaking.
# Brew autocomplete.
if command -v brew &>/dev/null; then
    fpath+=("$(brew --prefix)/share/zsh/site-functions")
fi

# Enable completion cache.
zstyle ':completion::complete:*' use-cache on
zstyle ':completion::complete:*' cache-path ~/.zsh/cache

autoload -Uz compinit && compinit
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}' 'r:|[._-]=* r:|=*'

setopt noautomenu
setopt nomenucomplete

# Enable fzf keybindings for zsh.
if command -v fzf &>/dev/null; then
    if [[ -f ~/.fzf.zsh ]]; then
        source ~/.fzf.zsh
    else
        echo "⚠️  fzf installed, but ~/.fzf.zsh not found. Did you run the install script with --key-bindings?"
    fi
else
    echo "fzf not found. Install fzf for fuzzy finding capabilities."
fi

# Additional arguments for common commands.
alias grep='grep --color=auto'
alias find='find 2>/dev/null'
alias git-log='git log --graph --abbrev-commit --oneline --decorate --all'

# ls with color support.
if [[ "$OSTYPE" == "darwin"* ]]; then
    alias ls='ls -G'
else
    alias ls='ls --color=auto'
fi

# Sublime Text alias.
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

# Add Pure prompt path depending on platform.
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
export HISTSIZE=50000
export SAVEHIST=50000
setopt INC_APPEND_HISTORY
setopt HIST_IGNORE_DUPS
setopt EXTENDED_HISTORY
setopt HIST_REDUCE_BLANKS
setopt SHARE_HISTORY

# Misellaneous paths.
export SL_AWS=s3://ssa-external-upload-mini-gnss-production

# Fix Ctrl+Arrow and Alt+Arrow keys in zsh
autoload -Uz select-word-style
select-word-style bash

# Ctrl + Arrow
bindkey "^[[1;5D" backward-word  # Ctrl+Left
bindkey "^[[1;5C" forward-word   # Ctrl+Right

# Alt + Arrow
bindkey "^[^[[D" backward-word   # Alt+Left
bindkey "^[^[[C" forward-word    # Alt+Right
bindkey "^[[1;3D" backward-word   # Alt+Left
bindkey "^[[1;3C" forward-word    # Alt+Right
