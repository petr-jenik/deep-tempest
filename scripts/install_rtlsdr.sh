#!/usr/bin/env bash
set -e

# RTL-SDR installer for Deep-Tempest
# Clones rtl-sdr, builds it, installs udev rules, and blacklists
# the conflicting DVB-T kernel module.

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
RTL_DIR="$ROOT_DIR/rtl-sdr"

# Clone rtl-sdr source
git clone git://git.osmocom.org/rtl-sdr.git "$RTL_DIR"

# Install build dependencies
sudo apt update
sudo apt install -y cmake make gcc libusb-1.0-0-dev pkg-config

# Build
mkdir -p "$RTL_DIR/build"
cd "$RTL_DIR/build"
cmake .. -DCMAKE_BUILD_TYPE=Release -DINSTALL_UDEV_RULES=OFF
make -j"$(nproc)"
sudo make install
sudo ldconfig

# udev rules — allow non-root access to the dongle
sudo cp "$RTL_DIR/rtl-sdr.rules" /etc/udev/rules.d/rtl-sdr.rules
sudo udevadm control --reload-rules && sudo udevadm trigger
sudo usermod -aG plugdev "$USER"

# Blacklist the DVB-T kernel driver that conflicts with rtl-sdr
sudo tee /etc/modprobe.d/rtlsdr-blacklist.conf >/dev/null <<'EOF'
blacklist dvb_usb_rtl28xxu
blacklist rtl2832
blacklist rtl2830
EOF
sudo modprobe -r dvb_usb_rtl28xxu 2>/dev/null || true

echo "Done. Plug in the dongle and test with: rtl_test -t"
echo "NOTE: Log out and back in for the plugdev group change to take effect."
