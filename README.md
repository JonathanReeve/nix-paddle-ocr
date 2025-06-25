# README

This is just a nix flake for using [Paddle OCR](https://github.com/PaddlePaddle/PaddleOCR), since the nixpkgs version wasn't working by default. 

This will probably be obsolete as soon as either Paddle or its nix expression are fixed. 

See also [the ollama branch](https://github.com/JonathanReeve/nix-paddle-ocr/tree/ollama) for an Ollama-based OCR pipeline, and [the spacy branch](https://github.com/JonathanReeve/nix-paddle-ocr/tree/spacy) for a version based on [spacy-layout](https://github.com/explosion/spacy-layout). 

## Usage 

``` sh
nix develop
python ocr.py
```
    
