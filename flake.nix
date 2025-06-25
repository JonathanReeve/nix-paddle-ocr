{
  description = "A dev environment for Spacy-layout";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }: flake-utils.lib.eachDefaultSystem (system:
    let
      # Create an overlay to skip tests for problematic packages
      pythonOverlay = final: prev: {
        python312 = prev.python312.override {
          packageOverrides = pyFinal: pyPrev: {
            accelerate = pyPrev.accelerate.overridePythonAttrs (oldAttrs: {
              # Skip the test phase completely
              doCheck = false;
            });
            
            plotly = pyPrev.plotly.overridePythonAttrs (oldAttrs: {
              # Skip the test phase completely
              doCheck = false;
            });
          };
        };
      };
      
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
        overlays = [ pythonOverlay ];
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
        pymupdf  # Added PyMuPDF for the fitz module
        spacy_models.en_core_web_sm # Replace with another model if you want it to be more accurate
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

