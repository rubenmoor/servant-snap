{ pkgs ? import <nixpkgs> {},
  compilerVersion ? "ghc810"
}:

pkgs.haskell.packages."${compilerVersion}".developPackage {
  name = "servant-snap";
  root = pkgs.lib.cleanSourceWith
    {
      src = ./.;
      filter = path: type:
        !(baseNameOf (toString path) == "dist-newstyle");

    };
}
