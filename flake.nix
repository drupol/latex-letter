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

  outputs = inputs @ {flake-parts, ...}:
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = inputs.nixpkgs.lib.systems.flakeExposed;

      flake = let
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
      in {
        overlays.default = overlay inputs.nixpkgs;

        # nix flake new --template templates#default ./my-new-document
        templates.default = {
          path = ./template;
          description = "A template for creating beautiful letters with Pandoc.";
        };
      };

      perSystem = {
        config,
        self',
        inputs',
        pkgs,
        system,
        ...
      }: let
        pkgs = import inputs.nixpkgs {
          overlays = [
            inputs.self.overlays.default
          ];
          inherit system;
        };

        tex = pkgs.texlive.combine {
          inherit (pkgs.texlive)
            scheme-full
            latex-bin
            latexmk
            lettrine
            ;
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
            ${pkgs.pandoc}/bin/pandoc \
              --data-dir=${pandoc-templates}/share/pandoc/ \
              "$@"
          '';
          runtimeInputs = [tex];
        };

        pandoc-letter-app = pkgs.writeShellApplication {
          name = "pandoc-letter-app";
          text = ''
            ${pkgs.pandoc}/bin/pandoc \
              --to=latex \
              --standalone \
              --template=${pandoc-templates}/share/pandoc/templates/letter.tex \
              "$@"
          '';
          runtimeInputs = [tex];
        };

        letter = pkgs.stdenvNoCC.mkDerivation {
          name = "latex-letter";

          src = pkgs.lib.cleanSource ./.;

          TEXINPUTS="${./.}//:";

          buildPhase = ''
            runHook preBuild

            ${pandoc-letter-app}/bin/pandoc-letter-app \
              --output=letter.pdf \
              --from=markdown \
              $src/template/src/letter/*.md

            runHook postBuild
          '';

          installPhase = ''
            runHook preInstall

            install -m644 -D *.pdf --target $out/

            runHook postInstall
          '';
        };

        pandoc-letter-scrlttr2-app = pkgs.writeShellApplication {
          name = "pandoc-letter-scrlttr2-app";
          text = ''
            ${pkgs.pandoc}/bin/pandoc \
              --to=latex \
              --standalone \
              --template=${pandoc-templates}/share/pandoc/templates/scrlttr2.tex \
              "$@"
          '';
          runtimeInputs = [tex];
        };

        letter-scrlttr2 = pkgs.stdenvNoCC.mkDerivation {
          name = "latex-letter-scrlttr2";

          src = pkgs.lib.cleanSource ./.;

          TEXINPUTS="${./.}//:";

          buildPhase = ''
            runHook preBuild

            ${pandoc-letter-scrlttr2-app}/bin/pandoc-letter-scrlttr2-app \
              --from=markdown \
              --output=letter.pdf \
              $src/template/src/letter-scrlttr2/*.md

            runHook postBuild
          '';

          installPhase = ''
            runHook preInstall

            install -m644 -D *.pdf --target $out/

            runHook postInstall
          '';
        };

        watch-letter-app = pkgs.writeShellApplication {
          name = "watch-letter-app";
          text = ''
            export TEXINPUTS="${./.}//:"

            echo "Now watching for changes and building it..."

            while true; do \
              ${pandoc-letter-app}/bin/pandoc-letter-app "$@"
              ${pkgs.inotify-tools}/bin/inotifywait --exclude '\.pdf|\.git' -qre close_write .; \
            done
          '';
        };

        watch-letter-scrlttr2-app = pkgs.writeShellApplication {
          name = "watch-letter-scrlttr2-app";
          text = ''
            export TEXINPUTS="${./.}//:"

            echo "Now watching for changes and building it..."

            while true; do \
              ${pandoc-letter-scrlttr2-app}/bin/pandoc-letter-scrlttr2-app "$@"
              ${pkgs.inotify-tools}/bin/inotifywait --exclude '\.pdf|\.git' -qre close_write .; \
            done
          '';
        };
      in {
        formatter = pkgs.alejandra;

        apps = {
          pandoc = {
            type = "app";
            program = pandoc;
          };
          letter = {
            type = "app";
            program = pandoc-letter-app;
          };
          letter-scrlttr2 = {
            type = "app";
            program = pandoc-letter-scrlttr2-app;
          };
          watch-letter = {
            type = "app";
            program = watch-letter-app;
          };
          watch-letter-scrlttr2 = {
            type = "app";
            program = watch-letter-scrlttr2-app;
          };
        };

        packages = {
          inherit letter letter-scrlttr2 pandoc-templates;
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
      };
    };
}
