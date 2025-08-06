#ifndef __SIP_SDK_AEC_H__
#define __SIP_SDK_AEC_H__

#include <SIPFramework/sip_sdk.h>

#ifdef __cplusplus
extern "C"
{
#endif

    void *aec_create(int rate);

    sdk_status_t aec_destroy(void *inst);

    sdk_status_t aec_farend(void *inst, signed short int *frame, sdk_size_t size);

    sdk_status_t aec_process(void *inst, signed short int *frame, sdk_size_t size, signed short int ms);

#ifdef __cplusplus
}
#endif

#endif
