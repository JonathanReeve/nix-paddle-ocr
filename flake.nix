{
  description = "A dev environment for Spacy-layout";

  inputs = {
    nixpkgs.url = "github.com/nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github.com/numtide/flake-utils";
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
          pname = "spacy_layout"; # Corrected: use underscore for PyPI fetch
          inherit version;
          sha256 = "5c96e8f6fdc2a059df2c3e02929f03cc5139c03aa1a454d5b82a5831ddeb454d";
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
