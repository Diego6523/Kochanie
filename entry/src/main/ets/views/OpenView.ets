import { common, Want } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { Box, Item, Person } from '../common/models';
import { canOpen, formatCountdown, moodLabel, msUntilUnlock, OpenCheck, personLabel } from '../common/rules';
import { photoResource } from '../common/photos';
import { Theme } from '../common/theme';

@Component
export struct OpenView {
  @Prop box: Box;
  @Prop current: Person = 'me';
  onOpened: (id: string) => void = () => {
  };
  onBack: () => void = () => {
  };
  @State now: number = Date.now();
  @State revealed: boolean = false;
  // Gift animation state
  @State lidY: number = 0;
  @State lidAngle: number = 0;
  @State giftScale: number = 1;
  @State giftOpacity: number = 1;
  // Content reveal state
  @State contentScale: number = 0.6;
  @State contentOpacity: number = 0;
  private timer: number = -1;
  private animating: boolean = false;

  aboutToAppear(): void {
    // Already-opened boxes show their content straight away.
    if (this.box.status === 'opened' && canOpen(this.box, this.current, Date.now()).allowed) {
      this.revealed = true;
      this.contentScale = 1;
      this.contentOpacity = 1;
    }
    this.timer = setInterval(() => {
      this.now = Date.now();
    }, 1000);
  }

  aboutToDisappear(): void {
    clearInterval(this.timer);
  }

  build() {
    Column() {
      Row() {
        Text('‹ Back')
          .id('btn_back')
          .fontSize(16)
          .fontColor(Theme.PRIMARY)
          .padding({ top: 6, bottom: 6, right: 12 })
          .onClick(() => {
            this.onBack();
          })
        Blank()
      }
      .width('100%')
      .padding({ left: Theme.PAD, right: Theme.PAD })

      if (this.revealed) {
        this.content()
      } else {
        this.closed()
      }
    }
    .width('100%')
    .layoutWeight(1)
  }

  @Builder
  giftBox() {
    Stack({ alignContent: Alignment.Top }) {
      // Body
      Stack() {
        Column().width(26).height('100%').backgroundColor('#FFF3C4')
      }
      .width(170)
      .height(130)
      .margin({ top: 46 })
      .backgroundColor(Theme.PRIMARY)
      .borderRadius({ bottomLeft: 14, bottomRight: 14, topLeft: 4, topRight: 4 })

      // Lid with bow
      Column() {
        Row({ space: 6 }) {
          Circle().width(34).height(34).fill('#FFF3C4')
          Circle().width(34).height(34).fill('#FFF3C4')
        }
        .margin({ bottom: -8 })

        Stack() {
          Column().width(26).height('100%').backgroundColor('#FFF3C4')
        }
        .width(190)
        .height(34)
        .backgroundColor('#C93F66')
        .borderRadius(8)
      }
      .translate({ y: this.lidY })
      .rotate({ angle: this.lidAngle, centerX: '0%', centerY: '100%' })
    }
    .width(200)
    .height(180)
    .scale({ x: this.giftScale, y: this.giftScale })
    .opacity(this.giftOpacity)
  }

  // Reads this.now directly (not via a by-value @Builder param) so the
  // locked -> unlocked switch re-renders when the countdown reaches zero.
  private check(): OpenCheck {
    return canOpen(this.box, this.current, this.now);
  }

  @Builder
  closed() {
    Column({ space: 14 }) {
      Blank().height(24)
      this.giftBox()
      Text(this.box.title)
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .fontColor(Theme.TEXT)
        .textAlign(TextAlign.Center)
      Text(`From ${personLabel(this.box.from)}`).fontSize(14).fontColor(Theme.MUTED)

      if (this.box.unlock.type === 'mood') {
        Text(moodLabel(this.box.unlock.mood))
          .fontSize(16)
          .fontStyle(FontStyle.Italic)
          .fontColor(Theme.PRIMARY)
      }

      if (this.check().allowed) {
        Button(this.box.unlock.type === 'mood' ? 'Open it' : 'It\'s time — open it')
          .id('btn_open')
          .width('70%')
          .height(48)
          .fontSize(17)
          .backgroundColor(Theme.PRIMARY)
          .margin({ top: 12 })
          .onClick(() => {
            if (this.check().needsConfirm) {
              this.confirmMoment();
            } else {
              this.reveal();
            }
          })
      } else if (this.current === this.box.to) {
        Text('Locked').fontSize(14).fontColor(Theme.LOCKED).margin({ top: 12 })
        Text(formatCountdown(msUntilUnlock(this.box, this.now)))
          .id('countdown')
          .fontSize(44)
          .fontWeight(FontWeight.Bold)
          .fontColor(Theme.TEXT)
          .fontFeature('"tnum" on')
        Text('Patience is part of the gift.').fontSize(14).fontColor(Theme.MUTED)
      } else {
        Text(this.check().reason)
          .fontSize(15)
          .fontColor(Theme.MUTED)
          .textAlign(TextAlign.Center)
          .margin({ top: 12 })
      }
    }
    .width('100%')
    .padding({ left: Theme.PAD, right: Theme.PAD })
  }

