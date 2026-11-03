"""
ENTRENAMIENTO MODELO TINYML - COMANDOS DE VOZ ROBOT MOVIL
Comandos: ["silencio", "avanzar", "retroceder", "girar", "detener"]
Genera el array de bytes en C (model_data.h) para ESP32-S3.
"""

import numpy as np
import tensorflow as tf
from tensorflow.keras import layers, models
import librosa
import os

SAMPLE_RATE = 16000
DURATION = 1.0  # 1 segundo de ventana de audio
N_MFCC = 40     # Coeficientes Cepstrales en las Frecuencias de Mel

def preprocess_audio(file_path):
    """Carga audio mono a 16 kHz y obtiene la matriz MFCC."""
    wav, sr = librosa.load(file_path, sr=SAMPLE_RATE, mono=True, duration=DURATION)
    if len(wav) < int(SAMPLE_RATE * DURATION):
        wav = np.pad(wav, (0, int(SAMPLE_RATE * DURATION) - len(wav)), mode='constant')
    
    mfcc = librosa.feature.mfcc(y=wav, sr=SAMPLE_RATE, n_mfcc=N_MFCC, n_fft=512, hop_length=256)
    return mfcc[..., np.newaxis] # (40, 63, 1)

def build_tinyml_model(input_shape, num_classes):
    """Red Convolucional 2D compacta ejecutable en microcontrolador."""
    model = models.Sequential([
        layers.Input(shape=input_shape),
        layers.Conv2D(16, (3, 3), activation='relu', padding='same'),
        layers.MaxPooling2D((2, 2)),
        layers.Dropout(0.2),
        
        layers.Conv2D(32, (3, 3), activation='relu', padding='same'),
        layers.MaxPooling2D((2, 2)),
        layers.Dropout(0.2),

        layers.Flatten(),
        layers.Dense(64, activation='relu'),
        layers.Dropout(0.25),
        layers.Dense(num_classes, activation='softmax')
    ])
    model.compile(optimizer='adam', loss='sparse_categorical_crossentropy', metrics=['accuracy'])
    return model

# Simulación de datos sintéticos representativos del pipeline
X_train = np.random.randn(200, 40, 63, 1).astype(np.float32)
y_train = np.random.randint(0, 5, size=(200,))

model = build_tinyml_model(input_shape=(40, 63, 1), num_classes=5)
model.fit(X_train, y_train, epochs=5, batch_size=16)

# --- Cuantización a INT8 para Microcontroladores (ESP32-S3) ---
def representative_data_gen():
    for i in range(50):
        yield [X_train[i:i+1]]

converter = tf.lite.TFLiteConverter.from_keras_model(model)
converter.optimizations = [tf.lite.Optimize.DEFAULT]
converter.representative_dataset = representative_data_gen
converter.target_spec.supported_ops = [tf.lite.OpsSet.TFLITE_BUILTINS_INT8]
converter.inference_input_type = tf.int8
converter.inference_output_type = tf.int8

tflite_quant_model = converter.convert()

with open("kws_esp32_model.tflite", "wb") as f:
    f.write(tflite_quant_model)

# --- Conversión a Array C (model_data.h) ---
def convert_to_c_array(tflite_bytes, output_header="model_data.h"):
    hex_array = [f"0x{b:02x}" for b in tflite_bytes]
    c_str = f"const unsigned char g_model[] = {{\n  " + ", ".join(hex_array) + "\n};\n"
    c_str += f"const int g_model_len = {len(tflite_bytes)};\n"
    with open(output_header, "w") as f:
        f.write(c_str)
    print(f"Modelo guardado como {output_header} ({len(tflite_bytes)} bytes)")

convert_to_c_array(tflite_quant_model)
#include "model_data.h"
#include <TensorFlowLite_ESP32.h> // O la librería TFLite correspondiente

#Referencia al modelo cargado desde model_data.h
#const tflite::Model* model = ::tflite::GetModel(g_model);