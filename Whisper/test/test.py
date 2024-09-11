import whisper

model = whisper.load_model("base")
result = model.transcribe("/app/test/audio.mp3")

# print(result["text"])
with open("/app/test/res.txt", "w") as file:
    file.write(result["text"])

