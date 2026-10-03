import { hilog } from '@kit.PerformanceAnalysisKit';
import { Box } from '../common/models';
import { BoxStore } from '../common/store';

@Entry
@Component
struct Index {
  @State boxes: Box[] = [];
  private store: BoxStore | null = null;

  aboutToAppear(): void {
    this.store = new BoxStore(this.getUIContext().getHostContext()!);
    this.boxes = this.store.load(Date.now());
    hilog.info(0x0001, 'OpenWhen', 'Loaded %{public}d boxes: %{public}s', this.boxes.length,
      JSON.stringify(this.boxes.map((b: Box) => b.title)));
  }

  build() {
    Column() {
      Text(`Boxes: ${this.boxes.length}`).fontSize(24)
    }
    .height('100%')
    .width('100%')
    .justifyContent(FlexAlign.Center)
  }
}
