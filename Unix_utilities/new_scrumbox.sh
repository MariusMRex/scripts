#!/bin/bash

# Lets make sure there is an augment to this script
if [ $# -eq 0 ]; then
    echo "Usage: $0 [runbox|codebox|fatbox]"
    echo "Please provide an argument to this script so we can target the host."
    exit 1
fi

# Copy up .ssh keys, .gitconfig and .gnupg
/usr/bin/scp -r ~/.ssh/scrumbox/* $1:~/.ssh/
/usr/bin/scp -r ~/.gnupg/scrumbox/* $1:~/.gnupg/
/usr/bin/scp ~/.gitconfig-vm $1:~/.gitconfig

# Minimal bash config
/usr/bin/scp ~/.bashrc-scrumbox $1:~/.local/include/shell/70-mrex-custimizations

# Make vim a bit more friendly
/usr/bin/scp ~/.vimrc-portable $1:~/.vimrc

/bin/echo '------------------------------'
/bin/echo "Now ssh to the $1 and run:"
/bin/echo 'git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim'
/bin/echo 'vim +PluginInstall +qall'

