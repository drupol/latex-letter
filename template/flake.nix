{
  description = "Letter document";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    nix-filter.url = github:numtide/nix-filter;
    latex-letter.url = "github:drupol/latex-letter";
  };

  outputs = { self, nixpkgs, flake-utils, nix-filter, latex-letter, ... }@inputs:
    flake-utils.lib.eachDefaultSystem (system:
      let
        version = self.shortRev or self.lastModifiedDate;

        pkgs = import nixpkgs {
          inherit system;

          overlays = [
            latex-letter.overlays.default
          ];
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

          nativeBuildInputs = [
            pandoc
            tex
          ];

          build = ''
            make build-letter
          '';

          installPhase = ''
            runHook preInstall

            install -m644 -D letter.pdf --target $out/

            runHook postInstall
          '';
        };
      in
      {
        # Nix shell / nix build
        packages.default = letter;

        # Nix develop
        devShells.default = pkgs.mkShellNoCC {
          name = "letter-devshell";
          buildInputs = [
            tex
            pandoc
            pkgs.gnumake
            pkgs.nixpkgs-fmt
            pkgs.nixfmt
          ];
        };
      });
}
