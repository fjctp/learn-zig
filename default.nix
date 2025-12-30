{ pkgs ? import <nixpkgs> { config = { allowUnfree = true; }; } }:
pkgs.mkShell {
  name = "zig";
  nativeBuildInputs = with pkgs; [
    zig
  ];
}
