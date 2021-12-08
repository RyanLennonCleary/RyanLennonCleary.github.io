/* Simple HTTP + SSL Server Example

   This example code is in the Public Domain (or CC0 licensed, at your option.)

   Unless required by applicable law or agreed to in writing, this
   software is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
   CONDITIONS OF ANY KIND, either express or implied.
 */

#include <esp_wifi.h>
#include <esp_event.h>
#include <esp_log.h>
#include <esp_system.h>
#include <nvs_flash.h>
#include "esp_log.h"
#include <sys/param.h>
#include "esp_netif.h"
#include "esp_eth.h"
#include "protocol_examples_common.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "freertos/event_groups.h"
#include <esp_https_server.h>
#include "string.h"
#include "esp_spiffs.h"
#include "driver/adc.h"
#include "driver/uart.h"
#include "cJSON.h"
#include "driver/ledc.h"
#include "time.h"
#include "esp_vfs_fat.h"
#include "driver/sdmmc_host.h"
#include "driver/sdspi_host.h"
#include "sdmmc_cmd.h"
#include "driver/pcnt.h"

#define SSID "Smart-Bike"
#define PASSWORD "password"
#define IP_ADDRESS_1 192
#define IP_ADDRESS_2 168
#define IP_ADDRESS_3 0
#define IP_ADDRESS_4 13

#define GW_ADDRESS_1 192
#define GW_ADDRESS_2 168
#define GW_ADDRESS_3 0
#define GW_ADDRESS_4 20

#define NM_ADDRESS_1 255
#define NM_ADDRESS_2 255
#define NM_ADDRESS_3 255
#define NM_ADDRESS_4 0
#define EXAMPLE_ESP_WIFI_CHANNEL   1
#define EXAMPLE_MAX_STA_CONN       4
#define BUFFER_SIZE 5000
#define SCRATCH_BUFSIZE 8192
char scratch[SCRATCH_BUFSIZE];

//LEDC

#ifdef CONFIG_IDF_TARGET_ESP32
#define LEDC_HS_TIMER          LEDC_TIMER_0
#define LEDC_HS_MODE           LEDC_HIGH_SPEED_MODE
#define LEDC_HS_CH0_GPIO       (18)
#define LEDC_HS_CH0_CHANNEL    LEDC_CHANNEL_0
#define LEDC_HS_CH1_GPIO       (19)
#define LEDC_HS_CH1_CHANNEL    LEDC_CHANNEL_1
#endif
#define LEDC_LS_TIMER          LEDC_TIMER_1
#define LEDC_LS_MODE           LEDC_LOW_SPEED_MODE
#ifdef CONFIG_IDF_TARGET_ESP32S2BETA
#define LEDC_LS_CH0_GPIO       (34)
#define LEDC_LS_CH0_CHANNEL    LEDC_CHANNEL_0
#define LEDC_LS_CH1_GPIO       (26)
#define LEDC_LS_CH1_CHANNEL    LEDC_CHANNEL_1
#endif
#define LEDC_LS_CH2_GPIO       (25)
#define LEDC_LS_CH2_CHANNEL    LEDC_CHANNEL_2
#define LEDC_LS_CH3_GPIO       (4)
#define LEDC_LS_CH3_CHANNEL    LEDC_CHANNEL_3

#define LEDC_TEST_CH_NUM       (4)
#define LEDC_TEST_DUTY         (4000)
#define LEDC_TEST_FADE_TIME    (3000)
#define PCNT_TEST_UNIT      PCNT_UNIT_0
#define PCNT_H_LIM_VAL      10000
#define PCNT_L_LIM_VAL     -10000
#define PCNT_THRESH1_VAL    5
#define PCNT_THRESH0_VAL   -5
#define PCNT_INPUT_SIG_IO   14  // Pulse Input GPIO
#define PCNT_INPUT_CTRL_IO  25  // Control GPIO HIGH=count up, LOW=count down
#define LEDC_OUTPUT_IO      18 // Output GPIO of a sample 1 Hz pulse generator

#define PIN_NUM_MISO 33
#define PIN_NUM_MOSI 23
#define PIN_NUM_CLK  32
#define PIN_NUM_CS   5
#define ECG_SAMPLES            (1000)

/* A simple example that demonstrates how to create GET and POST
 * handlers and start an HTTPS server.
 */
/*
//CJson setup
cJSON *inputJSON;
cJSON *outputJSON;
inputJSON=cJSON_CreateObject();
outputJSON=cJSON_CreateObject();
cJSON_AddNumberToObject(inputJSON, "updateDelay", 2000);
cJSON_AddNumberToObject(outputJSON, "hall_rpm",-1);
 */
static const char *TAG = "Smart Bike";
int hall_voltage = 0;
static bool alarmRunning = false;
extern int errno;
typedef struct  ADC_PARAMS
{
    uint16_t* adc_reading_collection_samples;
    uint16_t adc_reading_collection_head;
    uint16_t* hall_reading_samples;
    uint16_t hall_reading_samples_head;
    float latitude;
    uint8_t lat_direction;
    float longitude;
    uint8_t long_direction;
    uint16_t cadence;
    struct
    {
        uint16_t previous;
        uint16_t current;
        uint16_t heartrate;
    } ecg;
    struct
    {
        uint16_t previous;
        uint16_t current;
    } pulse_counts;
    struct
    {
        TickType_t readWakeTime;
        TickType_t writeWakeTime;
        TickType_t counterWakeTime;
        TickType_t cadenceWakeTime;

    }lastWakeTimes;
} adc_reading_collection;




