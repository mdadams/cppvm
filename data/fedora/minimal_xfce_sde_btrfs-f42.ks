#version=DEVEL

# Specify the action to take upon completion of the install.
#reboot
#shutdown
poweroff

# Use graphical install
graphical

# Use network installation
#url --url="__KS_URL__"
url --mirrorlist="https://mirrors.fedoraproject.org/mirrorlist?repo=fedora-$releasever&arch=$basearch"

# Uncomment the following line to allow the installation of updates.
#repo --name=updates

# Keyboard layouts
keyboard --vckeymap=us --xlayouts='us'

# System language
lang en_US.UTF-8

# Network information
network --bootproto=dhcp --device=ens3 --ipv6=auto --activate
network --hostname=terra

########################################
# Disk partitioning information
########################################
ignoredisk --only-use=sda
# System bootloader configuration
bootloader --location=mbr --boot-drive=sda
# Partition clearing information
clearpart --all --drives=sda
#clearpart --none --initlabel
# Disk partitioning information
part biosboot --fstype="biosboot" --ondisk=sda --size=1
part btrfs.01 --fstype="btrfs" --ondisk=sda --grow
btrfs none --label=fedora_terra btrfs.01
btrfs /boot --subvol --name=@boot LABEL=fedora_terra
btrfs / --subvol --name=@ LABEL=fedora_terra
btrfs /home --subvol --name=@home LABEL=fedora_terra

# Root password
#rootpw --plaintext iamroot
rootpw --lock
# User account
user --name=jdoe --groups=wheel --plaintext --password=iamjdoe --gecos="John/Jane Doe"

# System timezone
timezone America/Vancouver --utc

# Run the Setup Agent on first boot
firstboot --enable

# Configure the X Window System
#skipx
xconfig --startxonboot

# System services
services --enabled="chronyd"

# Packages
#lxdm?
#qt5-qtbase-devel
#xorg-x11-drv-vesa
# Apparently, the flex package is sometimes needed for building GCC trunk.
%packages
@^custom-environment
@core
xorg-x11-server-Xorg
xorg-x11-xinit
xorg-x11-drv-libinput
mesa-dri-drivers
xorg-x11-drv-qxl
spice-vdagent
lightdm-autologin-greeter
xfce4-panel
xfce4-session
xfce4-settings
xfconf
xfdesktop
xfwm4
xfce4-terminal
xfce4-appfinder
xfce4-pulseaudio-plugin
thunar-volman
network-manager-applet
udisks2
gvfs
firefox
wget
git
git-credential-libsecret
hub
gcc
gcc-c++
clang
make
meson
texinfo
python-devel
p7zip
p7zip-plugins
gmp-devel
mpfr-devel
freeglut-devel
glew-devel
glfw-devel
glm-devel
autoconf
automake
libcap-devel
libtool
libxslt
docbook-style-xsl
ncurses-devel
bzip2
xz
evince
a2ps
texlive-pdfjam
lsof
net-tools
openssl-devel
fftw-devel
unzip
perl-PerlIO-gzip
perl-JSON
perl-JSON-PP
vim-enhanced
flex
libsecret
seahorse
gperftools
papi-devel
tree
google-noto-emoji-color-fonts
valgrind
libedit-devel
poppler-utils
recode
%end

%addon com_redhat_kdump --disable --reserve-mb='128'

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

%post --interpreter /usr/bin/bash --nochroot --erroronfail
################################################################################

cp /tmp/mvmdi_setup.sh /mnt/sysimage/root/mvmdi_setup.sh

################################################################################
%end

%post --interpreter /usr/bin/bash --log /root/mvmdi.log --erroronfail
################################################################################

echo "========== START of mvmdi_setup.sh =========="
cat /root/mvmdi_setup.sh
echo "========== END of mvmdi_setup.sh =========="
source /root/mvmdi_setup.sh
echo "SDE version: $MVMDI_SDE_VERSION"
echo "SDE installation directory: $MVMDI_SDE_INSTALL_DIR"

################################################################################
%end

%post --interpreter /usr/bin/bash --log /root/install_sde.log --erroronfail
########## START OF sde_installer_stub ##########
#! /usr/bin/env bash

eecho()
{
	echo "$@" 1>&2
}

panic()
{
	echo "ERROR: $@" 1>&2
	exit 1
}

sde_repo_url="https://github.com/mdadams/sde.git"

tmp_dir_base=
log_file=
mvmdi_setup=

test_mode=0

while getopts f:l:nt: opt; do
	case $opt in
	l)
		log_file="$OPTARG";;
	f)
		mvmdi_setup="$OPTARG";;
	n)
		test_mode=1;;
	t)
		tmp_dir_base="$OPTARG";;
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
	if [ -z "$tmp_dir_base" ]; then
		panic "no temporary directory specified"
	fi
	tty_dev=$(tty) || panic "cannot get terminal"
