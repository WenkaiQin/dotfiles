# Autocomplete fixing.
autoload -Uz compinit && compinit
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}' 'r:|[._-]=* r:|=*'

setopt noautomenu
setopt nomenucomplete

# Additional arguments for common commands.
alias grep='grep --color=auto'
alias ls='ls --color=auto'
alias subl='/Applications/Sublime\ Text.app/Contents/SharedSupport/bin/subl'
alias latexindent='~/latexindent-macos'
alias find='find 2>/dev/null'

# Pangea stuff.
export BIBINPUTS=~/Workspace/pangea/:
export BSTINPUTS=~/Workspace/pangea/texStyleFiles:
export TEXINPUTS=~/Workspace/pangea/texStyleFiles:

# Source prompt.
# source ~/agkozak-zsh-prompt.plugin.zsh

if command -v brew &>/dev/null; then
  fpath+=("$(brew --prefix)/share/zsh/site-functions")
fi
autoload -U promptinit; promptinit;
zstyle :prompt:pure:git:stash show yes
prompt pure

# Syntax highlighting.
if [[ -f /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]]; then
  source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
elif [[ -f /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]]; then
  source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi

# eval "$(starship init zsh)"

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
