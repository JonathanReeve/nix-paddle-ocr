{
  description = "Python 3.13 environment with Jupyter and other packages";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };

        python = pkgs.python313;

        pythonPackages = python.pkgs;

        opencv-contrib-python = pkgs.python313Packages.buildPythonPackage rec {
          pname = "opencv-contrib-python";
          version = "4.11.0.86";
          src = pkgs.fetchPypi {
            inherit pname version;
            sha256 = "sha256-T/dz2rRJEdo2a5BmIclZLU65b2rTd3CYkzoj8GSqs44=";
          };
          propagatedBuildInputs = with pkgs; [
            cmake
            python313Packages.setuptools
            python313Packages.scikit-build
            python313Packages.wheel
          ];
        };

        my-python-env = python.withPackages (ps: with ps; [
          jupyter
          jupyterlab
          nbformat
          paddlepaddle
          pytorch3d
          widgetsnbextension
          notebook
          pytest-notebook
          jupyter-client
          jupyter-console
          jupyter-contrib-core
          jupyter-core
          paddleocr
          pypdfium2
          opencv-python
          opencv-contrib-python
          opencv-python-headless
          jupyterlab-widgets
        ]);
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = [
            my-python-env
          ];

          # Optional: ensure Python and Jupyter are on PATH
          shellHook = ''
            echo "Python 3.13 environment with Jupyter and CV packages activated."
          '';
        };
      }
    );
}
