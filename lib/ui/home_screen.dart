import 'package:flutter/material.dart';

import '../app_state.dart';
import '../catalog.dart';
import '../look/components.dart';
import '../look/look.dart';
import '../models.dart';
import 'mixer_bar.dart';
import 'sets_view.dart';
import 'sound_editor.dart';
import 'sound_tile.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.state});

  final AppState state;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;

  AppState get state => widget.state;

  /// С этой ширины сеты показываются боковой панелью, а не отдельной вкладкой.
  static const _sidePanelBreakpoint = 900.0;

  @override
  void initState() {
    super.initState();
    state.addListener(_showErrors);
  }

  @override
  void dispose() {
    state.removeListener(_showErrors);
    super.dispose();
  }

  void _showErrors() {
    final error = state.lastError;
    if (error == null) return;
    state.lastError = null;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
  }

  void _openEditor([Sound? sound]) => Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => SoundEditorScreen(state: state, sound: sound),
    ),
  );

  Future<void> _saveSet() async {
    final name = await askName(context, title: 'Сохранить микс как сет');
    if (name == null) return;
    await state.saveCurrentAsSet(name);
    if (mounted) setState(() => _tab = 1);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) => Scaffold(
        body: LookBackground(
          child: LayoutBuilder(
            builder: (context, constraints) =>
                constraints.maxWidth >= _sidePanelBreakpoint ? _wide() : _narrow(),
          ),
        ),
      ),
    );
  }

  /// Десктоп: звуки слева, сеты — постоянной панелью справа.
  Widget _wide() {
    final look = Look.of(context);
    return SafeArea(
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                _Header(state: state, onSaveSet: _saveSet),
                Expanded(
                  child: _SoundsGrid(state: state, onEdit: _openEditor),
                ),
                if (state.hasActive) MixerBar(state: state, onSaveSet: _saveSet),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 12, 12, 12),
            child: SizedBox(
              width: 360,
              child: LookPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 22, 20, 14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(look.caps ? 'SETS' : 'Сеты', style: look.display(30)),
                          const Spacer(),
                          Text(
                            state.sets.length.toString().padLeft(2, '0'),
                            style: look.label(color: look.text),
                          ),
                        ],
                      ),
                    ),
                    Expanded(child: SetsView(state: state)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Телефон: звуки и сеты — вкладками внизу.
  Widget _narrow() {
    return SafeArea(
      child: Column(
        children: [
          _Header(state: state, onSaveSet: _saveSet),
          Expanded(
            child: IndexedStack(
              index: _tab,
              children: [
                _SoundsGrid(state: state, onEdit: _openEditor),
                SetsView(state: state),
              ],
            ),
          ),
          if (state.hasActive) MixerBar(state: state, onSaveSet: _saveSet),
          LookTabs(
            index: _tab,
            labels: const ['Звуки', 'Сеты'],
            onChanged: (i) => setState(() => _tab = i),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.state, required this.onSaveSet});

  final AppState state;
  final VoidCallback onSaveSet;

  @override
  Widget build(BuildContext context) {
    final look = Look.of(context);
    final playing = state.hasActive && !state.paused;
    final status = !state.hasActive
        ? 'Тишина'
        : state.paused
        ? 'Пауза'
        : 'Играет · ${state.active.length.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 14, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(look.caps ? 'AMBY' : 'Amby', style: look.display(46)),
              const SizedBox(height: 8),
              Row(
                children: [
                  if (look.id == LookId.air || look.id == LookId.neu)
                    PlayingBars(
                      active: playing,
                      height: 10,
                      color: playing ? look.accent : look.textFaint,
                    )
                  else
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: playing ? look.accent : look.textFaint,
                        shape: look.id == LookId.retro ? BoxShape.rectangle : BoxShape.circle,
                      ),
                    ),
                  const SizedBox(width: 8),
                  Text(
                    look.t(status),
                    style: look.label(color: playing ? look.text : look.textDim, size: 12),
                  ),
                ],
              ),
            ],
          ),
          const Spacer(),
          if (state.hasActive) ...[
            LookIconButton(
              tooltip: 'Сохранить микс как сет',
              icon: Icons.bookmark_add_outlined,
              onPressed: onSaveSet,
            ),
            const SizedBox(width: 10),
          ],
          LookIconButton(
            tooltip: 'Оформление',
            icon: Icons.palette_outlined,
            selected: true,
            onPressed: () => showLookSheet(context, state),
          ),
        ],
      ),
    );
  }
}

