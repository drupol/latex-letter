{
  description = "Pandoc letters";

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

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    pandoc-letter,
    pandoc-scrlttr2,
    ...
  } @ inputs: let
    overlay = nixpkgs: final: prev: {
      pandoc-letter-template = final.stdenvNoCC.mkDerivation {
        name = "pandoc-letter-template";
        src = pandoc-letter;
        dontBuild = true;

        installPhase = ''
          runHook preInstall

          mkdir -p $out/share/pandoc/templates/
          cp $src/template-letter.tex $out/share/pandoc/templates/letter.tex

          runHook postInstall
        '';
      };

      pandoc-letter-scrlttr2-template = final.stdenvNoCC.mkDerivation {
        name = "pandoc-letter-scrlttr2-template";
        src = pandoc-scrlttr2;
        dontBuild = true;

        installPhase = ''
          runHook preInstall

          mkdir -p $out/share/pandoc/templates/
          cp $src/scrlttr2.latex $out/share/pandoc/templates/scrlttr2.tex

          runHook postInstall
        '';
      };
    };
  in
    {
      overlays.default = overlay nixpkgs;

      # nix flake new --template templates#default ./my-new-document
      templates.default = {
        path = ./template;
        description = "A template for creating beautiful letters with Pandoc.";
      };
    }
    // flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs {
        overlays = [
          self.overlays.default
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
          ${pkgs.pandoc}/bin/pandoc --data-dir=${pandoc-templates}/share/pandoc/ "$@"
        '';
        runtimeInputs = [tex];
      };

      letter = pkgs.stdenvNoCC.mkDerivation {
        name = "latex-letter";

        src = pkgs.lib.cleanSource ./.;

        buildInputs = [
          tex
          pandoc
          pkgs.gnumake
        ];

        buildPhase = ''
          make -C template build-letter
        '';

        installPhase = ''
          runHook preInstall

          install -m644 -D template/*.pdf --target $out/

          runHook postInstall
        '';
      };

      letter-scrlttr2 = pkgs.stdenvNoCC.mkDerivation {
        name = "latex-letter-scrlttr2";

        src = pkgs.lib.cleanSource ./.;

        buildInputs = [
          tex
          pandoc
          pkgs.gnumake
        ];

        buildPhase = ''
          make -C template build-letter-scrlttr2
        '';

        installPhase = ''
          runHook preInstall

          install -m644 -D template/*.pdf --target $out/

          runHook postInstall
        '';
      };
    in {
      formatter = pkgs.alejandra;

      apps = {
        pandoc = flake-utils.lib.mkApp {
          drv = pandoc;
        };
        letter = flake-utils.lib.mkApp {
          drv = pkgs.writeShellApplication {
            name = "pandoc-letter-app";
            text = ''
              ${pandoc}/bin/pandoc -s --template=letter.tex "$@"
            '';
            runtimeInputs = [tex];
          };
        };
        letter-scrlttr2 = flake-utils.lib.mkApp {
          drv = pkgs.writeShellApplication {
            name = "pandoc-letter-scrlttr2-app";
            text = ''
              ${pandoc}/bin/pandoc -s --template=scrlttr2.tex "$@"
            '';
            runtimeInputs = [tex];
          };
        };
      };

      packages = {
        letter = letter;
        letter-scrlttr2 = letter-scrlttr2;
      };

      # Nix develop
      devShells.default = pkgs.mkShellNoCC {
        name = "latex-letter-devShell";
        buildInputs = [
          tex
          pandoc
          pkgs.nodePackages.prettier
          pkgs.nixpkgs-fmt
          pkgs.nixfmt
        ];
      };

      checks = {
        letter = letter;
        letter-scrlttr2 = letter-scrlttr2;
        pandoc = pandoc;
      };
    });
}
