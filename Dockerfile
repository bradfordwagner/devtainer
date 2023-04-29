from --platform=linux/amd64 quay.io/bradfordwagner/ansible:3.6.2-archlinux_latest
copy . /src
workdir /src
run [ -f requirements.yml ] && ansible-galaxy install -r requirements.yml || echo "Dependency Download: No requirements.yml Found"
run ansible-playbook playbook.yml && echo Success || echo Failure
