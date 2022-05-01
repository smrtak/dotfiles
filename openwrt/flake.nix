{
  description = "A free and open source 3D creation suite (upstream binaries)";
  inputs.nixpkgs.url = "nixpkgs/nixos-unstable";
  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = {
    self,
    nixpkgs,
    flake-utils,
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = nixpkgs.legacyPackages.${system};
      uci = pkgs.callPackage ./nix {};
    in {
      packages = {
        inherit (uci) nix-uci writeUci;
      };
      apps.example = {
        type = "app";
        program = toString (self.packages.${system}.writeUci ./example.nix).command;
      };
      defaultPackage = self.packages.${system}.nix-uci;
    });
}
