import datetime
import os
import shutil
import uuid

def parse_directory(directory):
    size = 0
    for root, dirs, files in os.walk(directory):
        for file in files:
            size += os.path.getsize(os.path.join(root, file))
    return size

def handler(in_path):
    id = str(uuid.uuid4())
    download_path = f'/tmp/{id}'
    os.makedirs(download_path)

    download_begin = datetime.datetime.now()
    if os.path.isdir(in_path):
        shutil.copytree(in_path, download_path, dirs_exist_ok=True)
    else:
        shutil.copy(in_path, download_path)
    download_stop = datetime.datetime.now()
    size = parse_directory(download_path)

    compress_begin = datetime.datetime.now()
    archive_path = f'/tmp/{id}'
    shutil.make_archive(archive_path, 'zip', root_dir=download_path)
    compress_end = datetime.datetime.now()

    upload_begin = datetime.datetime.now()
    archive_name = '{}.zip'.format(id)
    archive_size = os.path.getsize(f'/tmp/{archive_name}')
    upload_stop = datetime.datetime.now()

    download_time = (download_stop - download_begin) / datetime.timedelta(microseconds=1)
    upload_time = (upload_stop - upload_begin) / datetime.timedelta(microseconds=1)
    process_time = (compress_end - compress_begin) / datetime.timedelta(microseconds=1)
    return {
            'measurement': {
                'download_time': download_time,
                'download_size': size,
                'upload_time': upload_time,
                'upload_size': archive_size,
                'compute_time': process_time
            }
        }

if __name__ == "__main__":
    input_path = "random.bin"
    result = handler(input_path)
    print("Processing Results:")
    for key, value in result['measurement'].items():
        print(f"{key}: {value}")