esp_err_t sendFromFile(const char* fileName, const char* fileType,httpd_req_t *req);

/* An HTTP GET handler */
static esp_err_t root_get_handler(httpd_req_t *req)
{
    // //ESP_LOGI(TAG, "Root Handler Start");
    sendFromFile("/spiffs/root.html","text/html",req);
    //ESP_LOGI(TAG, "Root Handler Done");
    return ESP_OK;
}

static esp_err_t setting_get_handler(httpd_req_t *req)
{
    alarmRunning = !alarmRunning;
    if(alarmRunning){
        ESP_LOGI(TAG, "Alarm On");
        // if(ledc_set_duty(alarm_channel[0].speed_mode,alarm_channel[0].channel,4000) != ESP_OK){
        //   ESP_LOGE(TAG, "Error set duty");
        //}
    }else{
        ESP_LOGI(TAG, "Alarm Off");
        //ledc_set_duty(alarm_channel[0].speed_mode,alarm_channel[0].channel,0);
    }
    httpd_resp_send(req,"200", -1);

    return ESP_OK;
}
static esp_err_t data_get_handler(httpd_req_t *req)
{
    //ESP_LOGI(TAG, "data get Start");
    sendFromFile("/spiffs/input.json","application/json",req);
    return ESP_OK;
}

static esp_err_t root_css_handler(httpd_req_t *req){
    sendFromFile("/spiffs/root.css","text/css",req);

    return ESP_OK;
}

static esp_err_t chart_js_handler(httpd_req_t *req)
{
    sendFromFile("/spiffs/Chart.bundle.min.js","text/javascript",req);

    return ESP_OK;
}

static esp_err_t root_js_handler(httpd_req_t *req)
{
    sendFromFile("/spiffs/root.js","text/javascript",req);

    return ESP_OK;
}

esp_err_t sendFromFile(const char* fileName, const char* fileType,httpd_req_t *req){
    FILE* fp = fopen(fileName ,"r");
    if (!fp){
        ESP_LOGE(TAG, "File open failed!");
        return ESP_FAIL;
    }
    int fileSize = -1;
    fseek(fp, 0L, SEEK_END);
    fileSize = ftell(fp);
    rewind(fp);
    httpd_resp_set_type(req,fileType);
    //IF file less than the buffer send it in 1 go
    if(fileSize < SCRATCH_BUFSIZE-1){
        char* data = (char*) calloc(fileSize+1,sizeof(char));
        fread(data,1, fileSize,fp);
        httpd_resp_send(req,data, -1);
        free(data);
    }
    //ELSE send it in chunks of CHUNK_SIZE
    else{
        char* chunk = scratch;
        size_t chunkSize;
        ESP_LOGI(TAG, "Sending file by chunks");
        do{
            chunkSize = fread(chunk, 1, SCRATCH_BUFSIZE, fp);
            if(chunkSize > 0){
                if (httpd_resp_send_chunk(req, chunk, chunkSize) != ESP_OK) {
                    fclose(fp);
                    ESP_LOGE(TAG, "File sending failed!");
                    /* Abort sending file */
                    httpd_resp_sendstr_chunk(req, NULL);
                    /* Respond with 500 Internal Server Error */
                    httpd_resp_send_err(req, HTTPD_500_INTERNAL_SERVER_ERROR, "Failed to send file");
                    return ESP_FAIL;
                }
            }
        }while(chunkSize != 0);
        httpd_resp_send_chunk(req, NULL, 0);
        ESP_LOGI(TAG, "Chunk send complete");
    }
    fclose(fp);
    return ESP_OK;
}


static const httpd_uri_t root = {
    .uri       = "/",
    .method    = HTTP_GET,
    .handler   = root_get_handler
};
static const httpd_uri_t settings = {
    .uri       = "/settings",
    .method    = HTTP_GET,
    .handler   = setting_get_handler
};
static const httpd_uri_t get_data = {
    .uri       = "/get_data",
    .method    = HTTP_GET,
    .handler   = data_get_handler
};
static const httpd_uri_t root_css = {
    .uri       = "/root.css",
    .method    = HTTP_GET,
    .handler   = root_css_handler
};
static const httpd_uri_t chart_js = {
    .uri       = "/chart.js",
    .method    = HTTP_GET,
    .handler   = chart_js_handler
};
static const httpd_uri_t root_js = {
    .uri       = "/root.js",
    .method    = HTTP_GET,
    .handler   = root_js_handler
};


static httpd_handle_t start_webserver(void)
{
    printf("start webserver core: %d\n", xPortGetCoreID());
    httpd_handle_t server = NULL;
    // Start the httpd server
    ESP_LOGI(TAG, "Starting server");
    httpd_ssl_config_t conf = HTTPD_SSL_CONFIG_DEFAULT();
    extern const unsigned char cacert_pem_start[] asm("_binary_cacert_pem_start");
    extern const unsigned char cacert_pem_end[]   asm("_binary_cacert_pem_end");
    conf.cacert_pem = cacert_pem_start;
    conf.cacert_len = cacert_pem_end - cacert_pem_start;
    extern const unsigned char prvtkey_pem_start[] asm("_binary_prvtkey_pem_start");
    extern const unsigned char prvtkey_pem_end[]   asm("_binary_prvtkey_pem_end");
    conf.prvtkey_pem = prvtkey_pem_start;
    conf.prvtkey_len = prvtkey_pem_end - prvtkey_pem_start;
    esp_err_t ret = httpd_ssl_start(&server, &conf);
    if (ESP_OK != ret) {
        ESP_LOGI(TAG, "Error starting server!");
        return NULL;
    }
    // Set URI handlers
    ESP_LOGI(TAG, "Registering URI handlers");
    httpd_register_uri_handler(server, &root);
    httpd_register_uri_handler(server, &settings);
    httpd_register_uri_handler(server, &get_data);
    httpd_register_uri_handler(server, &root_css);
    httpd_register_uri_handler(server, &root_js);
    httpd_register_uri_handler(server, &chart_js);

    return server;
}

