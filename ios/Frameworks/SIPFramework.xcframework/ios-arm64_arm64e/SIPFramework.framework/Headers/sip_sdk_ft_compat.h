#ifndef SIP_SDK_FT_COMPAT_H
#define SIP_SDK_FT_COMPAT_H

/*
 * sip_sdk_ft_compat.h
 *
 * 文件传输(ft)模块 API 适配层。
 *
 * ft 模块(从新版 SIPSDK 同步而来)使用新版命名：
 *   - 类型: sip_sdk_bool_t / sip_sdk_size_t / sip_sdk_uuid_t / sip_sdk_status_t
 *   - 常量: SIP_SDK_TRUE / SIP_SDK_FALSE / SIP_SDK_SUCCESS /
 *           SIP_SDK_ERROR_COMMON / SIP_SDK_INVALID_UUID
 *   - 尺寸宏: SIP_SDK_MAX_NAME_SIZE / SIP_SDK_MAX_IP_SIZE / SIP_SDK_MAX_URL_SIZE /
 *             SIP_SDK_MAX_STUN / SIP_SDK_MAX_CUSTOM_HEADERS
 *
 * 本仓库 sip_sdk.h 仍使用旧命名(sdk_bool_t / SDK_TRUE / SDK_ERROR_COMMON 等)，
 * 这里做一次性映射，避免改动现有 sip_sdk.h 及其全部调用方。
 *
 * 本文件只应被 ft 模块内部包含(经 ft_internal.h)，不得作为对外 API。
 */

#include <SIPFramework/sip_sdk.h>

#ifdef __cplusplus
extern "C"
{
#endif

/* ---- 类型别名：新命名 -> 旧命名 ---- */
typedef sdk_bool_t   sip_sdk_bool_t;
typedef sdk_status_t sip_sdk_status_t;
typedef sdk_size_t   sip_sdk_size_t;
typedef sdk_uuid_t   sip_sdk_uuid_t;

/* ---- 常量：新命名 -> 旧命名 ---- */
#ifndef SIP_SDK_TRUE
#define SIP_SDK_TRUE             SDK_TRUE
#endif
#ifndef SIP_SDK_FALSE
#define SIP_SDK_FALSE            SDK_FALSE
#endif
#ifndef SIP_SDK_SUCCESS
#define SIP_SDK_SUCCESS          SDK_SUCCESS
#endif
#ifndef SIP_SDK_ERROR_COMMON
#define SIP_SDK_ERROR_COMMON     SDK_ERROR_COMMON
#endif
#ifndef SIP_SDK_INVALID_UUID
#define SIP_SDK_INVALID_UUID     ((sdk_uuid_t)0)
#endif

/* ---- 尺寸宏(旧 sip_sdk.h 未定义，补齐) ---- */
#ifndef SIP_SDK_MAX_NAME_SIZE
#define SIP_SDK_MAX_NAME_SIZE        64
#endif
#ifndef SIP_SDK_MAX_IP_SIZE
#define SIP_SDK_MAX_IP_SIZE          46
#endif
#ifndef SIP_SDK_MAX_URL_SIZE
#define SIP_SDK_MAX_URL_SIZE         256
#endif
#ifndef SIP_SDK_MAX_STUN
#define SIP_SDK_MAX_STUN             5
#endif
#ifndef SIP_SDK_MAX_CUSTOM_HEADERS
#define SIP_SDK_MAX_CUSTOM_HEADERS   SDK_MAX_CUSTOM_HEADERS
#endif

/* ---- 账号类型(ft 用 SIP_SDK_ACCOUNT_TYPE_REMOTE 判断目标 URI 拼接) ---- */
typedef enum sip_sdk_ft_account_type
{
    SIP_SDK_ACCOUNT_TYPE_LOCAL = 0,
    SIP_SDK_ACCOUNT_TYPE_REMOTE = 1,
} sip_sdk_ft_account_type;

#ifdef __cplusplus
}
#endif

#endif /* SIP_SDK_FT_COMPAT_H */
