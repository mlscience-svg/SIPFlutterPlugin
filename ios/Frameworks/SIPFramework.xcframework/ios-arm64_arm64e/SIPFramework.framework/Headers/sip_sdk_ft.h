#ifndef __SIP_SDK_FT_H__
#define __SIP_SDK_FT_H__

#include <stdint.h>
#include <stddef.h>
#include <SIPFramework/sip_sdk.h>
#include <SIPFramework/sip_sdk_ft_compat.h>

/**
 * @file sip_sdk_ft.h
 * @brief 文件传输（File Transfer）模块公开 API
 *
 * 独立于呼叫/音视频媒体路径的文件传输功能：
 *  - 信令：复用 SIP MESSAGE 通道（MIME type = application/x-sipsdk-ft），只传控制 JSON
 *  - 传输：每个会话独立的 pj_ice_strans（STUN/TURN），P2P 优先、打洞失败自动 TURN 转发
 *  - 可靠传输：自研滑动窗口 ARQ 协议（ICE 为 UDP 通道）
 */

// 最大文件名长度
#define SIP_SDK_FT_MAX_FILENAME 256
// 最大附加信息长度
#define SIP_SDK_FT_MAX_META 128
// 传输会话最大并发数（默认）
#define SIP_SDK_FT_MAX_SESSIONS_DEFAULT 5

typedef enum sip_sdk_ft_role
{
    SIP_SDK_FT_ROLE_SENDER = 0,
    SIP_SDK_FT_ROLE_RECEIVER,
} sip_sdk_ft_role;

typedef enum sip_sdk_ft_state
{
    SIP_SDK_FT_STATE_NULL = 0,
    SIP_SDK_FT_STATE_NEGOTIATING,     /* offer 已发出/已收到，等待应答 */
    SIP_SDK_FT_STATE_ICE_CONNECTING,  /* ICE 建连中 */
    SIP_SDK_FT_STATE_TRANSFERRING,    /* 可靠通道已建立，数据在传输 */
    SIP_SDK_FT_STATE_COMPLETE,        /* 传输完成 */
    SIP_SDK_FT_STATE_ERROR,           /* 出错 */
    SIP_SDK_FT_STATE_CANCELLED,       /* 已取消 */
} sip_sdk_ft_state;

typedef enum sip_sdk_ft_error
{
    SIP_SDK_FT_ERR_NONE = 0,
    SIP_SDK_FT_ERR_BUSY = -100,        /* 无空闲会话槽 */
    SIP_SDK_FT_ERR_OPEN_FILE = -101,   /* 打开文件失败 */
    SIP_SDK_FT_ERR_ICE = -102,         /* ICE 失败 */
    SIP_SDK_FT_ERR_TIMEOUT = -103,     /* 超时 */
    SIP_SDK_FT_ERR_PEER_CANCEL = -104, /* 对端取消 */
    SIP_SDK_FT_ERR_LOCAL_CANCEL = -105,/* 本端取消 */
    SIP_SDK_FT_ERR_PROTOCOL = -106,    /* 协议错误 */
    SIP_SDK_FT_ERR_REJECTED = -107,    /* 对端拒绝 */
} sip_sdk_ft_error;

