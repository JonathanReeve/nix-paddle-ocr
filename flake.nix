{
  description = "A dev environment for Spacy-layout";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }: flake-utils.lib.eachDefaultSystem (system:
    let
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };

      python = pkgs.python312;

      pythonPackages = python.pkgs;

      spacy-layout = pythonPackages.buildPythonPackage rec {
        pname = "spacy-layout";
        version = "0.0.12";
        src = pkgs.fetchPypi {
          inherit pname version;
          sha256 = "aaaab35db28d8f88ff174c21df21b9afcfb7fb1f0a0c95abf562925d8f34e344";
        };
        propagatedBuildInputs = with pythonPackages; [
          spacy
          docling
          pandas
          srsly
          pytest
        ];
      };
      pythonEnv = python.withPackages (ps: with ps; [
        jupyterlab
        notebook
        ipykernel
        matplotlib
        pandas
        requests
        pillow
        spacy
        spacy-layout
      ]);

    in {
      devShells.default = pkgs.mkShell {
        name = "spacy-layout";

        packages = [
          pythonEnv
        ];
      };
    }
  );
}
