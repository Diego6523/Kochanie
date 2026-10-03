// Unit tests for entry/src/main/ets/common/rules.ets — run with scripts/test-rules.sh
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { validateBox, canOpen, isUnlocked, msUntilUnlock, formatCountdown, markOpened, nextCountdownBox } from './rules.ts';
import type { Box, Item } from './models.ts';

const NOW = 1_700_000_000_000;
const letter: Item = { type: 'letter', text: 'hello' };
const photo: Item = { type: 'photo', photoRes: 'demo_photo_1' };
const song: Item = { type: 'song', url: 'https://example.com/song' };

function dateBox(over: Partial<Box> = {}): Box {
  return {
    id: 'b1', from: 'me', to: 'her', title: 'Test',
    unlock: { type: 'date', at: NOW + 60_000 },
    items: [letter], status: 'sealed', createdAt: NOW, ...over
  };
}

function moodBox(over: Partial<Box> = {}): Box {
  return dateBox({ unlock: { type: 'mood', mood: 'sad' }, ...over });
}

test('rule 1: valid box with 1..3 distinct items', () => {
  assert.equal(validateBox(dateBox(), NOW).ok, true);
  assert.equal(validateBox(dateBox({ items: [letter, photo, song] }), NOW).ok, true);
});

test('rule 1: zero items is rejected', () => {
  const r = validateBox(dateBox({ items: [] }), NOW);
  assert.equal(r.ok, false);
  assert.match(r.errors.join(' '), /at least one/);
});

test('rule 1: more than 3 items is rejected', () => {
  const r = validateBox(dateBox({ items: [letter, photo, song, { type: 'letter', text: 'x' }] }), NOW);
  assert.equal(r.ok, false);
  assert.match(r.errors.join(' '), /at most 3/);
});

test('rule 1: repeated item type is rejected', () => {
  const r = validateBox(dateBox({ items: [letter, { type: 'letter', text: 'again' }] }), NOW);
  assert.equal(r.ok, false);
  assert.match(r.errors.join(' '), /Only one letter/);
});

test('rule 2: date unlock in the past or now is rejected', () => {
  assert.equal(validateBox(dateBox({ unlock: { type: 'date', at: NOW - 1 } }), NOW).ok, false);
  assert.equal(validateBox(dateBox({ unlock: { type: 'date', at: NOW } }), NOW).ok, false);
  assert.equal(validateBox(dateBox({ unlock: { type: 'date' } }), NOW).ok, false);
});

test('mood box needs a mood', () => {
  assert.equal(validateBox(moodBox(), NOW).ok, true);
  assert.equal(validateBox(dateBox({ unlock: { type: 'mood' } }), NOW).ok, false);
});

test('rule 5: item content problems give messages, not exceptions', () => {
  const r = validateBox(dateBox({
    title: '  ', items: [{ type: 'letter', text: ' ' }, { type: 'song', url: 'not a url' }, { type: 'photo' }]
  }), NOW);
  assert.equal(r.ok, false);
  assert.equal(r.errors.length, 4);
});

test('cannot send a box to yourself', () => {
  assert.equal(validateBox(dateBox({ to: 'me' }), NOW).ok, false);
});

test('rule 3: sender can never open their own box', () => {
  const b = moodBox();
  assert.equal(canOpen(b, 'me', NOW).allowed, false);
  assert.equal(canOpen({ ...b, status: 'opened' }, 'me', NOW).allowed, false);
  assert.equal(canOpen(dateBox(), 'me', NOW + 10 * 60_000).allowed, false);
});

test('rule 4: date box opens only when now >= at', () => {
  const b = dateBox();
  const early = canOpen(b, 'her', NOW);
  assert.equal(early.allowed, false);
  assert.match(early.reason, /Unlocks in 01:00/);
  assert.equal(canOpen(b, 'her', NOW + 60_000).allowed, true);
  assert.equal(canOpen(b, 'her', NOW + 60_000).needsConfirm, false);
  assert.equal(isUnlocked(b, NOW + 59_999), false);
  assert.equal(msUntilUnlock(b, NOW + 30_000), 30_000);
});

test('rule 4: mood box opens any time, with confirmation', () => {
  const c = canOpen(moodBox(), 'her', NOW);
  assert.equal(c.allowed, true);
  assert.equal(c.needsConfirm, true);
});

test('opened box can be re-viewed by recipient without confirmation', () => {
  const c = canOpen(moodBox({ status: 'opened' }), 'her', NOW);
  assert.equal(c.allowed, true);
  assert.equal(c.needsConfirm, false);
});

test('formatCountdown', () => {
  assert.equal(formatCountdown(0), '00:00');
  assert.equal(formatCountdown(65_000), '01:05');
  assert.equal(formatCountdown(3_725_000), '1:02:05');
  assert.equal(formatCountdown(90_061_000), '1d 01:01:01');
  assert.equal(formatCountdown(-5), '00:00');
});

test('markOpened sets status and keeps first openedAt', () => {
  const o = markOpened(moodBox(), NOW + 5);
  assert.equal(o.status, 'opened');
  assert.equal(o.openedAt, NOW + 5);
  assert.equal(markOpened(o, NOW + 99).openedAt, NOW + 5);
});

test('nextCountdownBox prefers the soonest upcoming box, then the latest ready one', () => {
  const a = dateBox({ id: 'a', unlock: { type: 'date', at: NOW + 5000 } });
  const b = dateBox({ id: 'b', unlock: { type: 'date', at: NOW + 1000 } });
  const ready = dateBox({ id: 'r', unlock: { type: 'date', at: NOW - 1000 } });
  const opened = dateBox({ id: 'c', unlock: { type: 'date', at: NOW + 10 }, status: 'opened' });
  assert.equal(nextCountdownBox([a, ready, b, opened, moodBox({ id: 'm' })], NOW)?.id, 'b');
  const older = dateBox({ id: 'o', unlock: { type: 'date', at: NOW - 9000 } });
  assert.equal(nextCountdownBox([older, ready, opened], NOW)?.id, 'r');
  assert.equal(nextCountdownBox([opened, moodBox()], NOW), undefined);
});
