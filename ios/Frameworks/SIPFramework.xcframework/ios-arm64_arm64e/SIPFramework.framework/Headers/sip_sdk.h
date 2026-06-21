#ifndef __SIP_SDK_H__
#define __SIP_SDK_H__
#include <time.h>
#include <stdint.h>

// 最大自定义消息头数量
#define SDK_MAX_CUSTOM_HEADERS 5

#ifdef __cplusplus
extern "C"
{
#endif

    typedef int sdk_bool_t;
    typedef int sdk_call_t;
    typedef int sdk_status_t;
    typedef int sdk_message_t;
    typedef int sdk_dtmf_info_t;
    typedef int sdk_input_video_t;
    typedef uint64_t sdk_size_t;
    typedef uint64_t sdk_uuid_t;
    typedef uint64_t sdk_timestamp_t;

    enum sdk_constants_
    {
        /** Status is OK. */
        SDK_SUCCESS = 0,
        /** Status Common Error. */
        SDK_ERROR_COMMON = -1,

        /** True value. */
        SDK_TRUE = 1,

        /** False value. */
        SDK_FALSE = 0,

        /* IP 呼叫 */
        SDK_CALL_TYPE_IP = 0,

        /* IP 呼叫 TCP 方式*/
        SDK_CALL_TYPE_IP_TCP = SDK_CALL_TYPE_IP + 1,

        /* 服务器呼叫 */
        SDK_CALL_TYPE_SERVER = SDK_CALL_TYPE_IP_TCP + 1,

        /* IP 消息 */
        SDK_MESSAGE_TYPE_IP = 0,

        /* IP 消息 TCP 方式*/
        SDK_MESSAGE_TYPE_IP_TCP = SDK_MESSAGE_TYPE_IP + 1,

        /* 服务器消息 */
        SDK_MESSAGE_TYPE_SERVER = SDK_MESSAGE_TYPE_IP_TCP + 1,

        /* RFC2833 消息 */
        SDK_DTMF_RFC2833_TYPE = 0,

        /* 普通 info 消息 */
        SDK_DTMF_INFO_TYPE = SDK_DTMF_RFC2833_TYPE + 1,

        /* 自定义 info 消息 */
        SDK_DTMF_INFO_TYPE_CUSTOM = SDK_DTMF_INFO_TYPE + 1,

        /* 呼叫状态 */
        CALL_STATE_NULL = 0,
        /* 呼叫状态 正在呼叫 */
        CALL_STATE_CALLING = CALL_STATE_NULL + 1,
        /* 呼叫状态 正在被叫叫 */
        CALL_STATE_INCOMING = CALL_STATE_CALLING + 1,
        /* 呼叫状态 回铃音 */
        CALL_STATE_EARLY = CALL_STATE_INCOMING + 1,
        /* 呼叫状态 正在连接 */
        CALL_STATE_CONNECTING = CALL_STATE_EARLY + 1,
        /* 呼叫状态 连接成功 */
        CALL_STATE_CONFIRMED = CALL_STATE_CONNECTING + 1,
        /* 呼叫状态 断开连接 */
        CALL_STATE_DISCONNECTED = CALL_STATE_CONFIRMED + 1,

        /* 通知对方发送关键帧 */
        SDK_MEDIA_NOTIFICATION_SEND_KEYFRAME = 10000,
    };

    typedef enum
    {
        /** license 测试使用 */
        SDK_LICENSE_TYPE_TEST = 0,
        /** license 时间授权 */
        SDK_LICENSE_TYPE_AUTHORIZATION_TIME = SDK_LICENSE_TYPE_TEST + 1,
        /** license 永久授权 */
        SDK_LICENSE_TYPE_AUTHORIZATION_ALWAYS = SDK_LICENSE_TYPE_AUTHORIZATION_TIME + 1,
        /** license 内部使用 */
        SDK_LICENSE_TYPE_AUTHORIZATION_INTERNAL = SDK_LICENSE_TYPE_AUTHORIZATION_ALWAYS + 1,
    } license_type;

    typedef struct
    {
        int count;              // stun 服务器数量
        char servers[8][64];    // stun 服务器地址
        sdk_bool_t enable_ipv6; // 是否使用 ipv6
    } sip_sdk_stun_config;

    typedef struct
    {
        sdk_bool_t enable; // 是否开启turn
        char *server;      // turn 服务器地址 HOST:PORT/DOMAIN:PORT
        char *realm;       // realm
        char *username;    // username
        char *password;    // password
    } sip_sdk_turn_config;

    typedef struct sip_header
    {
        char *key;
        char *value;
    } sip_header;

    typedef struct sip_sdk_local_config
    {
        char transport[16];               // transport
        unsigned port;                    // 端口
        char username[32];                // 用户名
        char bound_addr[46];              // 本地绑定指定网卡IP
        char public_addr[46];             // 公网IP配置（如果SDK运行在公网环境可以配置公网IP便于穿透）
        sdk_bool_t enable_stream_control; // 流发送控制
        int stream_elapsed;               // 流经过时间
        unsigned lock_codec;              // 锁定编解码器
    } sip_sdk_local_config;

    typedef struct sip_sdk_ip_change_param
    {
        sdk_bool_t restart;     // 是否重启
        unsigned restart_delay; // 重启延迟，单位毫秒，默认为20ms
    } sip_sdk_ip_change_param;

    typedef struct sip_sdk_registrar_config
    {
        char *domain;                               // 域
        char *username;                             // 用户名
        char *password;                             // 密码
        char *transport;                            // transport
        char *server_addr;                          // 服务器地址
        unsigned server_port;                       // 服务器端口
        sip_header headers[SDK_MAX_CUSTOM_HEADERS]; // sip header
        char *proxy;                                // 代理地址
        unsigned proxy_port;                        // 代理端口
        sdk_bool_t srtp_keying;                     // srtp_keying
        sdk_bool_t enable_stream_control;           // 流发送控制
        int stream_elapsed;                         // 流经过时间
        unsigned lock_codec;                        // 锁定编解码器
        sip_sdk_turn_config turn_config;            // turn 服务器
    } sip_sdk_registrar_config;

    typedef struct sip_sdk_find_incoming_param
    {
        int transport_type;
        char transport_name[16];
        char to_domain[128];
        char to_username[64];
        char from_domain[128];
        char from_username[64];
        char request_domain[128];
        char request_username[64];
    } sip_sdk_find_incoming_param;

    typedef struct sip_sdk_call_param
    {
        sdk_call_t call_type;                       // 呼叫类型
        char *username;                             // 呼叫账号
        char *remote_ip;                            // 远程IP
        sip_header headers[SDK_MAX_CUSTOM_HEADERS]; // sip header
        sdk_uuid_t call_uuid;                       // 呼叫ID
        sdk_bool_t transmit_video;                  // 是否传输视频
        sdk_bool_t transmit_sound;                  // 是否传输声音
    } sip_sdk_call_param;

    typedef struct sip_sdk_answer_param
    {
        unsigned code;             // 接听状态码
        sdk_uuid_t call_uuid;      // 呼叫ID
        sdk_bool_t transmit_video; // 是否传输视频
        sdk_bool_t transmit_sound; // 是否传输声音
    } sip_sdk_answer_param;

    typedef struct sip_sdk_hangup_param
    {
        unsigned code;        // 挂断状态码
        sdk_uuid_t call_uuid; // 呼叫ID
    } sip_sdk_hangup_param;

    typedef struct sip_sdk_message_param
    {
        sdk_message_t message_type; // 消息类型
        char *username;             // 对方账号
        char *remote_ip;            // 远程IP
        char *content;              // 消息内容
    } sip_sdk_message_param;

    typedef struct sip_sdk_dtmf_info_param
    {
        sdk_dtmf_info_t dtmf_info_type; // info消息类型
        sdk_uuid_t call_uuid;           // 呼叫ID
        char *content_type;             // 内容类型
        char *content;                  // 消息内容
    } sip_sdk_dtmf_info_param;

    typedef struct sip_sdk_call_status_param
    {
        sdk_uuid_t call_uuid;   // 呼叫ID
        sdk_status_t state;     // 状态
        int last_status;        // 状态码
        char *last_status_text; // 消息内容
    } sip_sdk_call_status_param;

    typedef struct sip_sdk_observer
    {
        void (*on_log_callback)(int level, const char *data, int len);
        void (*on_init_completed)(sdk_status_t state, const char *msg);
        void (*on_stop_completed)();
        void (*on_registrar_state)(sdk_status_t state);
        void (*on_incoming_call)(sip_sdk_call_param call_param);
        void (*on_find_incoming)(int *type, sip_sdk_find_incoming_param find_param);
        void (*on_dtmf_info)(sip_sdk_dtmf_info_param dtmf_info_param);
        void (*on_message)(sip_sdk_message_param message_param);
        void (*on_message_state)(sdk_status_t state, sip_sdk_message_param message_param);
        void (*on_call_status)(sip_sdk_call_status_param param);
        void (*expire_warning_callback)(time_t expire_time, time_t current_time);
        void (*activity_check_callback)();
    } sip_sdk_observer;

    typedef struct sip_sdk_common_config
    {
        int log_level;                           // 日志等级
        unsigned port;                           // 默认端口
        sdk_bool_t sdk_run;                      // 是否运行SDK
        char user_agent[32];                     // user agent
        int worker_thread_count;                 // 工作线程数量
        sdk_bool_t update_route;                 // 是否更新路由
        sdk_bool_t null_audio_enable;            // 是否启用空音频
        sdk_bool_t video_enable;                 // 是否启用视频
        sdk_bool_t video_out_auto_transmit;      // 视频输出自动传输
        sip_sdk_observer *sdk_observer;          // 状态回调
        sdk_bool_t allow_multiple_connections;   // 允许多个连接
        sdk_bool_t domain_name_direct_registrar; // 域名注册
        sdk_bool_t transport_stun_server;        // 是否使用stun解析地址构建transport(如果配置stun,又需要局域网IP呼叫需要配置SDK_FALSE)
        sdk_bool_t does_it_support_broadcast;    // 是否支持广播
        sip_sdk_stun_config stun_config;         // stun 服务器
        char custom_session_name[256];           // custom session name
        int local_call_update_time;              // 本地呼叫更新时间（IP 呼叫不会自动更新会话，配置大于0表示间隔多少秒发送更新消息）
    } sip_sdk_common_config;

    extern sip_sdk_common_config sip_sdk_config;

    sdk_status_t sip_sdk_register(const char *client_id,
                                  const char *client_secret,
                                  const char *device_uuid,
                                  const char *auth_file_path,
                                  const license_type lic_type);

    sdk_status_t sip_sdk_license_info(char *info, size_t size);

    sdk_status_t sip_sdk_init();

    sdk_status_t sip_sdk_init_interna(const char *token);

    sdk_status_t sip_sdk_init_token(const char *token,
                                    const char *clientId,
                                    const char *clientSecret,
                                    const char *packageName);

    sdk_status_t sip_sdk_destroy();

    sdk_status_t sip_sdk_handle_ip_change(const sip_sdk_ip_change_param ip_change_param);

    sdk_status_t local_account(const sip_sdk_local_config local_config);

    sdk_status_t registrar_account(const sip_sdk_registrar_config registrar_config);

    sdk_status_t unregistrar();

    sdk_status_t make_call(sip_sdk_call_param *call_param);

    sdk_status_t answer_call(const sip_sdk_answer_param answer_param);

    sdk_status_t hangup_call(const sip_sdk_hangup_param hangup_param);

    sdk_status_t send_message(const sip_sdk_message_param message_param);

    sdk_status_t send_dtmf_info(const sip_sdk_dtmf_info_param dtmf_info_param);

    sdk_status_t dump_info();

#ifdef __cplusplus
}
#endif

#endif
