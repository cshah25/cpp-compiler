{
  description = "Development environment for compiler engineering";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
      in
      {
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            nasm
            binutils
            gcc
            gnumake
            gdb
            valgrind
            strace
          ];

          env = {
            CPATH = "${pkgs.glibc.dev}/include";
          };

          shellHook = ''
            echo "🛠️  Compiler Development Environment Loaded!"
            echo "----------------------------------------"
            echo "• NASM:   $(nasm -v)"
            echo "• Linker: $(ld -v)"
            echo "• GCC:    $(gcc --version | head -n 1)"
            echo "----------------------------------------"
          '';
        };
      });
}

