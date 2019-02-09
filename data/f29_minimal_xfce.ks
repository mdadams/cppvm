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

%end

%addon com_redhat_kdump --disable --reserve-mb='128'

%end

%anaconda
pwpolicy root --minlen=6 --minquality=1 --notstrict --nochanges --notempty
pwpolicy user --minlen=6 --minquality=1 --notstrict --nochanges --emptyok
pwpolicy luks --minlen=6 --minquality=1 --notstrict --nochanges --notempty
%end
