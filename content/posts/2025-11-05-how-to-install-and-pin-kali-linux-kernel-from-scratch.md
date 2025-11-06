---
title: "How to install and pin kali linux kernel from scratch"
date: "2025-11-05"
slug: "2025-11-05-how-to-install-and-pin-kali-linux-kernel-from-scratch"
---

# Geek-along: Install —and pin— Linux kernel **6.12.38** on Debian/Kali

*Stable, simple, secure.*
---

## TL;DR

This walkthrough shows how to install a specific downloaded kernel package (example: **6.12.38+kali-amd64**), ensure the matching headers are present, fix packaging hiccups, and pin/hold that kernel so your system doesn't auto-upgrade to an unwanted 6.16+ kernel. Commands are copy-ready. Prioritize backups and test on non-production first.

---

## Prerequisites

- You must be root or use `sudo`.
- Local copies of the `.deb` packages for the kernel you want (e.g., `linux-image-6.12.38+kali-amd64_*.deb`, `linux-headers-6.12.38+kali-amd64_*.deb`, `linux-headers-6.12.38+kali-common_*.deb`, and `linux-kbuild-6.12.38+kali_*.deb`), placed in a working directory.
- Enough free space in `/boot`.
- Familiarity with `grub`, `dpkg`, and `apt`.
- A rescue medium or a second machine (recommended) in case of boot problems.

---

## Safety first — backup and inventory

Before changing kernels, snapshot what you currently have and back up important files:

```bash
# Save current kernel info
uname -a > ~/kernel-before.txt
dpkg --list | grep linux-image > ~/installed-images-before.txt
dpkg --list | grep linux-headers > ~/installed-headers-before.txt

# Copy /boot (for quick rollback)
sudo mkdir -p ~/boot-backup
sudo cp -a /boot/* ~/boot-backup/
```

If you're on LVM/ZFS/BTRFS consider taking a snapshot instead.

---

## Pre-checks (quick commands)

```bash
# See installed headers and images
dpkg --list | grep linux-headers
dpkg --list | grep linux-image

# Search available packages from repo (informational)
apt search linux-headers
```

---

## Step 1 — Update apt and ensure linux-base is present

A minimal update and ensuring linux-base exists avoids odd dependency problems:

```bash
sudo apt update
sudo apt install --yes linux-base
```

---

## Step 2 — Install kernel .debs in the safe order

If you've downloaded the kernel .deb files into your working directory, install in the order that ensures build-common & headers are present before the image if needed.

```bash
# from your working dir containing the .deb files:
# 1) kbuild (if provided)
sudo dpkg -i linux-kbuild-6.12.38+kali_*.deb

# 2) common headers
sudo dpkg -i linux-headers-6.12.38+kali-common_*.deb

# 3) image + arch-specific headers
sudo dpkg -i linux-image-6.12.38+kali-amd64_*.deb linux-headers-6.12.38+kali-amd64_*.deb
```

If dpkg reports dependency problems, run:

```bash
sudo apt --fix-broken install
# Then re-run the dpkg command if needed
sudo dpkg -i linux-image-6.12.38+kali-amd64_*.deb linux-headers-6.12.38+kali-amd64_*.deb
```

**Explainer:** `dpkg -i` installs local .debs. `apt --fix-broken install` lets APT fetch missing dependencies from repositories to complete the install.

---

## Step 3 — Ensure initramfs and grub are updated

After installing, regenerate initramfs and update GRUB so the new kernel is bootable:

```bash
# Replace KVER with the precise version if needed:
KVER="6.12.38+kali-amd64"

# generate initramfs for the new kernel (if the package didn't)
sudo update-initramfs -c -k "${KVER}"

# update grub config
sudo update-grub
```

On systems using grub-mkconfig directly (some distributions):

```bash
sudo grub-mkconfig -o /boot/grub/grub.cfg
```

---

## Step 4 — Reboot — and verify

Now reboot into the new kernel and verify:

