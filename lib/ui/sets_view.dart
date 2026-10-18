import 'package:flutter/material.dart';

import '../app_state.dart';
import '../look/components.dart';
import '../look/look.dart';
import '../models.dart';

class SetsView extends StatelessWidget {
  const SetsView({super.key, required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final look = Look.of(context);
    final builtIn = state.sets.where((s) => s.builtIn).toList();
    final custom = state.sets.where((s) => !s.builtIn).toList();
    final pad = look.id == LookId.neu ? 20.0 : 16.0;

    Widget header(String text) => Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
      child: Text(look.t(text), style: look.label(size: 12)),
    );

    return ListView(
      padding: EdgeInsets.fromLTRB(pad, 4, pad, 16),
      children: [
        if (builtIn.isNotEmpty) ...[
          header('Готовые сеты'),
          for (final (i, set) in builtIn.indexed) _SetCard(state: state, set: set, index: i + 1),
          const SizedBox(height: 20),
        ],
        header('Мои сеты'),
        if (custom.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(look.id == LookId.retro ? 4 : 24),
              border: Border.all(color: look.line, width: 1.5),
            ),
            child: Text(
              look.t('Включите несколько звуков, настройте громкость и сохраните микс как сет'),
              style: look.label(size: 12),
            ),
          ),
        for (final (i, set) in custom.indexed)
          _SetCard(state: state, set: set, index: builtIn.length + i + 1),
      ],
    );
  }
}

class _SetCard extends StatelessWidget {
  const _SetCard({required this.state, required this.set, required this.index});

  final AppState state;
  final SoundSet set;
  final int index;

  @override
  Widget build(BuildContext context) {
    final look = Look.of(context);
    final active = state.isSetActive(set);
    final fg = active ? look.activeText : look.text;
    final names = set.volumes.keys.map((id) => state.soundById(id)?.name).nonNulls.join(' · ');

    return Padding(
      padding: EdgeInsets.only(bottom: look.id == LookId.neu ? 16 : 10),
      child: LookSurface(
        active: active,
        onTap: () => active ? state.stopAll() : state.applySet(set),
        padding: const EdgeInsets.fromLTRB(18, 16, 12, 16),
        child: Row(
          children: [
            SizedBox(
              width: 52,
              child: Text(
                index.toString().padLeft(2, '0'),
                style: look.display(30, color: active ? look.accent : fg),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    look.t(set.name),
                    style: look.label(color: fg, size: 14, weight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    look.caps ? names.toLowerCase() : names,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: look.label(
                      size: 12,
                      color: active && look.id == LookId.ascii ? Colors.black54 : look.textDim,
                    ),
                  ),
                ],
              ),
            ),
            if (!set.builtIn)
              IconButton(
                tooltip: 'Удалить сет',
                color: fg,
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => state.deleteSet(set),
              ),
            const SizedBox(width: 4),
            LookIconButton(
              filled: active,
              icon: active ? Icons.stop_rounded : Icons.play_arrow_rounded,
              onPressed: () => active ? state.stopAll() : state.applySet(set),
            ),
          ],
        ),
      ),
    );
  }
}
