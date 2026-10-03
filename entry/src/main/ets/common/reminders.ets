// System reminders: the "box unlocked" notification arrives even when the app is closed.
import { reminderAgentManager } from '@kit.BackgroundTasksKit';
import { notificationManager } from '@kit.NotificationKit';
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { Box } from './models';
import { personLabel } from './rules';

const DOMAIN: number = 0x0001;
const TAG: string = 'OpenWhen';
export const BUNDLE_NAME: string = 'com.zuzu.openwhen';
export const ABILITY_NAME: string = 'EntryAbility';
// Key used in want.parameters to deep-link into a box (reminder tap / widget tap).
export const PARAM_BOX_ID: string = 'boxId';

export async function ensureNotificationsEnabled(context: common.UIAbilityContext): Promise<void> {
  try {
    const enabled = await notificationManager.isNotificationEnabled();
    if (!enabled) {
      await notificationManager.requestEnableNotification(context);
    }
  } catch (e) {
    const err = e as BusinessError;
    hilog.warn(DOMAIN, TAG, 'Notifications not enabled: %{public}d %{public}s', err.code, err.message);
  }
}

// Schedules a notification at the box's unlock time. Returns false if it could not be scheduled
// (the box still works; the user just will not get the notification).
export async function scheduleUnlockReminder(box: Box, now: number): Promise<boolean> {
  if (box.unlock.type !== 'date' || box.unlock.at === undefined || box.unlock.at <= now) {
    return false;
  }
  const params: Record<string, Object> = {};
  params[PARAM_BOX_ID] = box.id;
  const reminder: reminderAgentManager.ReminderRequestTimer = {
    reminderType: reminderAgentManager.ReminderType.REMINDER_TYPE_TIMER,
    triggerTimeInSeconds: Math.max(1, Math.round((box.unlock.at - now) / 1000)),
    title: 'A box just unlocked',
    content: `"${box.title}" from ${personLabel(box.from)} is ready for ${personLabel(box.to)} to open.`,
    wantAgent: { pkgName: BUNDLE_NAME, abilityName: ABILITY_NAME, parameters: params },
    tapDismissed: true
  };
  try {
    const id = await reminderAgentManager.publishReminder(reminder);
    hilog.info(DOMAIN, TAG, 'Reminder %{public}d scheduled in %{public}ds', id, reminder.triggerTimeInSeconds);
    return true;
  } catch (e) {
    const err = e as BusinessError;
    hilog.error(DOMAIN, TAG, 'publishReminder failed: %{public}d %{public}s', err.code, err.message);
    return false;
  }
}
