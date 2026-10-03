import { hilog } from '@kit.PerformanceAnalysisKit';
import { Box, Person } from '../common/models';
import { BoxStore } from '../common/store';
import { personLabel } from '../common/rules';
import { Theme } from '../common/theme';

type ViewName = 'list' | 'create' | 'open';

@Entry
@Component
struct Index {
  @State view: ViewName = 'list';
  @State current: Person = 'me';
  @State boxes: Box[] = [];
  @State openId: string = '';
  private store: BoxStore | null = null;

  aboutToAppear(): void {
    this.store = new BoxStore(this.getUIContext().getHostContext()!);
    this.boxes = this.store.load(Date.now());
    hilog.info(0x0001, 'OpenWhen', 'Loaded %{public}d boxes', this.boxes.length);
  }

  @Builder
  personToggle(p: Person) {
    Text(personLabel(p))
      .fontSize(14)
      .fontWeight(FontWeight.Medium)
      .fontColor(this.current === p ? Color.White : Theme.PRIMARY)
      .backgroundColor(this.current === p ? Theme.PRIMARY : Color.Transparent)
      .borderRadius(14)
      .padding({ left: 14, right: 14, top: 6, bottom: 6 })
      .id(`toggle_${p}`)
      .onClick(() => {
        this.current = p;
        this.view = 'list';
      })
  }

  @Builder
  header() {
    Row() {
      Text('Open When')
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .fontColor(Theme.TEXT)
      Blank()
      Text('I am:').fontSize(13).fontColor(Theme.MUTED).margin({ right: 6 })
      Row() {
        this.personToggle('me')
        this.personToggle('her')
      }
      .backgroundColor(Theme.PRIMARY_SOFT)
      .borderRadius(16)
      .padding(2)
    }
    .width('100%')
    .padding({ left: Theme.PAD, right: Theme.PAD, top: 12, bottom: 12 })
  }

  build() {
    Column() {
      this.header()
      if (this.view === 'list') {
        Text(`List view (${this.boxes.length} boxes) — as ${personLabel(this.current)}`)
          .fontColor(Theme.TEXT)
          .onClick(() => {
            this.view = 'create';
          })
      } else if (this.view === 'create') {
        Text('Create view (tap to go back)').onClick(() => {
          this.view = 'list';
        })
      } else {
        Text('Open view (tap to go back)').onClick(() => {
          this.view = 'list';
        })
      }
    }
    .height('100%')
    .width('100%')
    .backgroundColor(Theme.BG)
  }
}
