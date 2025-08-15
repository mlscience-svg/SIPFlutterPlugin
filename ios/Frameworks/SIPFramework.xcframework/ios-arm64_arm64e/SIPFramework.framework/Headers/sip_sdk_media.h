#ifndef __SIP_SDK_MEDIA_H__
#define __SIP_SDK_MEDIA_H__
#include <stddef.h>
#include <SIPFramework/sip_sdk.h>

typedef enum
{
    NALU_TYPE_UNKNOWN = 0,
    NALU_TYPE_SLICE = 1,
    NALU_TYPE_DPA = 2,
    NALU_TYPE_DPB = 3,
    NALU_TYPE_DPC = 4,
    NALU_TYPE_IDR = 5,
    NALU_TYPE_SEI = 6,
    NALU_TYPE_SPS = 7,
    NALU_TYPE_PPS = 8,
    NALU_TYPE_AUD = 9,
    NALU_TYPE_EOSEQ = 10,
    NALU_TYPE_EOSTREAM = 11,
    NALU_TYPE_FILL = 12,
} h264_nalu_type;

typedef enum
{
    // 内部控制时序
    AUDIO_TIME_TYPE_INTERNAL = 0,
    // 自主控制时序(如 alsa 需要自己控制)
    AUDIO_TIME_TYPE_AUTONOMIC = AUDIO_TIME_TYPE_INTERNAL + 1,
} audio_time_type;

typedef enum
{
    PORT_SIGNATURE_TYPE_PLAYER = 0,
    PORT_SIGNATURE_TYPE_STREAM = 1,
    PORT_SIGNATURE_TYPE_TEE = 2,
} port_signature_type;

typedef enum
{
    PORT_CONNECT_LEFT = 0,
    PORT_CONNECT_RIGHT = 1,
} port_connect_direction;

#ifdef __cplusplus
extern "C"
{
#endif

    typedef struct video_media_config
    {
        int fps;             // 帧率
        int width;           // 宽
        int height;          // 高
        int min_block_datas; // 数分块最小数量
    } video_media_config;

    typedef struct audio_media_frame
    {
        void *buf;       // 媒体数据
        sdk_size_t size; // buf size
    } audio_media_frame;

    typedef struct sip_video_op
    {
        sdk_status_t (*codec_init)(sdk_uuid_t call_uuid,
                                   video_media_config *vid_media_config,
                                   void **user_data);  // 初始化编解码器
        sdk_status_t (*codec_deinit)(void *user_data); // 销毁编解码器
        sdk_status_t (*codec_encode)(void *user_data,
                                     sdk_timestamp_t timestamp,
                                     void *buf,
                                     unsigned *buf_size,
                                     sdk_bool_t *is_keyframe,
                                     sdk_bool_t required_keyframe); // 回调编码帧
        sdk_status_t (*codec_decode)(void *user_data,               // 自定义数据
                                     sdk_timestamp_t timestamp,     // 时间戳
                                     int type,                      // 帧类型
                                     unsigned char *data,           // 帧数据
                                     unsigned data_size);           // 回调h.264数据
    } sip_video_op;

    typedef struct sip_audio_op
    {
        void (*write_audio_media_stream_thread_create)();                        // 写音频线程创建回调
        sdk_status_t (*write_audio_media_stream)(audio_media_frame media_frame); // 写音频数据回调
        void (*write_audio_media_stream_thread_destroy)();                       // 写音频线程销毁回调
        void (*read_audio_media_stream_thread_create)();                         // 读音频线程创建回调
        audio_media_frame *(*read_audio_frame_from_stream)();                    // 读音频数据回调
        void (*read_audio_frame_from_stream_v2)(void *buf, int size);            // 读音频数据回调v2
        void (*read_audio_media_stream_thread_destroy)();                        // 读音频线程销毁回调
    } sip_audio_op;

    typedef struct sip_sdk_media_h264_fmtp
    {
        char profile_level_id[20];
        char packetization_mode[10];
    } sip_sdk_media_h264_fmtp;
    typedef struct sip_sdk_media_config
    {
        int audio_clock_rate;              // 音频时钟速率（默认 16000)
        float mic_gain;                    // mic增益（默认 1)
        float speaker_gain;                // speaker增益（默认 1)
        sdk_bool_t ns_enable;              // 是否启用噪声抑制（默认 SDK_TRUE）
        int ns_strength;                   // 噪声抑制强度(默认 -20，-1～-40)
        sdk_bool_t agc_enable;             // 是否启用自动增益（默认 SDK_TRUE）
        sdk_bool_t aec_enable;             // 是否启用回音消除（默认 SDK_TRUE）
        short int aec_elimination_time;    // 回音消除时间 （默认 30 ms）
        sip_video_op video_op;             // 视频操作
        sip_audio_op audio_op;             // 音频操作
        sdk_bool_t not_enable_encode;      // 不启用编码（关闭可以省下一些内存）（默认 SDK_FALSE)
        sdk_bool_t not_enable_decode;      // 不启用解码（关闭可以省下一些内存）（默认 SDK_FALSE)
        unsigned decode_max_width;         // 解码支持最大宽度（默认 640)
        unsigned decode_max_height;        // 解码支持最大高度 (默认 480)
        sdk_bool_t combin_sps_pps_idr;     // 组合sps pps idr (默认 SDK_FALSE)
        sip_sdk_media_h264_fmtp h264_fmtp; // H264 fmtp
    } sip_sdk_media_config;

    typedef struct sip_sdk_media_connect_param
    {
        int source;      // 源
        int destination; // 目标
    } sip_sdk_media_connect_param;

    typedef sdk_status_t (*on_audio_port_stream)(void *user_data, audio_media_frame media_frame);
    typedef sdk_status_t (*get_audio_port_stream)(void *user_data, void *buf, size_t *size);
    typedef sdk_status_t (*on_audio_destroy)(void *user_data);
    typedef struct sip_sdk_media_audio_port_param
    {
        int media_id;
        char *name;
        port_signature_type signature_type;
        port_connect_direction connect_direction;
        void *user_data;
        unsigned clock_rate;
        unsigned channel_count;
        unsigned bits_per_sample;
        unsigned samples_per_frame;
        on_audio_port_stream on_port_stream;   // 回调音频数据
        get_audio_port_stream get_port_stream; // 获取音频数据
        on_audio_destroy on_destroy;           // 销毁回调
    } sip_sdk_media_audio_port_param;

    extern sip_sdk_media_config sip_media_config;

    audio_media_frame *alloc_audio_media_frame(sdk_size_t size);

    sdk_status_t free_audio_media_frame(audio_media_frame *media_frame);

    int media_connect_id(sdk_uuid_t call_uuid);

    sdk_status_t media_connect(const sip_sdk_media_connect_param param);

    sdk_status_t media_disconnect(const sip_sdk_media_connect_param param);

    void *create_audio_port(sip_sdk_media_audio_port_param param);

    int audio_port_put_frame(void *port, const void *frame_data, unsigned frame_size);

    void destroy_audio_port(void *port);

#ifdef __cplusplus
}
#endif

#endif
