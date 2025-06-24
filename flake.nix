{
  description = "Python development environment with paddleocr";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config = {
            allowUnfree = true;
          };
        };
        
        # Use Python 3.13
        python = pkgs.python313;
        
        # Create a Python environment with paddleocr
        pythonEnv = python.withPackages (ps: with ps; [
          paddlepaddle
          paddleocr
          pillow
          numpy
          opencv4
        ]);
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = [
            pythonEnv
          ];
          
          shellHook = ''
            echo "Python ${python.version} environment with paddleocr activated"
            echo "You can run your OCR script with: python ocr.py"
          '';
        };
      }
    );
}
