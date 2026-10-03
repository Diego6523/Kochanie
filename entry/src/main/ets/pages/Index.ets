import { hilog } from '@kit.PerformanceAnalysisKit';
import { Box, Person } from '../common/models';
import { BoxStore } from '../common/store';
import { canOpen, markOpened, personLabel } from '../common/rules';
import { Theme } from '../common/theme';
import { ListView } from '../views/ListView';
import { CreateView } from '../views/CreateView';
import { OpenView } from '../views/OpenView';

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

  // System back returns to the list instead of leaving the app.
  onBackPress(): boolean {
    if (this.view !== 'list') {
      this.view = 'list';
      return true;
    }
    return false;
  }

  private toast(message: string): void {
    try {
      this.getUIContext().getPromptAction().showToast({ message: message });
    } catch (e) {
      hilog.warn(0x0001, 'OpenWhen', 'toast failed: %{public}s', message);
    }
  }

  private persist(next: Box[]): boolean {
    if (this.store === null || !this.store.save(next)) {
      this.toast('Could not save. Please try again.');
      return false;
    }
    this.boxes = next;
    return true;
  }

  private addBox(box: Box): void {
    if (this.persist(this.boxes.concat([box]))) {
      this.toast(`Box sealed for ${personLabel(box.to)}`);
      this.view = 'list';
    }
  }

  private openBox(): Box | undefined {
    return this.boxes.find((b: Box) => b.id === this.openId);
  }

  // Rules are re-checked here so the stored data can never break them.
  private markBoxOpened(id: string): void {
    const now = Date.now();
    const next = this.boxes.map((b: Box) => {
      if (b.id === id && b.status === 'sealed' && canOpen(b, this.current, now).allowed) {
        return markOpened(b, now);
      }
      return b;
    });
    this.persist(next);
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
        ListView({
          boxes: this.boxes,
          current: this.current,
          onOpen: (id: string) => {
            this.openId = id;
            this.view = 'open';
          },
          onCreate: () => {
            this.view = 'create';
          }
        })
      } else if (this.view === 'create') {
        CreateView({
          current: this.current,
          onSeal: (box: Box) => {
            this.addBox(box);
          },
          onCancel: () => {
            this.view = 'list';
          }
        })
      } else if (this.openBox() !== undefined) {
        OpenView({
          box: this.openBox(),
          current: this.current,
          onOpened: (id: string) => {
            this.markBoxOpened(id);
          },
          onBack: () => {
            this.view = 'list';
          }
        })
      }
    }
    .height('100%')
    .width('100%')
    .backgroundColor(Theme.BG)
  }
}
