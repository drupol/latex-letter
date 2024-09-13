{
  description = "Pandoc and LaTeX letters";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    pandoc-letter = {
      url = "github:aaronwolen/pandoc-letter";
      flake = false;
    };
    pandoc-scrlttr2 = {
      url = "github:drupol/pandoc-scrlttr2";
      flake = false;
    };
  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = inputs.nixpkgs.lib.systems.flakeExposed;

      flake =
        let
          overlay =
            nixpkgs: final: prev:
            let

              pandoc-letter-template = final.stdenvNoCC.mkDerivation {
                name = "pandoc-letter-template";
                src = inputs.pandoc-letter;
                dontBuild = true;

                installPhase = ''
                  runHook preInstall

                  install -m644 -D $src/template-letter.tex $out/share/pandoc/templates/letter.tex

                  runHook postInstall
                '';
              };

              pandoc-letter-scrlttr2-template = final.stdenvNoCC.mkDerivation {
                name = "pandoc-letter-scrlttr2-template";
                src = inputs.pandoc-scrlttr2;
                dontBuild = true;

                installPhase = ''
                  runHook preInstall

                  install -m644 -D $src/scrlttr2.latex $out/share/pandoc/templates/scrlttr2.tex

                  runHook postInstall
                '';
              };

              pandoc-letter-templates = final.pkgs.symlinkJoin {
                name = "pandoc-templates";

                paths = [
                  pandoc-letter-scrlttr2-template
                  pandoc-letter-template
                ];
              };

            in
            {
              inherit pandoc-letter-templates;
            };
        in
        {
          overlays.default = overlay inputs.nixpkgs;

          # nix flake new --template templates#default ./my-new-document
          templates.default = {
            path = ./template;
            description = "A template for creating beautiful letters with Pandoc.";
          };
        };
    };
}
