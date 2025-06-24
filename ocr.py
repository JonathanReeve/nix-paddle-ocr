#!/usr/bin/env python3

from paddleocr import PaddleOCR
from PIL import Image
import os

def main():
    # Print current working directory and check if test.png exists
    print(f"Current working directory: {os.getcwd()}")
    print(f"test.png exists: {os.path.exists('test.png')}")
    
    # Initialize PaddleOCR
    print("Initializing PaddleOCR...")
    ocr = PaddleOCR(use_angle_cls=True, lang='en')
    
    # Read the image
    image_path = 'test.png'
    print(f"Reading image: {image_path}")
    
    # Perform OCR
    result = ocr.ocr(image_path, cls=True)
    
    # Print results
    print("\nRecognized Text:")
    print("-" * 50)
    
    if result:
        for idx, line in enumerate(result):
            print(f"Line {idx+1}:")
            for detection in line:
                if len(detection) >= 2:
                    text = detection[1][0]
                    confidence = detection[1][1]
                    print(f"  Text: {text}")
                    print(f"  Confidence: {confidence:.4f}")
                    print()
    else:
        print("No text detected in the image.")
    
    print("-" * 50)

if __name__ == "__main__":
    main()