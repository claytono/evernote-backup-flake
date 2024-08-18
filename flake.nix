{
  description = "Flake for evernote-backup CLI tool";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    poetry2nix = {
      url = "github:nix-community/poetry2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    evernote-backup-src = {
      url = "github:vzhd1701/evernote-backup?ref=refs/tags/v1.9.3";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, flake-utils, poetry2nix, evernote-backup-src }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        p2nix = poetry2nix.lib.mkPoetry2Nix { inherit pkgs; };
      in
      {
        packages.default = p2nix.mkPoetryApplication {
          projectDir = evernote-backup-src;
          preferWheels = true;
          overrides = p2nix.defaultPoetryOverrides.extend
            (self: super: {
              evernote3 = super.evernote3.overridePythonAttrs (old: {
                buildInputs = (old.buildInputs or [ ]) ++ [ super.setuptools ];
              });
            });
        };

        apps.default = flake-utils.lib.mkApp {
          drv = self.packages.${system}.default;
        };

        devShells.default = pkgs.mkShell {
          inputsFrom = [ self.packages.${system}.default ];
          packages = with pkgs; [
            poetry
          ];
        };
      });
}
