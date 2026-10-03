// Data model for Open When. Keep this file free of @kit imports so the rules
// can be unit-tested with plain Node (see scripts/test-rules.sh).

export type ItemType = 'letter' | 'photo' | 'song';
export type UnlockType = 'date' | 'mood';
export type Mood = 'miss_me' | 'sad' | 'cant_sleep';
export type Person = 'me' | 'her';
export type BoxStatus = 'sealed' | 'opened';

export interface Item {
  type: ItemType;
  text?: string;
  photoRes?: string;
  url?: string;
}

export interface Unlock {
  type: UnlockType;
  at?: number; // epoch ms
  mood?: Mood;
}

export interface Box {
  id: string;
  from: Person;
  to: Person;
  title: string;
  unlock: Unlock;
  items: Item[];
  status: BoxStatus;
  openedAt?: number;
  createdAt: number;
}
