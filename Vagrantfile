# Vagrantfile with K3s + Traefik + Rancher + TLS + Dashboard fully automated
Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/focal64"

  # ---------------------------
  # IP 與參數設定
  # ---------------------------
  MASTER_IP = "192.168.56.10"
  WORKER1_IP = "192.168.56.11"
  WORKER2_IP = "192.168.56.12"
  RANCHER_HOSTNAME = "rancher.local"
  DASHBOARD_HOSTNAME = "dashboard.localhost"
  TRAEFIK_CONFIG_DIR = "/vagrant/traefik-config"

  # 將本機 traefik-config 目錄同步到 VM
  config.vm.synced_folder "traefik-config", "/vagrant/traefik-config"

  # ---------------------------
  # K3s Master 節點
  # ---------------------------
  config.vm.define "k3s-master" do |master|
    master.vm.hostname = "k3s-master"
    master.vm.network "private_network", ip: MASTER_IP

    # 避免 host 上的 80/443 衝突，改轉發到 8080/8443
    master.vm.network "forwarded_port", guest: 80, host: 8080
    master.vm.network "forwarded_port", guest: 443, host: 8443

    master.vm.provider "virtualbox" do |vb|
      vb.memory = 8192
      vb.cpus = 4
    end

    # Master 安裝程序
    master.vm.provision "shell", inline: <<-SHELL
      echo "[INFO] 安裝 K3s Master 並啟用 Helm、Traefik、Rancher、Dashboard 與 TLS"

      # 安裝 K3s 並指定 node IP
      curl -sfL https://get.k3s.io | sh -s - --write-kubeconfig-mode=644 --node-ip=#{MASTER_IP}

      # 設定環境變數與快捷指令
      echo "export KUBECONFIG=/etc/rancher/k3s/k3s.yaml" >> /home/vagrant/.bashrc
      echo "alias k='kubectl'" >> /home/vagrant/.bashrc
      sudo ln -s /usr/local/bin/kubectl /usr/bin/kubectl
      sudo chown vagrant:vagrant /etc/rancher/k3s/k3s.yaml
      export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

      # 設定 hosts
      echo "#{MASTER_IP} #{RANCHER_HOSTNAME} #{DASHBOARD_HOSTNAME}" | sudo tee -a /etc/hosts

      # 等待節點 Ready
      until kubectl get nodes 2>/dev/null | grep -q 'Ready'; do
        echo "[INFO] 等待 K3s Master Ready..."
        sleep 5
      done

      # 輸出 token 給 Worker 使用
      sudo cat /var/lib/rancher/k3s/server/node-token > /vagrant/node-token

      # 安裝 Helm
      echo "[INFO] 安裝 Helm"
      sudo apt-get update -y
      sudo apt-get install -y curl apt-transport-https gnupg lsb-release openssl
      curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
      helm version

      # 設定 Helm Repo
      echo "[INFO] 設定 Helm Repo"
      helm repo add traefik https://helm.traefik.io/traefik
      helm repo add rancher-stable https://releases.rancher.com/server-charts/stable
      helm repo add jetstack https://charts.jetstack.io
      helm repo update

      # 建立自簽憑證
      echo "[INFO] 建立自簽憑證"
      mkdir -p #{TRAEFIK_CONFIG_DIR}/tls
      openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout #{TRAEFIK_CONFIG_DIR}/tls/tls.key \
        -out #{TRAEFIK_CONFIG_DIR}/tls/tls.crt \
        -subj "/CN=#{DASHBOARD_HOSTNAME}"

      # 建立 TLS secret
      echo "[INFO] 建立 tls secret"
      kubectl create namespace kube-system || true
      kubectl delete secret traefik-cert --namespace kube-system --ignore-not-found
      kubectl create secret tls traefik-cert \
        --cert=#{TRAEFIK_CONFIG_DIR}/tls/tls.crt \
        --key=#{TRAEFIK_CONFIG_DIR}/tls/tls.key \
        --namespace kube-system

      # 安裝 Traefik
      echo "[INFO] 安裝 Traefik"
      helm upgrade --install traefik traefik/traefik --version=23.0.0 \
        --namespace kube-system \
        --set service.type=LoadBalancer \
        --set ports.web.port=80 \
        --set ports.websecure.port=443 \
        --set ports.web.expose=true \
        --set ports.websecure.expose=true \
        --set ports.web.exposedPort=80 \
        --set ports.websecure.exposedPort=443 \
        --set additionalArguments[0]=--api.dashboard=true \
        --set additionalArguments[1]=--entrypoints.websecure.http.tls=true \
        --set additionalArguments[2]=--entrypoints.websecure.http.tls.certResolver=default \
        --set "volumes[0].name=certs" \
        --set "volumes[0].mountPath=/certs" \
        --set "volumes[0].type=secret" \
        --set "volumes[0].secretName=traefik-cert"

      # 等待 Traefik Ready
      echo "[INFO] 等待 Traefik 啟動..."
      until kubectl get pods -n kube-system | grep traefik | grep 'Running' > /dev/null; do
        sleep 10
      done

      # 套用 Traefik Dashboard 的 IngressRoute 設定
      echo "[INFO] 套用 Dashboard IngressRoute"
      kubectl apply -f #{TRAEFIK_CONFIG_DIR}/dashboard.yaml

      # 安裝 Rancher
      echo "[INFO] 安裝 Rancher"
      kubectl create namespace cattle-system || true
      helm install rancher rancher-stable/rancher \
        --namespace cattle-system \
        --set hostname="#{RANCHER_HOSTNAME}" \
        --set replicas=1 \
        --set bootstrapPassword="admin" \
        --set tls="none" \
        --set ingress.enabled=false

      # 等待 Rancher Ready
      echo "[INFO] 等待 Rancher 部署..."
      until kubectl get pods -n cattle-system | grep rancher | grep 'Running' > /dev/null; do
        sleep 10
      done

      # 套用 Rancher 的 IngressRoute
      echo "[INFO] 套用 Rancher IngressRoute"
      kubectl apply -f #{TRAEFIK_CONFIG_DIR}/rancher.yaml

      echo "[INFO] 所有服務已部署完成！"
      echo "[INFO] Rancher： https://localhost:8443"
      echo "[INFO] Dashboard： https://dashboard.localhost:8443"
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

    # Worker1 安裝程序
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

    # Worker2 安裝程序
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
