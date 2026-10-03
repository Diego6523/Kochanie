// Persistence: all boxes stored as one JSON array in @ohos.data.preferences.
import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { Box, Item } from './models';

const DOMAIN: number = 0x0001;
const TAG: string = 'OpenWhen';
const PREFS_NAME: string = 'openwhen';
const KEY_BOXES: string = 'boxes';
const KEY_SEEDED: string = 'seeded';

export function newId(now: number): string {
  return `${now.toString(36)}-${Math.floor(Math.random() * 1e6).toString(36)}`;
}

function demoBoxes(now: number): Box[] {
  const letter1: Item = {
    type: 'letter', text: 'Hi love! This is our first box. Every time you see it, remember I am thinking of you.'
  };
  const photo1: Item = { type: 'photo', photoRes: 'demo_photo_1' };
  const dateBox: Box = {
    id: newId(now),
    from: 'her',
    to: 'me',
    title: 'Our first box',
    unlock: { type: 'date', at: now + 2 * 60 * 1000 },
    items: [letter1, photo1],
    status: 'sealed',
    createdAt: now
  };
  const letter2: Item = {
    type: 'letter', text: 'Close your eyes, breathe slowly, and listen to this. I am right here.'
  };
  const song2: Item = { type: 'song', url: 'https://www.youtube.com/watch?v=hLQl3WQQoQ0' };
  const moodBox: Box = {
    id: newId(now + 1),
    from: 'me',
    to: 'her',
    title: 'For sleepless nights',
    unlock: { type: 'mood', mood: 'cant_sleep' },
    items: [letter2, song2],
    status: 'sealed',
    createdAt: now
  };
  return [dateBox, moodBox];
}

export class BoxStore {
  private prefs: preferences.Preferences;

  constructor(context: common.Context) {
    const options: preferences.Options = { name: PREFS_NAME };
    this.prefs = preferences.getPreferencesSync(context, options);
  }

  // Loads boxes; seeds the demo boxes on the very first launch.
  load(now: number): Box[] {
    try {
      if (!this.prefs.hasSync(KEY_SEEDED)) {
        const seed = demoBoxes(now);
        this.prefs.putSync(KEY_BOXES, JSON.stringify(seed));
        this.prefs.putSync(KEY_SEEDED, true);
        this.prefs.flushSync();
        return seed;
      }
      const raw = this.prefs.getSync(KEY_BOXES, '[]') as string;
      return JSON.parse(raw) as Box[];
    } catch (e) {
      hilog.error(DOMAIN, TAG, 'Could not load boxes, starting empty: %{public}s', JSON.stringify(e));
      return [];
    }
  }

  // Returns false if the write failed so the UI can tell the user.
  save(boxes: Box[]): boolean {
    try {
      this.prefs.putSync(KEY_BOXES, JSON.stringify(boxes));
      this.prefs.flushSync();
      return true;
    } catch (e) {
      hilog.error(DOMAIN, TAG, 'Could not save boxes: %{public}s', JSON.stringify(e));
      return false;
    }
  }
}
