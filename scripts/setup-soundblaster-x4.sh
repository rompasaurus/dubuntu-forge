#!/bin/bash
# Setup Creative Sound Blaster X4 on Ubuntu with PipeWire
# Enables surround profiles, chat mixer, and Dolby/DTS codecs

set -e

echo "=== Installing Dolby/DTS/surround codecs ==="
sudo apt update
sudo apt install -y \
    gstreamer1.0-plugins-ugly \
    gstreamer1.0-plugins-bad \
    gstreamer1.0-libav \
    ffmpeg \
    liba52-0.7.4-dev \
    libdca-dev \
    libfdk-aac2 \
    libavcodec-extra \
    pipewire-audio \
    wireplumber

echo ""
echo "=== Creating Sound Blaster X4 ALSA card profile ==="
mkdir -p ~/.config/alsa-card-profile/mixer/profile-sets

cat > ~/.config/alsa-card-profile/mixer/profile-sets/sound-blaster-x4.conf << 'EOF'
[General]
auto-profiles = no

[Mapping analog-stereo]
device-strings = front:%f
channel-map = left,right
paths-output = analog-output analog-output-lineout analog-output-speaker
direction = output
priority = 15

[Mapping analog-surround-21]
device-strings = surround21:%f
channel-map = front-left,front-right,lfe
paths-output = analog-output analog-output-lineout analog-output-speaker
direction = output
priority = 13

[Mapping analog-surround-40]
device-strings = surround40:%f
channel-map = front-left,front-right,rear-left,rear-right
paths-output = analog-output analog-output-lineout analog-output-speaker
direction = output
priority = 12

[Mapping analog-surround-41]
device-strings = surround41:%f
channel-map = front-left,front-right,rear-left,rear-right,lfe
paths-output = analog-output analog-output-lineout analog-output-speaker
direction = output
priority = 13

[Mapping analog-surround-50]
device-strings = surround50:%f
channel-map = front-left,front-right,rear-left,rear-right,front-center
paths-output = analog-output analog-output-lineout analog-output-speaker
direction = output
priority = 12

[Mapping analog-surround-51]
device-strings = surround51:%f
channel-map = front-left,front-right,rear-left,rear-right,front-center,lfe
paths-output = analog-output analog-output-lineout analog-output-speaker
direction = output
priority = 13

[Mapping analog-surround-71]
device-strings = surround71:%f
channel-map = front-left,front-right,rear-left,rear-right,front-center,lfe,side-left,side-right
paths-output = analog-output analog-output-lineout analog-output-speaker
direction = output
priority = 12

[Mapping analog-stereo-chat-output]
description-key = gaming-headset-chat
device-strings = hw:%f,1,0
channel-map = left,right
paths-output = analog-output analog-output-lineout analog-output-speaker
direction = output
priority = 15

[Mapping analog-stereo-chat-input]
description-key = gaming-headset-chat
device-strings = hw:%f,0,0
channel-map = left,right
paths-input = analog-input analog-input-linein analog-input-mic
direction = input
intended-roles = phone
priority = 15

[Profile sound-blaster-x4-20]
output-mappings = analog-stereo analog-stereo-chat-output
input-mappings = analog-stereo-chat-input

[Profile sound-blaster-x4-21]
output-mappings = analog-surround-21 analog-stereo-chat-output
input-mappings = analog-stereo-chat-input

[Profile sound-blaster-x4-40]
output-mappings = analog-surround-40 analog-stereo-chat-output
input-mappings = analog-stereo-chat-input

[Profile sound-blaster-x4-41]
output-mappings = analog-surround-41 analog-stereo-chat-output
input-mappings = analog-stereo-chat-input

[Profile sound-blaster-x4-50]
output-mappings = analog-surround-50 analog-stereo-chat-output
input-mappings = analog-stereo-chat-input

[Profile sound-blaster-x4-51]
output-mappings = analog-surround-51 analog-stereo-chat-output
input-mappings = analog-stereo-chat-input

[Profile sound-blaster-x4-71]
output-mappings = analog-surround-71 analog-stereo-chat-output
input-mappings = analog-stereo-chat-input
EOF

echo ""
echo "=== Creating WirePlumber config for Sound Blaster X4 ==="
mkdir -p ~/.config/wireplumber/wireplumber.conf.d

cat > ~/.config/wireplumber/wireplumber.conf.d/51-soundblaster-x4.conf << 'EOF'
monitor.alsa.rules = [
  {
    matches = [
      {
        device.nick = "Sound Blaster X4"
      }
    ]
    actions = {
      update-props = {
        api.alsa.use-acp = true,
        api.acp.auto-profile = false
        api.acp.auto-port = false
        device.profile-set = "sound-blaster-x4.conf"
        device.profile = "sound-blaster-x4-20"
      }
    }
  }
]
EOF

echo ""
echo "=== Restarting WirePlumber ==="
systemctl --user restart wireplumber.service
sleep 2

echo ""
echo "=== Done! ==="
echo ""
echo "Your Sound Blaster X4 is configured with:"
echo "  - Stereo, 2.1, 4.0, 4.1, 5.0, 5.1, and 7.1 surround profiles"
echo "  - Separate game/chat mixer channels"
echo "  - Dolby Digital (AC3), DTS, AAC, and surround codec support"
echo ""
echo "To switch profiles, use GNOME Settings → Sound,"
echo "or run: wpctl status"
echo ""
echo "NOTE: There is no official Creative utility for Linux."
echo "Use 'pwvucontrol' or 'pavucontrol' for advanced mixing."
