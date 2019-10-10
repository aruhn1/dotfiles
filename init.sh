#!/bin/bash
set -e

[[ "$(uname -s)" = "Darwin" ]] && current_os="Mac" || current_os="Linux"

echo "Initializing dotfiles for a $current_os setup..."
echo ""

if [[ ! -d "$HOME/dotfiles" ]]; then
  echo "Cloning dotfiles to $HOME/dotfiles"
  git clone git@github.com:mlaursen/dotfiles.git "$HOME/dotfiles"
else
  echo "$HOME/dotfiles found... skipping clone."
fi

cd "$HOME/dotfiles"

dotfiles=( ".bashrc" ".bash_profile" ".gitconfig" ".vimrc" )

echo ""
echo "Symlinking default dotfiles with backups..."
for file in "${dotfiles[@]}"; do
  if [ -h "$HOME/$file" ]; then
    echo "Skipping \"$HOME/$file\" since it is already a symlink..."
  else
    if [ -f "$HOME/$file" ]; then
      mv -v "$HOME/$file" "$HOME/$file.bak"
    fi

    ln -s "$HOME/dotfiles/$file" "$HOME/$file"
  fi
done

source ~/.bash_profile

echo ""
if [[ ! -d "$HOME/.nvm" ]]; then 
  echo "Installing nvm..."
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.35.0/install.sh | bash

  source "$HOME/.bashrc"
else
  echo "nvm installation found. Skipping..."
fi

if [ ! -x "$(command -v node)" ]; then
  echo "Installing node..."
  nvm install stable
  nvm alias default stable
  nvm use default

  source "$HOME/.bashrc"
else
  echo "node found... skipping installation"
fi

echo ""
echo "Adding $current_os specific functionality..."
if [[ "$current_os" = "Mac" ]]; then

  echo ""
  echo "Installing xcode additional tools..."
  xcode-select --install

  echo ""
  echo "Installing homebrew..."
  /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

  echo ""
  echo "Adding solarized..."
  curl -O http://ethanschoonover.com/solarized/files/solarized.zip \
    && unzip solarized.zip \
    && open solarized/iterm2-colors-solarized/Solarized\ Dark.itermcolors \
    && rm -rf solarized solarized.zip

  echo ""
  echo "Adding quicker key repeat (reqires re-login)..."
  defaults write NSGlobalDomain KeyRepeat -int 1
  defaults write NSGlobalDomain InitialKeyRepeat -int 10

  echo ""
  echo "Installing dependencies..."
  brew bundle

  echo ""
  echo "Adding useful fzf bindings and fuzzy completion"
  $(brew --prefix)/opt/fzf/install

  echo "Updating to use latest version of bash..."
  echo '/usr/local/bin/bash' | sudo tee -a /etc/shells
  chsh -s /usr/local/bin/bash
  source ~/.bash_profile
else
  echo ""
  echo "Installing fzf and adding useful keybindings..."
  git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
  ~/.fzf/install

  vim_full_version="unknown"
  if [ -x "$(command -v vim)" ]; then
    vim_full_version="$(vim --version | head -n1)"
  fi

  case "$vim_full_version" in
    *7.*)
      echo ""
      echo "Uninstalling the current version of vim since it is on version 7..."
      echo "$vim_full_version"

      sudo yum remove vim vim-runtime gvim -y
      ;;
  esac

  vim_dir="$HOME/vim"
  if [ ! -d "$vim_dir" ]; then
    git clone https://github.com/vim/vim.git "$vim_dir"
  fi

  cd "$vim_dir"
  git pull

  ./configure --with-features=huge \
    --enable-multibyte \
    --enable-rubyinterp \
    --enable-pythoninterp \
    --with-python-config-dir=/usr/lib64/python2.7/config \
    --enable-python3interp \
    --with-python3-config-dir=/usr/lib64/python3.6/config \
    --enable-perlinterp \
    --enable-luainterp \
    --enable-gui=auto \
    --enable-cscope \
    --prefix=/usr/local

  make VIMRUNTIMEDIR=/usr/local/share/vim/vim81
  sudo make install

  echo ""
  echo "Updating default editor to be vim ..."
  sudo update-alternatives --install /usr/bin/editor editor /usr/local/bin/vim 1
  sudo update-alternatives --set editor /usr/local/bin/vim

  echo ""
  echo "Installing nodejs for yarn dependency"
  sudo yum install epel-release -y
  sudo yum install nodejs -y

  echo ""
  echo "Installing yarn..."
  curl --silent --location https://dl.yarnpkg.com/rpm/yarn.repo | sudo tee /etc/yum.repos.d/yarn.repo
  sudo yum install yarn -y
fi

echo ""
echo "Updatig yarn to work without a specific node version"
yarn config set scripts-prepend-node-path true --global

nvim_dir="$HOME/.config/nvim"
minpac="pack/minpac/opt/minpac"
nvim_minpac="$nvim_dir/$minpac"
vim_minpac="$HOME/.vim/$minpac"

echo ""
echo "Initializing vim and neovim..."
mkdir -p "$nvim_dir"
echo "source ~/.vimrc" > "$nvim_dir/init.vim" # always overwrite

if [ ! -d "$vim_minpac" ]; then
  echo ""
  echo "Adding minpac for vim..."
  git clone https://github.com/k-takata/minpac.git "$vim_minpac"
fi

if [ ! -d "$nvim_minpac" ]; then
  echo ""
  echo "Adding minpac for nvim..."

  git clone https://github.com/k-takata/minpac.git "$nvim_minpac"
fi

if [[ "$current_os" = "Mac" ]]; then
  pip3 install neovim
else
  pip3 install neovim --user
fi

echo ""
echo "Initial setup complete! run vim +PackUpdate and nvim +PackUpdate to install vim packages"
