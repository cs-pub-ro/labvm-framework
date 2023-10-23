#!/bin/bash
# User account (student) tweaks

# this will be executed as the `student` user
function _user_script() {
	mkdir -p "$HOME/.config"

	# example: setup zsh (oh-my-zsh)
	[[ -d ~/.oh-my-zsh/.git ]] || \
		git clone "https://github.com/ohmyzsh/ohmyzsh.git" ~/.oh-my-zsh
	cp ~/.oh-my-zsh/templates/zshrc.zsh-template ~/.zshrc
}

# switch user and execute the above function
echo "$(declare -f _user_script); _user_script" | su -c 'bash -e' student
chsh -s $(which zsh) student

