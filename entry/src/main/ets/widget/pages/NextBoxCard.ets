// Home-screen widget: live countdown to the next box. Data comes from common/widget.ets
// (WidgetData) through LocalStorage; the card counts down by itself with TextTimer.
const storage = new LocalStorage();

const DAY_MS: number = 24 * 3600 * 1000;

@Entry(storage)
@Component
struct NextBoxCard {
  @LocalStorageProp('hasBox') @Watch('restart') hasBox: boolean = false;
  @LocalStorageProp('boxId') boxId: string = '';
  @LocalStorageProp('title') title: string = '';
  @LocalStorageProp('forWho') forWho: string = '';
  @LocalStorageProp('atMs') @Watch('restart') atMs: number = 0;
  @LocalStorageProp('atLabel') atLabel: string = '';
  @LocalStorageProp('hint') hint: string = 'Open the app to start';
  @State countMs: number = 0;
  @State ready: boolean = false;
  private controller: TextTimerController = new TextTimerController();

  aboutToAppear(): void {
    this.restart();
  }

  restart(): void {
    const left = this.atMs - Date.now();
    // Fields arrive one by one, so don't depend on hasBox here (the ready text is only
    // shown inside the hasBox branch anyway). TextTimer treats count <= 0 as 60 s.
    this.countMs = Math.max(1000, Math.min(left, DAY_MS));
    this.ready = left <= 0;
    this.controller.reset();
    this.controller.start();
  }

  build() {
    Column({ space: 4 }) {
      Text('OPEN WHEN')
        .fontSize(11)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FFE3EA')
        .letterSpacing(1)
      if (!this.hasBox) {
        Blank()
        Text(this.hint)
          .fontSize(14)
          .fontColor(Color.White)
          .maxLines(3)
        Blank()
      } else {
        Text(this.title)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(this.forWho)
          .fontSize(11)
          .fontColor('#FFE3EA')
          .maxLines(1)
        Blank()
        if (this.ready) {
          Text('Ready to open!')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.White)
        } else if (this.atMs - Date.now() > DAY_MS) {
          Text(this.atLabel)
            .fontSize(13)
            .fontColor(Color.White)
        } else {
          TextTimer({ isCountDown: true, count: this.countMs, controller: this.controller })
            .format(this.countMs >= 3600 * 1000 ? 'HH:mm:ss' : 'mm:ss')
            .fontSize(28)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.White)
            .onAppear(() => {
              // The controller is only bound once TextTimer exists, so start it here too.
              this.controller.start();
            })
            .onTimer((utc: number, elapsedTime: number) => {
              // elapsedTime is in the format's smallest unit (not ms), so use the clock.
              if (Date.now() >= this.atMs - 500) {
                this.ready = true;
              }
            })
          Text(this.atLabel)
            .fontSize(11)
            .fontColor('#FFE3EA')
        }
      }
    }
    .width('100%')
    .height('100%')
    .alignItems(HorizontalAlign.Start)
    .padding(14)
    .linearGradient({ angle: 160, colors: [['#F07A98', 0], ['#C93F66', 1]] })
    .onClick(() => {
      postCardAction(this, {
        action: 'router',
        abilityName: 'EntryAbility',
        params: { boxId: this.boxId }
      });
    })
  }
}
