{ inputs, self, ... }:
{
  perSystem =
    { system, ... }:
    {
      _module.args.pkgs = import self.inputs.nixpkgs {
        inherit system;
        overlays = [
          inputs.latex-letter.overlays.default
        ];
      };
    };
}
