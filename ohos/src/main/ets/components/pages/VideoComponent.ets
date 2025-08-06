import { util } from '@kit.ArkTS';
import { Params } from '@ohos/flutter_ohos/src/main/ets/plugin/platform/PlatformView';
import { SIPMediaListener, } from "sipsdkapi/src/main/ets/sip/SIPCallback";
import { addMediaListener, removeMediaListener } from 'sipsdkapi';
import { abilityAccessCtrl } from '@kit.AbilityKit';

@Component
export struct VideoComponent {
  @Prop params: Params;
  @State aspect: number = 480 / 640;
  mediaListener: SIPMediaListener = {
    onVideoSizeChang: (callUuid: bigint, width: number, height: number) => {
      this.aspect = width / height;
    }
  };

  aboutToAppear() {
    addMediaListener(this.mediaListener);
  }

  aboutToDisappear() {
    removeMediaListener(this.mediaListener);
  }

  build() {
    Stack() {
      XComponent({
        id: util.generateRandomUUID(),
        type: XComponentType.SURFACE,
        libraryname: 'render',
      }).aspectRatio(this.aspect)
        .height('100%')
        .width('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Color.Black)
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }
}