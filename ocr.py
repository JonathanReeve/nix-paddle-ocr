#!/usr/bin/env python3

from paddleocr import PaddleOCR
from PIL import Image
import os
import cv2  # Add OpenCV import
import paddle  # Import paddle for GPU verification

def main():
    # Check GPU availability
    print("\n===== GPU Information =====")
    print(f"CUDA available: {paddle.is_compiled_with_cuda()}")
    if paddle.is_compiled_with_cuda():
        print(f"GPU device count: {paddle.device.cuda.device_count()}")
        for i in range(paddle.device.cuda.device_count()):
            print(f"GPU {i} name: {paddle.device.cuda.get_device_name(i)}")
    print("==========================\n")
    
    # Print current working directory and check if test.png exists
    print(f"Current working directory: {os.getcwd()}")
    print(f"test.png exists: {os.path.exists('test.png')}")
    
    # Initialize PaddleOCR with GPU support
    print("Initializing PaddleOCR with GPU support...")
    ocr = PaddleOCR(use_textline_orientation=True, lang='en', use_gpu=True)
    
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