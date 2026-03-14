# ASUS ROG Zephyrus G16 (GU605MY) — Keyboard Fix

## Problem

The built-in keyboard works at the GDM login screen but stops working (or only types one key like "a") after logging into the GNOME Wayland session.

### Root Cause

The `hid_asus` kernel driver (kernel 6.17 and earlier) corrupts the HID report descriptor for the N-Key USB keyboard (`0b05:19b6`). It applies a broken fixup to the `0x5a` report, changing a 5-byte report count incorrectly, which causes most keycodes to get dropped or misinterpreted.

This is fixed in kernel 6.19+ via a patch series by Antheas Kapenekakis that prevents `hid_asus` from binding to all HID interfaces indiscriminately.

### Hardware Details

- **Keyboard**: USB HID "Asus Keyboard" — ITE Tech 8910 controller
- **Vendor/Product**: `0b05:19b6` (`USB_DEVICE_ID_ASUSTEK_ROG_NKEY_KEYBOARD2`)
- **Driver**: `hid_asus` (buggy on kernel ≤6.18), `hid-generic` (workaround)
- **USB path**: `3-6` (`/sys/bus/usb/devices/3-6`)

---

## Fix (kernel 6.17 and earlier)

Blacklist the buggy `hid_asus` driver so the keyboard falls back to `hid-generic`.

### Apply

```bash
bash fix-g16-gu605my-keyboard.sh
```

Or manually:

```bash
echo "blacklist hid_asus" | sudo tee /etc/modprobe.d/blacklist-hid-asus.conf
sudo modprobe -r hid_asus
echo -n "3-6" | sudo tee /sys/bus/usb/drivers/usb/unbind
sleep 1
echo -n "3-6" | sudo tee /sys/bus/usb/drivers/usb/bind
```

### What You Lose

- Keyboard backlight control via `asusctl` (backlight stays at last-set level)
- Special N-Key function key handling (media keys may still work via WMI)

### Revert

```bash
sudo rm /etc/modprobe.d/blacklist-hid-asus.conf
sudo reboot
```

---

## Kernel 6.19 Upgrade (Permanent Fix)

Kernel 6.19 includes the patched `hid_asus` driver. Once installed, remove the blacklist and the keyboard works natively with full backlight support.

### Install Kernel 6.19 from Ubuntu Mainline PPA

```bash
cd /tmp && mkdir -p kernel-6.19 && cd kernel-6.19

wget https://kernel.ubuntu.com/~kernel-ppa/mainline/v6.19/amd64/linux-headers-6.19.0-061900-generic_6.19.0-061900.202602082231_amd64.deb
wget https://kernel.ubuntu.com/~kernel-ppa/mainline/v6.19/amd64/linux-image-unsigned-6.19.0-061900-generic_6.19.0-061900.202602082231_amd64.deb
wget https://kernel.ubuntu.com/~kernel-ppa/mainline/v6.19/amd64/linux-modules-6.19.0-061900-generic_6.19.0-061900.202602082231_amd64.deb
wget https://kernel.ubuntu.com/~kernel-ppa/mainline/v6.19/linux-headers-6.19.0-061900_6.19.0-061900.202602082231_all.deb

sudo apt install ./linux-*.deb
sudo reboot
```

> **Secure Boot**: Mainline kernels are unsigned. If Secure Boot is enabled, either disable it in BIOS or sign the kernel manually with your MOK key.

### After Installing 6.19 — Remove the Blacklist

```bash
sudo rm /etc/modprobe.d/blacklist-hid-asus.conf
sudo reboot
```

### Uninstall Kernel 6.19

If 6.19 causes problems, boot into your old kernel from the GRUB menu (Advanced options → 6.17), then:

```bash
sudo apt remove linux-headers-6.19.0-061900-generic \
                 linux-headers-6.19.0-061900 \
                 linux-image-unsigned-6.19.0-061900-generic \
                 linux-modules-6.19.0-061900-generic
sudo update-grub
```

---

## Other Installed Fixes

These were installed by the fix script and can be cleaned up if no longer needed:

### udev Rule (ignore Asus WMI hotkeys)

- **File**: `/etc/udev/rules.d/99-asus-keyboard-fix.rules`
- **Purpose**: Tells libinput/mutter to ignore the "Asus WMI hotkeys" platform device
- **Remove**: `sudo rm /etc/udev/rules.d/99-asus-keyboard-fix.rules && sudo udevadm control --reload-rules`

### Suspend/Resume Hook

- **File**: `/usr/lib/systemd/system-sleep/asus-keyboard-resume.sh`
- **Purpose**: Reloads keyboard driver after waking from suspend
- **Remove**: `sudo rm /usr/lib/systemd/system-sleep/asus-keyboard-resume.sh`

### GRUB i8042 Parameters

- **File**: `/etc/default/grub` — `i8042.reset=1 i8042.nomux=1 i8042.nopnp=1`
- **Purpose**: PS/2 keyboard init (not needed — the real keyboard is USB HID)
- **Remove**: Edit `/etc/default/grub`, remove the i8042 params, run `sudo update-grub`

---

## References

- [Kernel patch: hid_asus multi-interface fix (LKML)](https://lkml.org/lkml/2026/2/3/1811)
- [Kernel patch: 0x5a report count fix (LKML)](https://lore.kernel.org/lkml/CAMXW6=97T1tzT=FSyzZN6jBAKgzUDOjqRoH-FMAPLHk1gsD=mA@mail.gmail.com/)
- [Ubuntu Mainline Kernel PPA](https://kernel.ubuntu.com/~kernel-ppa/mainline/)
- [Red Hat Bugzilla: 0b05:19b6 probe failure](https://bugzilla.redhat.com/show_bug.cgi?id=2222215)
- [asus-linux.org](https://asus-linux.org/)
