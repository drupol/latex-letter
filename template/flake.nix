{
  description = "Letter document";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    systems.url = "github:nix-systems/default";
    latex-letter.url = "github:drupol/latex-letter";
  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = import inputs.systems;

      imports = [
        ./nix/imports/pkgs.nix
        ./nix/imports/overlay.nix
      ];

      perSystem =
        { pkgs, ... }:
        let
          tex = pkgs.texlive.combine {
            inherit (pkgs.texlive) scheme-full latex-bin latexmk;
          };
        in
        {
          packages = {
            letter = pkgs.stdenvNoCC.mkDerivation {
              name = "pandoc-letter";

              src = pkgs.lib.cleanSource ./.;

              nativeBuildInputs = [ tex ];

              TEXINPUTS = "$src/src//:";

              buildPhase = ''
                 runHook preBuild

                ${pkgs.pandoc}/bin/pandoc \
                   --standalone \
                   --template=${pkgs.pandoc-letter-templates}/share/pandoc/templates/letter.tex \
                   -o letter.pdf \
                   $src/src/letter/*.md

                 runHook postBuild
              '';

              installPhase = ''
                runHook preInstall

                install -m644 -D letter.pdf --target $out/

                runHook postInstall
              '';
            };

            letter-scrlttr2 = pkgs.stdenvNoCC.mkDerivation {
              name = "pandoc-letter-scrlttr2";

              src = pkgs.lib.cleanSource ./.;

              nativeBuildInputs = [ tex ];

              TEXINPUTS = "$src/src//:";

              buildPhase = ''
                 runHook preBuild

                ${pkgs.pandoc}/bin/pandoc \
                   --standalone \
                   --template=${pkgs.pandoc-letter-templates}/share/pandoc/templates/scrlttr2.tex \
                   -o letter.pdf \
                   $src/src/letter-scrlttr2/*.md

                 runHook postBuild
              '';

              installPhase = ''
                runHook preInstall

                install -m644 -D letter.pdf --target $out/

                runHook postInstall
              '';
            };
          };
        };
    };
}
