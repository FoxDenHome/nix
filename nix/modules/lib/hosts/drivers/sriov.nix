{ nixpkgs, ... } :
let
  eSA = nixpkgs.lib.strings.escapeShellArg;
in
{
  driverOptsType = with nixpkgs.lib.types; submodule {
    vlan = nixpkgs.lib.mkOption {
      type = ints.unsigned;
    };
    bridge = nixpkgs.lib.mkOption {
      type = str;
    };
  };

  build = { ... } : {
    config.systemd = {};
  };

  hooks = ({ pkgs, ipCmd, serviceInterface, interface, ... }: let
    bridge = interface.driverOpts.bridge;

    allocSriovScript = pkgs.writeShellScript "allocate-sriov" ''
      set -euox pipefail
      interface="$1"
      numvfs_file="/sys/class/net/${bridge}/device/sriov_numvfs"
      totalvfs="$(cat /sys/class/net/${bridge}/device/sriov_totalvfs)"

      assign_vf() {
        idx="$1"
        # Enable spoof checking, set MAC and VLAN
        ${ipCmd} link set dev "${bridge}" vf "$idx" spoofchk on mac "${interface.mac}" vlan "${builtins.toString interface.driverOpts.vlan}"
        # Find current name of VF interface
        ifname="$(${pkgs.coreutils}/bin/ls /sys/class/net/${bridge}/device/virtfn$idx/net/)"
        # And rename it
        ${ipCmd} link set dev "$ifname" name "${serviceInterface}"
      }

      # Condition A: We find a VIF with our MAC address
      matched_vf="$(${ipCmd} link show dev "${bridge}" | ${pkgs.gnugrep}/bin/grep -oi "vf .* link/ether ${interface.mac} " | ${pkgs.coreutils}/bin/cut -d' ' -f2)"
      if [ -n "$matched_vf" ]; then
        assign_vf "$matched_vf"
        exit 0
      fi

      # Condition B: numvfs < totalvfs, we can allocate a new one
      current_vfs="$(cat "$numvfs_file")"
      if [ "$current_vfs" -lt "$totalvfs" ]; then
        echo $((current_vfs + 1)) > "$numvfs_file"
        assign_vf "$current_vfs"
        exit 0
      fi

      # TODO: Condition C: No free VFs, go hunting for unused ones
      exit 1
    '';
  in
  {
    start = [
      "${pkgs.util-linux}/bin/flock -x /run/foxden-sriov.lock '${allocSriovScript}' '${bridge}'"
    ];
    serviceInterface = "";
    stop = [
    ];
  });
}