static void stop_webserver(httpd_handle_t server)
{
    // Stop the httpd server
    httpd_ssl_stop(server);
}

static void disconnect_handler(void* arg, esp_event_base_t event_base,
        int32_t event_id, void* event_data)
{
    printf("disconnect handler core: %d\n", xPortGetCoreID());
    httpd_handle_t* server = (httpd_handle_t*) arg;
    if (*server) {
        stop_webserver(*server);
        *server = NULL;
    }
}

static void connect_handler(void* arg, esp_event_base_t event_base,
        int32_t event_id, void* event_data)
{
    printf("connect handler core: %d\n", xPortGetCoreID());
    httpd_handle_t* server = (httpd_handle_t*) arg;
    if (*server == NULL) {
        *server = start_webserver();
    }
}

static void wifi_event_handler(void* arg, esp_event_base_t event_base,
        int32_t event_id, void* event_data)
{
    printf("wifi event handler core: %d\n", xPortGetCoreID());
    if (event_id == WIFI_EVENT_AP_STACONNECTED) {
        wifi_event_ap_staconnected_t* event = (wifi_event_ap_staconnected_t*) event_data;

    } else if (event_id == WIFI_EVENT_AP_STADISCONNECTED) {
        wifi_event_ap_stadisconnected_t* event = (wifi_event_ap_stadisconnected_t*) event_data;

    }
}

static void startWifi()
{
    printf("start wifi core: %d\n", xPortGetCoreID());
    ESP_ERROR_CHECK(esp_netif_init());
    //ESP_ERROR_CHECK(esp_event_loop_create_default());
    esp_netif_create_default_wifi_ap();

    wifi_init_config_t cfg = WIFI_INIT_CONFIG_DEFAULT();
    ESP_ERROR_CHECK(esp_wifi_init(&cfg));

    ESP_ERROR_CHECK(esp_event_handler_register(WIFI_EVENT, ESP_EVENT_ANY_ID, &wifi_event_handler, NULL));


    wifi_config_t wifi_config = {
        .ap = {
            .ssid = SSID,
            .ssid_len = strlen(SSID),
            .channel = EXAMPLE_ESP_WIFI_CHANNEL,
            .password = PASSWORD,
            .max_connection = EXAMPLE_MAX_STA_CONN,
            .authmode = WIFI_AUTH_WPA_WPA2_PSK
        },
    };
    if (strlen(PASSWORD) == 0) {
        wifi_config.ap.authmode = WIFI_AUTH_OPEN;
    }

    ESP_ERROR_CHECK(esp_wifi_set_mode(WIFI_MODE_APSTA));
    ESP_ERROR_CHECK(esp_wifi_set_config(ESP_IF_WIFI_AP, &wifi_config));
    ESP_ERROR_CHECK(esp_wifi_start());
}

static esp_err_t spiffs_init()
{
    ESP_LOGI(TAG, "Initializing SPIFFS");

    esp_vfs_spiffs_conf_t conf = {
        .base_path = "/spiffs",
        .partition_label = NULL,
        .max_files = 5,
        .format_if_mount_failed = false
    };
    esp_err_t ret = esp_vfs_spiffs_register(&conf);

    if (ret != ESP_OK) {
        if (ret == ESP_FAIL) {
            ESP_LOGE(TAG, "Failed to mount or format filesystem");
        } else if (ret == ESP_ERR_NOT_FOUND) {
            ESP_LOGE(TAG, "Failed to find SPIFFS partition");
        } else {
            ESP_LOGE(TAG, "Failed to initialize SPIFFS (%s)", esp_err_to_name(ret));
        }
        return ESP_FAIL;
    }
    size_t total = 0, used = 0;
    ret = esp_spiffs_info(conf.partition_label, &total, &used);
    if (ret != ESP_OK) {
        ESP_LOGE(TAG, "Failed to get SPIFFS partition information (%s)", esp_err_to_name(ret));
    } else {
        ESP_LOGI(TAG, "Partition size: total: %u, used: %u", total, used);
    }

    return ESP_OK;
}

void read_data_from_file(){
    //printf("read data from file, core: %d\n", xPortGetCoreID());
    FILE* fp;
    if ((fp = fopen("/spiffs/input.json", "r")) == NULL){
        printf("Error: %s\n", strerror(errno));
    }
    char voltage_from_file[1024];
    while (fgets(voltage_from_file, 1024, fp) != NULL){
        //printf("Reading hall voltage from file: %s\n",voltage_from_file);
    }
    fclose(fp);

}
void write_data_to_file()
{

    printf("writing data to file, core: %d\n",xPortGetCoreID());
    FILE* fp;
    fp = fopen("/spiffs/input.json", "w");
    if (fp == NULL){
        printf("Got HerE!\n");
        printf("Error: %s\n",strerror(errno));
        return;
    }
    fputs("\"hall_rpm:\"",fp);
    char voltage_reading[33];
    sprintf(voltage_reading, "%d", hall_voltage);
    fputs(voltage_reading, fp);
    fputs("\n",fp);
    fclose(fp);
}

