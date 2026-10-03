import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { PARAM_BOX_ID } from '../common/reminders';

// AppStorage key Index watches to open a box (value: "<boxId>#<timestamp>").
export const DEEP_LINK_KEY: string = 'deepLinkBox';

interface CardRouterParams {
  boxId?: string;
}

// Reminder taps put boxId straight into want.parameters; widget taps (postCardAction router)
// deliver it JSON-encoded under "params".
function boxIdFromWant(want: Want): string {
  const p = want.parameters;
  if (p === undefined) {
    return '';
  }
  const direct = p[PARAM_BOX_ID];
  if (typeof direct === 'string') {
    return direct;
  }
  const raw = p['params'];
  if (typeof raw === 'string') {
    try {
      const parsed = JSON.parse(raw) as CardRouterParams;
      return parsed.boxId ?? '';
    } catch (e) {
      return '';
    }
  }
  return '';
}

function handleDeepLink(want: Want): void {
  const id = boxIdFromWant(want);
  if (id.length > 0) {
    AppStorage.setOrCreate<string>(DEEP_LINK_KEY, `${id}#${Date.now()}`);
  }
}

const DOMAIN = 0x0000;

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    try {
      this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    } catch (err) {
      hilog.error(DOMAIN, 'testTag', 'Failed to set colorMode. Cause: %{public}s', JSON.stringify(err));
    }
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onCreate');
    handleDeepLink(want);
  }

  onNewWant(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    handleDeepLink(want);
  }

  onDestroy(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    // Main window is created, set main page for this ability
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageCreate');

    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err));
        return;
      }
      hilog.info(DOMAIN, 'testTag', 'Succeeded in loading the content.');
    });
  }

  onWindowStageDestroy(): void {
    // Main window is destroyed, release UI related resources
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    // Ability has brought to foreground
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onForeground');
  }

  onBackground(): void {
    // Ability has back to background
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onBackground');
  }
}