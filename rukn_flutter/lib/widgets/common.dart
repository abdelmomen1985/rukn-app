import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../core/format.dart';
import '../core/theme.dart';
import '../l10n/i18n.dart';

void haptic([Haptic type = Haptic.light]) {
  switch (type) {
    case Haptic.light:
      HapticFeedback.lightImpact();
    case Haptic.medium:
      HapticFeedback.mediumImpact();
    case Haptic.heavy:
      HapticFeedback.heavyImpact();
    case Haptic.selection:
      HapticFeedback.selectionClick();
  }
}

enum Haptic { light, medium, heavy, selection }

void showSnack(BuildContext context, String message, {bool error = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: error ? AppColors.error : AppColors.darkGreen,
    ));
}

/// The official Saudi Riyal symbol, sized to the surrounding text.
class SarSymbol extends StatelessWidget {
  const SarSymbol({super.key, this.size = 14, this.color});
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? DefaultTextStyle.of(context).style.color ?? AppColors.foreground;
    return SvgPicture.asset(
      'assets/images/sar.svg',
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(c, BlendMode.srcIn),
    );
  }
}

/// "1,234.50 ⃁" with the riyal glyph.
class Price extends StatelessWidget {
  const Price(this.amount, {super.key, this.style, this.decimals, this.strike = false});
  final double amount;
  final TextStyle? style;
  final int? decimals;
  final bool strike;

  @override
  Widget build(BuildContext context) {
    final s = (style ?? const TextStyle()).copyWith(
      decoration: strike ? TextDecoration.lineThrough : null,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final effective = DefaultTextStyle.of(context).style.merge(s);
    final size = (effective.fontSize ?? 14) * 0.85;
    return Row(
      mainAxisSize: MainAxisSize.min,
      textDirection: TextDirection.ltr,
      children: [
        Text(formatNumber(amount, decimals: decimals), style: effective),
        const SizedBox(width: 4),
        SarSymbol(size: size, color: effective.color),
      ],
    );
  }
}

class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.trailing});
  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text.toUpperCase(),
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

class CardBox extends StatelessWidget {
  const CardBox({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.color, this.borderColor, this.onTap, this.margin});
  final Widget child;
  final EdgeInsets padding;
  final EdgeInsets? margin;
  final Color? color;
  final Color? borderColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final box = Container(
      margin: margin,
      decoration: BoxDecoration(
        color: color ?? AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor ?? AppColors.border),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
    return box;
  }
}

class InfoRow extends StatelessWidget {
  const InfoRow({super.key, required this.label, this.value, this.valueWidget, this.highlight = false, this.valueColor});
  final String label;
  final String? value;
  final Widget? valueWidget;
  final bool highlight;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: highlight ? AppColors.foreground : AppColors.muted,
                fontSize: 14,
                fontWeight: highlight ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
          const SizedBox(width: 8),
          DefaultTextStyle.merge(
            style: TextStyle(
              color: valueColor ?? AppColors.foreground,
              fontSize: 14,
              fontWeight: highlight ? FontWeight.w700 : FontWeight.w500,
            ),
            child: valueWidget ?? Text(value ?? ''),
          ),
        ],
      ),
    );
  }
}

/// Wrap of selectable pills (dark green when active, gold text).
class PillSelector<T> extends StatelessWidget {
  const PillSelector({super.key, required this.options, required this.selected, required this.onSelect, required this.label, this.leading});
  final List<T> options;
  final T? selected;
  final ValueChanged<T> onSelect;
  final String Function(T) label;
  final String Function(T)? leading;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final o in options)
          Pill(
            label: leading == null ? label(o) : '${leading!(o)}  ${label(o)}',
            active: o == selected,
            onTap: () {
              haptic();
              onSelect(o);
            },
          ),
      ],
    );
  }
}

class Pill extends StatelessWidget {
  const Pill({super.key, required this.label, required this.active, required this.onTap, this.dense = false});
  final String label;
  final bool active;
  final VoidCallback onTap;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? AppColors.darkGreen : AppColors.surface,
      shape: StadiumBorder(side: BorderSide(color: active ? AppColors.darkGreen : AppColors.border)),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: dense ? 12 : 14, vertical: dense ? 7 : 9),
          child: Text(
            label,
            style: TextStyle(
              color: active ? AppColors.primary : AppColors.foreground,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class GoldButton extends StatelessWidget {
  const GoldButton({super.key, required this.label, this.onPressed, this.loading = false, this.icon});
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: loading ? null : onPressed,
      style: FilledButton.styleFrom(
        disabledBackgroundColor: AppColors.darkGreen.withValues(alpha: 0.45),
        disabledForegroundColor: AppColors.primary.withValues(alpha: 0.8),
      ),
      child: loading
          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: AppColors.primary))
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[Icon(icon, size: 20), const SizedBox(width: 8)],
                Flexible(child: Text(label, textAlign: TextAlign.center)),
              ],
            ),
    );
  }
}

class MessageState extends StatelessWidget {
  const MessageState({super.key, required this.icon, required this.title, this.subtitle, this.action, this.actionLabel, this.emoji});
  final IconData icon;
  final String? emoji;
  final String title;
  final String? subtitle;
  final VoidCallback? action;
  final String? actionLabel;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (emoji != null)
              Text(emoji!, style: const TextStyle(fontSize: 48))
            else
              Icon(icon, size: 52, color: AppColors.muted),
            const SizedBox(height: 14),
            Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(subtitle!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.muted, fontSize: 13, height: 1.5)),
            ],
            if (action != null && actionLabel != null) ...[
              const SizedBox(height: 20),
              SizedBox(width: 220, child: GoldButton(label: actionLabel!, onPressed: action)),
            ],
          ],
        ),
      ),
    );
  }
}

class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.label});
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppColors.darkGreen),
            if (label != null) ...[
              const SizedBox(height: 12),
              Text(label!, style: const TextStyle(color: AppColors.muted)),
            ],
          ],
        ),
      ),
    );
  }
}

/// Error with a retry button — never a fake fallback catalogue.
class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.onRetry, this.title, this.subtitle});
  final VoidCallback onRetry;
  final String? title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return MessageState(
      icon: Icons.cloud_off_outlined,
      title: title ?? context.tr('catalogErrorTitle'),
      subtitle: subtitle ?? context.tr('catalogErrorSubtitle'),
      action: onRetry,
      actionLabel: context.tr('retry'),
    );
  }
}

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.label, required this.color, this.icon});
  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 13, color: color), const SizedBox(width: 4)],
          Text(label, style: TextStyle(color: color, fontSize: 11.5, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  bool destructive = false,
}) async {
  final i18n = context.i18nRead;
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(i18n.t('cancel'))),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: TextButton.styleFrom(foregroundColor: destructive ? AppColors.error : AppColors.darkGreen),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// Back chevron that points the right way in RTL.
IconData backIcon(BuildContext context) =>
    Directionality.of(context) == TextDirection.rtl ? Icons.chevron_right : Icons.chevron_left;
IconData forwardIcon(BuildContext context) =>
    Directionality.of(context) == TextDirection.rtl ? Icons.chevron_left : Icons.chevron_right;
