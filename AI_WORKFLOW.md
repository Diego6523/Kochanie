# AI workflow

How AI was used to build Kochanie (working name "Open When"), and how its output was checked.

## Tools

- **Model:** Claude Opus 5.5 (`claude-opus-5-5`), running as the coding agent in **Claude Code**
  (CLI) on Ubuntu 24.04.
- **Agents:** a single agent session. No sub-agents or multi-agent workflows.
- **Skills:** the brief lists the Oniro Agent Skills (ohos-app-scaffold, ohos-app-dev,
  ohos-system-dev), but they were not loaded in this session. The project was scaffolded with
  `oniro-app create` beforehand, and the agent drove the `oniro-app` CLI directly (`build`,
  `lint`, `app install/launch`, `watch`, `dump`, `input`, `screenshot`).
- **Instructions:** a written brief (product, environment, ArkTS rules, data model, business
  rules, phased plan, repo hygiene) was given to the agent at the start of the session.

## Main prompts

1. The brief itself (summarised): "You are the coding agent for a solo HackYeah 2026
   submission… work in small, verified steps… never claim something works without building and
   checking it on the emulator." It set out Phase 1 in 5 steps, with a commit after each.
2. The developer added: "if you need any extra info ask me first". The agent asked 4 questions
   before writing code: where the git root goes, demo photos (generate placeholders), the
   emulator state, and the UI labels (keep Me/Her).

## Process per step

For every step: write code → `oniro-app lint` → `oniro-app build` (with ArkTS warnings treated
as things to fix) → `oniro-app app install` + `launch` → drive the UI with
`oniro-app dump` / `input` → check `oniro-app screenshot` images and `watch` logs → commit.

## How the output was verified

- **Rules:** 14 unit tests (`./scripts/test-rules.sh`, Node 22 `node:test`) covering all 5
  business rules, the countdown formatting and `markOpened`.
- **APIs:** every non-trivial OpenHarmony API was checked against the SDK's `.d.ts` files
  before use (preferences sync API since API 14, `showDatePickerDialog` with `showTime` /
  `onDateAccept`, `showAlertDialog` button options).
- **UI:** each view was checked on the Oniro emulator through screenshots. The Phase 1
  acceptance scenario (Me creates a 1-minute box → Her sees it locked → after 1 minute it
  opens with the reveal animation) was run end to end. The reveal was captured as a burst
  contact sheet.

## Problems found during verification and fixed

- ArkTS warned that the preferences sync calls and `showToast` "may throw". They are now
  wrapped, so storage errors become messages instead of crashes (rule 5).
- Validation errors appeared below the fold. They moved above the action buttons.
- System Back exited the app from sub-views. `onBackPress` now returns to the list.
- **A locked box stayed locked at 00:00.** The `canOpen` result was passed into a `@Builder` as
  a by-value argument, which ArkUI does not re-evaluate when `now` changes. It is now computed
  from state inside the builder. Found only by watching the countdown on the emulator.
- The launcher label read "label" (template default). It was set to "Open When", later renamed to "Kochanie".

## Round 2: timed unlocks that work without the app

Prompt: "can you make the time functionality work? and do a quick example that can be opened a
couple of minutes from now (and actually that should be automatic, widget like)".

The agent read this as: date unlocks must notify even with the app closed, plus a self-updating
home-screen widget, plus a real example box on the emulator. It added `reminderAgentManager`
reminders, a FormExtensionAbility widget with a `TextTimer` countdown, and deep links from both
into the box.

Verified on the emulator: with the app closed, the notification arrived at the exact unlock
second (`anm dump` DeliveryTime). Tapping it opened the right box as the recipient. The widget
counted down live, flipped to "Ready to open!" at zero, and tapping it opened the box.

Bugs found while verifying:
- Selection chips never changed highlight (another by-value `@Builder` parameter). Fixed with a
  `Chip` component that takes `@Prop selected`.
- The notification prompt appeared while scripted taps were running and got denied. The request
  now happens when sealing a date box, not at launch.
- The widget showed `01:00` for a box that was already unlocked: `TextTimer` treats count 0 as
  60 s, and `ready` depended on a field that had not arrived yet.
- The widget did not tick: the controller was started before `TextTimer` existed. It now also
  starts in `onAppear`.
- The widget stuck at `00:00`: `onTimer`'s `elapsedTime` is not in ms. It now compares against
  the clock.
- After reinstalling, the launcher keeps a dead widget renderer (system log). Documented:
  re-add the widget.

## Round 3: rename to Kochanie

The developer asked to rename the app from its working name "Open When" to "Kochanie". Every
user-visible string was changed (launcher label, header, widget label and description). The
bundle name, preferences file names and log tag were kept on purpose, so existing data and
widgets keep working. Verified on the emulator: the existing boxes were still there and the
widget kept updating.

## What the developer did

Wrote the brief and product idea, set up the Linux toolchain and emulator, answered the agent's
setup questions, and reviewed the results.
