import datetime, io, json, os
# using https://squiggle.readthedocs.io/en/latest/
from squiggle import transform

def handler(in_path, out_path):
    download_begin = datetime.datetime.now()
    data = open(in_path, "r").read()
    download_stop = datetime.datetime.now()

    process_begin = datetime.datetime.now()
    result = transform(data)
    process_end = datetime.datetime.now()

    upload_begin = datetime.datetime.now()
    buf = io.BytesIO(json.dumps(result).encode())
    buf.seek(0)
    dir_name = os.path.dirname(out_path)
    if dir_name:
        os.makedirs(dir_name, exist_ok=True)
    with open(out_path, "w", encoding="utf-8") as f:
        json.dump(result, f, ensure_ascii=False, indent=4)
    upload_stop = datetime.datetime.now()
    buf.close()

    download_time = (download_stop - download_begin) / datetime.timedelta(microseconds=1)
    upload_time = (upload_stop - upload_begin) / datetime.timedelta(microseconds=1)
    process_time = (process_end - process_begin) / datetime.timedelta(microseconds=1)

    return {
            'measurement': {
                'download_time': download_time,
                'compute_time': process_time,
                'upload_time': process_time
            }
    }

if __name__ == "__main__":
    in_path = "bacillus_subtilis.fasta"
    out_path = "result.json"
    result = handler(in_path, out_path)
    print("Processing Results:")
    for key, value in result['measurement'].items():
        print(f"{key}: {value}")