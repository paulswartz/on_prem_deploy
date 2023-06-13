#!/usr/bin/env bash
# Run the Linux VM via QEMU
# $ bash run_qemu.sh [hostname]

set -e
ISO_PATH=ubuntu-22.04-server-cloudimg-amd64.img
ISO_URL=https://cloud-images.ubuntu.com/releases/jammy/release/"$ISO_PATH"

ARCH=$(arch)
QEMU_CPU=max
QEMU_MACHINE=q35

if [ "$ARCH" = "i386" ] || [ "$ARCH" = "x86-64" ]; then
   if qemu-system-x86_64 -accel help | grep -q hvf; then
      QEMU_CPU=host
      QEMU_MACHINE="accel=hvf"
   fi
fi

HOSTNAME=${1:-qemu}
tmpdir=tmp # ignored by .gitignore
mkdir -p "$tmpdir"

if [ -f "$tmpdir"/boot-disk.img ]; then
   echo Boot disk exists, not rebuilding...
else
   pushd "$tmpdir" >/dev/null
   wget --quiet -cN "$ISO_URL"

   cp $ISO_PATH boot-disk.img
   qemu-img resize boot-disk.img +4G
   popd >/dev/null
fi

bash build_cidata_iso.sh "$HOSTNAME"

qemu-system-x86_64 \
	 -net 'nic,model=virtio-net-pci' \
	 -net 'user,hostfwd=tcp::5555-:22' \
	 -machine $QEMU_MACHINE \
	 -cpu $QEMU_CPU \
	 -smp 2 \
	 -m 1024 \
	 -nodefaults \
	 -nographic \
     -serial stdio \
	 -hda "$tmpdir"/boot-disk.img \
	 -cdrom "$tmpdir"/"$HOSTNAME".iso
