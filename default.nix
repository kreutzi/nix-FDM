# default.nix
with import <nixpkgs> { };
{
  freedownloadmanager = pkgs.callPackage ./freedownloadmanager.nix { };
}
