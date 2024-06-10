{ lib
, stdenv
, fetchgit
, perl
, callPackage
, pve-cluster ? callPackage ./cluster.nix { }
, pve-rados2 ? callPackage ./rados2.nix { }
, ceph
, coreutils
, e2fsprogs
, file
, glusterfs
, gptfdisk
, libiscsi
, lvm2
, nfs-utils
, openiscsi
, openssh
, proxmox-backup-client
, pve-qemu
, rpcbind
, samba
, smartmontools
, targetcli
, util-linux
, zfs
}:

let
  perlDeps = with perl.pkgs; with callPackage ../perl-packages.nix { }; [
    Filechdir
    POSIXstrptime
    pve-cluster
    pve-rados2
  ];

  perlEnv = perl.withPackages (_: perlDeps);
in

perl.pkgs.toPerlModule (stdenv.mkDerivation rec {
  pname = "pve-storage";
  version = "8.0.2";

  src = fetchgit {
    url = "https://git.proxmox.com/git/${pname}.git";
    rev = "42c08f41cb361f350aa46646cea0b0dd5bc99bd0";
    hash = "sha256-lHXrFlxJ5jN3QBYkkwSMZz37zT8SB4hx4v7oo9O0cg8=";
  };

  sourceRoot = "source/src";

  postPatch = ''
    sed -i bin/Makefile \
      -e "s/pvesm.1 pvesm.bash-completion pvesm.zsh-completion//" \
      -e "/pvesm.1/,+3d"
  '';

  buildInputs = [ perlEnv ];
  propagatedBuildInputs = perlDeps;

  makeFlags = [
    "DESTDIR=$(out)"
    "PREFIX="
    "SBINDIR=/bin"
    "PERLDIR=/${perl.libPrefix}/${perl.version}"
  ];

  postInstall = ''
    sed -i $out/bin/* \
      -e "s/-T//" \
      -e "1s|$| -I$out/${perl.libPrefix}/${perl.version}|"
  '';

  postFixup = ''
    find $out -type f | xargs sed -i \
      -e "s|/bin/lsblk|${util-linux}/bin/lsblk|" \
      -e "s|/bin/mkdir|${coreutils}/bin/mkdir|" \
      -e "s|/bin/mount|${util-linux}/bin/mount|" \
      -e "s|/bin/umount|${util-linux}/bin/umount|" \
      -e "s|/sbin/blkid|${util-linux}/bin/blkid|" \
      -e "s|/sbin/blockdev|${util-linux}/bin/blockdev|" \
      -e "s|/sbin/lv|${lvm2.bin}/bin/lv|" \
      -e "s|/sbin/mkfs|${util-linux}/bin/mkfs|" \
      -e "s|/sbin/pv|${lvm2.bin}/bin/vg|" \
      -e "s|/sbin/sgdisk|${gptfdisk}/bin/sgdisk|" \
      -e "s|/sbin/showmount|${nfs-utils}/bin/showmount|" \
      -e "s|/sbin/vg|${lvm2.bin}/bin/vg|" \
      -e "s|/sbin/zfs|${zfs}/bin/zfs|" \
      -e "s|/sbin/zpool|${zfs}/bin/zpool|" \
      -e "s|/usr/bin/chattr|${e2fsprogs}/bin/chattr|" \
      -e "s|/usr/bin/cstream||" \
      -e "s|/usr/bin/file|${file}/bin/file|" \
      -e "s|/usr/bin/iscsi-ls|${libiscsi}/bin/iscsi-ls|" \
      -e "s|/usr/bin/iscsiadm|${openiscsi}/bin/iscsiadm|" \
      -e "s|/usr/bin/proxmox-backup-client|${proxmox-backup-client}/bin/proxmox-backup-client|" \
      -e "s|/usr/bin/qemu|${pve-qemu}/bin/qemu|" \
      -e "s|/usr/bin/rados|${ceph}/bin/rados|" \
      -e "s|/usr/bin/rbd|${ceph}/bin/rbd|" \
      -e "s|/usr/bin/scp|${openssh}/bin/scp|" \
      -e "s|/usr/bin/smbclient|${samba}/bin/smbclient|" \
      -e "s|/usr/bin/ssh|${openssh}/bin/ssh|" \
      -e "s|/usr/bin/targetcli|${targetcli}/bin/targetcli|" \
      -e "s|/usr/libexec/ceph|$out/libexec/ceph|" \
      -re "s|/usr/s?bin/ceph|${ceph}/bin/ceph|" \
      -e "s|/usr/sbin/gluster|${glusterfs}/bin/gluster|" \
      -e "s|/usr/sbin/ietadm||" \
      -e "s|/usr/sbin/pvesm|$out/bin/pvesm|" \
      -e "s|/usr/sbin/rpcinfo|${rpcbind}/bin/rpcinfo|" \
      -e "s|/usr/sbin/sbdadm||" \
      -e "s|/usr/sbin/smartctl|${smartmontools}/bin/smartctl|" \
      -e "s|/usr/sbin/stmfadm||" \
      -e "s|/usr/share/perl5|$out/${perl.libPrefix}/${perl.version}|" \
  '';

  meta = with lib; {
    description = "Read-Only Mirror of the Proxmox VE Storage Library";
    homepage = "https://github.com/proxmox/pve-storage";
    license = with licenses; [ ];
    maintainers = with maintainers; [ camillemndn julienmalka ];
    platforms = platforms.linux;
  };
})