typedef struct sip_sdk_ft_config
{
    /**
     * 是否启用文件传输（默认 SDK_FALSE）。
     * 启用后，sip_sdk_init 完成时会自动初始化 FT 模块；
     * 关闭时也可通过显式调用 sip_sdk_ft_init 手动启用。
     */
    sip_sdk_bool_t enable;

    /**
     * 最大并发会话数（默认 5，能力上限；实际用多少由应用决定）。0 表示使用默认值。
     */
    unsigned max_sessions;

    /**
     * 滑动窗口大小（默认 4，嵌入式省内存）。0 表示使用默认值。
     */
    unsigned window_size;

    /**
     * 分块大小，字节（默认 1024）。0 表示使用默认值。
     */
    unsigned chunk_size;

    /**
     * 初始重传超时 RTO，毫秒（默认 300）。0 表示使用默认值。
     */
    unsigned initial_rto_ms;

    /**
     * 最小重传超时 RTO，毫秒（默认 200）。0 表示使用默认值。
     */
    unsigned rto_min_ms;

    /**
     * 最大连续重传次数（默认 5）。0 表示使用默认值。
     */
    unsigned max_retransmit;

    /**
     * 会话硬超时，毫秒（默认 120000，即 120 秒无进展判失败）。
     * 覆盖协商（offer/answer）与传输全过程。0 表示使用默认值。
     */
    unsigned session_timeout_ms;

    /**
     * STUN 服务器。FT 配置自包含：不使用全局 sip_sdk_config.stun_config，
     * 也不继承账号配置；count == 0 表示 FT 不启用 STUN。
     */
    sip_sdk_stun_config stun;

    /**
     * TURN 服务器。FT 配置自包含：不使用账号 turn_config；
     * enable == SDK_FALSE 或 server 为空表示 FT 不启用 TURN（纯 P2P）。
     */
    sip_sdk_turn_config turn;

    /**
     * 是否启用 IPv6（默认 SDK_FALSE）
     */
    sip_sdk_bool_t enable_ipv6;

    /**
     * 等待对端应答(offer->answer)超时，毫秒。默认 30000。
     */
    unsigned answer_timeout_ms;

    /**
     * 对端应答后 ICE 建连超时，毫秒。默认 3000。
     */
    unsigned connect_timeout_ms;

    /**
     * 传输中无数据交互(无收发/无确认)超时，毫秒。默认 5000。
     */
    unsigned inactive_timeout_ms;

    /**
     * 发送节奏：每轮 poll 最多突发的包数。0 表示用默认值（FT_BURST_MAX）。
     * 增大可提高吞吐，但公网 relay→relay 突发过多会丢包；内网/P2P 可调大。
     */
    unsigned burst_max;

    /**
     * 两批发送之间的最小间隔，毫秒。0 表示用默认值（FT_SEND_INTERVAL_MS）。
     * 调小可提高发送频率（配合 burst_max 共同决定峰值吞吐）。
     */
    unsigned send_interval_ms;

    /**
     * KCP 发送窗口（默认 FT_KCP_SNDWND=128，段）。0 表示使用默认值。
     * 在途量 = 窗口 × 段长(1200)：越大吞吐越高、内存越大；公网 relay 路径
     * 窗口过大可能导致中继队列积压丢包，需配合 kcp_max_waitsnd 限流。
     */
    unsigned kcp_sndwnd;

    /**
     * KCP 接收窗口（默认 FT_KCP_RCVWND=256，段）。0 表示使用默认值。
     * 须 ≥ 对端 sndwnd，否则对端发送会被收窗卡死。
     */
    unsigned kcp_rcvwnd;

    /**
     * 发送端 KCP 队列段数上限（默认 FT_KCP_MAX_WAITSND=512，段）。0 表示使用默认值。
     * 满则暂停读文件喂数据（KCP 流控回压）：越大突发缓冲越高、内存越大。
     */
    unsigned kcp_max_waitsnd;

    /**
     * 是否关闭 KCP 拥塞控制（默认 SDK_FALSE = 开启拥塞控制）。
     * =TRUE 时 ikcp_nodelay nc=1（nocwnd=1）：flush 跳过 cwnd 上限，在途只受
     * kcp_sndwnd 限制，吞吐更高（可达 ~400KB/s+）但会野蛮填满链路、挤压共享公网
     * 其它流，丢包率高时易重传风暴；仅 P2P/干净链路建议开启。
     */
    sip_sdk_bool_t kcp_disable_cc;

    /**
     * 接收端默认保存目录（对端 offer 到达且 app 未指定保存路径时使用）
     */
    char default_save_dir[SIP_SDK_MAX_URL_SIZE];
} sip_sdk_ft_config;

