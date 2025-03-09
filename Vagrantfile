# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  # 1) 指定要使用的 Base Box
  #   可換成你想要的 Ubuntu 24.04 box 名稱
  config.vm.box = "ubuntu/focal64"

  # 2) 全域參數：避免 VirtualBox 內網 IP 與其他專案衝突，可自行修改
  MASTER_IP = "192.168.56.10"
  WORKER1_IP = "192.168.56.11"
  WORKER2_IP = "192.168.56.12"

  # -----------------------------------------------------------
  # 定義 "k3s-master" VM
  # -----------------------------------------------------------
  config.vm.define "k3s-master" do |master|
    master.vm.hostname = "k3s-master"
    master.vm.network "private_network", ip: MASTER_IP
    # 若需要從 Host 直接用 localhost:8443 存取 Rancher，可加這行 port forwarding
    # master.vm.network "forwarded_port", guest: 443, host: 8443

    master.vm.provider "virtualbox" do |vb|
      vb.name = "K3s Master"
      vb.memory = 2048
      vb.cpus = 2
    end

    # ---------------------------------------------------------
    # master provisioning script (inline shell)
    # ---------------------------------------------------------
    master.vm.provision "shell", inline: <<-SHELL
      echo "[INFO] === 安裝 K3s (Master) ==="
      # 安裝 K3s server
      curl -sfL https://get.k3s.io | sh -
      # 等待 K3s 啟動
      sleep 10

      echo "[INFO] === 將 node-token 複製到 /vagrant/node-token，以便 Workers 使用 ==="
      sudo cp /var/lib/rancher/k3s/server/node-token /vagrant/node-token

      echo "[INFO] === 安裝 Helm (用來部署 Rancher) ==="
      sudo apt-get update -y
      sudo apt-get install -y curl apt-transport-https gnupg lsb-release
      curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

      # 用 k3s 自帶的 kubectl 指令操作，可用完整路徑 /usr/local/bin/kubectl 或 ln -s
      echo "[INFO] === 在叢集上安裝 Rancher ==="
      /usr/local/bin/kubectl create namespace cattle-system

      helm repo add rancher-stable https://releases.rancher.com/server-charts/stable
      helm repo update

      # hostname 這裡可用 Master IP 或真實域名，若只在內網測試，可以直接設定為上面 MASTER_IP
      helm install rancher rancher-stable/rancher \
        --namespace cattle-system \
        --set hostname=#{MASTER_IP} \
        --set replicas=1

      echo "[INFO] === Rancher 部署中，請稍候幾分鐘後再試著連線 https://#{MASTER_IP} ==="
      echo "[INFO] 預設為自簽憑證，瀏覽器可能會出現不安全提示，測試環境可忽略。"
    SHELL
  end

  # -----------------------------------------------------------
  # 定義 "k3s-worker1" VM
  # -----------------------------------------------------------
  config.vm.define "k3s-worker1" do |worker|
    worker.vm.hostname = "k3s-worker1"
    worker.vm.network "private_network", ip: WORKER1_IP

    worker.vm.provider "virtualbox" do |vb|
      vb.name = "K3s Worker1"
      vb.memory = 2048
      vb.cpus = 2
    end

    # worker provisioning
    worker.vm.provision "shell", inline: <<-SHELL
      echo "[INFO] === 安裝 K3s Worker1 ==="
      # 等待 master 建立 node-token
      while [ ! -f /vagrant/node-token ]; do
        echo "[INFO] 等待 /vagrant/node-token ..."
        sleep 5
      done

      export K3S_URL="https://#{MASTER_IP}:6443"
      export K3S_TOKEN=$(cat /vagrant/node-token)

      curl -sfL https://get.k3s.io | sh -
      echo "[INFO] === K3s Worker1 安裝完成 ==="
    SHELL
  end

  # -----------------------------------------------------------
  # 定義 "k3s-worker2" VM
  # -----------------------------------------------------------
  config.vm.define "k3s-worker2" do |worker|
    worker.vm.hostname = "k3s-worker2"
    worker.vm.network "private_network", ip: WORKER2_IP

    worker.vm.provider "virtualbox" do |vb|
      vb.name = "K3s Worker2"
      vb.memory = 2048
      vb.cpus = 2
    end

    # worker provisioning
    worker.vm.provision "shell", inline: <<-SHELL
      echo "[INFO] === 安裝 K3s Worker2 ==="
      while [ ! -f /vagrant/node-token ]; do
        echo "[INFO] 等待 /vagrant/node-token ..."
        sleep 5
      done

      export K3S_URL="https://#{MASTER_IP}:6443"
      export K3S_TOKEN=$(cat /vagrant/node-token)

      curl -sfL https://get.k3s.io | sh -
      echo "[INFO] === K3s Worker2 安裝完成 ==="
    SHELL
  end
end

