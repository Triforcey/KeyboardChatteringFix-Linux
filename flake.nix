{
  description = "Dev shell for the KeyboardChatteringFix-Linux @Triforcey fork and its arm64 Debian packaging";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";

    # Upstream sources, referenced as a plain (non-flake) input so the
    # packaging here always tracks the original tools/scripts as-is.
    upstream = {
      url = "github:finkrer/KeyboardChatteringFix-Linux";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, upstream }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});
    in
    {
      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShell {
          packages = with pkgs; [
            python3
            libevdev # C library needed by the python-libevdev bindings
            binutils # ar: needed by ./build-deb.sh
            gnutar
            gzip
          ];

          shellHook = ''
            export LD_LIBRARY_PATH="${pkgs.libevdev}/lib''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
            if [ ! -d .venv ]; then
              echo "Creating Python venv in .venv ..."
              python3 -m venv .venv
            fi
            source .venv/bin/activate
            # Install the dependency set pinned by upstream requirements.txt
            pip install --quiet -r ${upstream}/requirements.txt
            echo "dev shell ready: python $(python --version 2>&1 | awk '{print $2}'), venv at .venv"
          '';
        };
      });
    };
}