typedef struct sip_sdk_ft_file_meta
{
    char name[SIP_SDK_FT_MAX_FILENAME]; /* 文件名 */
    sip_sdk_size_t size;                /* 文件大小（字节） */
    char extra[SIP_SDK_FT_MAX_META];    /* 附加信息 */
} sip_sdk_ft_file_meta;

typedef struct sip_sdk_ft_send_param
{
    sip_sdk_uuid_t acc_uuid;     /* 发送使用的账号 uuid */
    char *username;              /* 对端账号（远程账号必填） */
    char *remote_ip;             /* 对端 IP（本地账号必填） */
    char *file_path;             /* 待发送文件绝对路径 */
    char extra[SIP_SDK_FT_MAX_META];
} sip_sdk_ft_send_param;

typedef struct sip_sdk_ft_offer_param
{
    sip_sdk_uuid_t ft_id;              /* 传输会话 id（对端 accept/reject 时回填） */
    sip_sdk_uuid_t acc_uuid;           /* offer 到达的账号 uuid */
    char *username;                    /* 发送方账号 */
    char *remote_ip;                   /* 发送方 IP */
    sip_sdk_ft_file_meta file;         /* 文件元信息 */
} sip_sdk_ft_offer_param;

typedef struct sip_sdk_ft_request_param
{
    sip_sdk_uuid_t acc_uuid;           /* 发起请求用的账号 uuid */
    char *username;                    /* 请求谁发文件（远程账号必填） */
    char *remote_ip;                   /* 对端 IP（本地账号必填） */
    char *file_name;                   /* 请求的文件名/路径 */
    char extra[SIP_SDK_FT_MAX_META];
} sip_sdk_ft_request_param;

typedef struct sip_sdk_ft_request_info
{
    sip_sdk_uuid_t req_id;             /* 请求 id（回应对应用它） */
    sip_sdk_uuid_t acc_uuid;           /* 请求到达的账号 uuid */
    char *username;                    /* 请求方账号 */
    char *remote_ip;                   /* 请求方 IP */
    sip_sdk_ft_file_meta file;         /* 对方请求的文件名/附加信息 */
} sip_sdk_ft_request_info;

typedef struct sip_sdk_ft_progress
{
    sip_sdk_uuid_t ft_id;              /* 会话 id */
    sip_sdk_ft_state state;            /* 当前状态 */
    sip_sdk_size_t bytes_total;        /* 总字节数 */
    sip_sdk_size_t bytes_done;         /* 已完成字节数 */
    int percent;                       /* 0-100 */
    unsigned active_sessions;          /* 当前活跃会话数 */
} sip_sdk_ft_progress;

typedef struct sip_sdk_ft_complete_param
{
    sip_sdk_uuid_t ft_id;              /* 会话 id */
    sip_sdk_ft_role role;              /* 本端角色 */
    sip_sdk_ft_error error;            /* 错误码（正常完成为 NONE） */
    sip_sdk_size_t bytes_transferred;  /* 传输字节数 */
    unsigned elapsed_ms;               /* 耗时（毫秒） */
    char file_name[SIP_SDK_FT_MAX_FILENAME];
    char save_path[SIP_SDK_MAX_URL_SIZE]; /* 保存路径（接收端） */
} sip_sdk_ft_complete_param;

typedef struct sip_sdk_ft_observer
{
    /**
     * 收到对端文件传输请求（push：对端发文件给我）。
     * app 需要调用 sip_sdk_ft_accept() 或 sip_sdk_ft_reject() 决定是否接收。
     */
    void (*on_offer)(const sip_sdk_ft_offer_param *offer);

    /**
     * 收到对端请求文件（pull：对端要我从本地发文件给它）。
     * app 需要调用 sip_sdk_ft_respond_request() 决定同意(给本地文件路径)或拒绝。
     */
    void (*on_request)(const sip_sdk_ft_request_info *req);

    /**
     * 我发起的文件请求结果（req_id 对应 request_file 返回的 id）。
     * ok=1 对端同意(接下来会收到 offer)，ok=0 对端拒绝。
     */
    void (*on_request_result)(sip_sdk_uuid_t req_id, int ok, const char *reason);

    /**
     * 传输进度回调（节流触发，状态变化时也会触发）。
     */
    void (*on_progress)(const sip_sdk_ft_progress *progress);

    /**
     * 传输结束回调（完成/失败/取消都会触发，通过 error 区分）。
     */
    void (*on_complete)(const sip_sdk_ft_complete_param *complete);
} sip_sdk_ft_observer;