void adc_periodic_update(void* input)
{
    if (input == NULL)
    {
    ESP_LOGE(TAG,"input parameter null");

    }
    //ESP_LOGI(TAG,"input address; 0x%x\n",(uint32_t)input);
    const TickType_t xFrequency = (10) / portTICK_PERIOD_MS;
    adc_reading_collection* collection = input;
    uint16_t raw_reading = 0;
    //ESP_LOGI(TAG,"adc_init core: %d\n", xPortGetCoreID());
    adc1_config_width(ADC_WIDTH_BIT_12);
    adc1_config_channel_atten(ADC1_CHANNEL_6, ADC_ATTEN_DB_11);
    while(1)
    {
        if (collection->lastWakeTimes.readWakeTime == 0)
        {
            collection->lastWakeTimes.readWakeTime = xTaskGetTickCount();
        }
        raw_reading = adc1_get_raw(ADC1_CHANNEL_6);
        /*
        collection->ecg.previous = collection->ecg.current;
        collection->ecg.current = raw_reading;
        if (collection->ecg.current > collection->ecg.previous)
        {
            collection->adc_reading_collection_samples[collection->adc_reading_collection_head] = (uint8_t)1;
        }
        else
        {
            collection->adc_reading_collection_samples[collection->adc_reading_collection_head] = (uint8_t)0;
        }
        */
        collection->adc_reading_collection_samples[collection->adc_reading_collection_head] = raw_reading;
        collection->adc_reading_collection_head = (collection->adc_reading_collection_head + 1) % ECG_SAMPLES;
        //ESP_LOGI(TAG,"adcc reading head: %d",collection->adc_reading_collection_head);
        vTaskDelayUntil(&(collection->lastWakeTimes.readWakeTime), xFrequency);
    }
}

void adc_update_average(void* input)
{
    int sum = 0;
    const TickType_t xFrequency = (1000) / portTICK_PERIOD_MS;
    adc_reading_collection* collection = input;
    while (1){
        sum = 0;
        if (collection->lastWakeTimes.writeWakeTime == 0)
        {
            collection->lastWakeTimes.writeWakeTime = xTaskGetTickCount();
        }
        uint8_t rising_pulse = 0;
        uint8_t falling_pulse = 0;
        //ESP_LOGI(TAG,"adc reading data");
        /*
        for (int j = 0; j < ECG_SAMPLES; j++)
        {
            //ESP_LOGI(TAG,"%d: %d",(collection->adc_reading_collection_head+j)%ECG_SAMPLES,collection->adc_reading_collection_samples[(collection->adc_reading_collection_head+j)%ECG_SAMPLES]);
        }*/
        for (int i = 0; i < ECG_SAMPLES - 2; i++)
        {
            //ESP_LOGI(TAG,"i: %d",i);
            //ESP_LOGI(TAG,"array index: %d",collection->adc_reading_collection_samples[(collection->adc_reading_collection_head + i)%ECG_SAMPLES]);

            uint16_t current = collection->adc_reading_collection_samples[(collection->adc_reading_collection_head + i + 1 ) % ECG_SAMPLES];
            //ESP_LOGI(TAG,"current: %d",current);
            uint16_t previous = collection->adc_reading_collection_samples[(collection->adc_reading_collection_head + i) % ECG_SAMPLES];
            //ESP_LOGI(TAG,"previous: %d",previous);
            uint16_t next = collection->adc_reading_collection_samples[(collection->adc_reading_collection_head + i + 2) % ECG_SAMPLES];
            //ESP_LOGI(TAG,"next: %d",next);
            if (previous < 2800 && current >= 2800 && next >= current)
            {
                //ESP_LOGI(TAG,"rising_pulse");
                rising_pulse = 1;
            }
            if (previous >= 2800 && current < 2800 && next<= current)
            {
                //ESP_LOGI(TAG,"falling_pulse");
                falling_pulse = 1;
            }
            if (rising_pulse == 1 && falling_pulse == 1)
            {
                //ESP_LOGI(TAG,"increasing heartrate by 1");
                sum += 1;
            }
            if ((falling_pulse == 1 && rising_pulse == 1 )|| (falling_pulse == 1 && rising_pulse == 0))
            {
                //ESP_LOGI(TAG,"resetting pulse finders");
                falling_pulse = 0;
                rising_pulse = 0;
            }
        }
                sum *= 6;
        collection->ecg.heartrate = sum;
        vTaskDelayUntil(&(collection->lastWakeTimes.writeWakeTime), xFrequency);
    }
}

void update_pulse_count(void* input)
{
    const TickType_t xFrequency = (1000) / portTICK_PERIOD_MS;
    adc_reading_collection* collection = input;
    int16_t count = 0;
    while(1)
    {
        if (collection->lastWakeTimes.counterWakeTime == 0)
        {
            collection->lastWakeTimes.counterWakeTime = xTaskGetTickCount();
        }
        pcnt_get_counter_value(0,&count);
        ESP_LOGI(TAG, "count: %d",count);
        //ESP_LOGI(TAG, "hall_readin_samples_head %d",collection->hall_reading_samples_head);
        collection->hall_reading_samples[collection->hall_reading_samples_head] = (uint16_t)count;
        collection->hall_reading_samples_head =(collection->hall_reading_samples_head + 1) % 15;
        //ESP_LOGI(TAG,"pulse counter count: %d",count);
        collection->pulse_counts.previous = collection->pulse_counts.current;
        collection->pulse_counts.current = count;
        vTaskDelayUntil(&(collection->lastWakeTimes.counterWakeTime), xFrequency);
    }
}

