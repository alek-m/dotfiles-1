# ~/.bashrc
#
# pbrisbin 2010
#
# an attempt at a monolithic/portable bashrc
#
###

# get out if non-interactive
[[ -z "$PS1" ]] && return

### General options {{{

# is $1 installed?
_have() { which "$1" &>/dev/null; }

if [[ -f "$HOME/.lscolors" ]] && [[ $(tput colors) == "256" ]]; then
  # https://github.com/trapd00r/LS_COLORS
  eval $( dircolors -b $HOME/.lscolors )
fi

if [[ -f /etc/bash_completion ]]; then
  source /etc/bash_completion
  _have sudo && complete -cf sudo
fi

# bash 4 features
if [[ ${BASH_VERSINFO[0]} -ge 4 ]]; then
  shopt -s globstar
  shopt -s autocd
fi

shopt -s checkwinsize
shopt -s extglob

# should've done this a long time ago
set -o vi

# no flow control outside of the dumb tty
if [[ "$TERM" != 'linux' ]]; then
  stty -ixon -ixoff
fi

# list of apps to be tried in order
xbrowsers='browser:chromium:google-chrome:firefox'
browsers='elinks:lynx:links'
editors='vim:vi'

# }}}

### Overall conditionals/functions {{{

_islinux=false
[[ "$(uname -s)" =~ Linux|GNU|GNU/* ]] && _islinux=true

_isarch=false
[[ -f /etc/arch-release ]] && _isarch=true

_isxrunning=false
[[ -n "$DISPLAY" ]] && _isxrunning=true

_isroot=false
[[ $UID -eq 0 ]] && _isroot=true

# set $EDITOR
_set_editor() {
  local IFS=':' editor

  for editor in $editors; do
    editor="$(which $editor 2>/dev/null)"

    if [[ -x "$editor" ]]; then
      export EDITOR="$editor"
      export VISUAL="$EDITOR"
      break
    fi
  done
}

# set $BROWSER
_set_browser() {
  local IFS=':' _browsers="$*" browser

  for browser in $_browsers; do
    browser="$(which $browser 2>/dev/null)"

    if [[ -x "$browser" ]]; then
      export BROWSER="$browser"
      break
    fi
  done
}

# add directories to $PATH
_add_to_path() {
  local path

  for path in "$@"; do
    [[ -d "$path" ]] && [[ ! ":${PATH}:" =~ :${path}: ]] && export PATH=${path}:$PATH
  done
}

# ssh-agent stuff
_ssh_env="$HOME/.ssh/environment"

_start_agent() {
  [[ -d "$HOME/.ssh" ]] || return 1
  _have ssh-agent       || return 1

  ssh-agent | sed 's/^echo/#echo/g' > "$_ssh_env"

  chmod 600 "$_ssh_env"
  . "$_ssh_env" >/dev/null

  ssh-add
}

if [[ -f "$_ssh_env" ]]; then
  . "$_ssh_env" >/dev/null
  if ! ps "$SSH_AGENT_PID" | grep -q 'ssh-agent$'; then
    _start_agent
  fi
else
  _start_agent
fi

# }}}

### Bash exports {{{

# set path
_add_to_path "$HOME/.bin" "$HOME/Code/bin" "$HOME/.cabal/bin"

# set browser
$_isxrunning && _set_browser "$xbrowsers" || _set_browser "$browsers"

# set editor
_set_editor

# custom ip var
[[ -f "$HOME/.myip" ]] && export MYIP=$(cat "$HOME/.myip")

# custom log directory
[[ -d "$HOME/.logs" ]] && export LOGS="$HOME/.logs" || export LOGS='/tmp'

# screen tricks
if [[ -d "$HOME/.screen/configs" ]]; then
  export SCREEN_CONF_DIR="$HOME/.screen/configs"
  export SCREEN_CONF='main'
fi

# albumart.php
if _have albumart.php; then
  export AWS_LIB="$HOME/Code/php/albumart/lib"
  export AWS_CERT_FILE="$HOME/.aws/cert-67RVMJTXXBDL4ZZOYSYBI3A7ZP56N3XD.pem"
  export AWS_PRIVATE_KEY_FILE="$HOME/.aws/pk-67RVMJTXXBDL4ZZOYSYBI3A7ZP56N3XD.pem"
fi

# dmenu options
if _have dmenu; then
  # dmenu-xft required
  export DMENU_OPTIONS='-i -fn Verdana-8 -nb #303030 -nf #909090 -sb #909090 -sf #303030'
fi

# standard
export HISTSIZE=1000000
export HISTFILESIZE=1000000
export HISTTIMEFORMAT='%Y/%m/%d %H:%M '
export HISTIGNORE='&:ls:ll:la:cd:exit:clear:history'
export LANG=en_US.UTF-8
export LC_ALL=en_US.utf8

# less
if _have less; then
  export PAGER=less

  # these look terrible on a mac or in console
  if $_islinux && [[ "$TERM" != 'linux' ]]; then
    export LESS_TERMCAP_mb=$'\E[01;31m'       # begin blinking
    export LESS_TERMCAP_md=$'\E[01;38;5;74m'  # begin bold
    export LESS_TERMCAP_me=$'\E[0m'           # end mode
    export LESS_TERMCAP_se=$'\E[0m'           # end standout-mode
    export LESS_TERMCAP_so=$'\E[38;5;246m'    # begin standout-mode - info box
    export LESS_TERMCAP_ue=$'\E[0m'           # end underline
    export LESS_TERMCAP_us=$'\E[04;38;5;146m' # begin underline
  fi
fi

if _have mpc; then
  export MPD_HOST=192.168.0.5
  export MPD_PORT=6600
fi

# }}}

### Bash aliases {{{

# ssh
alias blue='ssh patrick@blue'
alias howie='ssh patrick@howard'
alias htpc='ssh xbmc@htpc'
alias susie='ssh patrick@susan'
alias slice='ssh patrick@50.56.101.27'

# only for linux
if $_islinux; then
  alias ls='ls -h --group-directories-first --color=auto'
else
  alias ls='ls -h'
fi

# standard
alias la='ls -la'
alias ll='ls -l'
alias grep='grep --color=auto'
alias myip='curl --silent http://tnx.nl/ip'
alias path='echo -e "${PATH//:/\n}"'

# only if we have mpc
if _have mpc; then
  alias addall='mpc --no-status clear && mpc listall | mpc --no-status add && mpc play'
  alias n='mpc next'
  alias p='mpc prev'
fi

if _have ossvol; then
  alias u='ossvol -i 3'
  alias d='ossvol -d 3'
  alias m='ossvol -t'
fi

# only if we have a screen_conf
if [[ -d "$SCREEN_CONF_DIR" ]]; then
  alias main='SCREEN_CONF=main screen -S main -D -R main'
  alias clean='SCREEN_CONF=clean screen -S clean -D -R clean'

  if _have rtorrent; then
    alias rtorrent='SCREEN_CONF=rtorrent screen -S rtorrent -R -D rtorrent'
    alias gtorrent='SCREEN_CONF=gtorrent screen -S gtorrent -R -D gtorrent'
  fi

  _have irssi && alias irssi='SCREEN_CONF=irssi screen -S irssi -R -D irssi'
fi

if _have colortail; then
  alias tailirc='/usr/bin/colortail -q -k /etc/colortail/conf.irc'
  alias colortail='colortail -q -k /etc/colortail/conf.messages'
fi

# need certain apps
_have curlpaste && alias pastie='curlpaste -s ghost -n pbrisbin'
_have hoogle    && alias hoogle='hoogle --color=true --n=10'
_have xprop     && alias xp='xprop | grep "^WM_WINDOW_ROLE\|^WM_CLASS\|^WM_NAME"'

# only if we have a disc drive
[[ -b '/dev/sr0' ]] && alias eject='eject -T /dev/sr0'

# only if we have xmonad
[[ -f "$HOME/.xmonad/xmonad.hs" ]] && alias checkmonad='(cd ~/.xmonad && ghci -ilib xmonad.hs)'

# only for mplayer
if _have mplayer; then
  alias playiso='mplayer dvd://1 -dvd-device'
  alias playdvd='mplayer dvdnav:// /dev/sr0'
  alias playcda='mplayer cdda:// -cdrom-device /dev/sr0 -cache 10000'
fi

# only for rdesktop
if _have rdesktop; then
  alias rdp='rdesktop -K -g 1280x1040'
  alias rdpat='rdesktop -K -g 1280x1040 -d GREENBEACON -u PBrisbin -p -'
  alias rdpfaf='rdesktop -K -g 1280x1040 -d FAF -u pbrisbin www.faf.com -p -'
  alias rdpste='rdesktop -K -g 1280x1040 -d STEINER -u pbrisbin -p -'
  alias rdpamp='rdesktop -K -g 1280x1040 -d Amp_Research -u beacon -p -'
fi

# pacman aliases
if $_isarch; then
  if ! $_isroot; then
    _have pacman-color && alias pacman='sudo pacman-color' || alias pacman='sudo pacman'
  else
    _have pacman-color && alias pacman='pacman-color'
  fi

  alias pacorphans='pacman -Rs $(pacman -Qtdq)'
  alias paccorrupt='sudo find /var/cache/pacman/pkg -name '\''*.part.*'\''' # sudo so we can quickly add -delete
  alias pactesting='pacman -Q $(pacman -Sql {community-,multilib-,}testing) 2>/dev/null'
fi

# ghc aliases
if _have ghc-pkg; then
  alias gc='ghc-pkg check'
  alias gl='ghc-pkg list'
  alias gu='ghc-pkg unregister'
fi

# }}}

### Bash functions {{{

# http://pbrisbin.com/posts/notes
noteit() {
  _have mutt || return 1

  local subject="$*" message

  [[ -z "$subject" ]] && { echo 'no subject.'; return 1; }

  echo -e "^D to save, ^C to cancel\nNote:\n"

  message="$(cat)"

  [[ -z "$message" ]] && { echo 'no message.'; return 1; }

  # send message
  echo "$message" | mutt -s "Note - $subject" -- pbrisbin@gmail.com

  echo -e "\nnoted.\n"
}

# cabal has no uninstall...
cabalremove() {
  local pkg="$1"

  [[ -d "$HOME/.cabal" ]] || return 1
  ghc-pkg unregister "$pkg" && find "$HOME/.cabal/" -depth -name "$pkg"'*' -exec rm -r {} \;
}

# update haskell documentation and publish it to my server
hdocs() {
  _have cabal || return 1

  # update
  cabal haddock \
    --html-location='http://hackage.haskell.org/packages/archive/$pkg/latest/doc/html' \
    --hyperlink-source "$@" || return 1

  # publish
  cp -r dist/doc/* /srv/http/haskell/docs/
}

# build/install haskell packages
hbuild() {
  _have cabal   || return 1
  cabal install || return 1
  hdocs "$@"    || return 1
}

# somewhat general build/deploy for a yesod app
toslice() {
  [[ -f ./fastcgi.hs ]] || return 1

  local ip="${1:-50.56.101.27}"

  touch ./Settings.hs # so CPP declarations take
  ghc -threaded -DPROD --make -o ./app.cgi ./fastcgi.hs && scp -r ./static ./app.cgi "$ip":~/
  touch ./Settings.hs
}

# once there we deploy
atslice() {
  sudo /etc/rc.d/lighttpd stop || return 1

  # sometimes lighttpd doesn't really stop
  pgrep app.cgi && return 2

  cp    /srv/http/app.cgi ./app.cgi.bak || return 1 
  cp -r /srv/http/static  ./static.bak  || return 1

  sudo cp    ./app.cgi  /srv/http/app.cgi || return 1
  sudo cp -r ./static/* /srv/http/static/ || return 1

  sudo /etc/rc.d/lighttpd start
}

# combine pdfs into one using ghostscript
combinepdf() {
  _have gs || return 1

  local out="$1"; shift

  gs -dBATCH -dNOPAUSE -q -sDEVICE=pdfwrite -sOutputFile="$out" "$@"
}

# make a thumb
thumbit() {
  _have mogrify || return 1

  for pic in "$@"; do
    case "$pic" in
      *.jpg)  thumb="${pic/.jpg/-thumb.jpg}"   ;;
      *.jpeg) thumb="${pic/.jpeg/-thumb.jpeg}" ;;
      *.png)  thumb="${pic/.png/-thumb.png}"   ;;
      *.bmp)  thumb="${pic/.bmp/-thumb.bmp}"   ;;
    esac

    [[ -z "$thumb" ]] && return 1

    cp "$pic" "$thumb" && mogrify -resize 10% "$thumb"
  done
}

# rip a dvd with handbrake
hbrip() {
  _have HandBrakeCLI || return 1

  local name="$1" out drop="$HOME/Movies"; shift
  [[ -d "$drop" ]] || mkdir -p "$drop"

  out="$drop/$name.mp4"

  echo "rip /dev/sr0 --> $out"
  HandBrakeCLI -Z iPad "$@" -i /dev/sr0 -o "$out" 2>/dev/null
  echo
}

# convert media to ipad format with handbrake
hbconvert() {
  _have HandBrakeCLI || return 1

  local in="$1" out drop="$HOME/Movies/converted"; shift
  [[ -d "$drop" ]] || mkdir -p "$drop"

  out="$drop/$(basename "${in%.*}").mp4"

  echo "convert $in --> $out"
  HandBrakeCLI -Z iPad "$@" -i "$in" -o "$out" 2>/dev/null
  echo
}

# share a file out of my public dropbox
#dbshare() {
#  local db="$HOME/Dropbox/Public" uid='472835' file url
#
#  file="${1/$db/}"
#
#  [[ -f "$db/$file" ]] || return 1
#
#  url="http://dl.dropbox.com/u/$uid/$file"
#
#  echo -n "$url" | xlip 2>/dev/null
#
#  echo "$url"
#}

# simple spellchecker, uses /usr/share/dict/words
spellcheck() {
  [[ -f /usr/share/dict/words ]] || return 1

  for word in "$@"; do
    if grep -Fqx "$word" /usr/share/dict/words; then
      echo -e "\e[1;32m$word\e[0m" # green
    else
      echo -e "\e[1;31m$word\e[0m" # red
    fi
  done
}

# go to google for anything
google() {
  [[ -z "$BROWSER" ]] && return 1

  local term="${*:-$(xclip -o)}"

  $BROWSER "http://www.google.com/search?q=${term// /+}" &>/dev/null &
}

# go to google for a definition 
define() {
  _have lynx || return 1

  local lang charset tmp

  lang="${LANG%%_*}"
  charset="${LANG##*.}"
  tmp='/tmp/define'
  
  lynx -accept_all_cookies \
       -dump \
       -hiddenlinks=ignore \
       -nonumbers \
       -assume_charset="$charset" \
       -display_charset="$charset" \
       "http://www.google.com/search?hl=$lang&q=define%3A+$1&btnG=Google+Search" | grep -m 5 -C 2 -A 5 -w "*" > "$tmp"

  if [[ ! -s "$tmp" ]]; then
    echo -e "No definition found.\n"
  else
    echo -e "$(grep -v Search "$tmp" | sed "s/$1/\\\e[1;32m&\\\e[0m/g")\n"
  fi

  rm -f "$tmp"
}

#
# just use readlink -f
#
# accepts a relative path and returns an absolute 
#rel2abs() {
#  local file dir
#
#  file="$(basename "$1")"
#  dir="$(dirname "$1")"
#
#  pushd "${dir:-./}" &>/dev/null || return 1
#  echo "$PWD/$file"
#  popd &>/dev/null
#}

# grep by paragraph 
grepp() { perl -00ne "print if /$1/i" < "$2"; }

# pull a single file out of a .tar.gz, stops on first match
# useful for .PKGINFO files in .pkg.tar.gz files
pullout() {
  $_islinux || return 1

  [[ "$2" =~ .tar.gz$|.tgz$ ]] || return 1

  gunzip < "$2" | bsdtar -qxf - "$1"
}

# recursively 'fix' dir/file perm
fix() {
  local dir

  for dir in "$@"; do
    find "$dir" -type d -exec chmod 755 {} \; 
    find "$dir" -type f -exec chmod 644 {} \;
  done
}

markdown2html() {
  _have pandoc || return 1

  local in="$1" out; shift

  out="${in%.*}.html"

  pandoc -f markdown -t html -o "$out" "$@" "$in"
  echo "created: $out"
}

# print docs to default printer in reverse page order 
printr() {
  _have enscript || return 1

  local file

  # files on commandline
  if [[ $# -ne 0 ]]; then
    for file in "$@"; do
      enscript -p - "$file" | psselect -r | lp
    done
  # try stdin
  else
    local IFS=$'\n'

    (while read -r; do
      echo "$REPLY"
    done) | enscript -p - | psselect -r | lp
  fi
}

# set an ad-hoc GUI timer 
timer() {
  $_isxrunning || return 1
  _have zenity || return 1

  local N=$1; shift

  (sleep $N && zenity --info --title="Time's Up" --text="${*:-DING}") &
  echo "timer set for $N"
}

# auto send an attachment from CLI 
send() {
  _have mutt    || return 1
  [[ -f "$1" ]] || return 1
  [[ -z "$2" ]] || return 1

  echo 'Auto-sent from linux. Please see attached.' | mutt -s 'File Attached' -a "$1" -- "$2"
}

# run a bash script in 'debug' mode
debug() {
  local script="$1"; shift

  if _have "$script"; then
    PS4='+$LINENO:$FUNCNAME: ' bash -x "$script" "$@"
  fi
}

# print the url to a manpage
webman() { echo "http://unixhelp.ed.ac.uk/CGI/man-cgi?$1"; }

# }}}

### Titlebar and Prompt {{{
#
# A simplification on http://volnitsky.com/project/git-prompt/.
#
# todo: did i break screen command recognition?
#
###

# colors setup {{{

# element colors
host_color=WHITE
retval_color=WHITE
sep_color=BLUE
root_sep_color=RED

# vcs colors
init_vcs_color=white
clean_vcs_color=white
modified_vcs_color=red
added_vcs_color=green
addmoded_vcs_color=yellow
untracked_vcs_color=white
op_vcs_color=magenta
detached_vcs_color=red
hex_vcs_color=white

# term color codes
black='\['`tput sgr0; tput setaf 0`'\]'
red='\['`tput sgr0; tput setaf 1`'\]'
green='\['`tput sgr0; tput setaf 2`'\]'
yellow='\['`tput sgr0; tput setaf 3`'\]'
blue='\['`tput sgr0; tput setaf 4`'\]'
magenta='\['`tput sgr0; tput setaf 5`'\]'
cyan='\['`tput sgr0; tput setaf 6`'\]'
white='\['`tput sgr0; tput setaf 7`'\]'

BLACK='\['`tput setaf 0; tput bold`'\]'
RED='\['`tput setaf 1; tput bold`'\]'
GREEN='\['`tput setaf 2; tput bold`'\]'
YELLOW='\['`tput setaf 3; tput bold`'\]'
BLUE='\['`tput setaf 4; tput bold`'\]'
MAGENTA='\['`tput setaf 5; tput bold`'\]'
CYAN='\['`tput setaf 6; tput bold`'\]'
WHITE='\['`tput setaf 7; tput bold`'\]'

colors_reset='\['`tput sgr0`'\]'

# replace symbolic colors names to raw terminfo strings
host_color=${!host_color}
retval_color=${!retval_color}
sep_color=${!sep_color}
root_sep_color=${!root_sep_color}

init_vcs_color=${!init_vcs_color}
modified_vcs_color=${!modified_vcs_color}
untracked_vcs_color=${!untracked_vcs_color}
clean_vcs_color=${!clean_vcs_color}
added_vcs_color=${!added_vcs_color}
op_vcs_color=${!op_vcs_color}
addmoded_vcs_color=${!addmoded_vcs_color}
detached_vcs_color=${!detached_vcs_color}
hex_vcs_color=${!hex_vcs_color}

# }}}

_parse_git_status() { # {{{
  local git_dir file_regex added_files modified files untracked_files
  local freshness op rawhex branch vcs_info status vcs_color

  git_dir="$(git rev-parse --git-dir 2> /dev/null)"
  
  if [[  -n ${git_dir/./} ]]; then
    file_regex='\([^/ ]*\/\{0,1\}\).*'
    added_files=()
    modified_files=()
    untracked_files=()
    freshness="="

    # quoting hell
    eval "$(
      git status 2>/dev/null |
      sed -n '
      s/^# On branch /branch=/p
      s/^nothing to commi.*/clean=clean/p
      s/^# Initial commi.*/init=init/p

      s/^# Your branch is ahead of .[/[:alnum:]]\+. by [[:digit:]]\+ commit.*/freshness=${WHITE}↑/p
      s/^# Your branch is behind .[/[:alnum:]]\+. by [[:digit:]]\+ commit.*/freshness=${YELLOW}↓/p
      s/^# Your branch and .[/[:alnum:]]\+. have diverged.*/freshness=${YELLOW}↕/p

      /^# Changes to be committed:/,/^# [A-Z]/ {
      s/^# Changes to be committed:/added=added;/p
      s/^#	modified:   '"$file_regex"'/	[[ \" ${added_files[*]} \" =~ \" \1 \" ]] || added_files[${#added_files[@]}]=\"\1\"/p
      s/^#	new file:   '"$file_regex"'/	[[ \" ${added_files[*]} \" =~ \" \1 \" ]] || added_files[${#added_files[@]}]=\"\1\"/p
      s/^#	renamed:[^>]*> '"$file_regex"'/	[[ \" ${added_files[*]} \" =~ \" \1 \" ]] || added_files[${#added_files[@]}]=\"\1\"/p
      s/^#	copied:[^>]*> '"$file_regex"'/ 	[[ \" ${added_files[*]} \" =~ \" \1 \" ]] || added_files[${#added_files[@]}]=\"\1\"/p
      }

      /^# Changed but not updated:/,/^# [A-Z]/ {
      s/^# Changed but not updated:/modified=modified;/p
      s/^#	modified:   '"$file_regex"'/	[[ \" ${modified_files[*]} \" =~ \" \1 \" ]] || modified_files[${#modified_files[@]}]=\"\1\"/p
      s/^#	unmerged:   '"$file_regex"'/	[[ \" ${modified_files[*]} \" =~ \" \1 \" ]] || modified_files[${#modified_files[@]}]=\"\1\"/p
      }

      /^# Changes not staged for commit:/,/^# [A-Z]/ {
      s/^# Changes not staged for commit:/modified=modified;/p
      s/^#	modified:   '"$file_regex"'/	[[ \" ${modified_files[*]} \" =~ \" \1 \" ]] || modified_files[${#modified_files[@]}]=\"\1\"/p
      s/^#	unmerged:   '"$file_regex"'/	[[ \" ${modified_files[*]} \" =~ \" \1 \" ]] || modified_files[${#modified_files[@]}]=\"\1\"/p
      }

      /^# Unmerged paths:/,/^[^#]/ {
      s/^# Unmerged paths:/modified=modified;/p
      s/^#	both modified:\s*'"$file_regex"'/	[[ \" ${modified_files[*]} \" =~ \" \1 \" ]] || modified_files[${#modified_files[@]}]=\"\1\"/p
      }

      /^# Untracked files:/,/^[^#]/{
      s/^# Untracked files:/untracked=untracked;/p
      s/^#	'"$file_regex"'/		[[ \" ${untracked_files[*]} ${modified_files[*]} ${added_files[*]} \" =~ \" \1 \" ]] || untracked_files[${#untracked_files[@]}]=\"\1\"/p
      }
      '
    )"

    grep -q "^ref:" $git_dir/HEAD 2>/dev/null || detached=detached

    if [[ -d "$git_dir/.dotest" ]] ;  then
      if [[ -f "$git_dir/.dotest/rebasing" ]] ;  then
        op="rebase"
      elif [[ -f "$git_dir/.dotest/applying" ]] ; then
        op="am"
      else
        op="am/rebase"
      fi
    elif  [[ -f "$git_dir/.dotest-merge/interactive" ]] ;  then
      op="rebase -i"
      # ??? branch="$(cat "$git_dir/.dotest-merge/head-name")"
    elif  [[ -d "$git_dir/.dotest-merge" ]] ;  then
      op="rebase -m"
      # ??? branch="$(cat "$git_dir/.dotest-merge/head-name")"

      # lvv: not always works. Should  ./.dotest  be used instead?
    elif  [[ -f "$git_dir/MERGE_HEAD" ]] ;  then
      op="merge"
      # ??? branch="$(git symbolic-ref HEAD 2>/dev/null)"
    elif  [[ -f "$git_dir/index.lock" ]] ;  then
      op="locked"
    else
      [[  -f "$git_dir/BISECT_LOG"  ]]   &&  op="bisect"
      # ??? branch="$(git symbolic-ref HEAD 2>/dev/null)" || \
      #     branch="$(git describe --exact-match HEAD 2>/dev/null)" || \
      #     branch="$(cut -c1-7 "$git_dir/HEAD")..."
    fi

    rawhex=$(git rev-parse HEAD 2>/dev/null)
    rawhex=${rawhex/HEAD/}
    rawhex="$hex_vcs_color${rawhex:0:5}"

    if [[ $init ]];  then 
      vcs_info=${white}init
    else
      if [[ "$detached" ]] ;  then
        branch="<detached:`git name-rev --name-only HEAD 2>/dev/null`"
      elif   [[ "$op" ]];  then
        branch="$op:$branch"
        if [[ "$op" == "merge" ]] ;  then
          branch+="<--$(git name-rev --name-only $(<$git_dir/MERGE_HEAD))"
        fi
        #branch="<$branch>"
      fi
      vcs_info="$branch$freshness$rawhex"
    fi

    status=${op:+op}
    status=${status:-$detached}
    status=${status:-$clean}
    status=${status:-$modified}
    status=${status:-$added}
    status=${status:-$untracked}
    status=${status:-$init}
    eval vcs_color="\${${status}_vcs_color}"

    [[ ${added_files[0]}     ]] && file_list+=" "$added_vcs_color${added_files[@]}
    [[ ${modified_files[0]}  ]] && file_list+=" "$modified_vcs_color${modified_files[@]}
    [[ ${untracked_files[0]} ]] && file_list+=" "$untracked_vcs_color${untracked_files[@]}

