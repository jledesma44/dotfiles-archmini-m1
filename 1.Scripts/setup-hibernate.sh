#!/usr/bin/env bash
# Sets up hibernate on btrfs with a swapfile.
# Must be run as root: sudo bash setup-hibernate.sh

set -e

SWAPFILE="/swap/swapfile"
SWAP_SIZE="16g"
DEVICE_UUID="725346d2-f127-47bc-b464-9dd46155e8d6"

echo "==> Creating btrfs swap subvolume..."
btrfs subvolume create /swap

echo "==> Creating ${SWAP_SIZE} swapfile (this may take a moment)..."
btrfs filesystem mkswapfile --size "$SWAP_SIZE" "$SWAPFILE"

echo "==> Enabling swap..."
swapon "$SWAPFILE"

echo "==> Adding swapfile to /etc/fstab..."
echo "/swap/swapfile none swap defaults 0 0" >> /etc/fstab

echo "==> Getting resume offset..."
RESUME_OFFSET=$(btrfs inspect-internal map-swapfile -r "$SWAPFILE")
echo "    Resume offset: $RESUME_OFFSET"

echo "==> Adding resume parameters to GRUB..."
sed -i "s|GRUB_CMDLINE_LINUX_DEFAULT=\"|GRUB_CMDLINE_LINUX_DEFAULT=\"resume=UUID=${DEVICE_UUID} resume_offset=${RESUME_OFFSET} |" /etc/default/grub

echo "==> Adding resume hook to initramfs..."
# Insert 'resume' before 'filesystems' in HOOKS
sed -i 's/\(.*block \)\(filesystems.*\)/\1resume \2/' /etc/mkinitcpio.conf

echo "==> Regenerating initramfs..."
mkinitcpio -P

echo "==> Regenerating GRUB config..."
grub-mkconfig -o /boot/grub/grub.cfg

echo ""
echo "Done! Hibernate is now configured."
echo "Test it with: systemctl hibernate"
echo "The system will power off and resume exactly where you left off on next boot."