void pulse_counter_init(void* input)
{
    //vTaskDelete(NULL);
    pcnt_config_t pcnt_config = {
        // Set PCNT input signal and control GPIOs
        .pulse_gpio_num = PCNT_INPUT_SIG_IO,
        .ctrl_gpio_num = PCNT_INPUT_CTRL_IO,
        .channel = PCNT_CHANNEL_0,
        .unit = PCNT_TEST_UNIT,
        // What to do on the positive / negative edge of pulse input?
        .pos_mode = PCNT_COUNT_INC,   // Count up on the positive edge
        .neg_mode = PCNT_COUNT_DIS,   // Keep the counter value on the negative edge
        // What to do when control input is low or high?
        .lctrl_mode = PCNT_MODE_KEEP, // Reverse counting direction if low
        .hctrl_mode = PCNT_MODE_KEEP,    // Keep the primary counter mode if high
        // Set the maximum and minimum limit values to watch
        .counter_h_lim = PCNT_H_LIM_VAL,
        .counter_l_lim = PCNT_L_LIM_VAL,
    };
    /* Initialize PCNT unit */
    pcnt_unit_config(&pcnt_config);

    /* Configure and enable the input filter */
    pcnt_set_filter_value(PCNT_TEST_UNIT, 100);
    pcnt_filter_enable(PCNT_TEST_UNIT);

    /* Set threshold 0 and 1 values and enable events to watch */
    pcnt_set_event_value(PCNT_TEST_UNIT, PCNT_EVT_THRES_1, PCNT_THRESH1_VAL);
    pcnt_event_enable(PCNT_TEST_UNIT, PCNT_EVT_THRES_1);
    pcnt_set_event_value(PCNT_TEST_UNIT, PCNT_EVT_THRES_0, PCNT_THRESH0_VAL);
    pcnt_event_enable(PCNT_TEST_UNIT, PCNT_EVT_THRES_0);
    /* Enable events on zero, maximum and minimum limit values */
    pcnt_event_enable(PCNT_TEST_UNIT, PCNT_EVT_ZERO);
    pcnt_event_enable(PCNT_TEST_UNIT, PCNT_EVT_H_LIM);
    pcnt_event_enable(PCNT_TEST_UNIT, PCNT_EVT_L_LIM);

    /* Initialize PCNT's counter */
    pcnt_counter_pause(PCNT_TEST_UNIT);
    pcnt_counter_clear(PCNT_TEST_UNIT);

    /* Register ISR handler and enable interrupts for PCNT unit */

    /* Everything is set up, now go to counting */
    pcnt_counter_resume(PCNT_TEST_UNIT);
    BaseType_t returned = xTaskCreate(
            update_pulse_count,
            "update_pulse_count",
            6250,
            input,
            tskIDLE_PRIORITY,
            NULL
            );
    if (returned != pdPASS)
    {
        //ESP_LOGI(TAG,"error creating pulse count update");
    }
    vTaskDelete(NULL);
}
void gps_test(void* input)
{
    const int uart_num = UART_NUM_1;
    adc_reading_collection* collection = input;
    uart_config_t uart_config = {
        .baud_rate = 9600,
        .data_bits = UART_DATA_8_BITS,
        .parity = UART_PARITY_DISABLE,
        .stop_bits = UART_STOP_BITS_1,
        .flow_ctrl = UART_HW_FLOWCTRL_CTS_RTS,
        .rx_flow_ctrl_thresh = 16,
    };
    ESP_ERROR_CHECK(uart_param_config(uart_num, &uart_config));
    ESP_ERROR_CHECK(uart_set_pin(UART_NUM_1, 18, 19, 21, 22));
    const int uart_buffer_size = (1024 * 2);
    QueueHandle_t uart_queue;
    ESP_ERROR_CHECK(uart_driver_install(UART_NUM_1, uart_buffer_size,uart_buffer_size, 10, &uart_queue, 0));
    uint8_t data[2048];
    int length = 0;
    while(1)
    {
        ESP_ERROR_CHECK(uart_get_buffered_data_len(uart_num, (size_t*)&length));
        if (length > 0)
        {
            uint16_t data_start = 0;
            length = uart_read_bytes(uart_num, data, length, 100);
            for (int i = 0; i < length; i++)
            {
                if(data[i] == 'L' && data[i+1] =='L')
                {
                    data_start = i - 4;
                    data[data_start+100]= '\0';
                    ////ESP_LOGI(TAG,"%s",data+data_start);
                    //ESP_LOGI(TAG,"data start: %c",data[data_start]);
                    //ESP_LOGI(TAG, "data type end: %c", data[data_start + 5]);
                    //ESP_LOGI(TAG,"token1: %s", token);
                    float latitude = 0;
                    int latitude_valid = 0;
                    float longitude = 0;
                    int longitude_valid = 0;
                    uint8_t n_s = 0;
                    uint8_t e_w = 0;
                    uint8_t j = 0;
                    while(j < 4)
                    {
                        if (data[data_start] == ',')
                        {
                            j++;
                            switch(j)
                            {
                                case 1:
                                    if (data[data_start + 1] != ',')
                                    {
                                        latitude = strtof((char*)(data + data_start + 1),NULL);
                                        latitude_valid = 1;
                                        //ESP_LOGI(TAG,"latitude: %f",latitude);
                                    }
                                    break;
                                case 2:
                                    n_s = data[data_start + 1];
                                    //ESP_LOGI(TAG,"north or sourth: %d",n_s);
                                    break;
                                case 3:
                                    if(data[data_start + 1] != ',')
                                    {
                                        longitude = strtof((  char*)( data + data_start + 1 ),NULL);
                                        longitude_valid = 1;
                                        //ESP_LOGI(TAG,"longtidude: %f",longitude);
                                    }
                                    break;
                                case 4:
                                    e_w = data[data_start + 1];
                                    //ESP_LOGI(TAG,"east or west: %d",e_w);
                                    break;
                            }
                        }
                        data_start++;
                    }
                    if (latitude_valid && longitude_valid)
                    {
                        collection->latitude = latitude;
                        collection->longitude = longitude;
                        collection->lat_direction = n_s;
                        collection->long_direction = e_w;
                    }
                }
            }
        }
    }
}

