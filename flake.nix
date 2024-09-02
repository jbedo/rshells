{
  description = "rPackages exposed with chains";
  inputs.nixpkgs.url = "github:nixos/nixpkgs/r-updates";

  outputs = {
    self,
    nixpkgs,
  }: let
    systems = ["x86_64-linux" "x86_64-darwin" "aarch64-linux" "aarch64-darwin"];

    withSystem = f: nixpkgs.lib.genAttrs systems (system: f system);
    pkgsFor = withSystem (system:
      import nixpkgs {
        inherit system;
        overlays = [self.overlay];
      });

    makeMerger = self: packages: wrapper: let
      gen = name: ps:
        self.buildEnv {
          inherit name;
          paths =
            [
              (wrapper.override {packages = ps;})
            ]
            ++ ps;
          ignoreCollisions = true;

          passthru = with builtins; mapAttrs (n: v: gen "merged" (ps ++ [v])) (self // packages);
        };
    in
      gen "merged" [];
  in {
    overlay = self: super: {
      rWrapper = makeMerger self super.rPackages super.rWrapper;
    };
    packages = withSystem (system: {inherit (pkgsFor.${system}) rWrapper;});
  };
}