```bash
sudo reboot
# after login:
uname -r
# expected: 6.12.38+kali-amd64
```

Confirm the headers are installed for the running kernel:

```bash
sudo apt install linux-headers-$(uname -r)  # safe no-op if already present
dpkg -l | grep headers-$(uname -r)
```

---

## Preventing automatic upgrades to 6.16+ (pin/hold)

If your goal is to stay on 6.12.38 and avoid 6.16+, prefer explicit holds for the specific packages you installed. This is safer than globally blocking all kernel updates.

```bash
sudo apt-mark hold linux-image-6.12.38+kali-amd64 linux-headers-6.12.38+kali-amd64 linux-headers-6.12.38+kali-common linux-kbuild-6.12.38+kali
```

To list holds:

```bash
apt-mark showhold
```

To undo:

```bash
sudo apt-mark unhold linux-image-6.12.38+kali-amd64 linux-headers-6.12.38+kali-amd64
```

**Alternative (advanced):** use APT pinning (`/etc/apt/preferences.d/`) to pin exact versions. That is more flexible but also more complex — for most use-cases `apt-mark hold` is clear and stable.

---

## How to remove/purge an unwanted kernel (careful)

If a newer kernel slipped in and you want to remove it:

```bash
# Example: remove a specific problematic kernel
sudo apt remove --purge linux-image-6.16.0-xxx linux-headers-6.16.0-xxx
sudo update-grub
```

**Always keep at least one known-good kernel installed. Do not purge the kernel you are running.**

---

## Troubleshooting tips

- **Partial install / broken packages:** `sudo apt --fix-broken install` then re-run the dpkg -i sequence.

- **Grub didn't list kernel:** check `/boot` for vmlinuz and initramfs for that version. Re-run `sudo update-grub`.

- **Boot fails:** on rescue/Live, restore `/boot` from `~/boot-backup` or reinstall grub. Keep rescue media ready.

- **Secure Boot systems:** unsigned kernels won't boot with Secure Boot enabled. Either sign the kernels or disable Secure Boot (understand the security implications).

---

## Notes & best practices (mentor's list)

- Prefer vendor-supplied kernels where possible — they include distro patches and security fixes.

- If you must run a specific kernel (for hardware support or compliance), pin exact package names and versions as shown. Avoid holding `linux-image*` globally unless you truly need to freeze kernel updates.

- Keep a recovery plan: rescue USB, known-good kernel, remote console access (if on a server), snapshots.

- Keep kernel packages in an archive directory so you can reinstall without redownloading.

- Document the changes (commit to your sysadmin notes / Change Control).

---

## Useful copyable checklist

```bash
# 1) pre-checks
dpkg --list | grep linux-headers
apt search linux-headers
uname -r

# 2) install (from .deb files)
sudo apt update
sudo apt install --yes linux-base
sudo dpkg -i linux-kbuild-6.12.38+kali_*.deb
sudo dpkg -i linux-headers-6.12.38+kali-common_*.deb
sudo dpkg -i linux-image-6.12.38+kali-amd64_*.deb linux-headers-6.12.38+kali-amd64_*.deb
sudo apt --fix-broken install
sudo dpkg -i linux-image-6.12.38+kali-amd64_*.deb linux-headers-6.12.38+kali-amd64_*.deb

# 3) initramfs + grub
KVER="6.12.38+kali-amd64"
sudo update-initramfs -c -k "${KVER}"
sudo update-grub

# 4) reboot & verify
sudo reboot
# after login:
uname -r
dpkg -l | grep headers-$(uname -r)

# 5) hold kernel packages to prevent auto-upgrade
sudo apt-mark hold linux-image-6.12.38+kali-amd64 linux-headers-6.12.38+kali-amd64
```

---

## Figure suggestion

```
<figure>
  <img src="/assets/images/kernel-install-flow.svg" alt="Kernel install flow" width="720"/>
  <figcaption>Figure: simplified flow for installing and pinning a kernel.</figcaption>
</figure>
```

---
