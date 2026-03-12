#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# RX 9070 / 9070 XT (Navi 48 / RDNA 4) Stability Fix for Ubuntu
# =============================================================================
# Problem: GPU drops off PCIe bus due to SDMA/GFX ring timeouts caused by
#          GfxOff (aggressive power-saving sleep the GPU can't wake from).
#          SMU firmware interface mismatch compounds the issue.
#
# Fix: Disable GfxOff via ppfeaturemask, disable runtime PM, and optionally
#      disable PCIe ASPM to prevent the GPU entering broken power states.
#
# Hardware: AMD RX 9070 / 9070 XT (PCI ID 1002:7550)
# =============================================================================

GRUB_FILE="/etc/default/grub"
GRUB_BACKUP="/etc/default/grub.bak.$(date +%Y%m%d%H%M%S)"

# Current ppfeaturemask with GFXOFF bit (bit 15 / 0x8000) cleared
# Default: 0xfff7bfff -> with GFXOFF disabled: 0xfff73fff
PP_MASK="0xfff73fff"

echo "=========================================================="
echo " RX 9070 / 9070 XT Stability Fix"
echo " Kernel: $(uname -r)"
echo "=========================================================="

# --- Preflight check ---
if [ -z "$(lspci -d 1002:7550 2>/dev/null)" ]; then
    echo ""
    echo "WARNING: No RX 9070/9070 XT detected (PCI ID 1002:7550)"
    read -rp "Continue anyway? [y/N] " ans
    [[ "$ans" =~ ^[Yy] ]] || exit 0
fi

echo ""
echo "This script will add kernel parameters to fix GPU crashes:"
echo ""
echo "  amdgpu.ppfeaturemask=${PP_MASK}  (disable GfxOff)"
echo "  amdgpu.runpm=0                   (disable runtime power mgmt)"
echo "  pcie_aspm=off                    (disable PCIe power states)"
echo ""
echo "Trade-off: ~5-10W higher idle power, but no more black screens."
echo ""

# --- Menu ---
echo "Choose fix level:"
echo ""
echo "  1) Conservative  - Disable GfxOff only (recommended first try)"
echo "  2) Moderate       - Disable GfxOff + runtime PM"
echo "  3) Aggressive     - Disable GfxOff + runtime PM + PCIe ASPM"
echo "  4) Show current   - Display current settings and exit"
echo "  5) Revert         - Remove all amdgpu fixes from GRUB"
echo ""
read -rp "Select [1-5]: " choice

PARAMS=""
case "$choice" in
    1)
        PARAMS="amdgpu.ppfeaturemask=${PP_MASK}"
        echo ""
        echo "-> Conservative: disabling GfxOff only"
        ;;
    2)
        PARAMS="amdgpu.ppfeaturemask=${PP_MASK} amdgpu.runpm=0"
        echo ""
        echo "-> Moderate: disabling GfxOff + runtime PM"
        ;;
    3)
        PARAMS="amdgpu.ppfeaturemask=${PP_MASK} amdgpu.runpm=0 pcie_aspm=off"
        echo ""
        echo "-> Aggressive: disabling GfxOff + runtime PM + PCIe ASPM"
        ;;
    4)
        echo ""
        echo "--- Current Kernel Parameters ---"
        echo "  Boot cmdline: $(cat /proc/cmdline)"
        echo ""
        echo "--- amdgpu Module Parameters ---"
        echo "  ppfeaturemask: $(cat /sys/module/amdgpu/parameters/ppfeaturemask 2>/dev/null || echo 'N/A')"
        echo "  runpm:         $(cat /sys/module/amdgpu/parameters/runpm 2>/dev/null || echo 'N/A')"
        echo "  aspm:          $(cat /sys/module/amdgpu/parameters/aspm 2>/dev/null || echo 'N/A')"
        echo ""
        echo "--- GPU Power State ---"
        for f in /sys/class/drm/card*/device/power_dpm_force_performance_level; do
            [ -f "$f" ] && echo "  $(basename "$(dirname "$(dirname "$f")")"): $(cat "$f")"
        done
        echo ""
        echo "--- PCIe Link ---"
        lspci -vv -s 03:00.0 2>/dev/null | /usr/bin/grep -i -E "lnksta:|lnkctl:|aspm" || echo "  (could not read)"
        echo ""
        echo "--- GRUB Config ---"
        /usr/bin/grep "GRUB_CMDLINE_LINUX" "$GRUB_FILE" 2>/dev/null || echo "  (could not read)"
        exit 0
        ;;
    5)
        echo ""
        echo "-> Reverting: removing amdgpu/pcie_aspm parameters from GRUB"
        sudo cp "$GRUB_FILE" "$GRUB_BACKUP"
        echo "  Backup saved to $GRUB_BACKUP"

        # Remove our parameters from GRUB_CMDLINE_LINUX_DEFAULT
        sudo sed -i \
            -e 's/ *amdgpu\.ppfeaturemask=[^ "]*//g' \
            -e 's/ *amdgpu\.runpm=[^ "]*//g' \
            -e 's/ *pcie_aspm=[^ "]*//g' \
            "$GRUB_FILE"

        echo "  Updating GRUB..."
        sudo update-grub

        echo ""
        echo "Done! Reboot to apply: sudo reboot"
        exit 0
        ;;
    *)
        echo "Invalid choice."
        exit 1
        ;;
esac

# --- Apply ---
echo ""
echo "Backing up GRUB config to $GRUB_BACKUP"
sudo cp "$GRUB_FILE" "$GRUB_BACKUP"

# First clean any existing amdgpu/pcie_aspm params we manage
sudo sed -i \
    -e 's/ *amdgpu\.ppfeaturemask=[^ "]*//g' \
    -e 's/ *amdgpu\.runpm=[^ "]*//g' \
    -e 's/ *pcie_aspm=[^ "]*//g' \
    "$GRUB_FILE"

# Append new params to GRUB_CMDLINE_LINUX_DEFAULT
# Match the closing quote and insert before it
sudo sed -i "s|^\(GRUB_CMDLINE_LINUX_DEFAULT=\".*\)\"|\1 ${PARAMS}\"|" "$GRUB_FILE"

# Verify
echo ""
echo "--- Updated GRUB config ---"
/usr/bin/grep "GRUB_CMDLINE_LINUX_DEFAULT" "$GRUB_FILE"
echo ""

# Update GRUB
echo "Updating GRUB..."
sudo update-grub

echo ""
echo "=========================================================="
echo " Done! Reboot required to apply."
echo "=========================================================="
echo ""
echo "  sudo reboot"
echo ""
echo "After reboot, verify with:"
echo "  cat /proc/cmdline"
echo "  cat /sys/module/amdgpu/parameters/ppfeaturemask"
echo ""
echo "If crashes persist after option 1, re-run and try option 2 or 3."
echo "To undo: re-run this script and choose option 5 (Revert)."
echo ""
