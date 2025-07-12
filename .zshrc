# Setup Zsh completion cache.
ZSH_CACHE_DIR="$HOME/.zsh/cache"
mkdir -p "$ZSH_CACHE_DIR"

zstyle ':completion::complete:*' use-cache on
zstyle ':completion::complete:*' cache-path "$ZSH_CACHE_DIR"

# Load compinit with cache support.
autoload -Uz compinit
zcompdump="${ZSH_CACHE_DIR}/zcompdump"
if [[ -s "$zcompdump" ]]; then
    compinit -d "$zcompdump"
else
    compinit -C -d "$zcompdump"
fi
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}' 'r:|[._-]=* r:|=*'

setopt noautomenu
setopt nomenucomplete

# Enable fzf key bindings and completions if available
if [[ "$OSTYPE" == "linux"* ]] && [[ -x "$HOME/.fzf/bin/fzf" ]]; then
    export PATH="$HOME/.fzf/bin:$PATH"
    fzf_version=$("$HOME/.fzf/bin/fzf" --version | awk '{print $1}')
    min_version="0.48"
    fzf_source_file="$HOME/.fzf.zsh"
    if [[ "$(printf '%s\n' "$min_version" "$fzf_version" | sort -V | head -n1)" != "$min_version" ]]; then
        echo "⚠️  fzf version $fzf_version is less than $min_version — key bindings and completions may not be available."
    elif [[ ! -r "$fzf_source_file" ]]; then
        echo "⚠️  fzf found in ~/.fzf but ~/.fzf.zsh is missing. Run ~/.fzf/install to generate key bindings and completions."
    else
        source "$fzf_source_file"
    fi
else
    echo "⚠️  fzf not found. Install it to enable fuzzy finding features."
fi

# Additional arguments for common commands.
alias grep='grep --color=auto'
alias find='find 2>/dev/null'

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

autoload -Uz promptinit; promptinit;
zstyle :prompt:pure:git:stash show yes
prompt pure

# Syntax highlighting.
if [[ -f /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]]; then
  source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
elif [[ -f /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]]; then
  source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi

# History settings.
export HISTFILE=~/.zsh_history
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
bindkey "^[[1;5D" backward-word     # Ctrl+Left
bindkey "^[[1;5C" forward-word      # Ctrl+Right

# Alt + Arrow
bindkey "^[^[[D" backward-word      # Alt+Left
bindkey "^[^[[C" forward-word       # Alt+Right
bindkey "^[[1;3D" backward-word     # Alt+Left
bindkey "^[[1;3C" forward-word      # Alt+Right

# Sync history across sessions safely
autoload -Uz add-zsh-hook
sync-history() {
    builtin fc -AI
}
add-zsh-hook precmd sync-history
