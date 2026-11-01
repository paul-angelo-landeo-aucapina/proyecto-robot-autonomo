import os
import random
import numpy as np
import tensorflow as tf
from tensorflow.keras import layers, models
import scipy.io.wavfile as wav

# ==============================================================================
# 1. PARÁMETROS DEL SISTEMA (SEGÚN INCISOS 5.1 Y 5.2 DEL PDF)
# ==============================================================================
SAMPLE_RATE = 16000
DURATION = 1.0  # 1.0 segundo de ventana temporal
TOTAL_SAMPLES = int(SAMPLE_RATE * DURATION)

# Comandos oficiales del PDF (Sección 5.2.A)
COMMANDS = [
    "_silencio_",      # Ruido ambiente y motores en marcha
    "_desconocido_",   # Palabras fuera de vocabulario
    "avanzar",
    "retroceder",
    "girar",
    "detener"
]
NUM_CLASSES = len(COMMANDS)

# ==============================================================================
# 2. GENERADOR SINTÉTICO DEL DATASET (PARA INICIAR SIN HARDWARE)
# ==============================================================================
DATASET_PATH = "./dataset_audio"
os.makedirs(DATASET_PATH, exist_ok=True)

print("Generando dataset sintético de audio en español...")
for cmd in COMMANDS:
    cmd_dir = os.path.join(DATASET_PATH, cmd)
    os.makedirs(cmd_dir, exist_ok=True)
    for i in range(100):  # 100 muestras base por comando
        t = np.linspace(0, DURATION, TOTAL_SAMPLES, endpoint=False)
        if cmd == "_silencio_":
            # Ruido blanco + armónicos de motor DC 37D
            noise = np.random.normal(0, 0.05, TOTAL_SAMPLES)
            motor_whine = 0.05 * np.sin(2 * np.pi * 220 * t)
            audio = noise + motor_whine
        elif cmd == "_desconocido_":
            audio = 0.3 * np.sin(2 * np.pi * random.uniform(800, 1500) * t) * np.hanning(TOTAL_SAMPLES)
        else:
            freq = 250 + (COMMANDS.index(cmd) * 120)
            # Simulación formántica vocal con envolvente
            audio = (np.sin(2 * np.pi * freq * t) + 0.5 * np.sin(2 * np.pi * (freq*1.8) * t)) * np.blackman(TOTAL_SAMPLES)
        
        audio = np.clip(audio, -1.0, 1.0)
        audio_int16 = (audio * 32767).astype(np.int16)
        wav.write(os.path.join(cmd_dir, f"{cmd}_{i}.wav"), SAMPLE_RATE, audio_int16)

print("[OK] Dataset creado exitosamente.")

# ==============================================================================
# 3. EXTRACCIÓN DE LOG-MEL SPECTROGRAM (COMPATIBLE CON TFLM)
# ==============================================================================
def get_spectrogram(audio):
    # Padding / Truncado a 16000 muestras
    audio = audio[:TOTAL_SAMPLES]
    zero_padding = tf.zeros([TOTAL_SAMPLES] - tf.shape(audio), dtype=tf.float32)
    equal_length = tf.concat([audio, zero_padding], 0)
    
    # STFT: Ventana de 30ms (480), Hop de 20ms (320), FFT 512
    stft = tf.signal.stft(equal_length, frame_length=480, frame_step=320, fft_length=512)
    spectrogram = tf.abs(stft)
    
    # 40 Filtros Mel entre 60Hz y 3800Hz
    num_mel_bins = 40
    mel_matrix = tf.signal.linear_to_mel_weight_matrix(num_mel_bins, spectrogram.shape[-1], SAMPLE_RATE, 60.0, 3800.0)
    mel_spectrogram = tf.tensordot(spectrogram, mel_matrix, 1)
    log_mel = tf.math.log(mel_spectrogram + 1e-6)
    
    # Dimensiones resultantes: (49 frames, 40 bandas Mel, 1 canal)
    return tf.expand_dims(log_mel, -1)

# Pipeline de tf.data
files = tf.data.Dataset.list_files(f"{DATASET_PATH}/*/*.wav", shuffle=True)
def parse_wav(file_path):
    parts = tf.strings.split(file_path, os.sep)
    label_str = parts[-2]
    label = tf.argmax(tf.constant(COMMANDS) == label_str)
    raw_audio = tf.io.read_file(file_path)
    wav_data, _ = tf.audio.decode_wav(raw_audio, desired_channels=1)
    spectrogram = get_spectrogram(tf.squeeze(wav_data, -1))
    return spectrogram, label

train_ds = files.map(parse_wav).batch(16).prefetch(tf.data.AUTOTUNE)

# ==============================================================================
# 4. MODELO CONVOLUCIONAL SEPARABLE (DS-CNN) PARA ESP32-S3
# ==============================================================================
model = models.Sequential([
    layers.Input(shape=(49, 40, 1)),
    layers.Conv2D(16, (3, 3), strides=(2, 2), padding='same', activation='relu'),
    layers.BatchNormalization(),
    
    # Bloque Depthwise Separable
    layers.DepthwiseConv2D((3, 3), padding='same', activation='relu'),
    layers.Conv2D(32, (1, 1), padding='same', activation='relu'),
    layers.BatchNormalization(),
    layers.MaxPooling2D((2, 2)),
    
    layers.GlobalAveragePooling2D(),
    layers.Dropout(0.2),
    layers.Dense(NUM_CLASSES, activation='softmax')
])

model.compile(optimizer='adam', loss='sparse_categorical_crossentropy', metrics=['accuracy'])
print("Entrenando red neuronal...")
model.fit(train_ds, epochs=15)

# ==============================================================================
# 5. CUANTIZACIÓN INT8 Y GENERACIÓN DEL ARCHIVO C++ (kws_model_data.h)
# ==============================================================================
def representative_data_gen():
    for spec, _ in train_ds.take(50):
        yield [spec]

converter = tf.lite.TFLiteConverter.from_keras_model(model)
converter.optimizations = [tf.lite.Optimize.DEFAULT]
converter.representative_dataset = representative_data_gen
converter.target_spec.supported_ops = [tf.lite.OpsSet.TFLITE_BUILTINS_INT8]
converter.inference_input_type = tf.int8
converter.inference_output_type = tf.int8

tflite_int8_model = converter.convert()

with open("model.tflite", "wb") as f:
    f.write(tflite_int8_model)

# Generar el archivo .h de C++ para Arduino IDE
def convert_to_c_array(tflite_bytes, output_filename="kws_model_data.h"):
    hex_str = ", ".join([f"0x{b:02x}" for b in tflite_bytes])
    c_content = f"""#pragma once
#include <stdint.h>

alignas(16) const unsigned char g_kws_model_data[{len(tflite_bytes)}] = {{
    {hex_str}
}};
const unsigned int g_kws_model_data_len = {len(tflite_bytes)};
"""
    with open(output_filename, "w") as f:
        f.write(c_content)
    print(f"\n[ÉXITO] Archivo generado: {output_filename}")
    print(f"Tamaño en Flash del ESP32: {len(tflite_bytes) / 1024:.2f} KB")

convert_to_c_array(tflite_int8_model)