#ifdef __cplusplus
extern "C"
{
#endif

    /**
     * 文件传输全局配置（仿照 sip_sdk_config / sip_media_config 模式）。
     * 应用可在 sip_sdk_init 之前修改；sip_sdk_init 完成时会自动初始化 FT 模块。
     */
    extern sip_sdk_ft_config sip_ft_config;

    /**
     * 文件传输回调（仿照 sip_sdk_config.sdk_observer 模式）。
     * 应用在 sip_sdk_init 之前赋值。
     */
    extern const sip_sdk_ft_observer *sip_ft_observer;

    /**
     * @brief 初始化文件传输模块。
     * @note 若 sip_ft_config.enable == SDK_TRUE，
     *       sip_sdk_init 完成时会自动调用本函数；app 也可自行调用（幂等）。
     */
    sip_sdk_status_t sip_sdk_ft_init(const sip_sdk_ft_config *config,
                                     const sip_sdk_ft_observer *observer);

    /**
     * @brief 销毁文件传输模块（停止 worker 线程，取消所有会话）。
     */
    void sip_sdk_ft_deinit(void);

    /**
     * @brief 发送一个文件（异步）。
     * @param out_ft_id 输出本次传输会话 id（可选，可为 NULL）
     */
    sip_sdk_status_t sip_sdk_ft_send_file(const sip_sdk_ft_send_param *param,
                                          sip_sdk_uuid_t *out_ft_id);

    /**
     * @brief 请求对端发送文件（pull，异步）。
     *        对端同意后会收到 on_offer 回调（正常接收流程），拒绝时触发 on_request_result。
     * @param out_req_id 输出请求 id（可选，可为 NULL，用于和 on_request_result 对应）
     */
    sip_sdk_status_t sip_sdk_ft_request_file(const sip_sdk_ft_request_param *param,
                                             sip_sdk_uuid_t *out_req_id);

    /**
     * @brief 回应对端的文件请求（on_request 回调里调用）。
     * @param req_id    on_request 回调中的请求 id
     * @param accept    1 同意（须给 file_path），0 拒绝
     * @param file_path 同意时本端要发送的本地文件路径；拒绝可为 NULL
     */
    sip_sdk_status_t sip_sdk_ft_respond_request(sip_sdk_uuid_t req_id, int accept,
                                                const char *file_path);

    /**
     * @brief 接受对端的文件传输请求。
     * @param ft_id      on_offer 回调中的会话 id
     * @param save_path  保存路径（含文件名）。为 NULL 时使用
     *                   sip_sdk_ft_config.default_save_dir + 文件名。
     */
    sip_sdk_status_t sip_sdk_ft_accept(sip_sdk_uuid_t ft_id, const char *save_path);

    /**
     * @brief 拒绝对端的文件传输请求。
     */
    sip_sdk_status_t sip_sdk_ft_reject(sip_sdk_uuid_t ft_id, const char *reason);

    /**
     * @brief 取消传输（发送端或接收端均可）。
     */
    sip_sdk_status_t sip_sdk_ft_cancel(sip_sdk_uuid_t ft_id);

    /**
     * @brief 查询会话状态。
     */
    sip_sdk_status_t sip_sdk_ft_get_state(sip_sdk_uuid_t ft_id, sip_sdk_ft_state *state);

#ifdef __cplusplus
}
#endif

#endif /* __SIP_SDK_FT_H__ */
