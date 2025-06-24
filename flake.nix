{
  description = "Python 3.13 environment with Jupyter, PaddleOCR and OpenCV";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config = {
            allowUnfree = true;
          };
        };

        python = pkgs.python313;
        pythonPackages = python.pkgs;

        # Create a Python environment with all required packages except opencv-contrib-python
        pythonEnv = python.withPackages (ps: with ps; [
          # Core tools
          pip
          setuptools
          wheel
          pytest  # Required by pytest-notebook
          
          # Jupyter packages
          jupyter
          jupyterlab
          nbformat
          widgetsnbextension
          notebook
          pytest-notebook
          jupyter-client
          jupyter-console
          jupyter-contrib-core
          jupyter-core
          jupyterlab-widgets
          
          # PaddlePaddle packages
          paddlepaddle
          # We'll handle paddleocr separately
          
          # Other packages
          pytorch3d
          pypdfium2
          
          # OpenCV dependencies
          numpy
          matplotlib
          
          # Build dependencies for OpenCV
          scikit-build
          cmake
        ]);
        
        # System dependencies needed for OpenCV
        opencvSysDeps = with pkgs; [
          # Compiler and build tools
          gcc
          cmake
          pkg-config
          
          # Image and video libraries
          libpng
          libjpeg
          libtiff
          libwebp
          ffmpeg
          
          # GUI and rendering
          libGL
          libGLU
          xorg.libX11
          xorg.libXi
          xorg.libXmu
        ];
        
      in
      {
        devShells.default = pkgs.mkShell {
          # Include basic Unix commands and Python environment
          buildInputs = [
            pkgs.coreutils
            pkgs.gnused
            pkgs.gnugrep
            pythonEnv
            opencvSysDeps
          ];

          shellHook = ''
            echo "Setting up Python environment with PaddleOCR and OpenCV..."
            
            # Create a site-packages directory for our custom packages
            SITE_PACKAGES="$PWD/.nix-shell/lib/python3.13/site-packages"
            mkdir -p $SITE_PACKAGES
            
            # Add our site-packages to PYTHONPATH
            export PYTHONPATH="$SITE_PACKAGES:$PYTHONPATH"
            
            # Install specific versions of packages to avoid conflicts
            echo "Installing opt-einsum 3.3.0 (required by paddlepaddle)..."
            ${pythonEnv}/bin/pip install --target=$SITE_PACKAGES opt-einsum==3.3.0
            
            # Install opencv-contrib-python directly to our site-packages
            echo "Installing opencv-contrib-python..."
            ${pythonEnv}/bin/pip install --target=$SITE_PACKAGES opencv-contrib-python
            
            # Install paddleocr directly to our site-packages to ensure it uses our opencv-contrib-python
            echo "Installing paddleocr..."
            ${pythonEnv}/bin/pip install --target=$SITE_PACKAGES paddleocr
            
            # Verify installations
            echo "Verifying installations..."
            PYTHONPATH="$SITE_PACKAGES:$PYTHONPATH" ${pythonEnv}/bin/python -c "import opt_einsum; print('opt_einsum version:', opt_einsum.__version__)"
            
            # Create a wrapper script for paddleocr
            mkdir -p $PWD/bin
            cat > $PWD/bin/paddleocr <<EOF
#!/bin/sh
# Set PYTHONPATH to include our site-packages
export PYTHONPATH="$SITE_PACKAGES:$PYTHONPATH"
# Run paddleocr with our Python
${pythonEnv}/bin/python -m paddleocr "\$@"
EOF
            chmod +x $PWD/bin/paddleocr
            
            # Add our bin directory to PATH
            export PATH="$PWD/bin:$PATH"
            
            # Test OpenCV installation
            echo "Testing OpenCV installation..."
            PYTHONPATH="$SITE_PACKAGES:$PYTHONPATH" ${pythonEnv}/bin/python -c "import cv2; print('OpenCV version:', cv2.version.opencv_version); print('Contrib modules available:', 'yes' if hasattr(cv2, 'xfeatures2d') else 'no')"
            
            echo ""
            echo "You can now run: paddleocr text_recognition -i test.png"
          '';
        };
      }
    );
}