void calculate_cadence(void* input)
{
    const TickType_t xFrequency = (1000) / portTICK_PERIOD_MS;
    adc_reading_collection* collection = input;
    while(1)
    {
        if (collection->lastWakeTimes.cadenceWakeTime == 0)
        {
            collection->lastWakeTimes.cadenceWakeTime = xTaskGetTickCount();
        }
        uint16_t next = collection->hall_reading_samples[((collection->hall_reading_samples_head) + 14) %15];
        ESP_LOGI(TAG,"sample pointer: %d",((collection->hall_reading_samples_head) + 14)%15);
        ESP_LOGI(TAG, "cadence next: %d",next);
        uint16_t previous = collection->hall_reading_samples[(collection->hall_reading_samples_head) ];
        ESP_LOGI(TAG, "cadence previous: %d",previous);
        uint16_t cadence = (next - previous)*4;
        ESP_LOGI(TAG,"cadence: %d", cadence);
        collection->cadence = cadence;
        vTaskDelayUntil(&(collection->lastWakeTimes.cadenceWakeTime), xFrequency);
    }
}
void app_main(void)
{
    printf("root get handler core: %d\n", xPortGetCoreID());
    static httpd_handle_t server = NULL;

    ESP_ERROR_CHECK(nvs_flash_init());
    ESP_ERROR_CHECK(esp_netif_init());
    ESP_ERROR_CHECK(esp_event_loop_create_default());
    //ESP_LOGI(TAG,"flash init complete");
    //    ESP_ERROR_CHECK(esp_event_handler_register(IP_EVENT, IP_EVENT_STA_GOT_IP, &connect_handler, &server));

    /* Register event handlers to start server when Wi-Fi or Ethernet is connected,
     * and stop server when disconnection happens.
     */

#ifdef CONFIG_EXAMPLE_CONNECT_WIFI
    ESP_ERROR_CHECK(esp_event_handler_register(IP_EVENT, IP_EVENT_STA_GOT_IP, &connect_handler, &server));
    ESP_ERROR_CHECK(esp_event_handler_register(WIFI_EVENT, WIFI_EVENT_STA_DISCONNECTED, &disconnect_handler, &server));
#endif // CONFIG_EXAMPLE_CONNECT_WIFI
#ifdef CONFIG_EXAMPLE_CONNECT_ETHERNET
    ESP_ERROR_CHECK(esp_event_handler_register(IP_EVENT, IP_EVENT_ETH_GOT_IP, &connect_handler, &server));
    ESP_ERROR_CHECK(esp_event_handler_register(ETH_EVENT, ETHERNET_EVENT_DISCONNECTED, &disconnect_handler, &server));
#endif // CONFIG_EXAMPLE_CONNECT_ETHERNET

    /* This helper function configures Wi-Fi or Ethernet, as selected in menuconfig.
     * Read "Establishing Wi-Fi or Ethernet Connection" section in
     * examples/protocols/README.md for more information about this function.
     */
    ESP_LOGI(TAG,"starting connect");
    ESP_ERROR_CHECK(example_connect());
    ESP_LOGI(TAG ,"starting spiffs init");
    ESP_ERROR_CHECK(spiffs_init());
    ESP_LOGI(TAG, "Using SPI peripheral");

    /*
    sdmmc_host_t host = SDSPI_HOST_DEFAULT();
    sdspi_slot_config_t slot_config = SDSPI_SLOT_CONFIG_DEFAULT();
    host.max_freq_khz = 1000;
    slot_config.gpio_miso = PIN_NUM_MISO;
    slot_config.gpio_mosi = PIN_NUM_MOSI;
    slot_config.gpio_sck  = PIN_NUM_CLK;
    slot_config.gpio_cs   = PIN_NUM_CS;
    esp_vfs_fat_sdmmc_mount_config_t mount_config = {
        .format_if_mount_failed = false,
        .max_files = 5,
        .allocation_unit_size = 16 * 1024
    };
    sdmmc_card_t* card;
    esp_err_t ret = esp_vfs_fat_sdmmc_mount("/sdcard", &host, &slot_config, &mount_config, &card);

    if (ret != ESP_OK) {
        if (ret == ESP_FAIL) {
            ESP_LOGE(TAG, "Failed to mount filesystem. "
                    "If you want the card to be formatted, set format_if_mount_failed = true.");
        } else {
            ESP_LOGE(TAG, "Failed to initialize the card (%s). "
                    "Make sure SD card lines have pull-up resistors in place.", esp_err_to_name(ret));
        }
        //return;
    }

    // Card has been initialized, print its properties
    sdmmc_card_print_info(stdout, card);
    */
    //startWifi();
    //LEDC INIT
    int ch;

    /*
     * Prepare and set configuration of timers
     * that will be used by LED Controller
     */
    ledc_timer_config_t ledc_timer = {
        .duty_resolution = LEDC_TIMER_13_BIT, // resolution of PWM duty
        .freq_hz = 500,                      // frequency of PWM signal
        .speed_mode = LEDC_LS_MODE,           // timer mode
        .timer_num = LEDC_LS_TIMER,            // timer index
        .clk_cfg = LEDC_AUTO_CLK,              // Auto select the source clock
    };
    // Set configuration of timer0 for high speed channels
    ledc_timer_config(&ledc_timer);
#ifdef CONFIG_IDF_TARGET_ESP32
    // Prepare and set configuration of timer1 for low speed channels
    ledc_timer.speed_mode = LEDC_HS_MODE;
    ledc_timer.timer_num = LEDC_HS_TIMER;
    ledc_timer_config(&ledc_timer);
#endif
    /*
     * Prepare individual configuration
     * for each channel of LED Controller
     * by selecting:
     * - controller's channel number
     * - output duty cycle, set initially to 0
     * - GPIO number where LED is connected to
     * - speed mode, either high or low
     * - timer servicing selected channel
     *   Note: if different channels use one timer,
     *         then frequency and bit_num of these channels
     *         will be the same
     */
    ledc_channel_config_t ledc_channel[LEDC_TEST_CH_NUM] = {
#ifdef CONFIG_IDF_TARGET_ESP32
        {
            .channel    = LEDC_HS_CH0_CHANNEL,
            .duty       = 0,
            .gpio_num   = LEDC_HS_CH0_GPIO,
            .speed_mode = LEDC_HS_MODE,
            .hpoint     = 0,
            .timer_sel  = LEDC_HS_TIMER
        },
        {
            .channel    = LEDC_HS_CH1_CHANNEL,
            .duty       = 0,
            .gpio_num   = LEDC_HS_CH1_GPIO,
            .speed_mode = LEDC_HS_MODE,
            .hpoint     = 0,
            .timer_sel  = LEDC_HS_TIMER
        },
#elif defined CONFIG_IDF_TARGET_ESP32S2BETA
        {
            .channel    = LEDC_LS_CH0_CHANNEL,
            .duty       = 0,
            .gpio_num   = LEDC_LS_CH0_GPIO,
            .speed_mode = LEDC_LS_MODE,
            .hpoint     = 0,
            .timer_sel  = LEDC_LS_TIMER
        },
        {
            .channel    = LEDC_LS_CH1_CHANNEL,
            .duty       = 0,
            .gpio_num   = LEDC_LS_CH1_GPIO,
            .speed_mode = LEDC_LS_MODE,
            .hpoint     = 0,
            .timer_sel  = LEDC_LS_TIMER
        },
#endif
        {
            .channel    = LEDC_LS_CH2_CHANNEL,
            .duty       = 0,
            .gpio_num   = LEDC_LS_CH2_GPIO,
            .speed_mode = LEDC_LS_MODE,
            .hpoint     = 0,
            .timer_sel  = LEDC_LS_TIMER
        },
        {
            .channel    = LEDC_LS_CH3_CHANNEL,
            .duty       = 0,
            .gpio_num   = LEDC_LS_CH3_GPIO,
            .speed_mode = LEDC_LS_MODE,
            .hpoint     = 0,
            .timer_sel  = LEDC_LS_TIMER
        },
    };

    // Set LED Controller with previously prepared configuration
    for (ch = 0; ch < LEDC_TEST_CH_NUM; ch++) {
        ledc_channel_config(&ledc_channel[ch]);
    }

    // Initialize fade service.
    ledc_fade_func_install(0);


    //Ryan's stuff

    adc_reading_collection* collection = calloc(1, sizeof *collection);
    //ESP_LOGI(TAG,"colection address: 0x%x\n",(uint32_t)collection);
    uint16_t* samples = calloc(ECG_SAMPLES, sizeof *samples);
    uint16_t* hall_samples = calloc(15, sizeof *hall_samples);
    collection->hall_reading_samples = hall_samples;
    collection->hall_reading_samples_head = 0;
    //ESP_LOGI(TAG,"samples address: 0x%x\n",(uint32_t)samples);
    collection->adc_reading_collection_head = 0;
    collection->adc_reading_collection_samples = samples;
    collection->lastWakeTimes.readWakeTime = 0;
    collection->lastWakeTimes.writeWakeTime = 0;
    collection->latitude = 0;
    collection->longitude = 0;
    collection->lat_direction = 'X';
    collection->long_direction = 'X';
    collection->pulse_counts.current = 0;
    collection->pulse_counts.previous = 0;
    collection->cadence = 0;

    BaseType_t xReturned2 = xTaskCreate(
            adc_periodic_update,
            "adc_read",
            6250,
            collection,
            tskIDLE_PRIORITY,
            NULL );
    if (xReturned2 != pdPASS)
    {
        ESP_LOGI(TAG,"failed to create task\n");
    }
    BaseType_t xReturned3 = xTaskCreate(
            adc_update_average,
            "adc_update_average",
            6250,
            collection,
            tskIDLE_PRIORITY,
            NULL );

    if (xReturned3 != pdPASS)
    {
        ESP_LOGI(TAG,"failed to create task\n");
    }

    BaseType_t xReturned4 = xTaskCreate(
            pulse_counter_init,
            "pulse_counter_init",
            6250 ,
            collection,
            tskIDLE_PRIORITY,
            NULL
            );
    if (xReturned4 != pdPASS)
    {
        ESP_LOGI(TAG, "failed to create task");
    }
    ESP_LOGI(TAG,"running gps test now");

    BaseType_t xReturned5 = xTaskCreatePinnedToCore(
            gps_test,
            "gps_test",
            6250,
            collection,
            tskIDLE_PRIORITY,
            NULL,
            1
            );
    if (xReturned5 != pdPASS)
    {
        ESP_LOGI(TAG, "failed to create task");

    }
    BaseType_t xReturned6 = xTaskCreate(
            calculate_cadence,
            "calculate_cadence",
            6250,
            collection,
            tskIDLE_PRIORITY,
            NULL
            );
    if (xReturned6 != pdPASS)
    {
        ESP_LOGI(TAG, "failed to create task");

    }
    ESP_LOGI(TAG,"end of main\n");
    time_t t;
    time(&t);
    struct tm * timeinfo;
    timeinfo = localtime (&t);
    int old_hr = timeinfo->tm_hour;
    ESP_LOGI(TAG,"time info");
    /*char buffer[256];
    char outbuffer[512];
    ESP_LOGI(TAG,"allocate");
    sprintf(buffer, "/sdcard/logFile.csv");
    ESP_LOGI(TAG,"opening file %s",buffer);
    FILE* outfile = fopen(buffer,"w");
    if(!outfile){
        printf("FILE FAIL: %s",strerror(errno));
        ESP_LOGE(TAG,"FO FAIL");
    }
    fclose(outfile);*/
    while (1)
    {
        time(&t);
        timeinfo = localtime (&t);
        /*
        if(timeinfo->tm_hour != old_hr){
            ESP_LOGI(TAG,"Starting new log");
            old_hr = timeinfo->tm_hour;
            */
            FILE* fp;
            if ((fp = fopen("/spiffs/input.json","w")) == NULL)
            {
                printf("failure ot open file probaby\n");
                return;
            }

            fputs("{\n\"heartrate\":",fp);
            uint8_t field[33];
            sprintf((char*)field, "%d", collection->ecg.heartrate);
            fputs((char*)field, fp);
            //ESP_LOGI(TAG, "heartrate: %d", collection->ecg.heartrate);

            fputs(",\n\"latitude\":",fp);
            sprintf((char*)field, "%f", collection->latitude / 100);
            fputs((char*)field, fp);
            //ESP_LOGI(TAG,"latitude: %f %c", collection->latitude / 100.0, collection->lat_direction);

            fputs(",\n\"latitudeDir\":",fp);
            sprintf((char*)field, "\"%c\"", collection->lat_direction);
            fputs((char*)field, fp);

            fputs(",\n\"longitude\":",fp);
            sprintf((char*)field, "%f", collection->longitude / 100);
            fputs((char*)field,fp);
            //ESP_LOGI(TAG,"longitude %f %c", collection->longitude / 100.00, collection->long_direction);

            fputs(",\n\"longitudeDir\":",fp);
            sprintf((char*)field, "\"%c\"", collection->long_direction);
            fputs((char*)field, fp);

            fputs(",\n\"cadence\":",fp);
            sprintf((char*)field,"\"%d\"",collection->cadence);
            fputs((char*)field,fp);
            //ESP_LOGI(TAG, "cadence: %d", collection->cadence);

            fputs("}",fp);

            fclose(fp);
            read_data_from_file();
            /*outfile = fopen(buffer,"a");
            if(outfile){
                sprintf(outbuffer,"%d,%f,%c,%f,%c,%d\n",collection->ecg.heartrate,collection->latitude/100,collection->lat_direction,collection->longitude/100,collection->long_direction,collection->cadence);
                //ESP_LOGI(TAG,"about to write files %s", outbuffer);
                fprintf(outfile,outbuffer);
                //ESP_LOGI(TAG,"wrote file");
                fclose(outfile);
            }else{
                ESP_LOGE(TAG, "file not open in loop");
            }*/
            if(alarmRunning){
                //printf("3. LEDC set duty = %d without fade\n", LEDC_TEST_DUTY);
                for (ch = 0; ch < LEDC_TEST_CH_NUM; ch++) {
                    ledc_set_duty(ledc_channel[ch].speed_mode, ledc_channel[ch].channel, LEDC_TEST_DUTY);
                    ledc_update_duty(ledc_channel[ch].speed_mode, ledc_channel[ch].channel);
                }

            }else{
                for (ch = 0; ch < LEDC_TEST_CH_NUM; ch++) {
                    ledc_set_duty(ledc_channel[ch].speed_mode, ledc_channel[ch].channel, 0);
                    ledc_update_duty(ledc_channel[ch].speed_mode, ledc_channel[ch].channel);
                }
            }
            vTaskDelay(pdMS_TO_TICKS(1000));

    }
}
