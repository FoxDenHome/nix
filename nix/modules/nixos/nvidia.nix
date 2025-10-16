{ lib, config, ... } :
{
  options.foxDen.nvidia.enable = lib.mkEnableOption "Enable NVIDIA support via the proprietary drivers";

  config = lib.mkIf config.foxDen.nvidia.enable {
    services.xserver.videoDrivers = [ "nvidia" ];
    hardware.nvidia.package = config.boot.kernelPackages.nvidiaPackages.mkDriver {
      version = "580.65.06";
      sha256_64bit = "sha256-BLEIZ69YXnZc+/3POe1fS9ESN1vrqwFy6qGHxqpQJP8=";
      openSha256 = "sha256-BKe6LQ1ZSrHUOSoV6UCksUE0+TIa0WcCHZv4lagfIgA=";
      settingsSha256 = "sha256-9PWmj9qG/Ms8Ol5vLQD3Dlhuw4iaFtVHNC0hSyMCU24=";
      usePersistenced = false;
    }; # TODO: Remove on 25.11/unstable
    hardware.nvidia.open = true;
    hardware.graphics.enable = true;

    foxDen.services.gpuDevices = [
      "/dev/nvidiactl"
      "/dev/nvidia-uvm"
      "/dev/nvidia-uvm-tools"
      "/dev/nvidia0"
    ];
  };
}
