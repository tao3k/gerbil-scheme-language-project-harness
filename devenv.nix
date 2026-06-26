{
  pkgs,
  lib,
  ...
}:

{
  packages = [
    pkgs.pkg-config
    pkgs.openssl
  ];

  env.PKG_CONFIG_PATH = lib.makeSearchPath "lib/pkgconfig" [
    pkgs.openssl.dev
  ];
}
