import datetime
import io
from PIL import Image

def resize_image(image_bytes, w, h):
    with Image.open(io.BytesIO(image_bytes)) as image:
        image.thumbnail((w, h))
        out = io.BytesIO()
        image.save(out, format='jpeg')
        out.seek(0)
        return out

def handler(width, height, in_path, out_path):
    # Measure download time
    download_begin = datetime.datetime.now()
    with open(in_path, 'rb') as f:
        img = f.read()
    download_end = datetime.datetime.now()

    # Measure processing time
    process_begin = datetime.datetime.now()
    resized = resize_image(img, width, height)
    resized_size = resized.getbuffer().nbytes
    process_end = datetime.datetime.now()

    # Measure upload time
    upload_begin = datetime.datetime.now()
    with open(out_path, 'wb') as f:
        f.write(resized.getvalue())
    upload_end = datetime.datetime.now()

    # Compute time measurements
    download_time = (download_end - download_begin).total_seconds() * 1e6
    upload_time = (upload_end - upload_begin).total_seconds() * 1e6
    process_time = (process_end - process_begin).total_seconds() * 1e6
    
    return {
        'measurement': {
            'download_time': download_time,
            'download_size': len(img),
            'upload_time': upload_time,
            'upload_size': resized_size,
            'compute_time': process_time
        }
    }

if __name__ == "__main__":
    input_path = "input.jpg"
    output_path = "output.jpg"
    width, height = 200, 200
    
    result = handler(width, height, input_path, output_path)
    print("Processing Results:")
    for key, value in result['measurement'].items():
        print(f"{key}: {value}")
