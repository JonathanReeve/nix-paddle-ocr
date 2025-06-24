from paddleocr import PaddleOCR
from PIL import Image
import matplotlib.pyplot as plt

def test_paddle_ocr(image_path="test.png"):
    ocr = PaddleOCR(use_angle_cls=True, lang='en')
    result = ocr.ocr(image_path, cls=True)

    for line in result[0]:
        text = line[1][0]
        score = line[1][1]
        print(f"Detected: '{text}' with confidence {score:.2f}")

if __name__ == "__main__":
    test_paddle_ocr()
