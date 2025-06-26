#!/usr/bin/env python3

import os
import sys
from PIL import Image
import pytesseract  # Import pytesseract for OCR
from pdf2image import convert_from_path  # For handling PDF files
import subprocess  # For calling tesseract directly
import tempfile  # For creating temporary files

# Try to import paddle and paddleocr, but handle the case where they might not be available
paddle_available = False
try:
    import paddle
    from paddleocr import PaddleOCR
    import cv2  # Add OpenCV import
    paddle_available = True
    print("PaddleOCR is available and will be used as primary OCR engine")
except ImportError:
    print("PaddleOCR is not available, using Tesseract OCR only")

def process_image(image_path):
    """Process an image file with OCR, using PaddleOCR if available, falling back to Tesseract"""
    print(f"Processing file: {image_path}")
    
    # Try PaddleOCR first if available
    if paddle_available:
        try:
            print("Initializing PaddleOCR...")
            ocr = PaddleOCR(use_textline_orientation=True, lang='en', use_gpu=paddle.is_compiled_with_cuda())
            
            print("Attempting OCR with PaddleOCR...")
            # Perform OCR with PaddleOCR
            result = ocr.predict(image_path)
            
            # Print results
            print("\nRecognized Text (PaddleOCR):")
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
                print("No text detected in the image with PaddleOCR.")
                raise Exception("No text detected with PaddleOCR")
                
        except Exception as e:
            print(f"PaddleOCR failed: {str(e)}")
            print("\nFalling back to Tesseract OCR...")
            use_tesseract = True
        else:
            # PaddleOCR succeeded, no need to use Tesseract
            use_tesseract = False
    else:
        # PaddleOCR not available, use Tesseract directly
        use_tesseract = True
    
    # Use Tesseract if needed
    if use_tesseract:
        try:
            print(f"Opening image file: {image_path}")
            # Use direct subprocess call to tesseract instead of pytesseract
            
            # Create a temporary file for the output
            with tempfile.NamedTemporaryFile(suffix='.txt', delete=False) as tmp_file:
                output_file = tmp_file.name
            
            print(f"Created temporary output file: {output_file}")
            
            # Build the tesseract command
            cmd = ['tesseract', image_path, output_file.replace('.txt', ''), '-l', 'eng', '--oem', '3', '--psm', '6']
            print(f"Running command: {' '.join(cmd)}")
            
            # Run tesseract directly
            process = subprocess.run(cmd, capture_output=True, text=True)
            
            if process.returncode != 0:
                print(f"Tesseract command failed with return code {process.returncode}")
                print(f"Error output: {process.stderr}")
                raise Exception(f"Tesseract command failed: {process.stderr}")
            
            # Read the output file
            with open(f"{output_file}", 'r') as f:
                text = f.read()
            
            # Clean up the temporary file
            os.remove(output_file)
            
            print("\nRecognized Text (Tesseract):")
            print("-" * 50)
            
            if text and text.strip():
                print("Text detected:")
                for idx, line in enumerate(text.strip().split('\n')):
                    if line.strip():
                        print(f"Line {idx+1}: {line}")
            else:
                print("No text detected in the image with Tesseract.")
        except Exception as tesseract_error:
            print(f"Tesseract OCR failed: {str(tesseract_error)}")
            import traceback
            print(traceback.format_exc())
            if paddle_available:
                print("Both OCR engines failed to process the image.")
            else:
                print("OCR failed to process the image.")
    
    print("-" * 50)

def main():
    # Check GPU availability if paddle is available
    if paddle_available:
        print("\n===== GPU Information =====")
        print(f"CUDA available: {paddle.is_compiled_with_cuda()}")
        if paddle.is_compiled_with_cuda():
            print(f"GPU device count: {paddle.device.cuda.device_count()}")
            for i in range(paddle.device.cuda.device_count()):
                print(f"GPU {i} name: {paddle.device.cuda.get_device_name(i)}")
        print("==========================\n")
    else:
        print("\n===== OCR Information =====")
        print("PaddleOCR is not available")
        print("Using Tesseract OCR only")
        print("==========================\n")
    
    # Get file path from command line arguments or use default
    if len(sys.argv) > 1:
        file_path = sys.argv[1]
    else:
        file_path = 'test.png'
        
    # Print current working directory and check if file exists
    print(f"Current working directory: {os.getcwd()}")
    print(f"File exists: {os.path.exists(file_path)}")
    
    if not os.path.exists(file_path):
        print(f"Error: File '{file_path}' not found.")
        sys.exit(1)
    
    # Check if the file is a PDF
    if file_path.lower().endswith('.pdf'):
        print("PDF file detected, converting to images...")
        try:
            # Convert PDF to images with higher DPI for better OCR
            images = convert_from_path(file_path, dpi=300)
            print(f"PDF contains {len(images)} pages")
            
            # Process each page
            for i, image in enumerate(images):
                print(f"\nProcessing page {i+1}/{len(images)}")
                # Save the image temporarily with high quality
                temp_image_path = f"temp_page_{i+1}.png"
                image.save(temp_image_path, 'PNG', quality=95)
                
                print(f"Saved temporary image: {temp_image_path}")
                print(f"File exists: {os.path.exists(temp_image_path)}")
                print(f"File size: {os.path.getsize(temp_image_path)} bytes")
                
                # Process the image
                process_image(temp_image_path)
                
                # Clean up temporary file
                if os.path.exists(temp_image_path):
                    os.remove(temp_image_path)
        except Exception as e:
            print(f"Error processing PDF: {str(e)}")
            import traceback
            print(traceback.format_exc())
            print("Attempting to process the PDF directly...")
            process_image(file_path)
    else:
        # Process a regular image file
        process_image(file_path)

if __name__ == "__main__":
    main()