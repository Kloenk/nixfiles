{ lib, stdenv, mkShell, rustc, cargo, rust-analyzer, nixfmt, rustfmt, pkg-config
, udev, libiconv, darwin }:
mkShell {
  nativeBuildInputs = [ rustc cargo rust-analyzer nixfmt rustfmt ]
    ++ lib.optional stdenv.isLinux [ pkg-config ];
  buildInputs = (lib.optionals stdenv.isDarwin [
    libiconv
    darwin.apple_sdk.frameworks.IOKit
    darwin.apple_sdk.frameworks.CoreBluetooth
    darwin.apple_sdk.frameworks.AppKit
  ]) ++ lib.optional stdenv.isLinux udev;
}