  @Builder
  itemView(item: Item) {
    if (item.type === 'photo') {
      Image(photoResource(item.photoRes))
        .width('100%')
        .aspectRatio(1)
        .objectFit(ImageFit.Cover)
        .borderRadius(Theme.RADIUS)
    } else if (item.type === 'letter') {
      Column({ space: 8 }) {
        Text(`Dear ${personLabel(this.box.to)},`)
          .fontSize(16)
          .fontStyle(FontStyle.Italic)
          .fontColor(Theme.MUTED)
        Text(item.text ?? '')
          .fontSize(18)
          .lineHeight(28)
          .fontColor(Theme.TEXT)
        Text(`— ${personLabel(this.box.from)}`)
          .fontSize(16)
          .fontStyle(FontStyle.Italic)
          .fontColor(Theme.MUTED)
          .width('100%')
          .textAlign(TextAlign.End)
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')
      .padding(20)
      .backgroundColor('#FFFDF7')
      .borderRadius(Theme.RADIUS)
      .border({ width: 1, color: '#F1E4D8' })
    } else {
      Row({ space: 12 }) {
        Text('♪')
          .fontSize(26)
          .fontColor(Color.White)
          .width(48)
          .height(48)
          .textAlign(TextAlign.Center)
          .backgroundColor(Theme.PRIMARY)
          .borderRadius(24)
        Column({ space: 2 }) {
          Text('A song for you').fontSize(16).fontWeight(FontWeight.Medium).fontColor(Theme.TEXT)
          Text(item.url ?? '')
            .fontSize(12)
            .fontColor(Theme.MUTED)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
      }
      .id('song_link')
      .width('100%')
      .padding(14)
      .backgroundColor(Theme.CARD)
      .borderRadius(Theme.RADIUS)
      .onClick(() => {
        this.openLink(item.url ?? '');
      })
    }
  }

  @Builder
  content() {
    Scroll() {
      Column({ space: 14 }) {
        Text(this.box.title)
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor(Theme.TEXT)
        Text(`From ${personLabel(this.box.from)}`).fontSize(14).fontColor(Theme.MUTED)
        ForEach(this.orderedItems(), (item: Item) => {
          this.itemView(item)
        }, (item: Item) => item.type)
      }
      .id('box_content')
      .width('100%')
      .padding({ left: Theme.PAD, right: Theme.PAD, top: 8, bottom: 24 })
      .scale({ x: this.contentScale, y: this.contentScale })
      .opacity(this.contentOpacity)
    }
    .layoutWeight(1)
    .align(Alignment.Top)
  }

  // Photo first, then the letter, then the song.
  private orderedItems(): Item[] {
    const rank = (i: Item): number => i.type === 'photo' ? 0 : i.type === 'letter' ? 1 : 2;
    return this.box.items.slice().sort((a: Item, b: Item) => rank(a) - rank(b));
  }

  private confirmMoment(): void {
    try {
      this.getUIContext().showAlertDialog({
        title: 'Is it really the moment?',
        message: `"${moodLabel(this.box.unlock.mood)}" — is that how you feel right now?`,
        autoCancel: true,
        primaryButton: {
          value: 'Not yet',
          action: () => {
          }
        },
        secondaryButton: {
          value: 'Yes, open it',
          fontColor: Theme.PRIMARY,
          action: () => {
            this.reveal();
          }
        }
      });
    } catch (e) {
      // If the dialog cannot be shown, do not block the recipient.
      this.reveal();
    }
  }

  // Lid pops off, the gift scales up and fades, then the content scales + fades in.
  private reveal(): void {
    if (this.animating) {
      return;
    }
    this.animating = true;
    this.onOpened(this.box.id);
    const ui = this.getUIContext();
    ui.animateTo({ duration: 450, curve: Curve.EaseOut }, () => {
      this.lidY = -90;
      this.lidAngle = -25;
    });
    ui.animateTo({
      duration: 450, delay: 350, curve: Curve.EaseIn, onFinish: () => {
        this.revealed = true;
        ui.animateTo({ duration: 700, curve: Curve.Friction }, () => {
          this.contentScale = 1;
          this.contentOpacity = 1;
        });
        this.animating = false;
      }
    }, () => {
      this.giftScale = 1.4;
      this.giftOpacity = 0;
    });
  }

  private openLink(url: string): void {
    const ctx = this.getUIContext().getHostContext() as common.UIAbilityContext;
    const want: Want = {
      action: 'ohos.want.action.viewData',
      entities: ['entity.system.browsable'],
      uri: url
    };
    ctx.startAbility(want).catch((err: BusinessError) => {
      try {
        this.getUIContext().getPromptAction().showToast({ message: `No app can open this link (${err.code}).` });
      } catch (e) {
        // ignore
      }
    });
  }
}
