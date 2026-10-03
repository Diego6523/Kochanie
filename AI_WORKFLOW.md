# AI workflow

How AI was used to build Open When, and how its output was checked.

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
- The launcher label read "label" (template default). It is now "Open When".

## What the developer did

Wrote the brief and product idea, set up the Linux toolchain and emulator, answered the agent's
setup questions, and reviewed the results.
