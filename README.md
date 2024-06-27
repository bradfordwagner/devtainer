# Devtainer
- Bradford's happy dotfiles, finally made public! Also as a container at https://quay.io/repository/bradfordwagner/devtainer?tab=tags it's a bit of a WIP so bear with me.

## Mac Quickstart
```bash
xcode-select --install
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
brew install ansible gh go-task
gh auth login -w -p https

# install oh-my-zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

task sudoer
task

# still comes from the original dotfiles
ansible-playbook pb-kubectl-krew.yml

# vim
python3 -m pip install --user --upgrade pynvim

# download and install tkgi cli
# https://network.pivotal.io/products/pivotal-container-service/#/releases/1293578/file_groups/13745
```

## Alfred
- [theme: big sur night](http://www.packal.org/theme/big-sur-night)
- [theme: monterey](https://github.com/chrismessina/alfred-theme-monterey/releases/tag/v0.1)

## Help with Unknown Sources
```bash
sudo spctl --master-enable
sudo spctl --master-disable
```

## Intellij Settings
- plugins: smart align, gruvbox, go, EasyChangeFontSize, Gitlab Integration, Hashicorp Terraform / HCL Language Support, IdeaVim, Kubernetes, Makefile Language, Nord, Python, Rainbow Brakets, Yaml / Ansible Support
```vm options
-Xms512m
-Xmx2g
-Deditor.distraction.free.mode=true
```
### idea external tools
```yaml
- name: open_file
  program: wezterm
  args: start -- zsh -lc "ij_open_file $ProjectFileDir$ $FilePath$"
- name: search_file
  program: wezterm
  args: start -- zsh -lc "ij_search_file $ProjectFileDir$ $FilePath$"
- name: search_files
  program: wezterm
  args: start -- zsh -lc "ij_search $ProjectFileDir$ $FilePath$"
- name: wezterm
  program: wezterm
  args: start --cwd $ProjectFileDir$ -- zsh -l
```

- spaceid - https://github.com/dshnkao/SpaceId/releases - to show spaces in menubar

## Iterm
- https://github.com/challenger-deep-theme/iterm
- https://stackoverflow.com/questions/196357/making-iterm-to-translate-meta-key-in-the-same-way-as-in-other-oses
- transparency: 25
- blur: 20
