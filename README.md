# LaTeX Letter

This is a repository of [Nix package expressions][nix homepage] for creating
beautiful letters using Pandoc/LaTeX. Pandoc templates in use are:

1. [Latex letter][pandoc letter] from [Aaron Wolen][aaron wolen], using LaTeX
   `letter` class.
2. [Custom template][scrlttr2 repository] adapted from the one of [Jens
   Erat][jens erat], using LaTeX `scrlttr2` class. This template is a mix
   between the one from Aaron and Jens.

Find an example of letter in [the latest release][latest release] section.

## Quick start

You have two options:

1. Do not start a full project and use `nix run` to compile a PDF from a
   Markdown file:
   1. `nix run github:drupol/latex-letter#letter -- /path/to/letter.md -o letter.pdf`
   2. `nix run github:drupol/latex-letter#letter-scrlttr2 -- /path/to/letter.md -o letter.pdf`
2. Scaffold a full project from a default template:
   `nix flake new --template github:drupol/latex-letter#default ./my-new-document`

## Usage

Create a new letter by creating a new project:

```shell
nix flake new --template github:drupol/latex-letter#default ./my-new-document
```

Then go into the new directory:

```shell
cd ./my-new-document
```

Then build the letter:

```shell
nix build .#letter
```

or

```shell
nix build .#letter-scrlttr2
```

Then open the resulting letter in PDF:

```shell
open result/letter.pdf
```

## API

This package is contains a `flake.nix` which exposes its derivations in an
[overlay][nix overlays].

Exposed derivations:

- `pandoc-letter-template`: The derivation of the Pandoc `letter` template
- `pandoc-letter-scrlttr2-template`: The derivation of the Pandoc letter
  `scrlttr2` template

To use it in your own package, here's a minimum working example:

```nix
{
  description = "Simple flake with Pandoc latex letter";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    latex-letter.url = "github:drupol/latex-letter";
  };

  outputs = inputs:
    inputs.flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import inputs.nixpkgs {
        overlays = [inputs.latex-letter.overlays.default];

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
          pandoc --data-dir=${pandoc-templates}/share/pandoc/ "$@"
        '';
        runtimeInputs = [tex pkgs.pandoc];
      };
    in {
      formatter = pkgs.alejandra;

      devShells.default = pkgs.mkShellNoCC {
        name = "latex-letter-devshell";

        buildInputs = [pandoc];
      };
    });
}
```

[nix homepage]: https://nixos.org
[nix overlays]: https://nixos.wiki/wiki/Overlays
[aaron wolen]: https://github.com/aaronwolen
[pandoc letter]: https://github.com/aaronwolen/pandoc-letter
[latest release]: https://github.com/drupol/latex-letter/releases/latest
[jens erat]: https://github.com/JensErat/
[scrlttr2 repository]: https://github.com/drupol/pandoc-scrlttr2
