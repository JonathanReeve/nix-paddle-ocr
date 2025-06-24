{
  description = "PaddleOCR dev environment with Python 3.13 and Jupyter";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    python-overlay.url = "github:nix-community/python-overlay";
  };

  outputs = { self, nixpkgs, flake-utils, python-overlay }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ python-overlay.overlays.default ];
        };

        python = pkgs.python313;

        pythonEnv = python.withPackages (ps: with ps; [
          pip
          jupyter
          notebook
          ipykernel
          matplotlib
          numpy
          pandas
          opencv4
          # PaddleOCR is not packaged in nixpkgs; we install it via pip in shellHook
        ]);
      in {
        devShells.default = pkgs.mkShell {
          buildInputs = [
            pythonEnv
            pkgs.git
            pkgs.ffmpeg
            pkgs.tesseract  # optional, for comparison or fallback
          ];

          shellHook = ''
            export PYTHONPATH=$PWD
            echo "Setting up Python environment..."
            pip install --upgrade pip
            pip install paddlepaddle paddleocr
            echo "You can now run Jupyter or use PaddleOCR from Python."
          '';
        };
      });
}
