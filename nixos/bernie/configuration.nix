 # Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, lib, ... }:
{
  imports = [
    ../modules/packages.nix
    ../modules/users.nix
    ../modules/zfs.nix
    ./hardware-configuration.nix
  ];
  networking.retiolum = {
    ipv4 = "10.243.29.169";
    ipv6 = "42:0:3c46:96e2:72f4:be89:d6eb:ab14";
  };

  boot.loader.systemd-boot.enable = true;

  users.extraUsers.shannan = {
    isNormalUser = true;
    home = "/home/shannan";
    extraGroups = [ "wheel" "plugdev" "adbusers" "input" "kvm" ];
    shell = "/run/current-system/sw/bin/zsh";
    uid = 1001;
  };
  networking.hostName = "bernie";
  networking.hostId = "ac174b52";

  networking.networkmanager.enable = true;
  networking.networkmanager.wifi.backend = "iwd";

  time.timeZone = null;
  i18n.defaultLocale = "en_DK.UTF-8";

  powerManagement.powertop.enable = true;
  programs.vim.defaultEditor = true;

  services.xserver = {
    enable = true;
    libinput.enable = true;
    displayManager.gdm.enable = true;
    desktopManager.gnome3.enable = true;
  };

  environment.systemPackages = with pkgs; [
    pkgs.firefox
    pkgs.celluloid
    pkgs.mpv
    pkgs.youtube-dl
    pkgs.calibre
    pkgs.libreoffice
    pkgs.gnome3.evolution
  ];

  documentation.doc.enable = false;

  services.openssh.enable = true;
  services.printing = {
    enable = true;
    browsing = true;
  };
}
