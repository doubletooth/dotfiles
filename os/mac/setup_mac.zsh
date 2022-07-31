#!/usr/bin/env zsh

RED="\033[1;31m"
GREEN="\033[1;32m"
WARNING="\033[93m"
NOCOLOR="\033[0m"

function print_red() {
  echo "${RED}$1${NOCOLOR}"
}

function print_green() {
  echo "${GREEN}$1${NOCOLOR}"
}

function print_warning() {
  echo "${WARNING}$1${NOCOLOR}"
}

function add_to_file() {
  local filepath=$1
  local string_to_add=$2
  local string_description=$3
  local protected_file=$4

  if grep -Fxq "${string_to_add}" "${filepath}"
  then
    print_warning "${string_description} already in ${filepath}, skipping."
  else
    if [ -z "${protected_file}" ]
    then
      echo "${string_to_add}" >> "${filepath}"
    else
      echo "${string_to_add}" | sudo tee -a "${filepath}" >> /dev/null
    fi
  fi
}

print_green "Installing developer tools for MacOS Operating System"
echo -n "${WARNING}Please enter your sudo password: ${NOCOLOR}"

# -r for properly escaping backslashes
# -s for not echoing password
read -r -s sudo_password

print_green "\nValidating sudo password"
# -S to read password from stdin
# -k not to use any previous cached auth
if ! echo "${sudo_password}" | sudo -S -k -u root true 2> /dev/null;
then
    print_red "Invalid sudo password provided, failing setup script"
    exit 1
fi
xcode-select --install
sudo touch /etc/paths.d/900-akshay

if [[ $(sysctl -a machdep.cpu.brand_string | awk '{ print $2 }') = "Apple" ]]; then
  print_green "Determined ARM install"
  export SYSTEM_VERSION="ARM"

  export HOMEBREW_PREFIX="/opt/homebrew";
  export HOMEBREW_CELLAR="/opt/homebrew/Cellar";
  export HOMEBREW_REPOSITORY="/opt/homebrew";
  export PATH="/opt/homebrew/bin:/opt/homebrew/sbin${PATH+:$PATH}";
  export MANPATH="/opt/homebrew/share/man${MANPATH+:$MANPATH}:";
  export INFOPATH="/opt/homebrew/share/info:${INFOPATH:-}";
else
  print_green "Determined Intel install"
  export SYSTEM_VERSION="Intel"

  export HOMEBREW_PREFIX="/usr/local";
  export HOMEBREW_CELLAR="/usr/local/Cellar";
  export HOMEBREW_REPOSITORY="/usr/local/Homebrew";
  export PATH="/usr/local/bin:/usr/local/sbin${PATH+:$PATH}";
  export MANPATH="/usr/local/share/man${MANPATH+:$MANPATH}:";
  export INFOPATH="/usr/local/share/info:${INFOPATH:-}";
fi

if [[ "${SYSTEM_VERSION}" = "ARM" ]]; then
  print_green "Installing Rosetta2 if it is not installed"
  if pgrep oahd > /dev/null; then
    print_green "Rosetta2 is already installed, skipping!"
  else
    sudo softwareupdate --install-rosetta --agree-to-license
  fi
fi

print_green "Installing package manager"
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

print_green "Installing shell"
brew install --cask iterm2

# Install oh my zsh to machine
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh) --unattended"

print_green "Installing zshrc additions"
add_to_file ~/.zshrc "$(curl -sSL https://raw.githubusercontent.com/doubletooth/dotfiles/main/tools/zsh/zshrc)" "path updates"
add_to_file /etc/paths.d/900-akshay "/opt/homebrew/bin" "brew path update"

print_green "Installing secrets manager"
brew install --cask 1password
brew install --cask 1password-cli

print_green "Installing GPG Tools"
brew install gnupg
brew install --cask keybase

# Install gpg agent. This will grab your signing-key password the first time you ever commit
brew install pinentry-mac
if [[ "${SYSTEM_VERSION}" = "ARM" ]]; then
  echo "pinentry-program /opt/homebrew/bin/pinentry-mac" >> ~/.gnupg/gpg-agent.conf
else
  echo "pinentry-program /usr/local/bin/pinentry-mac" >> ~/.gnupg/gpg-agent.conf
fi
killall gpg-agent

print_green "Installing VPN"
brew install --cask private-internet-access

print_green "Installing virtualization tools"
brew install docker
brew install minikube

print_green "Installing editors"
brew install --cask sublime-text sublime-merge
brew install --cask jetbrains-toolbox

add_to_file ~/.vimrc "$(curl -sSL https://raw.githubusercontent.com/doubletooth/dotfiles/main/tools/vim/vimrc)" "vim syntax updates"

print_green "Installing communication tools"
brew install --cask whatsapp
brew install --cask slack

print_green "Installing python tooling"
PYTHON_VERSION="3.10.4"
PYTHON2_VERSION="2.7.18"

# shellcheck disable=SC2016
PYENV_ZSHRC_ENTRY='
export PYENV_ROOT="$HOME/.pyenv"
eval "$(pyenv init --path)"
eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"
'
add_to_file ~/.zshrc "${PYENV_ZSHRC_ENTRY}" "pyenv shell setup"

brew install openssl readline sqlite3 xz zlib pyenv pyenv-virtualenv
brew upgrade pyenv pyenv-virtualenv

eval "$(pyenv init --path)"
pyenv install -s "${PYTHON_VERSION}"
pyenv install -s "${PYTHON2_VERSION}"
pyenv global "${PYTHON_VERSION}" "${PYTHON2_VERSION}"

print_green "Installing poetry"
curl -sSL https://install.python-poetry.org/ | python3 -

POETRY_PATH_UPDATE="${HOME}/.local/bin"
add_to_file "/etc/paths.d/900-akshay" "${POETRY_PATH_UPDATE}" "poetry bin path update" "true"

print_green "Installing golang tools"
brew install go@1.17
brew install go

print_green "Installing jq and yq"
brew install jq yq
brew upgrade jq yq

# Other language environments to setup
# nvm/node
# TeX
# Rust

# shellcheck disable=SC2016
print_green 'Installed what we could, please restart your shell (exec $SHELL)'
exit 0
