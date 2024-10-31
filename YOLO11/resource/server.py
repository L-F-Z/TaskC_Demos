import os
os.environ['OMP_NUM_THREADS'] = '1'
os.environ['MKL_NUM_THREADS'] = '1'
import argparse
import requests
import cv2
import time
import json
import numpy as np
from ultralytics import YOLO
import flask

import logging
logger = logging.getLogger('ultralytics')
logger.setLevel(logging.WARNING)

# Argument parsing
argparse = argparse.ArgumentParser()
argparse.add_argument('--port', type=int, default=5000)
args = argparse.parse_args()

# YOLO model initialization
model = YOLO('yolo11n.pt')

# Flask app initialization
app = flask.Flask(__name__)

# Endpoint for running YOLO model on image from a URL
@app.route("/run", methods=['POST'])
def run():
    try:
        if not flask.request.is_json:
            return {"error": "Invalid Content-Type. Expected application/json."}, 400
        process_request = flask.request.get_json()

        # Download the image from the provided URL
        response = requests.get(process_request.get('image'))
        if response.status_code != 200:
            return {"error": "Failed to download image"}, 400

        input_data = response.content
        nparr = np.frombuffer(input_data, np.uint8)
        image = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
        if image is None:
            return {"error": "Failed to decode image from bytes."}

        # Run the YOLO model
        for i in range(1):
            results = model(image)
        detections = results[0]

        output = []
        for detection in detections.boxes:
            class_id = int(detection.cls)
            confidence = float(detection.conf)
            class_name = model.names[class_id]
            output.append({
                "class": class_name,
                "confidence": round(confidence, 2)
            })

        # try:
        #     post_response = requests.post(process_request.get('send_addr'), json={"time": process_request.get('time'), "task_id": process_request.get('task_id')}, timeout=5)
        #     if post_response.status_code != 200:
        #         print(f"Failed to send POST request to send_addr. Status code: {post_response.status_code}")
        # except requests.exceptions.RequestException as e:
        #     print(f"Exception occurred while sending POST request to send_addr: {e}")

        data = {"time": process_request.get('time'), "task_id": process_request.get('task_id')}
        return {
            "executed_time_s": str(time.time()),
            "scheduler_send_to": {"send_addr": process_request.get('send_addr'), "data": json.dumps(data)}
        }, 200
    
        # return flask.jsonify(output)
    except Exception as e:
        return {"error": str(e)}, 500

# Health check endpoint
@app.route("/health", methods=['GET'])
def health():
    return {"status": "ok"}

# Main function to run the app
if __name__ == '__main__':
    app.run(host='0.0.0.0', port=args.port, debug=False)