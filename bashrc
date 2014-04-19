# Test for an interactive shell.  There is no need to set anything
# past this point for scp and rcp, and it's important to refrain from
# outputting anything in those cases.
if [[ $- != *i* ]] ; then
    # Set path
    PATH=$PATH:~/bin:/usr/local/bin:/opt/local/bin
    export $PATH

    # Shell is non-interactive.  Be done now!
    return
fi

# Find vim and set to EDITOR then alias vi, if not found set EDITOR to vi
if [ -e `which vim` ]
then
    EDITOR=`which vim`;export EDITOR
    alias vi='vim'
else
    EDITOR=`which vi`;export EDITOR
fi
# didn't find vi? what the hell

# Set path
PATH=$PATH:~/bin:/usr/local/bin:/opt/local/bin

# Git prompt
function _git_prompt() {
    GIT_PS1_SHOWDIRTYSTATE=1
    GIT_PS1_SHOWUPSTREAM="auto"
    local git_status="`git status -unormal 2>&1`"
    if ! [[ "$git_status" =~ Not\ a\ git\ repo ]]; then
        if [[ "$git_status" =~ nothing\ to\ commit ]]; then
            local ansi=32
        elif [[ "$git_status" =~ nothing\ added\ to\ commit\ but\ untracked\ files\ present ]]; then
            local ansi=34
        else
            local ansi=33
        fi  
        echo -n '\[\e[0;33;'"$ansi"'m\]'"$(__git_ps1)"'\[\e[0m\]'
    fi
}
# source in git-prompt.sh
if [ -e ~/.git-prompt.sh ]
then
    source ~/.git-prompt.sh
fi

# prompt colors
RCol='\[\e[0m\]'    # Text Reset
# set user to red if root otherwise green
if [ $UID -eq "0" ];then
    User='\[\e[0;31m\]'  # Red
else
    User='\[\e[0;32m\]'  # Green
fi
# set hostname to red if ssh otherwise blue for local
if [ -n "$SSH_TTY" ]; then
    Host='\[\e[0;31m\]'  # Red
else
    Host='\[\e[0;34m\]'  # Blue
fi
Red='\[\e[0;31m\]'  # Red
Gre='\[\e[0;32m\]'  # Green
Yel='\[\e[0;33m\]'  # Yellow
Blu='\[\e[0;34m\]'  # Blue
Pur='\[\e[0;35m\]'  # Purple
Cya='\[\e[0;36m\]'  # Cyan
Whi='\[\e[0;37m\]'  # White

# set prompt command
function _prompt_command() {
    PS1="${Whi}[${User}\u${Whi}@${Host}\h${Whi} ${Yel}\w ${Whi}!\!]`_git_prompt`\$ ${RCol}"
}
PROMPT_COMMAND=_prompt_command

# User specific aliases and functions
alias ll="ls -lh"
alias crontab='crontab -i'
# clear blank lines from input
alias cl="perl -le 'print $==grep(/\w+/,<>)'"
# clear comments from input
alias clearcomment="perl -e 'print @1=grep(/^[^#]/,<>)'"
# get sizes from current directory
alias dsize='du -hc --max-depth=1'
alias ls='ls --color'
# gpg encrypt/decrypt
alias encrypt='gpg --recipient user@example.net --encrypt'
alias decrypt='gpg --decrypt' 
# android connect device
alias android-connect='mtpfs -o allow_other /media/android'
alias android-disconnect='fusermount -u /media/android'
# edit vim encrypted file without needing separate vimrc
alias vimc='vim --cmd "set cm=blowfish" --cmd "set viminfo=" -x'

# make aliases work with sudo
alias sudo='sudo '

# creating functions with aliases to pass arguements
# function foo() { /path/to/command "$@" ;}

# generate X random characters
function genrandom() { /usr/bin/date +%s | /usr/bin/sha256sum | /usr/bin/base64 | /usr/bin/head -c "$@"; echo; }

# if no arguements are passed to ps assume auxx otherwise use what was passed
function __ps {                                                                
         if [ $1 ]; then
            ps "$@"                                                       
         else
            ps "auxx"
         fi                                                                     
} 
alias ps='__ps'

# some OS specific considerations
MYOS=`uname -a | awk '{print $1}'`
if [ "$MYOS" = "SunOS" ]
then
    unalias ls
    unalias vi
fi

if [ "$MYOS" = "FreeBSD" ]
then
    unalias ls
    alias ls='ls -G'
    unalias ps
fi

if [ "$MYOS" = "Darwin" ]
then
    unalias ls
    alias ls='ls -G'
    PATH=$PATH:/sw/bin:/sw/sbin
fi

# export PATH do this after OS modifications
export PATH

# auto generate ssh session aliases
# if .ssh/config exists
if [ -e ~/.ssh/config ]
then
    for name in `sed -n "/^Host/s/^Host //p" ~/.ssh/config`; do alias $name="ssh $name"; done
fi

# if this is a remote system attach/create default tmux session
if [ -n "$SSH_TTY" ]; then
    if which tmux 2>&1 >/dev/null; then
        #if not inside a tmux session, and if no session is started, start a new session
        test -z "$TMUX" && (tmux attach -t default || tmux new-session -s default)
    fi
fi