else
	log_file="/root/install_sde.log"
	mvmdi_setup="/root/mvmdi_setup.sh"
	tty_dev="/dev/tty10"
	tmp_dir_base="/tmp"
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
		#panic "no SDE version specified"
		echo "MVMDI_SDE_VERSION empty or not set"
		echo "skipping installation of SDE"
		exit 0
	fi
	sde_version="$MVMDI_SDE_VERSION"
	if [ -z "$MVMDI_SDE_INSTALL_DIR" ]; then
		panic "no SDE installation directory specified"
	fi
	sde_install_dir="$MVMDI_SDE_INSTALL_DIR"
	if [ -n "$MVMDI_TMP_DIR" ]; then
		tmp_dir_base="$MVMDI_TMP_DIR"
	fi

	tmp_dir=$(mktemp -d "$tmp_dir_base/mvmdi-XXXXXXXXXX") || \
	  panic "cannot make directory $tmp_dir"

	sde_git_dir="$tmp_dir/sde"
	sde_commit="v$sde_version"

	echo "SDE version: $sde_version"
	echo "SDE installation directory: $sde_install_dir"
	echo "SDE Git repository: $sde_repo_url"
	echo "SDE commit: $sde_commit"
	echo "temporary directory: $tmp_dir_base"

	sde_default_env=base

	# basic settings
	export SDE_TMPDIR="$tmp_dir_base"

	##########
	# Selection of packages other than GCC and Clang.
	##########
	export SDE_GCCGO_INSTALL=0
	export SDE_CMAKE_INSTALL=1
	export SDE_NINJA_INSTALL=1
	export SDE_BOOST_INSTALL=1
	##########
	#export SDE_TEXLIVE_INSTALL=1
	export SDE_TEXLIVE_INSTALL=0
	##########
	export SDE_JASPER_INSTALL=1
	export SDE_GDB_INSTALL=1
	export SDE_SPL_INSTALL=1
	export SDE_NDIFF_INSTALL=1
	export SDE_ARISTOTLE_INSTALL=1
	export SDE_PYARISTOTLE_INSTALL=1
	export SDE_YCM_INSTALL=0
	export SDE_VIM_INSTALL=0
	export SDE_GSL_INSTALL=1
	export SDE_CATCH_INSTALL=1
	export SDE_ALT_CATCH_INSTALL=1
	export SDE_LCOV_INSTALL=1
	export SDE_VIMLSP_INSTALL=1
	export SDE_CGAL_INSTALL=1
	export SDE_HUB_INSTALL=0
	# Note: Should GitHub CLI be installed?
	export SDE_GH_INSTALL=0
	export SDE_A2PS_INSTALL=0
	export SDE_GHI_INSTALL=0
	export SDE_MUSL_INSTALL=0
	export SDE_FMTLIB_INSTALL=0
	export SDE_RANGE_INSTALL=0
	export SDE_CMCSTL2_INSTALL=0
	##########

	##########
	# Selection of GCC and Clang packages.
	##########
	# Note:
	# The DNF package for GCC must always be installed.
	# So even if the SDE does not include GCC, GCC will be installed.
	export SDE_GCC_INSTALL=0
	export SDE_ALT_GCC_INSTALL=0
	#export SDE_ALT_GCC_INSTALL=${MVMDI_SDE_ALT_GCC_INSTALL:-0}
	##########
	# Note:
	# The DNF package for Clang may or may not be installed.  (Check the
	# Kickstart file to determine which is the case.)
	# If the SDE does not include Clang, Clang must be installed via dnf.
	export SDE_CLANG_INSTALL=0
	export SDE_ALT_CLANG_INSTALL=0
	#export SDE_ALT_CLANG_INSTALL=${MVMDI_SDE_ALT_CLANG_INSTALL:-0}
	##########

	# GCC settings
	# NOTE: add rust support in the future
	export SDE_GCC_INSTALL_OPTIONS="--num-jobs 8 --enable-languages c,c++,fortran --no-default-pie --no-old-abi --strip"

	# LLVM settings
	export SDE_CLANG_INSTALL_OPTIONS="--num-jobs 8 --num-parallel-compile-jobs 8 --num-parallel-link-jobs 1"

	# Boost settings
	# The following setting is a workaround for Boost not correctly finding
	# the Python installation.  In the pathname for the include directory
	# for Python, the "m" in "python3.7m" appears to be problematic.
	#export SDE_BOOST_CONFIG_DATA="using python : 3.7 : /usr/bin/python3 : /usr/include/python3.7m : /usr/lib ;"

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

pipe_status=("${PIPESTATUS[@]}")
if [ "${pipe_status[0]}" -ne 0 ]; then
	panic "installation failed"
fi
if [ "${pipe_status[1]}" -ne 0 ]; then
	panic "tee failed"
fi
########## END OF sde_installer_stub ##########
%end
