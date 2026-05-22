import os
import glob
import soundfile as sf
import subprocess

sfx_dir = "paws-n-parcels/Assets/SFX"
ogg_files = glob.glob(os.path.join(sfx_dir, "*.ogg"))

for ogg in ogg_files:
    base = os.path.splitext(ogg)[0]
    wav_path = base + ".wav"
    m4a_path = base + ".m4a"
    
    # 1. Convert OGG to WAV
    data, samplerate = sf.read(ogg)
    sf.write(wav_path, data, samplerate)
    
    # 2. Convert WAV to M4A using afconvert
    subprocess.run(["afconvert", "-f", "m4af", "-d", "aac", wav_path, m4a_path], check=True)
    
    # 3. Clean up OGG and WAV
    os.remove(ogg)
    os.remove(wav_path)
    
    print(f"Converted {ogg} to {m4a_path}")
