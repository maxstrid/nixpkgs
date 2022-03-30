{ haskellPackages, fetchpatch, haskell, removeReferencesTo }:

let
  static = haskell.lib.compose.justStaticExecutables haskellPackages.pandoc;

in
  (haskell.lib.compose.overrideCabal (drv: {
    configureFlags = drv.configureFlags or [] ++ ["-fembed_data_files"];
    buildDepends = drv.buildDepends or [] ++ [haskellPackages.file-embed];
    buildTools = (drv.buildTools or []) ++ [ removeReferencesTo ];

    postInstall = drv.postInstall or "" + ''
      remove-references-to \
        -t ${haskellPackages.pandoc-types} \
        $out/bin/pandoc
      remove-references-to \
        -t ${haskellPackages.HTTP} \
        $out/bin/pandoc
    '';
  }) static).overrideAttrs (drv: {
    # These libraries are still referenced, because they generate
    # a `Paths_*` module for figuring out their version.
    # The `Paths_*` module is generated by Cabal, and contains the
    # version, but also paths to e.g. the data directories, which
    # lead to a transitive runtime dependency on the whole GHC distribution.
    # This should ideally be fixed in haskellPackages (or even Cabal),
    # but a minimal pandoc is important enough to patch it manually.
    disallowedReferences = [ haskellPackages.pandoc-types haskellPackages.HTTP ];
  })
