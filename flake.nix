{
  description = "LaTeX Letter";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    aaronwolen-pandoc-letter = {
      url = "github:aaronwolen/pandoc-letter";
      flake = false;
    };
    benedicdudel-pandoc-letter = {
      url = "https://github.com/benedictdudel/pandoc-letter-din5008";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, flake-utils, aaronwolen-pandoc-letter, benedicdudel-pandoc-letter, ... }@inputs:
    let
      overlay = nixpkgs: final: prev: {
        pandoc-letter-template = final.stdenvNoCC.mkDerivation {
          name = "pandoc-letter-template";
          src = aaronwolen-pandoc-letter;
          dontBuild = true;

          installPhase = ''
            runHook preInstall

            install -m644 -D $src/template-letter.tex --target $out/share/pandoc/templates/letter.tex

            runHook postInstall
          '';
        };

        pandoc-letter-din5008-template = final.stdenvNoCC.mkDerivation {
          name = "pandoc-letter-din5008-template";
          src = benedicdudel-pandoc-letter;
          dontBuild = true;

          installPhase = ''
            runHook preInstall

            install -m644 -D $src/letter.latex --target $out/share/pandoc/templates/letter-din5008.tex

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
    } //
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          overlays = [
            self.overlays.default
          ];
          inherit system;
        };

        tex = pkgs.texlive.combine {
          inherit (pkgs.texlive) scheme-full latex-bin latexmk;
        };

        pandoc = pkgs.writeShellApplication {
          name = "pandoc";
          text = ''
            ${pkgs.pandoc}/bin/pandoc --data-dir=${pkgs.pandoc-letter-template}/share/pandoc/ "$@"
          '';
          runtimeInputs = [ tex ];
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

        letter-din5008 = pkgs.stdenvNoCC.mkDerivation {
          name = "latex-letter-din5008";

          src = pkgs.lib.cleanSource ./.;

          buildInputs = [
            tex
            pandoc
            pkgs.gnumake
          ];

          buildPhase = ''
            make -C template build-letter-din5008
          '';

          installPhase = ''
            runHook preInstall

            install -m644 -D template/*.pdf --target $out/

            runHook postInstall
          '';
        };
      in
      {
        packages = {
          letter = letter;
          letter-din5008 = letter-din5008;

          pandoc = pandoc;
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
      });
}
