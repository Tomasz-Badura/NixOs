{
  description = "NixOs config";

  inputs = 
  {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager.url = "github:nix-community/home-manager/release-24.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    spicetify-nix.url = "github:Gerg-L/spicetify-nix";
    spicetify-nix.inputs.nixpkgs.follows = "nixpkgs";

    xremap-flake.url = "github:xremap/nix-flake";
  };

  outputs = { self, nixpkgs, home-manager, ... } @ inputs: 
  let
    inherit (self) outputs;
  in 
  {
    # sudo nixos-rebuild --flake /config
    nixosConfigurations = 
    {
      TERMINATOR = nixpkgs.lib.nixosSystem 
      {
        specialArgs = {inherit inputs outputs;};
        modules = [./nixos/configuration.nix];
      };
    };

    # sudo home-manager --flake /config#terminator@TERMINATOR
    homeConfigurations = 
    {
      "terminator@TERMINATOR" = home-manager.lib.homeManagerConfiguration 
      {
        pkgs = nixpkgs.legacyPackages.x86_64-linux;
        extraSpecialArgs = {inherit inputs outputs;};
        modules = [./home-manager/home.nix];
      };
    }; 
  };
}