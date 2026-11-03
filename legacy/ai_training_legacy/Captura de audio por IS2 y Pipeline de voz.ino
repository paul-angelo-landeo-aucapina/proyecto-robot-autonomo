/**
 * ROBOT DE TRANSPORTE - FIRMWARE AUDIO ESP32-S3
 * Periféricos: Micrófono I2S INMP441 + Amplificador I2S MAX98357A
 * Framework: ESP-IDF con FreeRTOS
 */

#include <stdio.h>
#include <string.h>
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "driver/i2s_std.h"
#include "driver/uart.h"
#include "esp_log.h"

static const char *TAG = "AUDIO_VOICE_S3";

// Pines Micrófono INMP441 (I2S RX)
#define I2S_MIC_BCLK   GPIO_NUM_4
#define I2S_MIC_WS     GPIO_NUM_5
#define I2S_MIC_DIN    GPIO_NUM_6

// Pines DAC MAX98357A (I2S TX)
#define I2S_SPK_BCLK   GPIO_NUM_15
#define I2S_SPK_WS     GPIO_NUM_16
#define I2S_SPK_DOUT   GPIO_NUM_7

#define UART_TX_TO_MAIN GPIO_NUM_17
#define UART_RX_FROM_MAIN GPIO_NUM_18

i2s_chan_handle_t rx_handle = NULL;
i2s_chan_handle_t tx_handle = NULL;

void init_i2s_inmp441_and_spk() {
    i2s_chan_config_t chan_cfg = I2S_CHANNEL_DEFAULT_CONFIG(I2S_NUM_0, I2S_ROLE_MASTER);
    ESP_ERROR_CHECK(i2s_new_channel(&chan_cfg, &tx_handle, &rx_handle));

    // Configuración para el micrófono INMP441 (16 kHz, 16-bit, Mono)
    i2s_std_config_t std_cfg_rx = {
        .clk_cfg = I2S_STD_CLK_DEFAULT_CONFIG(16000),
        .slot_cfg = I2S_STD_PHILIPS_SLOT_DEFAULT_CONFIG(I2S_DATA_BIT_WIDTH_16BIT, I2S_SLOT_MODE_MONO),
        .gpio_cfg = {
            .mclk = I2S_GPIO_UNUSED,
            .bclk = I2S_MIC_BCLK,
            .ws   = I2S_MIC_WS,
            .dout = I2S_GPIO_UNUSED,
            .din  = I2S_MIC_DIN
        },
    };
    ESP_ERROR_CHECK(i2s_channel_init_std_mode(rx_handle, &std_cfg_rx));
    ESP_ERROR_CHECK(i2s_channel_enable(rx_handle));

    // Configuración para el parlante MAX98357A (16 kHz, 16-bit, Mono)
    i2s_std_config_t std_cfg_tx = {
        .clk_cfg = I2S_STD_CLK_DEFAULT_CONFIG(16000),
        .slot_cfg = I2S_STD_PHILIPS_SLOT_DEFAULT_CONFIG(I2S_DATA_BIT_WIDTH_16BIT, I2S_SLOT_MODE_MONO),
        .gpio_cfg = {
            .mclk = I2S_GPIO_UNUSED,
            .bclk = I2S_SPK_BCLK,
            .ws   = I2S_SPK_WS,
            .dout = I2S_SPK_DOUT,
            .din  = I2S_GPIO_UNUSED
        },
    };
    ESP_ERROR_CHECK(i2s_channel_init_std_mode(tx_handle, &std_cfg_tx));
    ESP_ERROR_CHECK(i2s_channel_enable(tx_handle));
}

void send_command_to_main_esp32(const char *cmd) {
    uart_write_bytes(UART_NUM_1, cmd, strlen(cmd));
    uart_write_bytes(UART_NUM_1, "\n", 1);
}

// Tarea para captura de audio y procesamiento de comandos (ESP-SR)
void audio_recognition_task(void *pvParameters) {
    size_t bytes_read = 0;
    int16_t audio_buffer[512];

    ESP_LOGI(TAG, "Iniciando pipeline de escucha I2S...");

    while (1) {
        // Lectura continua de muestras digitales desde el INMP441
        esp_err_t ret = i2s_channel_read(rx_handle, audio_buffer, sizeof(audio_buffer), &bytes_read, portMAX_DELAY);
        
        if (ret == ESP_OK && bytes_read > 0) {
            /*
             * En un despliegue completo de ESP-SR:
             * 1. Se entregan las muestras a wakenet_detect()
             * 2. Si detecta la palabra de activación, pasa a multinet_detect()
             * 3. Si coincide con comando en español (ej. "Avanzar", ID = 1):
             */
            
            // Simulación lógica de validación de orden
            bool command_avanzar_detected = false; 
            
            if (command_avanzar_detected) {
                ESP_LOGI(TAG, "Comando 'Avanzar' identificado.");
                send_command_to_main_esp32("CMD_AVANZAR");
            }
        }
        vTaskDelay(pdMS_TO_TICKS(10));
    }
}

void app_main(void) {
    const uart_config_t uart_config = {
        .baud_rate = 115200,
        .data_bits = UART_DATA_8_BITS,
        .parity    = UART_PARITY_DISABLE,
        .stop_bits = UART_STOP_BITS_1,
        .flow_ctrl = UART_HW_FLOWCTRL_DISABLE
    };
    uart_param_config(UART_NUM_1, &uart_config);
    uart_set_pin(UART_NUM_1, UART_TX_TO_MAIN, UART_RX_FROM_MAIN, UART_PIN_NO_CHANGE, UART_PIN_NO_CHANGE);
    uart_driver_install(UART_NUM_1, 1024, 0, 0, NULL, 0);

    init_i2s_inmp441_and_spk();

    // Creación de la tarea de audio en el Core 1 del ESP32-S3
    xTaskCreatePinnedToCore(audio_recognition_task, "audio_rec_task", 8192, NULL, 5, NULL, 1);
}
