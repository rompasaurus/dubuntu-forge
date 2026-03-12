# RX 9070 / 9070 XT (Navi 48) GPU Crash Troubleshooting

## Hardware
- **GPU:** Gigabyte RX 9070 XT (PCI ID `1002:7550`, rev C0)
- **CPU:** AMD Ryzen (Granite Ridge) with integrated GPU at `7d:00.0`
- **Motherboard:** ASUS ROG Crosshair X870E Hero
- **Kernel:** 6.17.0-14-generic

## Symptoms
- Screen goes black, system completely unresponsive
- Requires hard reboot (power button)
- Happens randomly, sometimes multiple times in 30 minutes

## Root Cause

The GPU drops off the PCIe bus due to a power management failure. The crash sequence from `journalctl -b -1 -k`:

1. **SMU stops responding** — `SMU: response:0xFFFFFFFF` (device gone from bus)
2. **GfxOff can't be disabled** — GPU is in a power-saving sleep it can't wake from
3. **Ring timeouts cascade** — gfx, sdma0, sdma1 all time out
4. **GPU falls off PCIe bus** — `device lost from bus!` in an infinite loop
5. **Recovery fails** — `GPU Recovery Failed: -19` (ENODEV, no device to reset)

### Contributing Factors

- **GfxOff enabled** — aggressive GPU power-saving that puts the card into a broken sleep state. RDNA 4 driver support is still maturing on Linux.
- **SMU firmware mismatch** — driver expects interface `0x2e`, card has `0x32`
- **PCIe link at x8 instead of x16** — `limited by 32.0 GT/s PCIe x8 link at 0000:00:01.1`
- **USB `usb2-port4` error spam** — a failing device on Bus 2 (AMD 800 chipset USB 3.x controller) was hammering `pm_runtime_work` every 4 seconds, which hogged the CPU and likely interfered with GPU power state transitions

### Crash Log Pattern

```
amdgpu 0000:03:00.0: amdgpu: device lost from bus!
amdgpu 0000:03:00.0: amdgpu: SMU: response:0xFFFFFFFF for index:18 param:0x00000005 message:TransferTableSmu2Dram?
amdgpu 0000:03:00.0: amdgpu: Failed to export SMU metrics table!
```

This repeats indefinitely until hard reboot.

## Fix: setup-rx9070-stability.sh

The script at `scripts/setup-rx9070-stability.sh` adds kernel parameters to GRUB:

| Level | Parameters | What it does |
|-------|-----------|--------------|
| 1) Conservative | `amdgpu.ppfeaturemask=0xfff73fff` | Disable GfxOff only |
| 2) Moderate | Above + `amdgpu.runpm=0` | Also disable runtime power management |
| 3) Aggressive | Above + `pcie_aspm=off` | Also disable PCIe power state management |

### How ppfeaturemask works

- Default value: `0xfff7bfff` (GfxOff enabled, bit 15 set)
- Fixed value: `0xfff73fff` (GfxOff disabled, bit 15 cleared)
- No `amdgpu.gfxoff` parameter exists on kernel 6.17, so `ppfeaturemask` is the way

### Usage

```bash
bash scripts/setup-rx9070-stability.sh
# Select option 1-3, then reboot
sudo reboot

# Verify after reboot
cat /proc/cmdline
cat /sys/module/amdgpu/parameters/ppfeaturemask  # should show 0xfff73fff
```

To revert, re-run the script and select option 5.

## USB Bus 2 Port 4 Issue

A device on `usb2-port4` (AMD 800 Series Chipset USB 3.x controller at `11:00.0`) was failing to enumerate every 4 seconds from boot:

```
usb usb2-port4: Cannot enable. Maybe the USB cable is bad?
workqueue: pm_runtime_work hogged CPU for >10000us 35 times
```

This is **not** WiFi or Bluetooth (those are on Bus 1 and PCIe respectively). Bus 2 is a motherboard USB 3.x controller.

### Resolution

Reseating USB connections resolved the `usb2-port4` errors. If they return:

```bash
# Monitor in real-time
dmesg -w | grep usb2-port4

# If errors persist with all external USB unplugged, it's an internal header
```

## Diagnostic Commands

```bash
# Check for GPU errors
journalctl -b -1 -k | grep -E "device lost|ring.*timeout|GPU reset|Recovery|gfxoff"

# Check current amdgpu parameters
cat /sys/module/amdgpu/parameters/ppfeaturemask
cat /sys/module/amdgpu/parameters/runpm

# Check GPU power state
cat /sys/class/drm/card*/device/power_dpm_force_performance_level

# Check PCIe link width
lspci -vv -s 03:00.0 | grep -i lnksta

# Monitor USB errors
dmesg -w | grep "Cannot enable"

# Full GPU log from previous boot
journalctl -b -1 -k | grep amdgpu
```
