import requests
import torch
from PIL import Image, ImageDraw
from io import BytesIO
from transformers import pipeline, AutoTokenizer, AutoModelForSequenceClassification

# Check if CUDA is available and set the device
device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
print(f"Using device: {device}")
assert device.type == "cuda"

# Sentiment analysis using pipeline
print("Running sentiment analysis using pipeline...")
classifier = pipeline('sentiment-analysis', device=0 if torch.cuda.is_available() else -1)
result = classifier('We are very happy to introduce pipeline to the transformers repository.')
print(f"Sentiment analysis result: {result}")
print("Sentiment analysis completed successfully.")

# Image download and object detection
print("\nDownloading image and running object detection...")
url = "https://huggingface.co/datasets/huggingface/documentation-images/resolve/main/coco_sample.png"
response = requests.get(url)
image = Image.open(BytesIO(response.content))

object_detector = pipeline('object-detection', device=0 if torch.cuda.is_available() else -1)
detection_result = object_detector(image)
print(f"Object detection found {len(detection_result)} objects.")

# Draw bounding boxes on the image
draw = ImageDraw.Draw(image)
for detection in detection_result:
    box = detection['box']
    label = f"{detection['label']} {detection['score']:.2f}"
    draw.rectangle([box['xmin'], box['ymin'], box['xmax'], box['ymax']], outline="red", width=2)
    draw.text((box['xmin'], box['ymin'] - 10), label, fill="red")

# Save the image with detected objects
output_path = "detected_objects.jpg"
image.save(output_path)
print(f"Image with detected objects saved as '{output_path}'")
print("Object detection completed successfully.")

# BERT model for sentiment analysis
print("\nUsing BERT model for sentiment analysis...")
model_name = "distilbert-base-uncased-finetuned-sst-2-english"
tokenizer = AutoTokenizer.from_pretrained(model_name)
model = AutoModelForSequenceClassification.from_pretrained(model_name).to(device)

# Function to classify sentiment
def classify_sentiment(text):
    inputs = tokenizer(text, return_tensors="pt", truncation=True, padding=True).to(device)
    with torch.no_grad():
        outputs = model(**inputs)
    probabilities = outputs.logits.softmax(dim=1)
    sentiment = "POSITIVE" if probabilities[0][1] > probabilities[0][0] else "NEGATIVE"
    confidence = probabilities[0][1] if sentiment == "POSITIVE" else probabilities[0][0]
    return sentiment, confidence.item()

# Test sentences
test_sentences = [
    "I love this movie!",
    "This book was terrible.",
    "The weather is okay today."
]

print("BERT model sentiment analysis results:")
for sentence in test_sentences:
    sentiment, confidence = classify_sentiment(sentence)
    print(f"Text: '{sentence}'")
    print(f"Sentiment: {sentiment}, Confidence: {confidence:.4f}\n")

print("BERT model sentiment analysis completed successfully.")

print("\nAll operations completed successfully!")