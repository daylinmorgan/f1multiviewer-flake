{
  description = "f1multiviewer";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs =
    { self, nixpkgs }:
    let
      inherit (nixpkgs.lib) genAttrs;
      # supportedSystems = ["x86_64-linux" "x86_64-darwin" "aarch64-linux" "aarch64-darwin"];
      supportedSystems = [ "x86_64-linux" ];
      forAllSystems = f: genAttrs supportedSystems (system: f nixpkgs.legacyPackages.${system});
    in
    {
      packages = forAllSystems (pkgs: {
        f1multiviewer = pkgs.callPackage ./default.nix { };
        default = self.packages.${pkgs.system}.f1multiviewer;
      });
      formatter = forAllSystems (pkgs: pkgs.nixfmt-rfc-style);
    };
}
