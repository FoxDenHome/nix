{ nixpkgs, ... } :
{
  driverOptsType = with nixpkgs.lib.types; submodule {
    vlan = nixpkgs.lib.mkOption {
      type = ints.unsigned;
    };
    root = nixpkgs.lib.mkOption {
      type = str;
    };
  };

  build = { ... } : {
    config.systemd = {};
  };

  hooks = ({ pkgs, ipCmd, serviceInterface, interface, ... }: let
    root = interface.driverOpts.root;

    allocSriovScript = pkgs.writeShellScript "allocate-sriov" ''
      set -euox pipefail
      interface="$1"
      numvfs_file="/sys/class/net/${root}/device/sriov_numvfs"
      totalvfs="$(cat /sys/class/net/${root}/device/sriov_totalvfs)"
      current_vfs="$(cat "$numvfs_file")"
      if [ "$current_vfs" -eq 0 ]; then
        echo $totalvfs > "$numvfs_file"
      fi

      assign_vf() {
        idx="$1"
        # Enable spoof checking, set MAC and VLAN
        ${ipCmd} link set dev "${root}" vf "$idx" spoofchk on mac "${interface.mac}" vlan "${builtins.toString interface.driverOpts.vlan}"
        # Find current name of VF interface
        ifname="$(${pkgs.coreutils}/bin/ls /sys/class/net/${root}/device/virtfn$idx/net/)"
        # And rename it
        ${ipCmd} link set dev "$ifname" name "${serviceInterface}"
      }

      assign_vf_by_mac() {
        mac="$1"
        matched_vf="$(${ipCmd} link show dev "${root}" | ${pkgs.gnugrep}/bin/grep -oi "vf .* link/ether $mac " | ${pkgs.coreutils}/bin/cut -d' ' -f2 | ${pkgs.coreutils}/bin/head -1 || :)"
        if [ -n "$matched_vf" ]; then
          assign_vf "$matched_vf"
          exit 0
        fi
      }

      # Condition A: We find a VIF with our MAC address
      assign_vf_by_mac '${interface.mac}'

      # Condition B: Find an unused VF
      assign_vf_by_mac '00:00:00:00:00:00'

      # TODO: Condition C: No free VFs, go hunting for unused ones (in main netns)
      exit 1
    '';
  in
  {
    start = [
      "${pkgs.util-linux}/bin/flock -F -x /run/foxden-sriov.lock '${allocSriovScript}' '${root}'"
    ];
    serviceInterface = "";
    stop = [
    ];
  });
}
