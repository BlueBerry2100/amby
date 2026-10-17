import 'package:flutter/material.dart';

import '../app_state.dart';
import '../look/components.dart';
import '../look/look.dart';

/// Нижняя панель текущего микса: число звуков, таймер, микшер, стоп, пауза.
class MixerBar extends StatelessWidget {
  const MixerBar({super.key, required this.state, required this.onSaveSet});

  final AppState state;
  final VoidCallback onSaveSet;

  @override
  Widget build(BuildContext context) {
    final look = Look.of(context);
    final names = state.active.keys.map((id) => state.soundById(id)?.name).nonNulls.join(', ');
    final sleepAt = state.sleepAt;

    return Padding(
      padding: EdgeInsets.fromLTRB(12, look.id == LookId.neu ? 8 : 0, 12, 10),
      child: LookSurface(
        radius: look.id == LookId.retro ? 6 : 28,
        onTap: () => showMixerSheet(context, state, onSaveSet),
        padding: const EdgeInsets.fromLTRB(18, 10, 10, 10),
        child: Row(
          children: [
            Text(state.active.length.toString().padLeft(2, '0'), style: look.display(34)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    look.t(
                      sleepAt == null
                          ? (state.paused ? 'Пауза' : 'В миксе')
                          : 'До ${_hhmm(sleepAt)}',
                    ),
                    style: look.label(
                      color: sleepAt == null ? look.text : look.accent,
                      size: 12,
                      weight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    look.caps ? names.toLowerCase() : names,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: look.label(size: 12),
                  ),
                ],
              ),
            ),
            LookIconButton(
              tooltip: 'Таймер сна',
              selected: sleepAt != null,
              icon: sleepAt == null ? Icons.timer_outlined : Icons.timer,
              onPressed: () => showSleepTimerSheet(context, state),
            ),
            const SizedBox(width: 6),
            LookIconButton(
              tooltip: 'Микшер',
              icon: Icons.tune,
              onPressed: () => showMixerSheet(context, state, onSaveSet),
            ),
            const SizedBox(width: 6),
            LookIconButton(tooltip: 'Стоп', icon: Icons.stop_rounded, onPressed: state.stopAll),
            const SizedBox(width: 8),
            LookIconButton(
              tooltip: state.paused ? 'Продолжить' : 'Пауза',
              filled: true,
              size: 54,
              icon: state.paused ? Icons.play_arrow_rounded : Icons.pause_rounded,
              onPressed: state.togglePause,
            ),
          ],
        ),
      ),
    );
  }
}

String _hhmm(DateTime t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

String _percent(double v) => (v * 100).round().toString().padLeft(2, '0');

void showMixerSheet(BuildContext context, AppState state, VoidCallback onSaveSet) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) => ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        final look = Look.of(context);
        if (!state.hasActive) {
          // всё выключили — закрываем шторку
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) Navigator.of(context).maybePop();
          });
        }
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.75),
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              children: [
                Text(look.t('Микшер'), style: look.label(size: 12)),
                const SizedBox(height: 16),
                _VolumeRow(
                  label: look.t('Общая'),
                  value: state.masterVolume,
                  onChanged: state.setMasterVolume,
                  big: true,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Divider(color: look.line, height: 1),
                ),
                for (final MapEntry(key: id, value: volume) in state.active.entries)
                  if (state.soundById(id) case final sound?)
                    _VolumeRow(
                      label: look.t(sound.name),
                      value: volume,
                      onChanged: (v) => state.setVolume(id, v),
                      onRemove: () => state.toggle(sound),
                    ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    onSaveSet();
                  },
                  icon: const Icon(Icons.bookmark_add_outlined, size: 20),
                  label: Text(look.t('Сохранить как сет')),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

class _VolumeRow extends StatelessWidget {
  const _VolumeRow({
    required this.label,
    required this.value,
    required this.onChanged,
    this.onRemove,
    this.big = false,
  });

  final String label;
  final double value;
  final ValueChanged<double> onChanged;
  final VoidCallback? onRemove;
  final bool big;

  @override
  Widget build(BuildContext context) {
    final look = Look.of(context);
    return SizedBox(
      height: big ? 56 : 48,
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: look.label(color: look.text, size: 13, weight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: LookSlider(value: value, onChanged: onChanged, height: big ? 26 : 20),
          ),
          SizedBox(
            width: 52,
            child: Text(
              _percent(value),
              textAlign: TextAlign.right,
              style: big ? look.display(24) : look.label(color: look.text, size: 13),
            ),
          ),
          SizedBox(
            width: 40,
            child: onRemove == null
                ? null
                : IconButton(
                    tooltip: 'Убрать из микса',
                    icon: Icon(Icons.close, size: 18, color: look.textDim),
                    onPressed: onRemove,
                  ),
          ),
        ],
      ),
    );
  }
}

void showSleepTimerSheet(BuildContext context, AppState state) {
  const options = [15, 30, 45, 60, 90, 120];
  showModalBottomSheet(
    context: context,
    builder: (context) {
      final look = Look.of(context);
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(look.t('Таймер сна'), style: look.label(size: 12)),
              const SizedBox(height: 6),
              Text('Звук плавно затихнет и выключится.', style: look.body(size: 14)),
              const SizedBox(height: 18),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final m in options)
                    OutlinedButton(
                      onPressed: () {
                        state.setSleepTimer(Duration(minutes: m));
                        Navigator.pop(context);
                      },
                      child: Text(
                        look.t(
                          m < 60 ? '$m мин' : '${m ~/ 60} ч${m % 60 == 0 ? '' : ' ${m % 60} мин'}',
                        ),
                      ),
                    ),
                  if (state.sleepAt != null)
                    FilledButton(
                      style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
                      onPressed: () {
                        state.cancelSleepTimer();
                        Navigator.pop(context);
                      },
                      child: Text(look.t('Отключить')),
                    ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}
