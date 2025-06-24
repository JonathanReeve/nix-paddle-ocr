{
  description = "PaddleOCR dev environment with Python 3.13 and Jupyter";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        python = pkgs.python313;
      in {
        devShells.default = pkgs.mkShell {
          buildInputs = [
            python
            python.pkgs.pip
            python.pkgs.setuptools
            python.pkgs.wheel

            # Jupyter and common deps
            python.pkgs.jupyter
            python.pkgs.notebook
            python.pkgs.matplotlib
            python.pkgs.numpy
            python.pkgs.pandas

            # Required native dependencies for PaddleOCR
            pkgs.glibcLocales
            pkgs.ffmpeg
            pkgs.tesseract
            pkgs.git
            pkgs.opencv

            # (optional) useful for PIL image debugging
            pkgs.imagemagick
          ];

          # For UTF-8 compatibility with PaddleOCR
          LANG = "en_US.UTF-8";
          LOCALE_ARCHIVE = "${pkgs.glibcLocales}/lib/locale/locale-archive";

          shellHook = ''
            export PYTHONIOENCODING=utf-8
            echo "Installing PaddleOCR and PaddlePaddle with pip..."
            pip install --upgrade pip
            pip install paddleocr paddlepaddle
            echo "✅ Environment ready. Try running: python test_ocr.py"
          '';
        };
      });
}
