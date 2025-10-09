{
  pkgs,
  lib,
  qtcreator,
  ...
}:
f:
let
  # Specifing path for each plugin cause Qt Creator will not search for them even if we create combined package with symlinks (hardcoded default search path)
  plugins_arg = builtins.foldl' (
    acc: val: acc + "-pluginpath ${val.outPath}/lib/qtcreator/plugins/"
  ) "" f;
  qtcreator_runner = pkgs.writeShellScriptBin "qtcreator" ''
    exec ${lib.getExe qtcreator} ${plugins_arg} "$@"
  '';
in
pkgs.symlinkJoin {
  inherit (qtcreator) version meta;
  name = "qtcreator-with-plugins";
  paths = [
    qtcreator_runner
    qtcreator
  ];
}
