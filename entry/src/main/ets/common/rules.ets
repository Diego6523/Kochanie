// Business rules for Kochanie — pure functions only (no @kit imports, no I/O),
// so they can be unit-tested outside the device (see scripts/test-rules.sh).
import { Box, Item, ItemType, Mood, Person } from './models';

export const MAX_ITEMS: number = 3;
export const MIN_ITEMS: number = 1;

export interface ValidationResult {
  ok: boolean;
  errors: string[];
}

export interface OpenCheck {
  allowed: boolean;
  needsConfirm: boolean;
  reason: string;
}

export function moodLabel(mood: Mood | undefined): string {
  if (mood === 'miss_me') {
    return 'Open when you miss me';
  }
  if (mood === 'sad') {
    return 'Open when you are sad';
  }
  if (mood === 'cant_sleep') {
    return 'Open when you can\'t sleep';
  }
  return 'Open when the moment comes';
}

export function personLabel(p: Person): string {
  return p === 'me' ? 'Me' : 'Her';
}

export function otherPerson(p: Person): Person {
  return p === 'me' ? 'her' : 'me';
}

function isHttpUrl(url: string): boolean {
  const u = url.trim().toLowerCase();
  return (u.startsWith('http://') || u.startsWith('https://')) && u.length > 'https://'.length;
}

// Rules 1 + 2 + 5: everything that must hold before a box can be sealed.
// Returns user-facing messages; never throws.
export function validateBox(box: Box, now: number): ValidationResult {
  const errors: string[] = [];

  if (box.title.trim().length === 0) {
    errors.push('Give your box a title.');
  }
  if (box.from === box.to) {
    errors.push('A box must be sent to your partner, not to yourself.');
  }

  // Rule 1: 1–3 items, no repeated type.
  if (box.items.length < MIN_ITEMS) {
    errors.push('Add at least one thing to the box: a letter, a photo or a song.');
  }
  if (box.items.length > MAX_ITEMS) {
    errors.push('A box can hold at most 3 items.');
  }
  const seen: ItemType[] = [];
  for (const item of box.items) {
    if (seen.includes(item.type)) {
      errors.push(`Only one ${item.type} per box.`);
    } else {
      seen.push(item.type);
    }
    for (const e of validateItem(item)) {
      errors.push(e);
    }
  }

  // Rule 2: date unlock must be in the future at sealing time.
  if (box.unlock.type === 'date') {
    if (box.unlock.at === undefined || isNaN(box.unlock.at)) {
      errors.push('Pick when the box should unlock.');
    } else if (box.unlock.at <= now) {
      errors.push('The unlock time must be in the future.');
    }
  } else if (box.unlock.mood === undefined) {
    errors.push('Pick a moment for the box to be opened.');
  }

  const result: ValidationResult = { ok: errors.length === 0, errors: errors };
  return result;
}

function validateItem(item: Item): string[] {
  const errors: string[] = [];
  if (item.type === 'letter' && (item.text === undefined || item.text.trim().length === 0)) {
    errors.push('The letter is empty.');
  }
  if (item.type === 'photo' && (item.photoRes === undefined || item.photoRes.length === 0)) {
    errors.push('Choose a photo.');
  }
  if (item.type === 'song' && (item.url === undefined || !isHttpUrl(item.url))) {
    errors.push('The song link must start with http:// or https://');
  }
  return errors;
}

// Rule 4 (date part): has the unlock time been reached?
export function isUnlocked(box: Box, now: number): boolean {
  if (box.unlock.type === 'mood') {
    return true;
  }
  return box.unlock.at !== undefined && now >= box.unlock.at;
}

export function msUntilUnlock(box: Box, now: number): number {
  if (box.unlock.type !== 'date' || box.unlock.at === undefined) {
    return 0;
  }
  return Math.max(0, box.unlock.at - now);
}

// Rules 3 + 4: may `viewer` open `box` right now?
export function canOpen(box: Box, viewer: Person, now: number): OpenCheck {
  if (viewer === box.from) {
    const r: OpenCheck = {
      allowed: false, needsConfirm: false, reason: 'You sent this box — only your partner can open it.'
    };
    return r;
  }
  if (viewer !== box.to) {
    const r: OpenCheck = { allowed: false, needsConfirm: false, reason: 'This box is not for you.' };
    return r;
  }
  if (box.status === 'opened') {
    const r: OpenCheck = { allowed: true, needsConfirm: false, reason: '' };
    return r;
  }
  if (box.unlock.type === 'mood') {
    const r: OpenCheck = { allowed: true, needsConfirm: true, reason: '' };
    return r;
  }
  if (isUnlocked(box, now)) {
    const r: OpenCheck = { allowed: true, needsConfirm: false, reason: '' };
    return r;
  }
  const r: OpenCheck = {
    allowed: false, needsConfirm: false, reason: `Unlocks in ${formatCountdown(msUntilUnlock(box, now))}`
  };
  return r;
}

function pad2(n: number): string {
  return n < 10 ? `0${n}` : `${n}`;
}

// 65_000 ms -> "01:05", 3_725_000 -> "1:02:05", 90_061_000 -> "1d 01:01:01"
export function formatCountdown(ms: number): string {
  const total = Math.max(0, Math.ceil(ms / 1000));
  const days = Math.floor(total / 86400);
  const hours = Math.floor((total % 86400) / 3600);
  const mins = Math.floor((total % 3600) / 60);
  const secs = total % 60;
  if (days > 0) {
    return `${days}d ${pad2(hours)}:${pad2(mins)}:${pad2(secs)}`;
  }
  if (hours > 0) {
    return `${hours}:${pad2(mins)}:${pad2(secs)}`;
  }
  return `${pad2(mins)}:${pad2(secs)}`;
}

// Returns a new box marked as opened (immutable update for @State).
export function markOpened(box: Box, now: number): Box {
  const opened: Box = {
    id: box.id,
    from: box.from,
    to: box.to,
    title: box.title,
    unlock: box.unlock,
    items: box.items,
    status: 'opened',
    openedAt: box.openedAt ?? now,
    createdAt: box.createdAt
  };
  return opened;
}

// The box the widget counts down to: the sealed date box that unlocks soonest in the future.
// If none is still counting down, the most recently unlocked unopened one ("ready to open").
export function nextCountdownBox(boxes: Box[], now: number): Box | undefined {
  let upcoming: Box | undefined = undefined;
  let ready: Box | undefined = undefined;
  for (const b of boxes) {
    if (b.status !== 'sealed' || b.unlock.type !== 'date' || b.unlock.at === undefined) {
      continue;
    }
    if (b.unlock.at > now) {
      if (upcoming === undefined || b.unlock.at < (upcoming.unlock.at ?? 0)) {
        upcoming = b;
      }
    } else if (ready === undefined || b.unlock.at > (ready.unlock.at ?? 0)) {
      ready = b;
    }
  }
  return upcoming ?? ready;
}
