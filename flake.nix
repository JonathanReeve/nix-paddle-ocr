{
  description = "Ollama + llama3-vision Python dev environment";

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

      python = pkgs.python313;

      pythonPackages = python.pkgs;

      pythonEnv = python.withPackages (ps: with ps; [
        jupyterlab
        notebook
        ipykernel
        matplotlib
        pandas
        requests
        pillow
        # For vision model input/output handling
        opencv4
        # Python interface to Ollama
        ollama
      ]);

    in {
      devShells.default = pkgs.mkShell {
        name = "ollama-vision-env";

        packages = [
          pkgs.ollama
          pythonEnv
        ];

        shellHook = ''
          echo "Starting environment for Ollama + llama3-vision..."
          echo "To use the model, make sure to run:"
          echo "  ollama serve &"
          echo "  ollama pull llama3:vision"
          echo "Then use the Python interface to query the model."
        '';
      };
    }
  );
}
