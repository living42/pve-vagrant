#!/bin/bash
set -euxo pipefail

# configure apt for non-interactive mode.
export DEBIAN_FRONTEND=noninteractive

# switch to the non-enterprise repository.
# see https://pve.proxmox.com/wiki/Package_Repositories
rm -f /etc/apt/sources.list.d/pve-enterprise.list
echo "deb http://download.proxmox.com/debian/pve $(. /etc/os-release && echo "$VERSION_CODENAME") pve-no-subscription" >/etc/apt/sources.list.d/pve.list

# use traditional interface names like eth0 instead of enp0s3
# by disabling the predictable network interface names.
sed -i -E 's,^(GRUB_CMDLINE_LINUX=).+,\1"net.ifnames=0",' /etc/default/grub
update-grub

# configure the network for working in a vagrant environment.
# NB proxmox has created the vmbr0 bridge and placed eth0 on the it, but
#    that will not work, vagrant expects to control eth0. so we have to
#    undo the proxmox changes.
cat >/etc/network/interfaces <<'EOF'
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet dhcp

auto eth1
iface eth1 inet manual

auto vmbr0
iface vmbr0 inet dhcp
        bridge-ports eth1
        bridge-stp off
        bridge-fd 0
EOF

apt-get update
apt-get dist-upgrade -y

# create a group where sudo will not ask for a password.
apt-get install -q -y sudo
groupadd -r admin
echo '%admin ALL=(ALL) NOPASSWD:ALL' >/etc/sudoers.d/admin

# create the vagrant user. also allow access with the insecure vagrant public key.
# vagrant will replace it on the first run.
groupadd vagrant
useradd -g vagrant -m vagrant -s /bin/bash
gpasswd -a vagrant admin
chmod 750 /home/vagrant
install -d -m 700 /home/vagrant/.ssh
pushd /home/vagrant/.ssh
wget -q --no-check-certificate https://github.com/hashicorp/vagrant/raw/main/keys/vagrant.pub -O authorized_keys
chmod 600 authorized_keys
chown -R vagrant:vagrant .
popd

# install the Guest Additions.
# https://www.vagrantup.com/docs/providers/virtualbox/boxes#virtualbox-guest-additions
apt-get -y -q install pve-headers-$(uname -r) build-essential dkms

mkdir /media/VBoxGuestAdditions
mount -o loop,ro /root/VBoxGuestAdditions.iso /media/VBoxGuestAdditions
# dont't known why it exit with code 2
sh /media/VBoxGuestAdditions/VBoxLinuxAdditions.run || true
rm /root/VBoxGuestAdditions.iso
umount /media/VBoxGuestAdditions
rmdir /media/VBoxGuestAdditions

# disable the DNS reverse lookup on the SSH server. this stops it from
# trying to resolve the client IP address into a DNS domain name, which
# is kinda slow and does not normally work when running inside VB.
echo UseDNS no >>/etc/ssh/sshd_config

# disable the graphical terminal. its kinda slow and useless on a VM.
sed -i -E 's,#(GRUB_TERMINAL\s*=).*,\1console,g' /etc/default/grub
update-grub

# reset the machine-id.
# systemd will re-generate it on the next boot.
# machine-id is indirectly used in DHCP as Option 61 (Client Identifier), which
#    the DHCP server uses to (re-)assign the same or new client IP address.
# see https://www.freedesktop.org/software/systemd/man/machine-id.html
# see https://www.freedesktop.org/software/systemd/man/systemd-machine-id-setup.html
echo '' >/etc/machine-id
rm -f /var/lib/dbus/machine-id

# reset the random-seed.
# systemd-random-seed re-generates it on every boot and shutdown.
# you can prove that random-seed file does not exist on the image with:
#       sudo virt-filesystems -a ~/.vagrant.d/boxes/proxmox-ve-amd64/0/libvirt/box.img
#       sudo guestmount -a ~/.vagrant.d/boxes/proxmox-ve-amd64/0/libvirt/box.img -m /dev/pve/root --pid-file guestmount.pid --ro /mnt
#       sudo ls -laF /mnt/var/lib/systemd
#       sudo guestunmount /mnt
#       sudo bash -c 'while kill -0 $(cat guestmount.pid) 2>/dev/null; do sleep .1; done; rm guestmount.pid' # wait for guestmount to finish.
# see https://www.freedesktop.org/software/systemd/man/systemd-random-seed.service.html
# see https://manpages.debian.org/stretch/manpages/random.4.en.html
# see https://manpages.debian.org/stretch/manpages/random.7.en.html
# see https://github.com/systemd/systemd/blob/master/src/random-seed/random-seed.c
# see https://github.com/torvalds/linux/blob/master/drivers/char/random.c
systemctl stop systemd-random-seed
rm -f /var/lib/systemd/random-seed

# clean packages.
apt-get -y autoremove
apt-get -y clean

# show the free space.
df -h /

# zero the free disk space -- for better compression of the box file.
while true; do
    output="$(fstrim -v /)"
    cat <<<"$output"
    sync
    sleep 15
    bytes_trimmed="$(echo "$output" | perl -n -e '/\((\d+) bytes\)/ && print $1')"
    # NB if this never reaches zero, it might be because there is not
    #    enough free space for completing the trim.
    if (( bytes_trimmed < $((4*1024*1024)) )); then # < 4 MiB is good enough.
        break
    fi
done
