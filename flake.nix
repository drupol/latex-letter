{
  description = "LaTeX Letter";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    nix-filter.url = github:numtide/nix-filter;
    aaronwolen-pandoc-letter = {
      url = "github:aaronwolen/pandoc-letter";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, flake-utils, nix-filter, aaronwolen-pandoc-letter, ... }@inputs:
    let
      overlay = nixpkgs: final: prev: {
        pandoc-letter-template = final.stdenvNoCC.mkDerivation {
          name = "pandoc-letter-template";

          src = final.fetchFromGitHub {
            owner = "aaronwolen";
            repo = "pandoc-letter";
            rev = "b0fd7342b352ebb87aea17614ec014f68d48747f";
            sha256 = "6GTTncMvoMjEXdqzdtc/LYsZOzBMcrh2vlQBWpLeyKA=";
          };

          dontBuild = true;

          installPhase = ''
            runHook preInstall

            install -m644 -D $src/template-letter.tex --target $out/share/pandoc/templates/

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
        description = "A template for creating letter document from Markdown.";
      };
    } //
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          overlays = [
            self.overlays.default
          ];
          inherit system;
        };

        pandoc = pkgs.writeShellScriptBin "pandoc" ''
          ${pkgs.pandoc}/bin/pandoc --data-dir ${pkgs.pandoc-letter-template}/share/pandoc/ $@
        '';

        tex = pkgs.texlive.combine {
          inherit (pkgs.texlive) scheme-full latex-bin latexmk;
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

            install -m644 -D template/letter.pdf --target $out/

            runHook postInstall
          '';
        };
      in
      {
        # Nix shell / nix build
        packages.default = pkgs.pandoc-letter-template;
        packages.letter = letter;

        # Nix develop
        devShells.default = pkgs.mkShellNoCC {
          name = "latex-letter-devShell";
          buildInputs = [
            tex
            pandoc
            pkgs.nixpkgs-fmt
            pkgs.nixfmt
          ];
        };

        checks.default = letter;
      });
}
