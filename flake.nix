{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    dory = {
      url = "path:./dory";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, home-manager, dory }:
    let
      username = "athena";
      theme = "temple";
      desktop = "gnome";
      dmanager = "sddm";
      mainShell = "fish";
      terminal = "kitty";
      browser = "firefox";
      bootloader = "systemd";
      dory-pkg = pkgs: pkgs.rustPlatform.buildRustPackage {
        pname = "dory";
        version = "0.1.0";
        src = dory;
        cargoHash = "sha256-YIQdDnKSfK42uORIQweuALNmdeVL7mRz1iF11Rb1foA=";
        nativeBuildInputs = [ pkgs.pkg-config ];
        buildInputs = [ pkgs.tpm2-tss ];
      };
      mkSystem = extraModules:
      nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ({ lib, pkgs, config, ...}: let
            hostname = "athenaos";
            hashed = "$6$zjvJDfGSC93t8SIW$AHhNB.vDDPMoiZEG3Mv6UYvgUY6eya2UY5E2XA1lF7mOg6nHXUaaBmJYAMMQhvQcA54HJSLdkJ/zdy8UKX3xL1";
            hashedRoot = "$6$zjvJDfGSC93t8SIW$AHhNB.vDDPMoiZEG3Mv6UYvgUY6eya2UY5E2XA1lF7mOg6nHXUaaBmJYAMMQhvQcA54HJSLdkJ/zdy8UKX3xL1";
          in {
            networking.hostName = "${hostname}";
            users = lib.mkIf (config.athena.enable or false) {
              mutableUsers = false;
              extraUsers.root.hashedPassword = "${hashedRoot}";
              users.${config.athena.homeManagerUser} = {
                shell = pkgs.${config.athena.mainShell};
                isNormalUser = true;
                hashedPassword = "${hashed}";
                extraGroups = [ "wheel" "input" "video" "render" "networkmanager" ];
              };
            };
          })
        ] ++ extraModules;
      };
    in {
      nixosConfigurations = {
        "live-image" = mkSystem [
          ./nixos/installation/iso.nix
          home-manager.nixosModules.home-manager
          ./nixos
          ({ lib, pkgs, ... }: {
            athena = {
              enable = true;
              baseHosts = true;
              baseLocale = true;
              homeManagerUser = "athena";
              desktopManager = lib.mkForce "none";
              displayManager = lib.mkForce null;
              terminal = "alacritty";
              theme = "temple";
            };

            services.xserver.enable = lib.mkForce false;
            services.displayManager.enable = lib.mkForce false;
            services.displayManager.autoLogin.enable = lib.mkForce false;

            environment.systemPackages = [ (dory-pkg pkgs) ];
          })
        ];

        "runtime" = mkSystem [
          "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
          home-manager.nixosModules.home-manager
          ./nixos
          {
            athena = {
              inherit bootloader terminal theme mainShell browser;
              enable = true;
              baseConfiguration = true;
              baseSoftware = true;
              baseLocale = true;
              homeManagerUser = username;
              desktopManager = desktop;
              displayManager = dmanager;
            };
          }
        ];

        "student" = mkSystem [
          "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
          ./nixos/modules/cyber/roles/student.nix
          ({ pkgs, ... }: {
            environment.systemPackages = [ (dory-pkg pkgs) ];
          })
        ];
      };

      packages."x86_64-linux" = (builtins.mapAttrs (n: v: v.config.system.build.isoImage) self.nixosConfigurations) // {
        default = self.packages."x86_64-linux"."live-image";
      };

      nixosModules = rec {
        athena = ./nixos;
        default = athena;
      };
    };
}
