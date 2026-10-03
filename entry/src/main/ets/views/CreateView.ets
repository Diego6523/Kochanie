import { Box, Item, Mood, Person, Unlock, UnlockType } from '../common/models';
import { moodLabel, otherPerson, personLabel, validateBox, ValidationResult } from '../common/rules';
import { newId } from '../common/store';
import { DEMO_PHOTOS, photoResource } from '../common/photos';
import { Theme } from '../common/theme';

type DateMode = 'minutes' | 'datetime';

const MOODS: Mood[] = ['miss_me', 'sad', 'cant_sleep'];
const QUICK_MINUTES: number[] = [1, 5, 60];

function two(n: number): string {
  return n < 10 ? `0${n}` : `${n}`;
}

function formatDateTime(ms: number): string {
  const d = new Date(ms);
  return `${d.getFullYear()}-${two(d.getMonth() + 1)}-${two(d.getDate())} ${two(d.getHours())}:${two(d.getMinutes())}`;
}

@Component
export struct CreateView {
  @Prop current: Person = 'me';
  onSeal: (box: Box) => void = () => {
  };
  onCancel: () => void = () => {
  };
  @State title: string = '';
  @State unlockType: UnlockType = 'date';
  @State dateMode: DateMode = 'minutes';
  @State minutes: string = '1';
  @State at: number = Date.now() + 60 * 60 * 1000;
  @State mood: Mood = 'miss_me';
  @State letter: string = '';
  @State songUrl: string = '';
  @State photo: string = '';
  @State errors: string[] = [];

  @Builder
  label(text: string) {
    Text(text)
      .fontSize(13)
      .fontWeight(FontWeight.Bold)
      .fontColor(Theme.MUTED)
      .margin({ top: 10 })
  }

  @Builder
  chip(text: string, selected: boolean, id: string, action: () => void) {
    Text(text)
      .id(id)
      .fontSize(14)
      .fontColor(selected ? Color.White : Theme.TEXT)
      .backgroundColor(selected ? Theme.PRIMARY : Theme.CARD)
      .border({ width: 1, color: selected ? Theme.PRIMARY : '#E6DCE0' })
      .borderRadius(18)
      .padding({ left: 14, right: 14, top: 8, bottom: 8 })
      .onClick(action)
  }

  @Builder
  dateSection() {
    Row({ space: 8 }) {
      this.chip('In N minutes', this.dateMode === 'minutes', 'mode_minutes', () => {
        this.dateMode = 'minutes';
      })
      this.chip('Date & time', this.dateMode === 'datetime', 'mode_datetime', () => {
        this.dateMode = 'datetime';
      })
    }

    if (this.dateMode === 'minutes') {
      Row({ space: 8 }) {
        Text('Unlock in').fontSize(15).fontColor(Theme.TEXT)
        TextInput({ text: this.minutes })
          .id('input_minutes')
          .type(InputType.Number)
          .width(80)
          .height(40)
          .backgroundColor(Theme.CARD)
          .onChange((v: string) => {
            this.minutes = v;
          })
        Text('minutes').fontSize(15).fontColor(Theme.TEXT)
      }
      .margin({ top: 8 })

      Row({ space: 8 }) {
        ForEach(QUICK_MINUTES, (m: number) => {
          this.chip(m === 60 ? '1 h' : `${m} min`, this.minutes === `${m}`, `quick_${m}`, () => {
            this.minutes = `${m}`;
          })
        }, (m: number) => `${m}`)
      }
      .margin({ top: 8 })
    } else {
      Row({ space: 8 }) {
        Text(formatDateTime(this.at)).fontSize(16).fontColor(Theme.TEXT)
        Button('Change')
          .id('btn_pick_date')
          .fontSize(14)
          .height(36)
          .backgroundColor(Theme.PRIMARY_SOFT)
          .fontColor(Theme.PRIMARY)
          .onClick(() => {
            this.getUIContext().showDatePickerDialog({
              start: new Date(),
              selected: new Date(this.at),
              showTime: true,
              useMilitaryTime: true,
              onDateAccept: (d: Date) => {
                this.at = d.getTime();
              }
            });
          })
      }
      .margin({ top: 8 })
    }
  }

