#!/usr/bin/env python

import datetime
import os
import stat
import subprocess

SCRIPT_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__)))

def call_ffmpeg(args):
    ret = subprocess.run(['ffmpeg', '-y'] + args,
            #subprocess might inherit Lambda's input for some reason
            stdin=subprocess.DEVNULL,
            stdout=subprocess.PIPE, stderr=subprocess.STDOUT
    )
    if ret.returncode != 0:
        print('Invocation of ffmpeg failed!')
        print('Out: ', ret.stdout.decode('utf-8'))
        raise RuntimeError()

# https://superuser.com/questions/556029/how-do-i-convert-a-video-to-gif-using-ffmpeg-with-reasonable-quality
def to_gif(video, duration):
    output = '/tmp/processed-{}.gif'.format(os.path.basename(video))
    call_ffmpeg(["-i", video,
        "-t",
        "{0}".format(duration),
        "-vf",
        "fps=10,scale=320:-1:flags=lanczos,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse",
        "-loop", "0",
        output])
    return output

# https://devopstar.com/2019/01/28/serverless-watermark-using-aws-lambda-layers-ffmpeg/
def watermark(video, duration):
    output = '/tmp/processed-{}'.format(os.path.basename(video))
    watermark_file = os.path.dirname(os.path.realpath(__file__))
    call_ffmpeg([
        "-i", video,
        "-i", os.path.join(watermark_file, os.path.join('resources', 'watermark.png')),
        "-t", "{0}".format(duration),
        "-filter_complex", "overlay=main_w/2-overlay_w/2:main_h/2-overlay_h/2",
        output])
    return output

def transcode_mp3(video, duration):
    pass

operations = { 'transcode' : transcode_mp3, 'extract-gif' : to_gif, 'watermark' : watermark }

def handler(duration, op, in_path):
    # Restore executable permission
    ffmpeg_binary = os.path.join(SCRIPT_DIR, 'ffmpeg', 'ffmpeg')
    try:
        st = os.stat(ffmpeg_binary)
        os.chmod(ffmpeg_binary, st.st_mode | stat.S_IEXEC)
    except OSError:
        pass

    download_begin = datetime.datetime.now()
    download_size = os.path.getsize(in_path)
    download_stop = datetime.datetime.now()

    process_begin = datetime.datetime.now()
    upload_path = operations[op](in_path, duration)
    process_end = datetime.datetime.now()

    upload_begin = datetime.datetime.now()
    filename = os.path.basename(upload_path)
    upload_size = os.path.getsize(upload_path)
    upload_stop = datetime.datetime.now()

    download_time = (download_stop - download_begin) / datetime.timedelta(microseconds=1)
    upload_time = (upload_stop - upload_begin) / datetime.timedelta(microseconds=1)
    process_time = (process_end - process_begin) / datetime.timedelta(microseconds=1)
    return {
            'measurement': {
                'download_time': download_time,
                'download_size': download_size,
                'upload_time': upload_time,
                'upload_size': upload_size,
                'compute_time': process_time
            }
        }

if __name__ == "__main__":
    input_path = "city.mp4"
    duration = 5
    op = "extract-gif"
    result = handler(duration, op, input_path)
    print("Processing Results:")
    for key, value in result['measurement'].items():
        print(f"{key}: {value}")