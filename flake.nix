{
  description = "Display switch via USB switch";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    crane = {
      url = "github:ipetkov/crane";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };
  };
  outputs = {
    self,
    nixpkgs,
    crane,
    flake-utils,
    rust-overlay,
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      overlays = [(import rust-overlay)];
      pkgs = import nixpkgs {
        inherit system overlays;
      };

      rustToolchain = pkgs.pkgsBuildHost.rust-bin.fromRustupToolchainFile ./rust-toolchain;
      craneLib = (crane.mkLib pkgs).overrideToolchain rustToolchain;

      nativeBuildInputs = with pkgs; lib.optionals stdenv.isLinux [pkg-config];
      buildInputs = with pkgs; lib.optionals stdenv.isLinux [udev xorg.libXi];
    in {
      defaultPackage = craneLib.buildPackage {
        inherit nativeBuildInputs buildInputs;
        src = craneLib.cleanCargoSource (craneLib.path ./.);
        # Certain tests fail in pure evaluation.
        doCheck = false;
      };

      devShell = pkgs.mkShell {
        inherit buildInputs nativeBuildInputs;

        LD_LIBRARY_PATH = nixpkgs.lib.makeLibraryPath buildInputs;
      };
    });
}
