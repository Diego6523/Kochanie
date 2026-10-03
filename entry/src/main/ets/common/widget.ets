// Home-screen widget ("next box" countdown): data shape + refresh helpers.
// The form extension runs in its own process, so every read here drops the preferences
// cache first to see what the app wrote.
import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { formBindingData, formProvider } from '@kit.FormKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { Box } from './models';
import { moodLabel, nextCountdownBox, personLabel } from './rules';

const DOMAIN: number = 0x0001;
const TAG: string = 'OpenWhen';
const FORMS_PREFS: string = 'openwhen_forms';
const KEY_IDS: string = 'ids';

// Field names must match the @LocalStorageProp keys in widget/pages/NextBoxCard.ets.
export class WidgetData {
  hasBox: boolean = false;
  boxId: string = '';
  title: string = '';
  forWho: string = '';
  atMs: number = 0;
  atLabel: string = '';
  hint: string = '';
}

function two(n: number): string {
  return n < 10 ? `0${n}` : `${n}`;
}

export function buildWidgetData(boxes: Box[], now: number): WidgetData {
  const data = new WidgetData();
  const box = nextCountdownBox(boxes, now);
  if (box === undefined || box.unlock.at === undefined) {
    const moods = boxes.filter((b: Box) => b.status === 'sealed' && b.unlock.type === 'mood');
    data.hint = moods.length > 0 ? `${moods.length} box(es) waiting: ${moodLabel(moods[0].unlock.mood).toLowerCase()}`
      : 'No sealed boxes yet';
    return data;
  }
  const d = new Date(box.unlock.at);
  data.hasBox = true;
  data.boxId = box.id;
  data.title = box.title;
  data.forWho = `For ${personLabel(box.to)} · from ${personLabel(box.from)}`;
  data.atMs = box.unlock.at;
  data.atLabel = box.unlock.at - now < 24 * 3600 * 1000 ? `unlocks at ${two(d.getHours())}:${two(d.getMinutes())}`
    : `unlocks ${d.getFullYear()}-${two(d.getMonth() + 1)}-${two(d.getDate())} ${two(d.getHours())}:${two(d.getMinutes())}`;
  return data;
}

function formsPrefs(context: common.Context): preferences.Preferences | null {
  const options: preferences.Options = { name: FORMS_PREFS };
  try {
    preferences.removePreferencesFromCacheSync(context, options);
    return preferences.getPreferencesSync(context, options);
  } catch (e) {
    hilog.error(DOMAIN, TAG, 'forms preferences unavailable: %{public}s', JSON.stringify(e));
    return null;
  }
}

export function loadFormIds(context: common.Context): string[] {
  const p = formsPrefs(context);
  if (p === null) {
    return [];
  }
  try {
    return JSON.parse(p.getSync(KEY_IDS, '[]') as string) as string[];
  } catch (e) {
    hilog.error(DOMAIN, TAG, 'loadFormIds failed: %{public}s', JSON.stringify(e));
    return [];
  }
}

function saveFormIds(context: common.Context, ids: string[]): void {
  const p = formsPrefs(context);
  if (p === null) {
    return;
  }
  try {
    p.putSync(KEY_IDS, JSON.stringify(ids));
    p.flushSync();
  } catch (e) {
    hilog.error(DOMAIN, TAG, 'saveFormIds failed: %{public}s', JSON.stringify(e));
  }
}

export function addFormId(context: common.Context, formId: string): void {
  const ids = loadFormIds(context).filter((id: string) => id !== formId);
  ids.push(formId);
  saveFormIds(context, ids);
}

export function removeFormId(context: common.Context, formId: string): void {
  saveFormIds(context, loadFormIds(context).filter((id: string) => id !== formId));
}

export function pushWidgetData(formId: string, data: WidgetData): void {
  formProvider.updateForm(formId, formBindingData.createFormBindingData(data)).catch((err: BusinessError) => {
    hilog.warn(DOMAIN, TAG, 'updateForm %{public}s failed: %{public}d', formId, err.code);
  });
}

// Called by the app after every change to the boxes.
export function refreshAllWidgets(context: common.Context, boxes: Box[]): void {
  const data = buildWidgetData(boxes, Date.now());
  for (const id of loadFormIds(context)) {
    pushWidgetData(id, data);
  }
}
