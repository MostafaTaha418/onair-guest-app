import 'package:flutter/material.dart';
import 'package:on_air/design_system/icons/app_icons.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/design_system/tokens/dimens.dart';

final class AckStep {
  const AckStep({
    required this.label,
    required this.statusText,
    required this.done,
  });

  final String label;
  final String statusText;
  final bool done;
}

final class AcknowledgementTracker extends StatelessWidget {
  const AcknowledgementTracker({
    required this.title,
    required this.steps,
    this.note,
    super.key,
  });

  final String title;
  final List<AckStep> steps;
  final String? note;

  @override
  Widget build(BuildContext context) => MergeSemantics(
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(Dimens.space16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: Dimens.space16),
            for (var index = 0; index < steps.length; index++) ...[
              _StepRow(step: steps[index]),
              if (index < steps.length - 1)
                const SizedBox(height: Dimens.space8),
            ],
            if (note != null) ...[
              const SizedBox(height: Dimens.space8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(AppIcons.keyOutline, size: 20),
                  const SizedBox(width: Dimens.space8),
                  Expanded(
                    child: Text(
                      note!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

final class _StepRow extends StatelessWidget {
  const _StepRow({required this.step});

  final AckStep step;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(
        step.done ? AppIcons.checkCircle : AppIcons.schedule,
        color: step.done
            ? context.colors['success']
            : context.colors.textSecondary,
        size: 20,
      ),
      const SizedBox(width: Dimens.space8),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(step.label, style: Theme.of(context).textTheme.labelLarge),
            Text(
              step.statusText,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: context.colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}
