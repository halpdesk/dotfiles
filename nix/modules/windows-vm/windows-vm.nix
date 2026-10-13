{ config, pkgs, lib, ... }:

let
  ovmfCode = "${pkgs.OVMF.fd}/FV/OVMF_CODE.fd";
  ovmfVarsSrc = "${pkgs.OVMF.fd}/FV/OVMF_VARS.fd";
  downloadUrl = "https://aka.ms/windev_VM_virtualbox";

  windowsVmSetup = pkgs.writeShellScriptBin "windows-vm-setup" ''
    set -euo pipefail

    VM_DIR="$HOME/VMs/windows11-dev"
    VM_DISK="$VM_DIR/windows11-dev.qcow2"

    if [ -f "$VM_DISK" ]; then
      echo "VM disk already exists at $VM_DISK"
      echo "To re-setup, remove the directory first:"
      echo "  rm -rf $VM_DIR"
      exit 0
    fi

    mkdir -p "$VM_DIR"

    cat <<'BANNER'
    ══════════════════════════════════════════════
      Windows 11 Dev VM Setup
    ══════════════════════════════════════════════
      Downloads the free Microsoft Windows 11
      Development VM and converts it for QEMU/KVM.

      Download size:  ~22 GB
      Peak disk use:  ~60 GB (during conversion)
      Final disk use: ~20 GB
    ══════════════════════════════════════════════
    BANNER

    read -p "Continue? [y/N] " -n 1 -r
    echo
    [[ $REPLY =~ ^[Yy]$ ]] || exit 0

    LOCAL_FILE="''${1:-}"
    ZIPFILE="$VM_DIR/WinDev.zip"

    if [ -n "$LOCAL_FILE" ] && [ -f "$LOCAL_FILE" ]; then
      echo "Using local file: $LOCAL_FILE"
      cp "$LOCAL_FILE" "$ZIPFILE"
    elif [ -f "$ZIPFILE" ]; then
      echo "Resuming with previously downloaded archive..."
    else
      echo "Downloading from Microsoft (this will take a while)..."
      ${pkgs.curl}/bin/curl -L --retry 3 --progress-bar \
        -o "$ZIPFILE.part" "${downloadUrl}" \
        && mv "$ZIPFILE.part" "$ZIPFILE"
    fi

    echo "Extracting archive..."
    ${pkgs.unzip}/bin/unzip -o "$ZIPFILE" -d "$VM_DIR"

    OVA="$(find "$VM_DIR" -maxdepth 1 -name '*.ova' -print -quit 2>/dev/null || true)"
    if [ -n "$OVA" ]; then
      echo "Extracting OVA..."
      ${pkgs.gnutar}/bin/tar xf "$OVA" -C "$VM_DIR"
    fi

    VMDK="$(find "$VM_DIR" -maxdepth 1 -name '*.vmdk' -print -quit 2>/dev/null || true)"
    if [ -z "$VMDK" ]; then
      echo "Error: no .vmdk found after extraction"
      ls -la "$VM_DIR"
      exit 1
    fi

    echo "Converting to qcow2 (this takes a while)..."
    ${pkgs.qemu}/bin/qemu-img convert -p -f vmdk -O qcow2 "$VMDK" "$VM_DISK"

    cp "${ovmfVarsSrc}" "$VM_DIR/OVMF_VARS.fd"
    chmod 644 "$VM_DIR/OVMF_VARS.fd"

    echo "Cleaning up intermediate files..."
    rm -f "$VM_DIR"/*.zip "$VM_DIR"/*.ova "$VM_DIR"/*.vmdk \
          "$VM_DIR"/*.ovf "$VM_DIR"/*.mf "$VM_DIR"/*.cert

    cat <<DONE

    ══════════════════════════════════════════════
      Setup complete!
    ══════════════════════════════════════════════
      VM disk: $VM_DISK

      Launch with:  windows-vm

      Inside Windows, install BankID from:
        https://install.bankid.com
    ══════════════════════════════════════════════
    DONE
  '';

  windowsVm = pkgs.writeShellScriptBin "windows-vm" ''
    set -euo pipefail

    VM_DIR="$HOME/VMs/windows11-dev"
    VM_DISK="$VM_DIR/windows11-dev.qcow2"
    OVMF_VARS="$VM_DIR/OVMF_VARS.fd"
    CPUS="''${WINDOWS_VM_CPUS:-4}"
    RAM="''${WINDOWS_VM_RAM:-8G}"

    if [ ! -f "$VM_DISK" ]; then
      echo "VM disk not found. Run 'windows-vm-setup' first."
      exit 1
    fi

    if [ ! -e /dev/kvm ]; then
      echo "Error: /dev/kvm not available."
      echo "Make sure KVM is enabled (kvm_intel or kvm_amd kernel module)."
      exit 1
    fi

    if ! [ -r /dev/kvm ] || ! [ -w /dev/kvm ]; then
      echo "Error: no permission to access /dev/kvm."
      echo "Fix: sudo usermod -aG kvm $USER  (then log out and back in)"
      exit 1
    fi

    if [ ! -f "$OVMF_VARS" ]; then
      cp "${ovmfVarsSrc}" "$OVMF_VARS"
      chmod 644 "$OVMF_VARS"
    fi

    exec ${pkgs.qemu}/bin/qemu-system-x86_64 \
      -machine q35,accel=kvm \
      -cpu host \
      -smp "$CPUS" \
      -m "$RAM" \
      -drive if=pflash,format=raw,readonly=on,file=${ovmfCode} \
      -drive if=pflash,format=raw,file="$OVMF_VARS" \
      -drive file="$VM_DISK",format=qcow2 \
      -device qemu-xhci \
      -device usb-tablet \
      -netdev user,id=net0 \
      -device e1000,netdev=net0 \
      -display gtk \
      -vga std \
      -audiodev pa,id=snd0 \
      -device ich9-intel-hda \
      -device hda-duplex,audiodev=snd0 \
      "$@"
  '';

in {

  home.packages = [
    pkgs.qemu
    windowsVmSetup
    windowsVm
  ];

  xdg.desktopEntries.windows-vm = {
    name = "Windows 11 VM";
    comment = "Windows 11 Dev VM via QEMU/KVM (for BankID etc.)";
    exec = "${windowsVm}/bin/windows-vm";
    icon = "computer";
    terminal = false;
    type = "Application";
    categories = [ "System" "Emulator" ];
  };
}
