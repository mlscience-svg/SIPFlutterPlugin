import PlatformView, { Params } from '@ohos/flutter_ohos/src/main/ets/plugin/platform/PlatformView';
import common from '@ohos.app.ability.common';
import { BinaryMessenger } from '@ohos/flutter_ohos/src/main/ets/plugin/common/BinaryMessenger';
import { VideoComponent } from './VideoComponent';

@Observed
export class VideoComponentView extends PlatformView {
  constructor(context: common.Context, viewId: number, args: ESObject, message: BinaryMessenger) {
    super();
    console.log("nodeController viewId:" + viewId)
  }


  getView(): WrappedBuilder<[Params]> {
    return new WrappedBuilder(VideoComponentBuilder);
  }

  dispose(): void {
  }
}

@Builder
export function VideoComponentBuilder(params: Params) {
  VideoComponent({ params: params })
    .backgroundColor(Color.White)
}
