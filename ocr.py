#!/usr/bin/env python3

# OCR with llama3:vision via Ollama

from ollama import Client
from PIL import Image
import base64
import io

# Initialize Ollama client
client = Client()

# Load and encode the image
def encode_image(image_path):
    with Image.open(image_path) as img:
        # Convert to RGB if needed
        if img.mode != 'RGB':
            img = img.convert('RGB')

        buffered = io.BytesIO()
        img.save(buffered, format="JPEG")  # JPEG is usually more efficient
        return base64.b64encode(buffered.getvalue()).decode()

image_path = "test.png"  # path to your image file
image_b64 = encode_image(image_path)

# Send request to Ollama
response = client.generate(
    model="llama3.2-vision",
    prompt="Please transcribe all the text in this image.",
    images=[image_b64]
)

print("Model Response:\n")
print(response["response"])
