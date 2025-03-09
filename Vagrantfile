Vagrant.configure("2") do |config|
  # 1) 使用 Ubuntu 24.04 LTS (可更換為合適的 box)
  config.vm.box = "ubuntu/focal64"  # focal64 代表 Ubuntu 20.04，Ubuntu 24.04 可換成 "generic/ubuntu2404"

  # 2) 定義網路與 Master / Worker IP
  MASTER_IP = "192.168.56.10"
  WORKER1_IP = "192.168.56.11"
  WORKER2_IP = "192.168.56.12"

  # ---------------------------
  # K3s Master 節點
  # ---------------------------
  config.vm.define "k3s-master" do |master|
    master.vm.hostname = "k3s-master"
    master.vm.network "private_network", ip: MASTER_IP

    master.vm.provider "virtualbox" do |vb|
      vb.name = "K3s Master"
      vb.memory = 8192
      vb.cpus = 4
    end

    master.vm.provision "shell", inline: <<-SHELL
      echo "[INFO] 安裝 K3s (Master) 並修改權限"

      # 安裝 K3s Server 並允許非 root 用戶存取 kubeconfig
      curl -sfL https://get.k3s.io | sh -s - --write-kubeconfig-mode=644

      # 確保 kubeconfig 權限可讀取
      sudo chown vagrant:vagrant /etc/rancher/k3s/k3s.yaml

      # 讓 vagrant 使用者可直接使用 kubectl
      echo "export KUBECONFIG=/etc/rancher/k3s/k3s.yaml" >> /home/vagrant/.bashrc
      echo "alias k='kubectl'" >> /home/vagrant/.bashrc
      sudo ln -s /usr/local/bin/kubectl /usr/bin/kubectl

      # 等待 K3s 完全啟動
      until /usr/local/bin/kubectl get nodes 2>/dev/null | grep -q 'Ready'; do
        echo "Waiting for K3s to be ready..."
        sleep 5
      done

      # 取得 node-token 並提供給 Workers
      sudo cat /var/lib/rancher/k3s/server/node-token > /vagrant/node-token

      # 安裝 Helm
      echo "[INFO] 安裝 Helm"
      sudo apt-get update -y
      sudo apt-get install -y curl apt-transport-https gnupg lsb-release
      curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

      # 安裝 Rancher
      echo "[INFO] 安裝 Rancher"
      /usr/local/bin/kubectl create namespace cattle-system
      helm repo add rancher-stable https://releases.rancher.com/server-charts/stable
      helm repo update
      helm install rancher rancher-stable/rancher \
        --namespace cattle-system \
        --set hostname=#{MASTER_IP} \
        --set replicas=1 \
        --kubeconfig /etc/rancher/k3s/k3s.yaml

      echo "[INFO] Rancher 安裝完成，可在瀏覽器中開啟 https://#{MASTER_IP}"
    SHELL
  end

  # ---------------------------
  # K3s Worker 1 節點
  # ---------------------------
  config.vm.define "k3s-worker1" do |worker|
    worker.vm.hostname = "k3s-worker1"
    worker.vm.network "private_network", ip: WORKER1_IP

    worker.vm.provider "virtualbox" do |vb|
      vb.name = "K3s Worker1"
      vb.memory = 4096
      vb.cpus = 4
    end

    worker.vm.provision "shell", inline: <<-SHELL
      echo "[INFO] 安裝 K3s Worker1"

      # 等待 node-token
      while [ ! -f /vagrant/node-token ]; do
        echo "[INFO] 等待 node-token..."
        sleep 5
      done

      export K3S_URL="https://#{MASTER_IP}:6443"
      export K3S_TOKEN=$(cat /vagrant/node-token)

      # 安裝 K3s Agent
      curl -sfL https://get.k3s.io | sh -

      echo "[INFO] K3s Worker1 已加入叢集"
    SHELL
  end

  # ---------------------------
  # K3s Worker 2 節點
  # ---------------------------
  config.vm.define "k3s-worker2" do |worker|
    worker.vm.hostname = "k3s-worker2"
    worker.vm.network "private_network", ip: WORKER2_IP

    worker.vm.provider "virtualbox" do |vb|
      vb.name = "K3s Worker2"
      vb.memory = 4096
      vb.cpus = 4
    end

    worker.vm.provision "shell", inline: <<-SHELL
      echo "[INFO] 安裝 K3s Worker2"

      # 等待 node-token
      while [ ! -f /vagrant/node-token ]; do
        echo "[INFO] 等待 node-token..."
        sleep 5
      done

      export K3S_URL="https://#{MASTER_IP}:6443"
      export K3S_TOKEN=$(cat /vagrant/node-token)

      # 安裝 K3s Agent
      curl -sfL https://get.k3s.io | sh -

      echo "[INFO] K3s Worker2 已加入叢集"
    SHELL
  end
end

