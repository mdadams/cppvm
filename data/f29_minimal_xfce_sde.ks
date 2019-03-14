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
#reboot
#shutdown
poweroff

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

%pre
################################################################################
set -- `cat /proc/cmdline`

for x in $*; do 
	case $x in MVMDI_*) 
		#eval $x
		echo $x >> /tmp/mvmdi_setup.sh
		;; 
	esac; 
done

################################################################################
%end

%post --interpreter /usr/bin/bash --nochroot
################################################################################

cp /tmp/mvmdi_setup.sh /mnt/sysimage/root/mvmdi_setup.sh

################################################################################
%end

%post --interpreter /usr/bin/bash --log /root/mvmdi.log
################################################################################

source /root/mvmdi_setup.sh
echo "SDE version: $MVMDI_SDE_VERSION"
echo "SDE installation directory: $MVMDI_SDE_INSTALL_DIR"

################################################################################
%end

%post --interpreter /usr/bin/bash --log /root/install_sde.log
########## START OF installer_stub ##########

#! /usr/bin/env bash

panic()
{
	echo "ERROR: $@" 1>&2
	exit 1
}

sde_repo_url="https://github.com/mdadams/sde.git"

log_file=
mvmdi_setup=

test_mode=0

while getopts f:l:n opt; do
	case $opt in
	l)
		log_file="$OPTARG";;
	f)
		mvmdi_setup="$OPTARG";;
	n)
		test_mode=1;;
	esac
done
shift $((OPTIND - 1))

if [ "$test_mode" -ne 0 ]; then
	if [ -z "$log_file" ]; then
		panic "no log file specified"
	fi
	if [ -z "$mvmdi_setup" ]; then
		panic "no setup file specified"
	fi
	tty_dev=$(tty) || panic "cannot get terminal"
else
	log_file="/root/install_sde.log"
	mvmdi_setup="/root/mvmdi_setup.sh"
	tty_dev="/dev/tty10"
fi


if [ -z "$log_file" ]; then
	panic "no log file specified"
fi
if [ -z "$tty_dev" ]; then
	panic "no TTY device specified"
fi
if [ -z "$mvmdi_setup" ]; then
	panic "no setup file specified"
fi

if [ -f "$log_file" ]; then
	rm -f "$log_file" || panic "cannot remove log file"
fi

{

	if [ ! -f "$mvmdi_setup" ]; then
		panic "missing MVMDI setup file"
	fi
	source "$mvmdi_setup"

	if [ -z "$MVMDI_SDE_VERSION" ]; then
		panic "no SDE version specified"
	fi
	sde_version="$MVMDI_SDE_VERSION"
	if [ -z "$MVMDI_SDE_INSTALL_DIR" ]; then
		panic "no SDE installation directory specified"
	fi
	sde_install_dir="$MVMDI_SDE_INSTALL_DIR"

	tmp_dir=$(mktemp -d "/tmp/mvmdi-XXXXXXXXXX") || \
	  panic "cannot make directory $tmp_dir"

	sde_git_dir="$tmp_dir/sde"
	sde_commit="v$sde_version"

	sde_default_env=base
	export SDE_GCC_USE_OLD_ABI=0
	#export SDE_TEXLIVE_INSTALL=1
	export SDE_TEXLIVE_INSTALL=0
	export SDE_VIM_INSTALL=0
	export SDE_CGAL_INSTALL=1
	export SDE_LLVM_INSTALL_LLDB=0
	export SDE_LLVM_INSTALL_TEST_SUITE=0
	export SDE_HUB_INSTALL=0
	export SDE_TMPDIR=/tmp
	export SDE_INSTALL_GCC_ENABLE_LANGUAGES="c,c++"

	git clone -q "$sde_repo_url" "$sde_git_dir" || \
	  panic "cannot clone repository $sde_repo_url"

	(cd "$sde_git_dir" && git checkout -q "$sde_commit") || \
	  panic "cannot checkout branch/commit $sde_commit"

	sde_install_opts=()
	sde_install_opts+=(-f)
	"$sde_git_dir/installer" \
	  -d "$sde_install_dir" -e "$sde_default_env" \
	  "${sde_install_opts[@]}" || \
	  panic "cannot install SDE"

} 2>&1 | tee -a "$log_file" > "$tty_dev"

########## END OF installer_stub ##########
%end
