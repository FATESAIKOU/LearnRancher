Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/focal64"

  MASTER_IP = "192.168.56.10"
  WORKER1_IP = "192.168.56.11"
  WORKER2_IP = "192.168.56.12"
  RANCHER_HOSTNAME = "rancher.local"
  TRAEFIK_CONFIG_DIR = "traefik-config"
  TRAEFIK_CONFIG_DIR = "/vagrant/traefik-config"

  # 確保 traefik-config 目錄在 VM 內部可用
  config.vm.synced_folder "traefik-config", "/vagrant/traefik-config"

  # ---------------------------
  # K3s Master 節點
  # ---------------------------
  config.vm.define "k3s-master" do |master|
    master.vm.hostname = "k3s-master"
    master.vm.network "private_network", ip: MASTER_IP
    master.vm.network "forwarded_port", guest: 6443, host: 6443  # K3s API Server
    master.vm.network "forwarded_port", guest: 32080, host: 8080 # Traefik HTTP 入口

    master.vm.provider "virtualbox" do |vb|
      vb.memory = 8192
      vb.cpus = 4
    end

    master.vm.provision "shell", inline: <<-SHELL
      echo "[INFO] 安裝 K3s Master 並啟用 Helm、Traefik 和 Rancher"

      # 安裝 K3s 並指定 Master 的 node-ip
      curl -sfL https://get.k3s.io | sh -s - --write-kubeconfig-mode=644 --node-ip=#{MASTER_IP}

      # 讓 vagrant 使用者可使用 kubectl
      echo "export KUBECONFIG=/etc/rancher/k3s/k3s.yaml" >> /home/vagrant/.bashrc
      echo "alias k='kubectl'" >> /home/vagrant/.bashrc
      sudo ln -s /usr/local/bin/kubectl /usr/bin/kubectl
      sudo chown vagrant:vagrant /etc/rancher/k3s/k3s.yaml

      # 設定 kubeconfig，確保 helm 安裝時可以使用
      export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

      # 設定 /etc/hosts，確保 Rancher 可解析
      echo "192.168.56.10 #{RANCHER_HOSTNAME}" | sudo tee -a /etc/hosts

      # 等待 K3s 完全啟動
      until kubectl get nodes 2>/dev/null | grep -q 'Ready'; do
        echo "[INFO] 等待 K3s Master Ready..."
        sleep 5
      done

      # 確保 kubectl 正常運作
      kubectl get nodes

      # 取得 Worker 需要的 token
      sudo cat /var/lib/rancher/k3s/server/node-token > /vagrant/node-token

      # 安裝 Helm
      echo "[INFO] 安裝 Helm"
      sudo apt-get update -y
      sudo apt-get install -y curl apt-transport-https gnupg lsb-release
      curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

      # 確保 Helm 版本正確
      helm version

      # 新增 Helm Repository
      echo "[INFO] 設定 Helm Repo"
      helm repo add traefik https://helm.traefik.io/traefik
      helm repo add rancher-stable https://releases.rancher.com/server-charts/stable
      helm repo add jetstack https://charts.jetstack.io
      helm repo update

      # 安裝 Traefik 並固定 NodePort
      echo "[INFO] 安裝 Traefik"
      helm install traefik traefik/traefik \
        --namespace kube-system \
        --set service.spec.type=NodePort \
        --set service.spec.ports[0].nodePort=32080 \
        --set additionalArguments="{--entryPoints.web.address=:32080}"

      # 確保 Traefik 成功部署
      echo "[INFO] 等待 Traefik 部署..."
      until kubectl get pods -n kube-system | grep traefik | grep 'Running' > /dev/null; do
        echo "[INFO] 等待 Traefik Ready..."
        sleep 10
      done

      # 安裝 Rancher
      echo "[INFO] 安裝 Rancher"
      kubectl create namespace cattle-system || true
      helm install rancher rancher-stable/rancher \
        --namespace cattle-system \
        --set hostname=#{RANCHER_HOSTNAME} \
        --set replicas=1 \
        --set bootstrapPassword="admin" \
        --set tls=external \
        --set ingress.enabled=false

      # 套用 Traefik 設定
      kubectl apply -f #{TRAEFIK_CONFIG_DIR}/rancher.yaml

      echo "[INFO] Rancher 安裝完成，可透過 http://#{MASTER_IP}:8080 訪問"
    SHELL
  end

  # ---------------------------
  # K3s Worker 1
  # ---------------------------
  config.vm.define "k3s-worker1" do |worker|
    worker.vm.hostname = "k3s-worker1"
    worker.vm.network "private_network", ip: WORKER1_IP

    worker.vm.provider "virtualbox" do |vb|
      vb.memory = 8192
      vb.cpus = 4
    end

    worker.vm.provision "shell", inline: <<-SHELL
      echo "[INFO] 安裝 K3s Worker1"

      while [ ! -f /vagrant/node-token ]; do
        echo "[INFO] 等待 node-token..."
        sleep 5
      done

      export K3S_URL="https://#{MASTER_IP}:6443"
      export K3S_TOKEN=$(cat /vagrant/node-token)

      curl -sfL https://get.k3s.io | sh -s - --node-ip=#{WORKER1_IP}

      echo "[INFO] K3s Worker1 已加入叢集"
    SHELL
  end

  # ---------------------------
  # K3s Worker 2
  # ---------------------------
  config.vm.define "k3s-worker2" do |worker|
    worker.vm.hostname = "k3s-worker2"
    worker.vm.network "private_network", ip: WORKER2_IP

    worker.vm.provider "virtualbox" do |vb|
      vb.memory = 8192
      vb.cpus = 4
    end

    worker.vm.provision "shell", inline: <<-SHELL
      echo "[INFO] 安裝 K3s Worker2"

      while [ ! -f /vagrant/node-token ]; do
        echo "[INFO] 等待 node-token..."
        sleep 5
      done

      export K3S_URL="https://#{MASTER_IP}:6443"
      export K3S_TOKEN=$(cat /vagrant/node-token)

      curl -sfL https://get.k3s.io | sh -s - --node-ip=#{WORKER2_IP}

      echo "[INFO] K3s Worker2 已加入叢集"
    SHELL
  end
end

