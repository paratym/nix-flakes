{
  description = "Development environment for Rust graphics development";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    wgsl-analyzer = {
      url = "github:wgsl-analyzer/wgsl-analyzer";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = { self, fenix, nixpkgs, wgsl-analyzer, ... }: let
    system = "x86_64-linux";
    pkgs = import nixpkgs { inherit system; };
    fenix-package = fenix.packages.${system};
    stable = fenix.packages.${system}.stable;
    nightly = fenix.packages.${system}.complete;
    rust-analyzer-nightly = fenix.packages.${system}.rust-analyzer;
    wasm-stable = fenix-package.targets.wasm32-unknown-unknown.stable;
    wasm-nightly = fenix-package.targets.wasm32-unknown-unknown.latest;
  in {
    devShells.${system}.default = with pkgs; mkShell rec {
      packages = [
        pkg-config

        # Rust
        (fenix-package.combine [
          nightly.cargo
          nightly.rustc
          nightly.rust-src

          nightly.rust-std
          wasm-nightly.rust-std

          stable.rustfmt
          stable.clippy
        ])
        rust-analyzer-nightly
        cargo-watch

        gdb
        clang
        mold

        # Vulkan
        vulkan-tools

        trunk
        cargo-lambda
        wasm-pack
      ];

      inputsFrom = [
        # Wayland libraries
        wayland

        # X11 libraries
        xorg.libX11
        xorg.libXcursor
        xorg.libXi
        libxkbcommon

        # Vulkan libraries
        shaderc
        spirv-tools
        vulkan-loader
        vulkan-validation-layers
      ];
      buildInputs = [
        # Audio
        alsa-lib
        udev

        # File chooser
        pango
        atkmm
        gdk-pixbuf
        rubyPackages.gdk3
        gtk3
        glib

        openssl
        openssl.dev
      ];
      shellHook = ''
        export LD_LIBRARY_PATH=${lib.makeLibraryPath (inputsFrom ++ buildInputs)};
        export SHADERC_LIB_DIR=${lib.makeLibraryPath [ shaderc ]};
        export VK_LAYER_PATH="${vulkan-validation-layers}/share/vulkan/explicit_layer.d";
        export RUSTFLAGS="-C link-arg=-fuse-ld=${mold}/bin/mold";
        export XDG_DATA_DIRS=XDG_DATA_DIRS:$GSETTINGS_SCHEMAS_PATH;

        WINDOWNAME="Voxei"

        if command -v hyprctl > /dev/null 2>&1; then
          hyprctl keyword windowrulev2 unset,title:$WINDOWNAME
          hyprctl keyword windowrulev2 float,title:$WINDOWNAME
          hyprctl keyword windowrulev2 opacity 0.4,title:$WINDOWNAME
          hyprctl keyword windowrulev2 noinitialfocus,title:$WINDOWNAME
          hyprctl keyword windowrulev2 monitor DP-3,title:$WINDOWNAME
          hyprctl keyword windowrulev2 size 35% 35%,title:$WINDOWNAME
          hyprctl keyword windowrulev2 move onscreen 100% 100%,title:$WINDOWNAME
        fi
      '';
    };
  };
}
