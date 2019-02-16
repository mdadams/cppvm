#version=DEVEL
ignoredisk --only-use=sda
# Partition clearing information
clearpart --all --drives=sda
#clearpart --none --initlabel
# Use graphical install
graphical
# Use network installation
url --url="https://sjc.edge.kernel.org/fedora-buffet/fedora/linux/releases/29/Everything/x86_64/os/"
# Keyboard layouts
keyboard --vckeymap=us --xlayouts='us'
# System language
lang en_US.UTF-8
# Reboot
reboot

# Network information
network  --bootproto=dhcp --device=ens3 --ipv6=auto --activate
network  --hostname=cpp
# Root password
rootpw --plaintext iamroot
# Run the Setup Agent on first boot
firstboot --enable
# Configure the X Window System
#skipx
xconfig --startxonboot
# System services
services --enabled="chronyd"
# System timezone
timezone America/Vancouver --isUtc
user --name=student --password=iamstudent --plaintext --gecos="Student"
# Disk partitioning information
part --asprimary --fstype ext4 --grow --label=root --ondisk=sda /

%packages
@^minimal-environment
xorg-x11-server-Xorg
xorg-x11-xinit
xorg-x11-drv-libinput
mesa-dri-drivers
xorg-x11-drv-qxl
xorg-x11-drv-vesa
spice-vdagent
lightdm
xfce4-panel
xfce4-session
xfce4-settings
xfconf
xfdesktop
xfwm4
xfce4-terminal
firefox
xfce4-pulseaudio-plugin
firefox
thunar-volman
udisks2
gvfs
wget
git
gcc
gcc-c++
make
texinfo
python-devel
p7zip
p7zip-plugins
gmp-devel
mpfr-devel
freeglut-devel
glew-devel
autoconf
automake
libcap-devel
libtool
libxslt
docbook-style-xsl
ncurses-devel
qt5-devel
bzip2
xz
evince
a2ps
texlive-pdfjam
zerofree
lsof

%end

%addon com_redhat_kdump --disable --reserve-mb='128'

%end

%anaconda
pwpolicy root --minlen=6 --minquality=1 --notstrict --nochanges --notempty
pwpolicy user --minlen=6 --minquality=1 --notstrict --nochanges --emptyok
pwpolicy luks --minlen=6 --minquality=1 --notstrict --nochanges --notempty
%end

%post --interpreter /usr/bin/bash --log /root/install_sde_stub.log
########## START OF INSTALLER STUB ##########

#! /usr/bin/env bash

sde_version=4.0.10
tmp_dir="/tmp/install_sde-$$"
sde_install_dir="/opt/sde-$sde_version"
log_file="/root/install_sde.log"
tty_dev="/dev/tty10"

panic()
{
	echo "ERROR: $@"
	exit 1
}

test_mode=0
while getopts n opt; do
	case $opt in
	n)
		test_mode=1;;
	esac
done
shift $((OPTIND - 1))

if [ "$test_mode" -ne 0 ]; then
	tmp_dir="/tmp/install_sde"
	sde_install_dir="/tmp/sde-$sde_version"
	log_file="/tmp/install_sde.log"
	tty_dev=$(tty) || panic "cannot get terminal"
fi

git_dir="$tmp_dir/cppvm"

rm -f "$log_file"

{

	mkdir -p "$tmp_dir" || \
	  panic "cannot make directory $tmp_dir"
	git -C "$tmp_dir" clone https://github.com/mdadams/cppvm.git "$git_dir" || \
	  panic "cannot clone repository"

	options=()
	if [ "$test_mode" -ne 0 ]; then
		options+=(-n)
	fi
	"$git_dir/bin/installer" -d "$sde_install_dir" -v "$sde_version" \
	  -t "$tmp_dir/sde" "${options[@]}" || \
	  panic "installer failed"

} 2>&1 | tee -a "$log_file" > "$tty_dev"

########## END OF INSTALLER STUB ##########
%end
