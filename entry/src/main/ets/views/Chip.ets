import { Theme } from '../common/theme';

// Selectable pill. A component (not a @Builder) so `selected` re-renders when it changes:
// by-value @Builder params are not reactive.
@Component
export struct Chip {
  @Prop label: string = '';
  @Prop selected: boolean = false;
  chipId: string = '';
  onTap: () => void = () => {
  };

  build() {
    Text(this.label)
      .id(this.chipId)
      .fontSize(14)
      .fontColor(this.selected ? Color.White : Theme.TEXT)
      .backgroundColor(this.selected ? Theme.PRIMARY : Theme.CARD)
      .border({ width: 1, color: this.selected ? Theme.PRIMARY : '#E6DCE0' })
      .borderRadius(18)
      .padding({ left: 14, right: 14, top: 8, bottom: 8 })
      .onClick(() => {
        this.onTap();
      })
  }
}
