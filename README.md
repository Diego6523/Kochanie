# Open When

HackYeah 2026 · Huawei challenge "Imagine What's Next" · OpenHarmony app

Two partners send each other **boxes** with 1–3 items (a letter, a photo, a song link). A box
unlocks either **at a date/time** the sender picks, or at a **moment** the recipient picks
("open when you miss me / you're sad / you can't sleep").

Phase 1 (this version) is a one-device prototype. A toggle at the top, **I am: Me / Her**,
switches between the two partners so you can demo both sides on one emulator.

## Features (Phase 1)

- **List view:** boxes for you (Locked / Unlocked / When ready / Opened badge, live countdown for
  date boxes, mood label for mood boxes) and boxes you sent (status only).
- **Create view:** title; unlock "in N minutes" (quick chips 1 min / 5 min / 1 h) or at a date &
  time (system picker), or at a mood; optional letter, photo (3 bundled images) and song link.
  Rule violations show as messages above the buttons.
- **Open view:** a locked box shows a countdown and switches to "open" by itself at zero. A mood
  box asks "Is it really the moment?". Opening plays a lid-pop plus scale-and-fade reveal, then
  shows the photo, letter and song link.
- Data persists locally (`@ohos.data.preferences`). Two demo boxes are seeded on first launch.

## Unlocks without opening the app

- **System reminder:** sealing a date box schedules a `reminderAgentManager` timer reminder. At
  unlock time, "A box just unlocked" arrives as a notification even when the app is closed.
  Tapping it opens the app as the recipient, straight onto that box. The system asks for
  notification permission the first time you seal a date box.
- **Home-screen widget ("Next box"):** long-press the app icon → *add widget to desktop*. It
  shows the next box with a live countdown (`TextTimer`) and flips to **Ready to open!** at
  zero by itself. If nothing is counting down, it shows the most recently unlocked unopened
  box. Tapping it opens that box. The app pushes fresh data to the widget on every change.

## Business rules

All in `entry/src/main/ets/common/rules.ets` (pure functions, unit-tested):

1. A box has 1–3 items, with no repeated item type.
2. A date unlock must be in the future when sealing.
3. The sender can never open their own box; they only see its status.
4. A date box opens only when `now >= at`. A mood box opens any time, after confirmation.
5. Validation errors are shown as messages, never as crashes.

## Requirements

Tested on **Ubuntu 24.04**. DevEco Studio is not needed (and doesn't run on Linux).

| Tool | Version used |
| --- | --- |
| Node.js | 22.17 (via nvm) |
| Oniro App Builder CLI | `@oniroproject/oniro-app` 0.11.0 |
| OpenHarmony SDK | 6.1 / API 23 (installed with `oniro-app sdk`) |
| Command-line tools | installed with `oniro-app cmdtools` |
| Java | JDK 17+ on PATH, for signing (21 works too) |
| Emulator | Oniro Emulator (QEMU + KVM), OpenHarmony 6.1 |
| Python 3 + Pillow | only for `scripts/make-demo-photos.py` and `scripts/tap.sh` |

SDK levels (`build-profile.json5`): compatible 20, compile 23, target 23.

## Setup

```bash
npm install -g @oniroproject/oniro-app
oniro-app sdk install 6.1      # OpenHarmony SDK 6.1 = API 23
oniro-app cmdtools install     # hvigor / ohpm / codelinter
oniro-app emulator install
oniro-app emulator start
```

Clone the repo, then create a `local.properties` that points at your SDK (it is git-ignored):

```bash
echo "sdk.dir=$HOME/setup-ohos-sdk/linux" > local.properties
```

Generate your own signing material (`signatures/` is git-ignored; this rewrites the
`signingConfigs` block in `build-profile.json5`):

```bash
oniro-app sign
```

## Build & run

```bash
oniro-app emulator connect
oniro-app lint
oniro-app build
oniro-app app install
oniro-app app launch
oniro-app watch --bundle com.zuzu.openwhen --log OpenWhen   # app logs
```

Or run everything at once: `./scripts/dev-loop.sh` (lint → build → install → launch).

To reset demo data, reinstall from scratch:
`oniro-app app uninstall com.zuzu.openwhen && oniro-app app install`.

## Tests

The rules module has no `@kit` imports, so its tests run on the host with Node's built-in type
stripping (no device needed):

```bash
./scripts/test-rules.sh       # 15 tests, node:test
```

hvigor's local unit-test runner (`entry/src/test`, Hypium) needs DevEco Studio, so it is not
used here. UI flows were verified on the emulator with `oniro-app dump` / `input` /
`screenshot`; `scripts/tap.sh <id-or-text>` taps a node by its `.id()` or its text.

## Demo script (Phase 1 acceptance)

1. As **Me**, tap **+ New box for Her**, enter a title, keep "In N minutes = 1", add a letter
   and/or photo, then tap **Seal the box**.
2. Switch to **Her**. The box shows **Locked** with a live countdown; tap it to see the big
   countdown.
3. At 00:00 the button **It's time — open it** appears. Tap it to see the reveal.
4. Switch back to **Me**. The sent box now shows **Opened**.

## Known limitations

- After reinstalling the app (`oniro-app app install`), the launcher keeps a dead renderer for
  an existing widget (`UpdateForm failed … invalid FormRendererGroup` in hilog), so it stops
  updating. Remove the widget and add it again. Normal use (no reinstall) is not affected.
- If you deny the notification prompt, the emulator's Settings app has no per-app toggle to
  undo it. Uninstall and reinstall the app to be asked again.
- The emulator has no browser, so tapping a song link shows the system "Cannot open this file"
  dialog. On a device with a browser the link opens normally.
- Single-device prototype (both partners on one phone). Still planned: a 3D gift box, and a
  backend with pairing for two devices.

## Project layout

```
entry/src/main/ets/
  common/models.ets     data types
  common/rules.ets      business rules (pure)
  common/store.ets      preferences persistence + demo seed
  common/photos.ets     bundled demo photos
  common/theme.ets      colors
  common/reminders.ets  unlock notifications (reminderAgentManager)
  common/widget.ets     widget data + refresh, widget id bookkeeping
  entryability/         deep links from reminder / widget taps
  formability/          NextBoxFormAbility (widget provider)
  widget/pages/         NextBoxCard (widget UI)
  pages/Index.ets       single @Entry page, view switch, Me/Her toggle
  views/ListView.ets    list
  views/CreateView.ets  create
  views/OpenView.ets    open + reveal animation
tests/rules.test.ts     rule tests (Node)
scripts/                dev-loop, tests, tap helper, demo photo generator
```

Demo photos are generated placeholders (`scripts/make-demo-photos.py`). Replace
`entry/src/main/resources/base/media/demo_photo_{1,2,3}.jpg` with real ones if you like.
