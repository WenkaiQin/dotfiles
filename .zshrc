# De-duplicate fpath. Just in case!
typeset -U fpath 
if command -v brew &>/dev/null; then
  fpath+=("$(brew --prefix)/share/zsh/site-functions")
fi

# Setup Zsh completion cache. Then, load compinit with cache support.
ZSH_CACHE_DIR="$HOME/.zsh/cache"
mkdir -p "$ZSH_CACHE_DIR"

zstyle ':completion::complete:*' use-cache on
zstyle ':completion::complete:*' cache-path "$ZSH_CACHE_DIR"

# Enhanced UI
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*' group-name ''
zstyle ':completion:*:descriptions' format '%F{yellow}%d%f'
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}' 'r:|[._-]=* r:|=*'
# zstyle ':completion:*' menu yes select

setopt noautomenu
autoload -Uz compinit

zcompdump="${ZSH_CACHE_DIR}/zcompdump"
if [[ -s "$zcompdump" ]]; then
    compinit -d "$zcompdump"
else
    compinit -C -d "$zcompdump"
fi

# Enable fzf key bindings and completions if available.
fzf_source_file="$HOME/.fzf.zsh"

# Source the fzf bin. Linux requires special treatment since we install it using git.
if [[ "$OSTYPE" == "linux"* ]]; then
    export PATH="$HOME/.fzf/bin:$PATH"
fi

if command -v fzf &>/dev/null; then

    # Detect fzf version -- too low, need above 0.48 for keybindings and
    # completions.
    fzf_version=$(fzf --version | awk '{print $1}')
    min_version="0.48"
    if [[ "$(printf '%s\n' "$fzf_version" "$min_version" | sort -V | head -n1)" == "$min_version" ]]; then
        echo "⚠️  fzf version $fzf_version is less than $min_version - key bindings and completions may not be available."
    fi

    # Detect no fzf source file found.
    if [[ ! -r "$fzf_source_file" ]]; then
        fzf_bin_path="$(command -v fzf)"
        fzf_base_dir="${fzf_bin_path:h:h}"
        echo "⚠️  fzf is installed at $fzf_bin_path but completions are missing. Run \"$fzf_base_dir/install\" to generate key bindings and completions."
    else
        source "$fzf_source_file"
    fi
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

# Add Pure prompt path if on Linux. On Mac, Homebrew covers it.
if [[ "$OSTYPE" == "linux"* ]] && [[ -d "$HOME/.zsh/pure" ]]; then
    fpath+=("$HOME/.zsh/pure")
fi

autoload -Uz promptinit; promptinit;
zstyle :prompt:pure:git:stash show yes
if type prompt_pure_setup &>/dev/null; then
  prompt pure
fi

# Syntax highlighting.
if [[ -f /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]]; then
  source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
elif [[ -f /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]]; then
  source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
elif [[ -f "$HOME/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]]; then
  source "$HOME/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
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

bindkey -e

# Sync history across sessions safely
autoload -Uz add-zsh-hook
sync-history() {
    builtin fc -AI
}
add-zsh-hook precmd sync-history
