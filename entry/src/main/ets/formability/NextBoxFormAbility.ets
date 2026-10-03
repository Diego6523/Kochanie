import { formBindingData, FormExtensionAbility, formInfo } from '@kit.FormKit';
import { Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BoxStore } from '../common/store';
import { addFormId, buildWidgetData, pushWidgetData, removeFormId } from '../common/widget';

// Provides the "next box" home-screen widget. The app pushes updates on every change;
// this ability answers when a widget is added or the system asks for a refresh.
export default class NextBoxFormAbility extends FormExtensionAbility {
  onAddForm(want: Want): formBindingData.FormBindingData {
    const formId = (want.parameters?.[formInfo.FormParam.IDENTITY_KEY] ?? '') as string;
    if (formId.length > 0) {
      addFormId(this.context, formId);
    }
    hilog.info(0x0001, 'OpenWhen', 'Widget added: %{public}s', formId);
    const boxes = new BoxStore(this.context, true).load(Date.now());
    return formBindingData.createFormBindingData(buildWidgetData(boxes, Date.now()));
  }

  onUpdateForm(formId: string): void {
    const boxes = new BoxStore(this.context, true).load(Date.now());
    pushWidgetData(formId, buildWidgetData(boxes, Date.now()));
  }

  onRemoveForm(formId: string): void {
    removeFormId(this.context, formId);
  }

  onAcquireFormState(want: Want): formInfo.FormState {
    return formInfo.FormState.READY;
  }
}
