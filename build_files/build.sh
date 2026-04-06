#!/bin/bash

set -ouex pipefail

### Install packages

# Packages can be installed from any enabled yum repo on the image.
# RPMfusion repos are available by default in ublue main images
# List of rpmfusion packages can be found here:
# https://mirrors.rpmfusion.org/mirrorlist?path=free/fedora/updates/39/x86_64/repoview/index.html&protocol=https&redirect=1

# Base CLI setup
dnf5 install -y kitty
dnf5 install -y tmux
dnf5 install -y zsh
# CLI tools
dnf5 install -y gopass
dnf5 install -y gopass-jsonapi
dnf5 install -y ncdu
dnf5 install -y podman-compose
# IDE and Dev
dnf5 install -y neovim
dnf5 install -y nodejs24
dnf5 install -y python3-neovim
# Pnpm
dnf5 install -y pnpm

# CachyOS Kernel
echo 'Enable SElinux Kernel policy'
setsebool -P domain_kernel_load_modules on
dnf5 -y copr enable bieszczaders/kernel-cachyos

# Derive the kernel version automatically from the repo metadata
KVER=$(dnf5 repoquery kernel-cachyos --queryformat '%{version}-%{release}.%{arch}' | tail -1)

# Pre-create modules.dep so dracut doesn't abort during the rpm-ostree transaction
mkdir -p /usr/lib/modules/${KVER}
touch /usr/lib/modules/${KVER}/modules.dep

rpm-ostree override remove kernel kernel-core kernel-modules kernel-modules-core kernel-modules-extra \
  --install kernel-cachyos

# Rebuild the real modules.dep now that the kernel modules are in place
depmod -a "${KVER}"
dnf5 -y copr disable bieszczaders/kernel-cachyos

# Use a COPR Example:
#
# dnf5 -y copr enable ublue-os/staging
# dnf5 -y install package
# Disable COPRs so they don't end up enabled on the final image:
# dnf5 -y copr disable ublue-os/staging

#### Example for enabling a System Unit File

systemctl enable podman.socket
