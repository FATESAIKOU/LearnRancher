# A basic cluster build script for Rancher / K3smaster+K3sworker on Vagrant


## Installation

- Basic compile-related lib
```shell
$ sudo apt update && sudo apt install -y build-essential pkg-config libz-dev libssl-dev libffi-dev libyaml-dev
```

- Basic virtualize-related lib
```shell
$ sudo apt update && sudo apt install -y dkms linux-headers-$(uname -r)
```

- VirtualBox
```shell
$ sudo apt update && sudo apt install virtualbox
```

- Vagrant
```shell
$ wget -O - https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
$ echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
$ sudo apt update && sudo apt install vagrant
```

## Launch
``shell
$ vagrant up
```

## Remove
```shell
$ vagrant destroy
```
