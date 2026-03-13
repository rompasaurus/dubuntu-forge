#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# ASUS X870E Hero S/PDIF 5.1 Output for PipeWire
# =============================================================================
# Problem: The ASUS X870E Hero motherboard's USB audio chip (0b05:1b7c)
#          has 4 playback devices. PipeWire maps the IEC958/S/PDIF profile
#          to device 0 (analog multichannel), but the actual S/PDIF output
#          is device 2 (hw:Audio,2, Interface 6, Endpoint 8).
#
# Fix: Creates an ALSA a52 device that encodes 5.1 PCM to Dolby Digital
#      (AC3) and sends it over S/PDIF to the Z-5500's decoder.
#      A PipeWire sink wraps this with the correct channel mapping.
#
# Channel map: The a52 encoder outputs channels in a non-standard order:
#   ch0=FL, ch1=FR, ch2=RL, ch3=RR, ch4=FC, ch5=LFE
#
# Hardware: Logitech Z-5500 connected via S/PDIF optical/coax to mobo
# =============================================================================

PIPEWIRE_CONF_DIR="$HOME/.config/pipewire/pipewire.conf.d"
CONF_FILE="$PIPEWIRE_CONF_DIR/spdif-output.conf"
ASOUNDRC="$HOME/.asoundrc"

echo "=========================================================="
echo " ASUS X870E Hero S/PDIF 5.1 Output (Z-5500)"
echo "=========================================================="

# --- Menu ---
echo ""
echo "  1) Install   - S/PDIF 5.1 surround (AC3) + set as default"
echo "  2) Uninstall - Remove S/PDIF config and ALSA a52 setup"
echo "  3) Status    - Show current audio setup"
echo ""
read -rp "Select [1-3]: " choice

case "$choice" in
    1)
        echo ""

        # Install a52 encoder if needed
        if ! ls /usr/lib/*/alsa-lib/libasound_module_pcm_a52.so &>/dev/null; then
            echo "Installing AC3 encoder plugin..."
            sudo apt-get update -qq
            sudo apt-get install -y libasound2-plugin-a52
        else
            echo "AC3 encoder plugin already installed."
        fi

        # Install EasyEffects for audio management
        if ! command -v easyeffects &>/dev/null; then
            echo "Installing EasyEffects (equalizer, effects, per-app control)..."
            sudo apt-get install -y easyeffects
        else
            echo "EasyEffects already installed."
        fi

        # Create ALSA a52 device config
        echo "Creating ALSA a52 encoder config..."
        cat > "$ASOUNDRC" << 'EOF'
# AC3 5.1 encoder over S/PDIF for Logitech Z-5500
# Takes 6-channel PCM input, encodes to Dolby Digital, outputs via S/PDIF
pcm.spdif_51 {
    type a52
    card 3
    slavepcm "hw:3,2"
    rate 48000
    bitrate 448
    channels 6
}

pcm.spdif_51_plug {
    type plug
    slave.pcm "spdif_51"
}
EOF

        # Create PipeWire sink config with correct channel mapping
        echo "Creating PipeWire 5.1 AC3 sink config..."
        mkdir -p "$PIPEWIRE_CONF_DIR"

        cat > "$CONF_FILE" << 'EOF'
context.objects = [
    # 5.1 Surround via AC3 encoding over S/PDIF to Logitech Z-5500
    # PipeWire mixes all audio (stereo, 5.1, etc.) into 6 channels,
    # encodes to Dolby Digital AC3, and sends over S/PDIF.
    # The Z-5500's decoder handles the rest.
    #
    # Channel mapping: a52 encoder outputs FL,FR,RL,RR,FC,LFE
    # (not the standard FL,FR,FC,LFE,RL,RR)
    {   factory = adapter
        args = {
            factory.name     = api.alsa.pcm.sink
            node.name        = "alsa_output.spdif-z5500-surround51"
            node.description = "S/PDIF 5.1 Surround AC3 (Z-5500)"
            media.class      = "Audio/Sink"
            api.alsa.path    = "spdif_51_plug"
            api.alsa.period-size = 1024
            api.alsa.headroom    = 512
            audio.format     = "S16_LE"
            audio.rate       = 48000
            audio.channels   = 6
            audio.position   = [ FL FR RL RR FC LFE ]
            priority.session  = 2000
        }
    }
]
EOF

        echo "Restarting PipeWire..."
        systemctl --user restart pipewire pipewire-pulse wireplumber
        sleep 3

        # Find and set the new sink as default
        SPDIF_ID=$(wpctl status 2>/dev/null | /usr/bin/grep "S/PDIF 5.1" | /usr/bin/grep -oP '^\s*\K\d+' | head -1)
        if [ -n "$SPDIF_ID" ]; then
            wpctl set-default "$SPDIF_ID"
            echo ""
            echo "Done! S/PDIF 5.1 Surround AC3 (Z-5500) set as default (node $SPDIF_ID)"
        else
            echo ""
            echo "WARNING: Sink created but couldn't find it to set as default."
            echo "Check: wpctl status"
        fi

        echo ""
        echo "Testing..."
        pw-play /usr/share/sounds/freedesktop/stereo/bell.oga 2>/dev/null || true
        echo "You should have heard a bell sound from the Z-5500."
        echo ""
        echo "All audio (stereo, 5.1, 7.1) will be mixed to 5.1 AC3"
        echo "and sent over S/PDIF to the Z-5500's Dolby decoder."
        echo ""
        echo "Use EasyEffects for EQ, bass boost, compressor, and more:"
        echo "  easyeffects"
        ;;

    2)
        echo ""
        REMOVED=false

        if [ -f "$CONF_FILE" ]; then
            rm "$CONF_FILE"
            echo "Removed $CONF_FILE"
            REMOVED=true
        fi

        if [ -f "$ASOUNDRC" ]; then
            rm "$ASOUNDRC"
            echo "Removed $ASOUNDRC"
            REMOVED=true
        fi

        if [ "$REMOVED" = true ]; then
            echo "Restarting PipeWire..."
            systemctl --user restart pipewire pipewire-pulse wireplumber
            sleep 2
            echo "Done! S/PDIF sink removed. Default output reset."
        else
            echo "Nothing to remove — config files don't exist."
        fi
        ;;

    3)
        echo ""
        echo "--- Config Files ---"
        [ -f "$CONF_FILE" ] && echo "  PipeWire: $CONF_FILE" || echo "  PipeWire: NOT FOUND"
        [ -f "$ASOUNDRC" ] && echo "  ALSA:     $ASOUNDRC" || echo "  ALSA:     NOT FOUND"

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
        echo "--- a52 Plugin ---"
        ls /usr/lib/*/alsa-lib/libasound_module_pcm_a52.so 2>/dev/null \
            && echo "  Installed" || echo "  NOT INSTALLED"

        echo ""
        echo "--- EasyEffects ---"
        command -v easyeffects &>/dev/null \
            && echo "  Installed (run: easyeffects)" || echo "  NOT INSTALLED"

        echo ""
        echo "--- Manual Tests ---"
        echo "  Stereo:  speaker-test -c 2 -D plughw:Audio,2 -t sine -l 1"
        echo "  5.1 AC3: speaker-test -c 6 -D spdif_51_plug -t sine -l 1"
        echo "  GNOME:   Settings → Sound → Test"
        ;;

    *)
        echo "Invalid choice."
        exit 1
        ;;
esac
