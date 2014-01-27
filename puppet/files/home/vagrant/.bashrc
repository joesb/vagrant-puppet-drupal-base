# .bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
	. /etc/bashrc
fi

# User specific aliases and functions
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/usr/local/rvm/bin:/usr/sbin:/sbin:/bin

# commandline style
export PS1="\[\e[36;1m\]\u@\h\[\e[0m\]:\[\e[34;1m\]\w\[\e[0m\]$ "