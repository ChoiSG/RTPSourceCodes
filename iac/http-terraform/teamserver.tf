resource "digitalocean_droplet" "c2" {
  name   = "${var.c2}.${var.domain}"
  region = "nyc1"
  size   = "s-1vcpu-2gb"
  image  = "ubuntu-22-04-x64"

  ssh_keys = [digitalocean_ssh_key.default.fingerprint]

  connection {
    host        = self.ipv4_address
    user        = "root"
    type        = "ssh"
    private_key = file(var.ssh_private_key)
    timeout     = "120s"
  }

  provisioner "remote-exec" {
    inline = [
      <<SCRIPT
      export DEBIAN_FRONTEND=noninteractive; NEEDRESTART_MODE=a; apt update -y -qq ; 
      apt install --no-install-recommends -y -qq git build-essential apt-utils cmake libfontconfig1 libglu1-mesa-dev libgtest-dev libspdlog-dev libboost-all-dev libncurses5-dev libgdbm-dev libssl-dev libreadline-dev libffi-dev libsqlite3-dev libbz2-dev mesa-common-dev qtbase5-dev qtchooser qt5-qmake qtbase5-dev-tools libqt5websockets5 libqt5websockets5-dev qtdeclarative5-dev golang-go qtbase5-dev libqt5websockets5-dev libspdlog-dev python3-dev libboost-all-dev mingw-w64 nasm gcc 

      add-apt-repository ppa:deadsnakes/ppa -y 
      apt update -y 
      apt install python3.10 python3.10-dev -y --no-install-recommends -qq 

      cd /opt
      git clone https://github.com/HavocFramework/Havoc.git
      
      # Don't need client since operators can use their own 
      #cd /opt/Havoc/Client
      #make 
      #./Havoc --help 

      cd /opt/Havoc/Teamserver
      go mod download golang.org/x/sys  
      go mod download github.com/ugorji/go
      ./Install.sh 

      make
      ./teamserver -h 

      SCRIPT
    ]
  }
}