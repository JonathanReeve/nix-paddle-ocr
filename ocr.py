#!/usr/bin/env python3

from paddleocr import PaddleOCR
from PIL import Image
import os
import cv2  # Add OpenCV import

def main():
    # Print current working directory and check if test.png exists
    print(f"Current working directory: {os.getcwd()}")
    print(f"test.png exists: {os.path.exists('test.png')}")
    
    # Initialize PaddleOCR
    print("Initializing PaddleOCR...")
    ocr = PaddleOCR(use_textline_orientation=True, lang='en')
    
    # Read the image
    image_path = 'test.png'
    print(f"Reading image: {image_path}")
    
    # Perform OCR
    # The 'cls' parameter is deprecated, use predict() directly
    result = ocr.predict(image_path)
    
    # Print results
    print("\nRecognized Text:")
    print("-" * 50)
    
    # Extract and print just the recognized text in a clean format
    if result and isinstance(result, list) and len(result) > 0:
        if 'rec_texts' in result[0]:
            texts = result[0]['rec_texts']
            scores = result[0]['rec_scores']
            
            print("Text detected:")
            for idx, (text, score) in enumerate(zip(texts, scores)):
                print(f"Line {idx+1}: {text} (confidence: {score:.4f})")
        else:
            print("Text detected, but in an unexpected format:")
            print(result)
    else:
        print("No text detected in the image.")
    
    print("-" * 50)

if __name__ == "__main__":
    main()