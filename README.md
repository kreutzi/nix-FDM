# Free Download Manager for NixOS

This repository provides Free Download Manager as a flake package. The package
is unfree and currently supports `x86_64-linux`.

## Install with a temporary flake

Run this from any directory:

```bash
nix profile install github:kreutzi/nix-FDM
```

This installs the package from this repository's `main` branch and records the
flake revision in the profile. Future package updates can be installed with:

```bash
nix profile upgrade '.*'
```

## Use from a NixOS flake

Add this repository to your system flake inputs:

```nix
{
  inputs.nix-fdm.url = "github:kreutzi/nix-FDM";

  outputs = { self, nixpkgs, nix-fdm, ... }:
    {
      nixosConfigurations.my-host = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ({ pkgs, ... }: {
            environment.systemPackages = [
              nix-fdm.packages.${pkgs.system}.default
            ];
          })
        ];
      };
    };
}
```

Update the pinned package revision and rebuild when you want to receive an
automated update merged into this repository:

```bash
nix flake lock --update-input nix-fdm
sudo nixos-rebuild switch --flake .#my-host
```

The GitHub Actions workflow checks for new FDM releases, updates the package
version and hash, builds it, and opens an auto-merge pull request. Flake locks
keep deployed systems reproducible until you explicitly update them.

## Fix Autostart

```bash
sed -i 's|^Exec=.*|Exec=freedownloadmanager --hidden|' ~/.config/autostart/FDM.desktop
```
