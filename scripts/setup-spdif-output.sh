#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# ASUS X870E Hero S/PDIF Output Fix for PipeWire
# =============================================================================
# Problem: The ASUS X870E Hero motherboard's USB audio chip (0b05:1b7c)
#          has 4 playback devices. PipeWire maps the IEC958/S/PDIF profile
#          to device 0 (analog multichannel), but the actual S/PDIF output
#          is device 2 (hw:Audio,2, Interface 6, Endpoint 8).
#
# Fix: Creates a PipeWire sink that targets hw:Audio,2 directly, then
#      sets it as the default output.
#
# Hardware: Logitech Z-5500 connected via S/PDIF optical/coax to mobo
# =============================================================================

PIPEWIRE_CONF_DIR="$HOME/.config/pipewire/pipewire.conf.d"
CONF_FILE="$PIPEWIRE_CONF_DIR/spdif-output.conf"

echo "=========================================================="
echo " ASUS X870E Hero S/PDIF Output Fix"
echo "=========================================================="

# --- Menu ---
echo ""
echo "  1) Install   - Create S/PDIF sink and set as default"
echo "  2) Uninstall - Remove S/PDIF sink config"
echo "  3) Status    - Show current audio setup"
echo ""
read -rp "Select [1-3]: " choice

case "$choice" in
    1)
        echo ""
        echo "Creating PipeWire S/PDIF sink config..."
        mkdir -p "$PIPEWIRE_CONF_DIR"

        cat > "$CONF_FILE" << 'EOF'
context.objects = [
    {   factory = adapter
        args = {
            factory.name     = api.alsa.pcm.sink
            node.name        = "alsa_output.spdif-z5500"
            node.description = "S/PDIF Digital Out (Z-5500)"
            media.class      = "Audio/Sink"
            api.alsa.path    = "hw:Audio,2"
            api.alsa.period-size = 1024
            api.alsa.headroom    = 512
            audio.format     = "S24_3LE"
            audio.rate       = 48000
            audio.channels   = 2
            audio.position   = [ FL FR ]
        }
    }
]
EOF

        echo "Restarting PipeWire..."
        systemctl --user restart pipewire pipewire-pulse wireplumber
        sleep 2

        # Find and set the new sink as default
        SPDIF_ID=$(wpctl status 2>/dev/null | /usr/bin/grep "S/PDIF Digital Out" | /usr/bin/grep -oP '^\s*\K\d+' | head -1)
        if [ -n "$SPDIF_ID" ]; then
            wpctl set-default "$SPDIF_ID"
            echo ""
            echo "Done! S/PDIF Digital Out (Z-5500) set as default (node $SPDIF_ID)"
        else
            echo ""
            echo "WARNING: Sink created but couldn't find it to set as default."
            echo "Check: wpctl status"
        fi

        echo ""
        echo "Testing..."
        pw-play /usr/share/sounds/freedesktop/stereo/bell.oga 2>/dev/null || true
        echo "You should have heard a bell sound from the Z-5500."
        ;;

    2)
        echo ""
        if [ -f "$CONF_FILE" ]; then
            rm "$CONF_FILE"
            echo "Removed $CONF_FILE"
            echo "Restarting PipeWire..."
            systemctl --user restart pipewire pipewire-pulse wireplumber
            sleep 2
            echo "Done! S/PDIF sink removed. Default output reset."
        else
            echo "Nothing to remove — config doesn't exist."
        fi
        ;;

    3)
        echo ""
        echo "--- Config File ---"
        if [ -f "$CONF_FILE" ]; then
            echo "  $CONF_FILE exists"
        else
            echo "  $CONF_FILE NOT FOUND"
        fi

        echo ""
        echo "--- PipeWire Sinks ---"
        wpctl status 2>/dev/null | sed -n '/Sinks:/,/Sources:/p' | head -10

        echo ""
        echo "--- Default Sink ---"
        wpctl status 2>/dev/null | /usr/bin/grep -E '^\s*\*' | head -3

        echo ""
        echo "--- ALSA Card 'Audio' Devices ---"
        aplay -l 2>/dev/null | /usr/bin/grep -A1 "Audio" || echo "  USB Audio card not found"

        echo ""
        echo "--- S/PDIF Test ---"
        echo "  Run: speaker-test -c 2 -D plughw:Audio,2 -t sine -l 1"
        ;;

    *)
        echo "Invalid choice."
        exit 1
        ;;
esac
