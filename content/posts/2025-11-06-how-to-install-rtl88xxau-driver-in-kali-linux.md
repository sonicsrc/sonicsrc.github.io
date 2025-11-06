---
title: "How to install rtl88xxau driver in kali linux"
date: "2025-11-06"
slug: "2025-11-06-how-to-install-rtl88xxau-driver-in-kali-linux"
---

Installing and configuring Realtek RTL88xxAU (8812AU / 8821AU) drivers on Kali Linux (with dkms)

Goal
------
Get a Realtek RTL88xxAU-based USB Wi‑Fi adapter working in Kali Linux with:
 - DKMS-backed driver (survives kernel updates)
 - Monitor mode + packet injection support
 - Optional TX power adjustment (be aware of your local regulations)

Important prerequisites and safety
----------------------------------
1. Work on a local machine or an authorized test lab. Do not intercept networks or attempt attacks you are not explicitly allowed to perform.
2. You may need internet connectivity to install packages and fetch source code.
3. Know your kernel headers must match the running kernel; otherwise DKMS builds fail.
4. Excessive TX power may be illegal in your country — check the regulatory domain and local laws before changing transmitter power.

A. Quick path — install Kali packaged driver (recommended if available)
----------------------------------------------------------------------
These packages are in Kali repositories and provide a DKMS package for many RTL88xxAU devices.

Commands:
```bash
sudo apt update
sudo apt full-upgrade -y

# Install the packaged DKMS driver (Kali repo)
sudo apt install -y realtek-rtl88xxau-dkms

# Verify DKMS status and module presence
sudo dkms status
find /lib/modules/"$(uname -r)"/ -name "*88*au*.ko" || find /lib/modules/"$(uname -r)"/ -name "8812au.ko"

# Load module (if not autoloaded)
sudo modprobe 8812au || sudo modprobe 88xxau || true

# Check dmesg for driver messages
dmesg | tail -n 40 | grep -i -E "8812|88xx|rtl|usb"
```

If that worked you should see a new wireless interface in `ip link` or `iw dev`.

B. Build-from-source path (aircrack-ng / DKMS) — flexible and more up-to-date
-------------------------------------------------------------------------------
Use this when the packaged driver doesn't support your kernel or you want the latest fixes.

Commands:
```bash
# 1) Install build tools and headers
sudo apt update
sudo apt install -y git dkms build-essential bc libelf-dev rfkill

# Ensure kernel headers exist for your running kernel:
sudo apt install -y linux-headers-"$(uname -r)" || sudo apt install -y linux-headers-amd64

# 2) Clone a maintained source (aircrack-ng branch is known and supports DKMS)
git clone -b v5.6.4.2 https://github.com/aircrack-ng/rtl8812au.git
cd rtl8812au

# 3) Install via the included DKMS script
sudo ./dkms-install.sh

# Confirm install:
sudo dkms status
find /lib/modules/"$(uname -r)"/ -name "*88*au*.ko" || find /lib/modules/"$(uname -r)"/ -name "8812au.ko"
```

If `dkms-install.sh` is not present in a different repo, there may be `make`/`make install` or `sudo ./install-driver.sh` (see that repo's README).

C. Uninstalling / removing drivers
----------------------------------
Remove the packaged driver:
```bash
sudo apt remove --purge -y realtek-rtl88xxau-dkms
sudo apt autoremove -y
```

If you installed from a git repo that provided DKMS scripts:
```bash
# in the source directory:
sudo ./dkms-remove.sh   # if present

# OR remove via dkms directly (example module name/version; adjust to what `dkms status` shows)
sudo dkms remove -m rtl8812au -v 5.6.4.2 --all
sudo dkms status
```

D. Enabling monitor mode and testing injection (benign checks)
--------------------------------------------------------------
1) Identify interface (it might be wlan0, wlan1, or something like wlx...)
```bash
ip link
iw dev
```

2) Using `airmon-ng` (aircrack-ng suite)
```bash
# stop interfering services and put iface into monitor
sudo airmon-ng check kill
sudo airmon-ng start wlan0      # replace wlan0 with your interface
# stop monitor mode and restore networking
sudo airmon-ng stop wlan0mon
sudo systemctl restart NetworkManager.service || sudo service NetworkManager restart
```

3) Manual method with `iw`:
```bash
sudo ip link set wlan0 down
sudo iw dev wlan0 set type monitor
sudo ip link set wlan0 up
# verify
iw dev wlan0 info
```

4) Test injection capability (safe test):
```bash
# install aircrack-ng if you don't already have it:
sudo apt install -y aircrack-ng

# run an injection test (this is a harmless TX/RX test)
sudo aireplay-ng --test wlan0mon    # replace with your monitor interface (wlan0mon)
```

E. Blacklist conflicting in-kernel driver (if necessary)
--------------------------------------------------------
Some kernels ship `rtl8xxxu` which can bind before the out-of-tree module. If the out-of-tree driver fails to bind, blacklist the in-kernel one:

```bash
echo "blacklist rtl8xxxu" | sudo tee /etc/modprobe.d/blacklist-rtl8xxxu.conf
# Rebuild initramfs (Debian/Kali)
sudo update-initramfs -u
# Reboot or reload modules
sudo reboot
```

F. Set TX power
--------------------------------------
You can inspect and set tx power. Examples:
```bash
# show current power settings
iw dev wlan0 link
iwconfig wlan0 | grep -i tx

# using iwconfig (legacy):
sudo ip link set wlan0 down
sudo iwconfig wlan0 txpower 30  # sets 30 dBm (if hardware/regulatory allows)
sudo ip link set wlan0 up

# using modern iw (txpower in mBm, 3000 mBm == 30.00 dBm on many iw implementations)
sudo ip link set wlan0 down
sudo iw dev wlan0 set txpower fixed 3000
sudo ip link set wlan0 up

# verify:
iw dev wlan0 info
```
If `Operation not permitted` or `Invalid argument` appears, your regulatory domain or driver doesn't allow the requested value.

G. Troubleshooting checklist
----------------------------
 - If DKMS build fails: ensure `linux-headers-$(uname -r)` are installed and match your running kernel. Some kernels use `-kali-amd64` variants; `linux-headers-amd64` is a helpful fallback.
 - Inspect `sudo dkms build` output in `/var/lib/dkms/<module>/<version>/build/make.log`.
 - `dmesg | grep -i rtl` or `dmesg | grep -i 8812` for driver messages.
 - If interface never appears: try removing and re-plugging the USB adapter, `sudo modprobe -r 88xxau 8812au rtl8xxxu`, then `sudo modprobe 8812au`.
 - If you see kernel incompatibility with newest kernels, try a different upstream driver repo (morrownr, c4pt000, n0ss, aircrack-ng variants are commonly used).
 - As a last resort, use the packaged Kali `.deb` from the Kali packages repo (it may contain patches for the distro): `sudo apt install realtek-rtl88xxau-dkms`.

References and further reading
------------------------------
 - aircrack-ng rtl8812au repository (DKMS scripts & monitor support). See README. (used for build-from-source path).  
   https://github.com/aircrack-ng/rtl8812au  (aircrack-ng).  
 - Kali package: realtek-rtl88xxau-dkms (Kali packages repo).  
   https://gitlab.com/kalilinux/packages/realtek-rtl88xxau-dkms  
 - morrownr driver variant (alternative source, installer scripts):  
   https://github.com/morrownr/8812au-20210820  
 - Official Alfa documentation (device vendor notes): https://docs.alfa.com.tw/Support/Linux/RTL8812AU/ 
