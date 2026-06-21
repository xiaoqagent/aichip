import { UIAbility } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';

export default class EntryAbility extends UIAbility {
  onCreate(): void {
    hilog.info(0x0001, 'AIChip', 'EntryAbility onCreate');
  }

  onDestroy(): void {
    hilog.info(0x0001, 'AIChip', 'EntryAbility onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    hilog.info(0x0001, 'AIChip', 'onWindowStageCreate');
    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        hilog.error(0x0001, 'AIChip', 'Failed to load content: %{public}d', err.code);
      }
    });
  }
}
