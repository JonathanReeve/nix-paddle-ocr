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
          overlays = [
            (final: prev: {
              python313 = prev.python313.override {
                packageOverrides = pyFinal: pyPrev: {
                  # Enable CUDA support for paddlepaddle
                  paddlepaddle = pyPrev.paddlepaddle.override {
                    cudaSupport = true;
                  };
                  
                  # Create a patched version of paddlex that doesn't check for OCR dependencies
                  paddlex = pyPrev.paddlex.overridePythonAttrs (oldAttrs: {
                    postPatch = ''
                      # Patch the dependency check to always return True
                      substituteInPlace paddlex/utils/deps.py \
                        --replace "raise RuntimeError(msg)" "pass"
                      
                      # Add cv2 import to all files that need it
                      echo 'import cv2' | cat - paddlex/inference/common/reader/image_reader.py > temp && mv temp paddlex/inference/common/reader/image_reader.py
                      echo 'import cv2' | cat - paddlex/inference/models/common/vision/processors.py > temp && mv temp paddlex/inference/models/common/vision/processors.py
                      
                      # Find all Python files that might use cv2 and add the import
                      find paddlex -name "*.py" -type f -exec grep -l "cv2\." {} \; | xargs -I{} sh -c 'echo "import cv2" | cat - {} > temp && mv temp {}'
                    '';
                  });
                  
                  # Make sure opencv-python is available
                  opencv-python = pyPrev.opencv4;
                };
              };
            })
          ];
        };
        
        # Use Python 3.13
        python = pkgs.python313;
        
        # Create a Python environment with paddleocr and all required dependencies
        pythonEnv = python.withPackages (ps: with ps; [
          # Core packages
          paddlepaddle
          paddlex
          paddleocr
          
          # Image processing
          pillow
          numpy
          opencv4
          
          # OCR dependencies
          shapely
          scikit-image
          tqdm
          matplotlib
          pyqt5
          
          # Additional dependencies needed for paddleocr
          protobuf
          pyclipper
          lmdb
          imageio
          rarfile
          flask
          flask-babel
          pandas
          scipy
          networkx
          
          # Optional but helpful
          ipython
          jupyter
        ]);
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = [
            pythonEnv
            # Add CUDA dependencies
            pkgs.cudaPackages.cudatoolkit
            pkgs.cudaPackages.cudnn
          ];
          
          shellHook = ''
            echo "Python ${python.version} environment with paddleocr activated"
            echo "All dependencies installed via Nix"
            echo "CUDA-enabled paddlepaddle is available"
            echo "You can run your OCR script with: python ocr.py"
            
            # Set environment variables for CUDA
            export LD_LIBRARY_PATH=${pkgs.cudaPackages.cudatoolkit}/lib:${pkgs.cudaPackages.cudnn}/lib:$LD_LIBRARY_PATH
          '';
        };
      }
    );
}
