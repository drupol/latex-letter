{
  description = "Pandoc and LaTeX letters";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    pandoc-letter = {
      url = "github:aaronwolen/pandoc-letter";
      flake = false;
    };
    pandoc-scrlttr2 = {
      url = "github:drupol/pandoc-scrlttr2";
      flake = false;
    };
  };

  outputs = inputs: let
    overlay = nixpkgs: final: prev: {
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
    };
  in
    {
      overlays.default = overlay inputs.nixpkgs;

      # nix flake new --template templates#default ./my-new-document
      templates.default = {
        path = ./template;
        description = "A template for creating beautiful letters with Pandoc.";
      };
    }
    // inputs.flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import inputs.nixpkgs {
        overlays = [
          inputs.self.overlays.default
        ];
        inherit system;
      };

      tex = pkgs.texlive.combine {
        inherit (pkgs.texlive) scheme-full latex-bin latexmk;
      };

      pandoc-templates = pkgs.symlinkJoin {
        name = "pandoc-templates";

        paths = [
          pkgs.pandoc-letter-scrlttr2-template
          pkgs.pandoc-letter-template
        ];
      };

      pandoc = pkgs.writeShellApplication {
        name = "pandoc";
        text = ''
          ${pkgs.pandoc} \
            --data-dir=${pandoc-templates}/share/pandoc/ \
            "$@"
        '';
        runtimeInputs = [tex];
      };

      letter = pkgs.stdenvNoCC.mkDerivation {
        name = "latex-letter";

        src = pkgs.lib.cleanSource ./.;

        buildInputs = [ tex ];

        TEXINPUTS = "$src/template/src//:";

        buildPhase = ''
          runHook preBuild

        	${pkgs.pandoc}/bin/pandoc \
            --standalone \
            --template=${pandoc-templates}/share/pandoc/templates/letter.tex \
            -o letter.pdf \
            $src/template/src/letter/*.md

          runHook postBuild
        '';

        installPhase = ''
          runHook preInstall

          install -m644 -D *.pdf --target $out/

          runHook postInstall
        '';
      };

      letter-scrlttr2 = pkgs.stdenvNoCC.mkDerivation {
        name = "latex-letter-scrlttr2";

        src = pkgs.lib.cleanSource ./.;

        TEXINPUTS = "$src/template/src//:";

        buildInputs = [ tex ];

        buildPhase = ''
          runHook preBuild

        	${pkgs.pandoc}/bin/pandoc \
            --standalone \
            --template=${pandoc-templates}/share/pandoc/templates/scrlttr2.tex \
            -o letter.pdf \
            $src/template/src/letter-scrlttr2/*.md

          runHook postBuild
        '';

        installPhase = ''
          runHook preInstall

          install -m644 -D *.pdf --target $out/

          runHook postInstall
        '';
      };
    in {
      formatter = pkgs.alejandra;

      apps = {
        pandoc = inputs.flake-utils.lib.mkApp {
          drv = pandoc;
        };
        letter = inputs.flake-utils.lib.mkApp {
          drv = pkgs.writeShellApplication {
            name = "pandoc-letter-app";
            text = ''
              ${pkgs.pandoc}/bin/pandoc \
                --standalone \
                --template=${pandoc-templates}/share/pandoc/templates/letter.tex \
                "$@"
            '';
            runtimeInputs = [tex];
          };
        };
        letter-scrlttr2 = inputs.flake-utils.lib.mkApp {
          drv = pkgs.writeShellApplication {
            name = "pandoc-letter-scrlttr2-app";
            text = ''
              ${pkgs.pandoc}/bin/pandoc \
                --standalone \
                --template=${pandoc-templates}/share/pandoc/templates/scrlttr2.tex \
                "$@"
            '';
            runtimeInputs = [tex];
          };
        };
      };

      packages = {
        letter = letter;
        letter-scrlttr2 = letter-scrlttr2;
        pandoc-templates = pandoc-templates;
      };

      # Nix develop
      devShells.default = pkgs.mkShellNoCC {
        name = "latex-letter-devShell";
        buildInputs = [
          tex
          pandoc
          pkgs.nodePackages.prettier
        ];
      };

      checks = {
        letter = letter;
        letter-scrlttr2 = letter-scrlttr2;
        pandoc-templates = pandoc-templates;
      };
    });
}
