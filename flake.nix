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
            # Allow unsupported system to try building packages
            allowUnsupportedSystem = true;
          };
          overlays = [
            (final: prev: {
              python312 = prev.python312.override {
                packageOverrides = pyFinal: pyPrev: {
                  # Only include paddlepaddle and paddlex on supported platforms
                  # or make them optional if they can't be built
                  paddlepaddle = if (system == "x86_64-linux") then
                    pyPrev.paddlepaddle.override {
                      cudaSupport = true;
                    }
                  else
                    null;
                  
                  # Make paddlex optional
                  paddlex = if (system == "x86_64-linux") then
                    pyPrev.paddlex.overridePythonAttrs (oldAttrs: {
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
                    })
                  else
                    null;
                  
                  # Make sure opencv-python is available
                  opencv-python = pyPrev.opencv4;
                };
              };
            })
          ];
        };
        
        # Use Python 3.12
        python = pkgs.python312;
        
        # Helper function to filter out null packages
        filterNull = list: builtins.filter (x: x != null) list;
        
        # Check if we're on a supported platform for paddleocr
        isPaddleSupported = (system == "x86_64-linux");
        
        # Create a Python environment with dependencies
        pythonEnv = python.withPackages (ps: with ps; filterNull [
          # Core packages - conditionally included
          (if isPaddleSupported then paddlepaddle else null)
          (if isPaddleSupported then paddlex else null)
          (if isPaddleSupported then paddleocr else null)
          
          # Image processing - always included
          pillow
          numpy
          opencv4
          
          # OCR dependencies - always included
          shapely
          scikit-image
          tqdm
          matplotlib
          pyqt5
          
          # Additional dependencies - conditionally included
          (if isPaddleSupported then protobuf else null)
          (if isPaddleSupported then pyclipper else null)
          (if isPaddleSupported then lmdb else null)
          imageio
          (if isPaddleSupported then rarfile else null)
          (if isPaddleSupported then flask else null)
          (if isPaddleSupported then flask-babel else null)
          pandas
          scipy
          (if isPaddleSupported then networkx else null)
          
          # Tesseract OCR fallback - always included
          pytesseract
          pdf2image
          
          # Optional but helpful - always included
          ipython
          jupyter
        ]);
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = filterNull [
            pythonEnv
            # Add CUDA dependencies conditionally
            (if isPaddleSupported then pkgs.cudaPackages.cudatoolkit else null)
            (if isPaddleSupported then pkgs.cudaPackages.cudnn else null)
            # Add Tesseract OCR - always included
            pkgs.tesseract
            # Add poppler for PDF handling
            pkgs.poppler_utils
          ];
          
          shellHook = ''
            echo "Python ${python.version} environment activated"
            echo "All dependencies installed via Nix"
            ${if isPaddleSupported then ''
              echo "CUDA-enabled paddlepaddle is available"
              # Set environment variables for CUDA
              export LD_LIBRARY_PATH=${pkgs.cudaPackages.cudatoolkit}/lib:${pkgs.cudaPackages.cudnn}/lib:$LD_LIBRARY_PATH
            '' else ''
              echo "Running on unsupported platform for paddleocr"
              echo "Tesseract OCR will be used as the primary OCR engine"
            ''}
            echo "You can run your OCR script with: python ocr.py <filename>"
          '';
        };
      }
    );
}