# todo: bring back limiting, but do it by number of files, not number of
# characters -- if you cut off a terminal color escape the whole prompt
# falls apart
#    if [[ ${#file_list} -gt 100 ]]; then
#      file_list=${file_list:0:100}
#    fi

    echo "$vcs_color${vcs_info}$vcs_color${file_list}$colors_reset/"
  else
    echo "${PWD/$HOME/~}/"
  fi
}

# }}}

prompt_command_function() {
  local retval="$?" _screen _sep_color host_retval

  # sep changes colors for root
  $_isroot && _sep_color=$root_sep_color || _sep_color=$sep_color

  # add control characters for screen
  [[ -n "$STY" ]] && _screen='\[\ek\e\\\]\[\ek\w\e\\\]' || _screen=''

  # parse git info if we're in a git repo
  git_info="$(_parse_git_status)"

  # set the main section
  host_retval=${_sep_color}//${host_color}$HOSTNAME${_sep_color}/${retval_color}${retval}${_sep_color}/${colors_reset}

  # add the git or cwd info
  PS1="${_screen}${host_retval}${git_info} "
  PS2="${_sep_color}//${colors_reset} "
}

unset PROMPT_COMMAND
PROMPT_COMMAND=prompt_command_function
# }}}

### Starting X {{{

# auto startx if on tty1 and logout if/when X ends
if [[ $(tty) = /dev/tty1 ]] && ! $_isroot && ! $_isxrunning; then
  _set_browser "$xbrowsers"

  startx | tee "$LOGS/X.log"
  logout
fi

# }}}
