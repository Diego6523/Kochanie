import { Box, Item, Person } from '../common/models';
import { canOpen, formatCountdown, moodLabel, msUntilUnlock, otherPerson, personLabel } from '../common/rules';
import { Theme } from '../common/theme';

function itemsSummary(items: Item[]): string {
  return items.map((i: Item) => i.type === 'letter' ? 'Letter' : i.type === 'photo' ? 'Photo' : 'Song').join(' · ');
}

@Component
export struct ListView {
  @Prop boxes: Box[] = [];
  @Prop current: Person = 'me';
  onOpen: (id: string) => void = () => {
  };
  onCreate: () => void = () => {
  };
  @State now: number = Date.now();
  private timer: number = -1;

  aboutToAppear(): void {
    this.timer = setInterval(() => {
      this.now = Date.now();
    }, 1000);
  }

  aboutToDisappear(): void {
    clearInterval(this.timer);
  }

  @Builder
  badge(label: string, color: string) {
    Text(label)
      .fontSize(12)
      .fontWeight(FontWeight.Medium)
      .fontColor(Color.White)
      .backgroundColor(color)
      .borderRadius(10)
      .padding({ left: 8, right: 8, top: 3, bottom: 3 })
  }

  @Builder
  incomingCard(box: Box) {
    Column({ space: 6 }) {
      Row() {
        Text(box.title)
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .fontColor(Theme.TEXT)
          .layoutWeight(1)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        if (box.status === 'opened') {
          this.badge('Opened', Theme.MUTED)
        } else if (box.unlock.type === 'mood') {
          this.badge('When ready', Theme.PRIMARY)
        } else if (canOpen(box, this.current, this.now).allowed) {
          this.badge('Unlocked', Theme.UNLOCKED)
        } else {
          this.badge('Locked', Theme.LOCKED)
        }
      }
      .width('100%')

      Text(`From ${personLabel(box.from)} · ${itemsSummary(box.items)}`)
        .fontSize(13)
        .fontColor(Theme.MUTED)
      if (box.unlock.type === 'mood') {
        Text(moodLabel(box.unlock.mood))
          .fontSize(14)
          .fontColor(Theme.PRIMARY)
          .fontStyle(FontStyle.Italic)
      } else if (box.status === 'sealed' && msUntilUnlock(box, this.now) > 0) {
        Text(`Unlocks in ${formatCountdown(msUntilUnlock(box, this.now))}`)
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor(Theme.LOCKED)
      } else if (box.status === 'sealed') {
        Text('Ready to open!')
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor(Theme.UNLOCKED)
      }
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding(Theme.PAD)
    .backgroundColor(Theme.CARD)
    .borderRadius(Theme.RADIUS)
    .shadow({ radius: 8, color: '#14000000', offsetY: 2 })
    .id(`box_${box.id}`)
    .onClick(() => {
      this.onOpen(box.id);
    })
  }

  @Builder
  sentRow(box: Box) {
    Row() {
      Column({ space: 2 }) {
        Text(box.title)
          .fontSize(15)
          .fontColor(Theme.TEXT)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(box.unlock.type === 'mood' ? moodLabel(box.unlock.mood) :
          `To ${personLabel(box.to)} · ${box.status === 'sealed' && msUntilUnlock(box, this.now) > 0 ?
            'unlocks in ' + formatCountdown(msUntilUnlock(box, this.now)) : 'unlock time reached'}`)
          .fontSize(12)
          .fontColor(Theme.MUTED)
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      this.badge(box.status === 'opened' ? 'Opened' : 'Sealed', box.status === 'opened' ? Theme.UNLOCKED : Theme.LOCKED)
    }
    .width('100%')
    .padding({ left: Theme.PAD, right: Theme.PAD, top: 10, bottom: 10 })
    .backgroundColor(Theme.CARD)
    .borderRadius(12)
    .onClick(() => {
      this.getUIContext().getPromptAction().showToast({
        message: `Only ${personLabel(box.to)} can open this box.`
      });
    })
  }

  @Builder
  sectionTitle(text: string) {
    Text(text)
      .fontSize(13)
      .fontWeight(FontWeight.Bold)
      .fontColor(Theme.MUTED)
      .margin({ top: 8, bottom: 2 })
  }

  build() {
    Column() {
      Scroll() {
        Column({ space: 10 }) {
          this.sectionTitle('BOXES FOR YOU')
          if (this.incoming().length === 0) {
            Text('No boxes yet. Maybe ask nicely?')
              .fontSize(14)
              .fontColor(Theme.MUTED)
              .padding(Theme.PAD)
          }
          ForEach(this.incoming(), (box: Box) => {
            this.incomingCard(box)
          }, (box: Box) => `${box.id}-${box.status}`)

          this.sectionTitle('BOXES YOU SENT')
          if (this.sent().length === 0) {
            Text('You have not sent any box yet.')
              .fontSize(14)
              .fontColor(Theme.MUTED)
              .padding(Theme.PAD)
          }
          ForEach(this.sent(), (box: Box) => {
            this.sentRow(box)
          }, (box: Box) => `${box.id}-${box.status}`)
        }
        .padding({ left: Theme.PAD, right: Theme.PAD, bottom: 24 })
        .alignItems(HorizontalAlign.Start)
      }
      .layoutWeight(1)
      .align(Alignment.Top)

      Button(`+  New box for ${personLabel(otherPerson(this.current))}`)
        .id('btn_new_box')
        .width('90%')
        .height(48)
        .fontSize(16)
        .backgroundColor(Theme.PRIMARY)
        .margin({ top: 8, bottom: 16 })
        .onClick(() => {
          this.onCreate();
        })
    }
    .width('100%')
    .layoutWeight(1)
  }

  // Newest first.
  private incoming(): Box[] {
    return this.boxes.filter((b: Box) => b.to === this.current).sort((a: Box, b: Box) => b.createdAt - a.createdAt);
  }

  private sent(): Box[] {
    return this.boxes.filter((b: Box) => b.from === this.current).sort((a: Box, b: Box) => b.createdAt - a.createdAt);
  }
}
