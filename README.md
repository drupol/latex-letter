# LaTeX Letter

This is a repository of [Nix package expressions][nix homepage] for the LaTeX
Letter Pandoc template.

The Pandoc LaTeX letter template is from
[Aaron Wolen](https://github.com/aaronwolen), see the
[template repository](https://github.com/aaronwolen/pandoc-letter).

This package is a flake for this project.

## Usage

Create a new letter by creating a new project:

```shell
nix flake new --template github:drupol/latex-letter#default ./my-new-document
```

Then build the letter:

```shell
nix build
```

Then open the letter:

```shell
open result/letter.pdf
```

## API

This package is contains a `flake.nix` which exposes its derivations in an
[overlay][nix overlays].

Exposed derivations:

- `pandoc-letter-template`: The derivation of the Pandoc letter template

To use it in your own package, here's a minimum working example:

```nix
{
  description = "Simple flake with Pandoc latex letter";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    latex-letter.url = "github:drupol/latex-letter";
  };

  outputs = { self, nixpkgs, flake-utils, latex-letter, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          overlays = [
            latex-letter.overlays.default
          ];

          inherit system;
        };

        tex = pkgs.texlive.combine {
          inherit (pkgs.texlive) scheme-full latex-bin latexmk;
        };

        pandoc = pkgs.writeShellScriptBin "pandoc" ''
          ${pkgs.pandoc}/bin/pandoc --data-dir ${pkgs.pandoc-letter-template}/share/pandoc/ $@
        '';
      in
      {
        devShells.default = pkgs.mkShellNoCC {
          name = "latex-letter-devshell";

          buildInputs = [
            tex
            pandoc
          ];
        };
      });
}
```

[nix homepage]: https://nixos.org
[nix overlays]: https://nixos.wiki/wiki/Overlays