class _SoundsGrid extends StatelessWidget {
  const _SoundsGrid({required this.state, required this.onEdit});

  final AppState state;
  final void Function([Sound? sound]) onEdit;

  @override
  Widget build(BuildContext context) {
    final look = Look.of(context);
    final sounds = state.sounds;
    final gap = look.id == LookId.neu ? 18.0 : 10.0; // неоморфизму нужно место под тени
    return GridView.builder(
      padding: EdgeInsets.fromLTRB(gap + 2, look.id == LookId.neu ? 8 : 0, gap + 2, 16),
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: look.id == LookId.neu ? 150 : 170,
        mainAxisSpacing: gap,
        crossAxisSpacing: gap,
        childAspectRatio: look.tileAspect,
      ),
      itemCount: sounds.length + 1,
      itemBuilder: (context, i) {
        if (i == sounds.length) return AddSoundTile(onTap: onEdit);
        final sound = sounds[i];
        return SoundTile(
          sound: sound,
          index: i + 1,
          active: state.isActive(sound.id),
          volume: state.volumeOf(sound.id),
          onTap: () => state.toggle(sound),
          onVolume: (v) => state.setVolume(sound.id, v),
          onEdit: sound.isCustom ? () => onEdit(sound) : null,
        );
      },
    );
  }
}

/// Выбор оформления и акцентного цвета. Каждый вариант показан живой карточкой
/// в своём оформлении.
void showLookSheet(BuildContext context, AppState state) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) => ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        final look = Look.of(context);
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.85),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(look.t('Оформление'), style: look.label()),
                  const SizedBox(height: 14),
                  LayoutBuilder(
                    builder: (context, c) {
                      final w = ((c.maxWidth - 12) / 2).clamp(0.0, 220.0);
                      return Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          for (final id in LookId.values)
                            SizedBox(
                              width: w,
                              child: _LookOption(
                                id: id,
                                accent: state.accent,
                                selected: id == state.lookId,
                                onTap: () => state.setLook(id),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  Text(look.t('Акцентный цвет'), style: look.label()),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 14,
                    runSpacing: 14,
                    children: [
                      for (final MapEntry(key: key, value: color) in Accents.all.entries)
                        GestureDetector(
                          onTap: () => state.setAccent(key),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            width: 50,
                            height: 50,
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: key == state.accentKey ? look.text : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: DecoratedBox(
                              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}

class _LookOption extends StatelessWidget {
  const _LookOption({
    required this.id,
    required this.accent,
    required this.selected,
    required this.onTap,
  });

  final LookId id;
  final Color accent;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final current = Look.of(context);
    final preview = Look.build(id, accent);
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            height: 170,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: selected ? accent : current.line,
                width: selected ? 2.5 : 1,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Theme(
              data: preview.toTheme(),
              child: LookBackground(
                child: Center(
                  child: SizedBox(
                    width: 104,
                    child: AspectRatio(
                      aspectRatio: preview.tileAspect,
                      // живая карточка «Дождь» в этом оформлении
                      child: SoundTile(
                        sound: builtInSounds.first,
                        index: 1,
                        active: true,
                        volume: 0.6,
                        onTap: onTap,
                        onVolume: (_) {},
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            current.t(id.title),
            style: current.label(
              color: selected ? accent : current.text,
              size: 13,
              weight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Диалог ввода названия. Возвращает null при отмене.
Future<String?> askName(BuildContext context, {required String title, String initial = ''}) {
  final controller = TextEditingController(text: initial);
  final look = Look.of(context);
  return showDialog<String>(
    context: context,
    builder: (context) {
      void submit() {
        final text = controller.text.trim();
        if (text.isNotEmpty) Navigator.pop(context, text);
      }

      return AlertDialog(
        title: Text(look.t(title)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: look.body(),
          decoration: InputDecoration(hintText: look.t('Название')),
          onSubmitted: (_) => submit(),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(look.t('Отмена'))),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
            onPressed: submit,
            child: Text(look.t('Сохранить')),
          ),
        ],
      );
    },
  );
}
