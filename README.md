# Devtainer
- Bradford's happy dotfiles, finally made public! Also as a container at https://quay.io/repository/bradfordwagner/devtainer?tab=tags it's a bit of a WIP so bear with me.

## Mac Quickstart
```bash
xcode-select --install
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
brew install ansible
brew install gh

gh auth login -w -p https

# clone
mkdir ~/tmp
cd ~/tmp
git clone https://github.com/bradfordwagner/dotfiles.git
cd dotfiles
cd ansible; ansible-galaxy collection install geerlingguy.mac; ansible-galaxy install -r requirements.yml -v --force
# set sudoers password
# note password changes require this to be run again
# for local
ansible-playbook pb-sudoer.yml --ask-become-pass

# homebrew installations
ansible-playbook pb-mac-brew.yml
ansible-playbook pb-kubectl-krew.yml

cd ~/tmp
git clone https://github.com/bradfordwagner/devtainer.git
cd devtainer
ansible-galaxy install -r requirements.yml
ansible-playbook playbook.yaml
```

## Alfred
- [theme: big sur night](http://www.packal.org/theme/big-sur-night)

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

- spaceid - https://github.com/dshnkao/SpaceId/releases - to show spaces in menubar