  @Builder
  moodSection() {
    Column({ space: 8 }) {
      ForEach(MOODS, (m: Mood) => {
        this.chip(moodLabel(m), this.mood === m, `mood_${m}`, () => {
          this.mood = m;
        })
      }, (m: Mood) => m)
    }
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  photoGrid() {
    Row({ space: 10 }) {
      ForEach(DEMO_PHOTOS, (name: string) => {
        Image(photoResource(name))
          .id(`photo_${name}`)
          .width(90)
          .height(90)
          .objectFit(ImageFit.Cover)
          .borderRadius(12)
          .border({ width: this.photo === name ? 4 : 0, color: Theme.PRIMARY })
          .opacity(this.photo === '' || this.photo === name ? 1 : 0.5)
          .onClick(() => {
            // Tap again to remove the photo from the box.
            this.photo = this.photo === name ? '' : name;
          })
      }, (name: string) => name)
    }
  }

  build() {
    Column() {
      Scroll() {
        Column({ space: 6 }) {
          Text(`New box for ${personLabel(otherPerson(this.current))}`)
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor(Theme.TEXT)

          this.label('TITLE')
          TextInput({ placeholder: 'e.g. For a rainy Sunday', text: this.title })
            .id('input_title')
            .maxLength(60)
            .backgroundColor(Theme.CARD)
            .onChange((v: string) => {
              this.title = v;
            })

          this.label('UNLOCKS')
          Row({ space: 8 }) {
            this.chip('On a date', this.unlockType === 'date', 'unlock_date', () => {
              this.unlockType = 'date';
            })
            this.chip('At a moment', this.unlockType === 'mood', 'unlock_mood', () => {
              this.unlockType = 'mood';
            })
          }

          if (this.unlockType === 'date') {
            this.dateSection()
          } else {
            this.moodSection()
          }

          this.label('LETTER (optional)')
          TextArea({ placeholder: 'Write something from the heart...', text: this.letter })
            .id('input_letter')
            .height(110)
            .maxLength(2000)
            .backgroundColor(Theme.CARD)
            .onChange((v: string) => {
              this.letter = v;
            })

          this.label('PHOTO (optional, tap to choose)')
          this.photoGrid()

          this.label('SONG LINK (optional)')
          TextInput({ placeholder: 'https://...', text: this.songUrl })
            .id('input_song')
            .type(InputType.URL)
            .backgroundColor(Theme.CARD)
            .onChange((v: string) => {
              this.songUrl = v;
            })

        }
        .alignItems(HorizontalAlign.Start)
        .padding({ left: Theme.PAD, right: Theme.PAD, bottom: 24 })
      }
      .layoutWeight(1)
      .align(Alignment.Top)

      if (this.errors.length > 0) {
        Column({ space: 4 }) {
          ForEach(this.errors, (e: string) => {
            Text(`• ${e}`).fontSize(14).fontColor(Theme.ERROR)
          }, (e: string) => e)
        }
        .id('errors')
        .alignItems(HorizontalAlign.Start)
        .width('92%')
        .padding(12)
        .margin({ top: 8 })
        .backgroundColor('#FDECEC')
        .borderRadius(12)
      }
      Row({ space: 12 }) {
        Button('Cancel')
          .id('btn_cancel')
          .layoutWeight(1)
          .height(48)
          .backgroundColor(Theme.PRIMARY_SOFT)
          .fontColor(Theme.PRIMARY)
          .onClick(() => {
            this.onCancel();
          })
        Button('Seal the box')
          .id('btn_seal')
          .layoutWeight(2)
          .height(48)
          .backgroundColor(Theme.PRIMARY)
          .onClick(() => {
            this.seal();
          })
      }
      .padding({ left: Theme.PAD, right: Theme.PAD, top: 8, bottom: 16 })
    }
    .width('100%')
    .layoutWeight(1)
  }

  private buildItems(): Item[] {
    const items: Item[] = [];
    if (this.letter.trim().length > 0) {
      const it: Item = { type: 'letter', text: this.letter.trim() };
      items.push(it);
    }
    if (this.photo.length > 0) {
      const it: Item = { type: 'photo', photoRes: this.photo };
      items.push(it);
    }
    if (this.songUrl.trim().length > 0) {
      const it: Item = { type: 'song', url: this.songUrl.trim() };
      items.push(it);
    }
    return items;
  }

  private buildUnlock(now: number): Unlock {
    if (this.unlockType === 'mood') {
      const u: Unlock = { type: 'mood', mood: this.mood };
      return u;
    }
    if (this.dateMode === 'minutes') {
      const n = Number(this.minutes);
      // NaN / <= 0 is reported by validateBox as "must be in the future".
      const u: Unlock = { type: 'date', at: isNaN(n) ? NaN : now + Math.round(n * 60 * 1000) };
      return u;
    }
    const u: Unlock = { type: 'date', at: this.at };
    return u;
  }

  private seal(): void {
    const now = Date.now();
    const box: Box = {
      id: newId(now),
      from: this.current,
      to: otherPerson(this.current),
      title: this.title.trim(),
      unlock: this.buildUnlock(now),
      items: this.buildItems(),
      status: 'sealed',
      createdAt: now
    };
    const result: ValidationResult = validateBox(box, now);
    this.errors = result.errors;
    if (result.ok) {
      this.onSeal(box);
    }
  }
}
