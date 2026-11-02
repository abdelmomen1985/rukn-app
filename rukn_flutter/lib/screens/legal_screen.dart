import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/config.dart';
import '../core/format.dart';
import '../core/theme.dart';
import '../data/legal.dart';
import '../l10n/i18n.dart';
import '../widgets/common.dart';

/// `/privacy` and `/terms`: the in-app copy of the website's legal pages. Renders the
/// bundled text in the current language; the website link is a secondary action.
class LegalScreen extends StatefulWidget {
  const LegalScreen({super.key, required this.slug});

  /// `privacy` or `terms`.
  final String slug;

  @override
  State<LegalScreen> createState() => _LegalScreenState();
}

class _LegalScreenState extends State<LegalScreen> {
  final _scroll = ScrollController();
  final List<GlobalKey> _clauseKeys = [];

  LegalDoc? get _doc => legalDocs[widget.slug];

  @override
  void initState() {
    super.initState();
    _clauseKeys.addAll(List.generate(_doc?.clauses.length ?? 0, (_) => GlobalKey()));
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _jumpTo(int index) {
    final context = _clauseKeys[index].currentContext;
    if (context == null) return;
    Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
      alignment: 0.02,
    );
  }

  Future<void> _openWeb(String url) async {
    final ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication).catchError((_) => false);
    if (!ok && mounted) showSnack(context, AppConfig.supportEmail);
  }

  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;
    final doc = _doc;
    if (doc == null) {
      return Scaffold(
        appBar: AppBar(),
        body: MessageState(icon: Icons.gavel_outlined, title: i18n.t('articleNotFound')),
      );
    }
    final isAr = i18n.isAr;
    final webUrl = widget.slug == 'terms' ? AppConfig.termsUrl(i18n.lang) : AppConfig.privacyPolicyUrl(i18n.lang);
    final updated = formatDate(doc.updated, i18n.lang);

    return Scaffold(
      appBar: AppBar(title: Text(doc.title.pick(isAr), maxLines: 1, overflow: TextOverflow.ellipsis)),
      body: SingleChildScrollView(
        controller: _scroll,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CardBox(
              padding: const EdgeInsets.all(20),
              color: AppColors.cream,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(doc.title.pick(isAr), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, height: 1.3)),
                  const SizedBox(height: 8),
                  Text(doc.summary.pick(isAr), style: const TextStyle(fontSize: 14.5, height: 1.7, color: AppColors.foreground)),
                  const SizedBox(height: 12),
                  Text(
                    '${i18n.t('legalUpdated')}: $updated',
                    style: const TextStyle(fontSize: 12.5, color: AppColors.muted),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            CardBox(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(i18n.t('legalContents'), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.muted)),
                  const SizedBox(height: 6),
                  for (var i = 0; i < doc.clauses.length; i++)
                    InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => _jumpTo(i),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 28,
                              child: Text(formatNumber(i + 1, decimals: 0), style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
                            ),
                            Expanded(child: Text(doc.clauses[i].heading.pick(isAr), style: const TextStyle(fontSize: 14.5, height: 1.4))),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            for (var i = 0; i < doc.clauses.length; i++)
              Padding(
                key: _clauseKeys[i],
                padding: const EdgeInsets.only(bottom: 14),
                child: CardBox(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(formatNumber(i + 1, decimals: 0), style: const TextStyle(fontSize: 22, color: AppColors.primary, fontWeight: FontWeight.w800)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              doc.clauses[i].heading.pick(isAr),
                              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, height: 1.35),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      for (final block in doc.clauses[i].blocks) ...[
                        _BlockView(block: block, isAr: isAr, onOpen: _openWeb),
                        const SizedBox(height: 10),
                      ],
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 6),
            Center(
              child: OutlinedButton.icon(
                onPressed: () => _openWeb(webUrl),
                icon: const Icon(Icons.open_in_new, size: 18),
                label: Text(i18n.t('legalReadOnWeb')),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '${legalCompany.name.pick(isAr)} · ${i18n.t('legalCommercialReg')} ${legalCompany.commercialRegister}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: AppColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}

class _BlockView extends StatelessWidget {
  const _BlockView({required this.block, required this.isAr, required this.onOpen});

  final LegalBlock block;
  final bool isAr;
  final Future<void> Function(String url) onOpen;

  @override
  Widget build(BuildContext context) {
    const bodyStyle = TextStyle(fontSize: 15, height: 1.8, color: AppColors.foreground);
    return switch (block) {
      LegalParagraph(:final text) => _Linkified(text: text.pick(isAr), style: bodyStyle, onOpen: onOpen),
      LegalList(:final items) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final item in items)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsetsDirectional.only(top: 9, end: 10, start: 2),
                      child: Transform.rotate(
                        angle: 0.785398,
                        child: Container(width: 6, height: 6, color: AppColors.primary),
                      ),
                    ),
                    Expanded(child: _Linkified(text: item.pick(isAr), style: bodyStyle, onOpen: onOpen)),
                  ],
                ),
              ),
          ],
        ),
    };
  }
}

/// Body text with e-mail addresses, phone numbers and URLs made tappable.
class _Linkified extends StatefulWidget {
  const _Linkified({required this.text, required this.style, required this.onOpen});

  final String text;
  final TextStyle style;
  final Future<void> Function(String url) onOpen;

  /// URLs, e-mail addresses, and phone numbers (international `+…` or 9-digit local).
  static final _pattern = RegExp(
    r'(https?://[^\s,)]+|[\w.+-]+@[\w-]+(?:\.[\w-]+)+|\+\d[\d ]{7,14}\d|\b9\d{8}\b)',
  );

  @override
  State<_Linkified> createState() => _LinkifiedState();
}

class _LinkifiedState extends State<_Linkified> {
  final _recognizers = <TapGestureRecognizer>[];

  @override
  void dispose() {
    for (final r in _recognizers) {
      r.dispose();
    }
    super.dispose();
  }

  String _target(String match) {
    if (match.startsWith('http')) return match;
    if (match.contains('@')) return 'mailto:$match';
    return 'tel:${match.replaceAll(' ', '')}';
  }

  @override
  Widget build(BuildContext context) {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();

    final spans = <InlineSpan>[];
    var last = 0;
    for (final m in _Linkified._pattern.allMatches(widget.text)) {
      if (m.start > last) spans.add(TextSpan(text: widget.text.substring(last, m.start)));
      final match = m.group(0)!;
      final target = _target(match);
      final recognizer = TapGestureRecognizer()..onTap = () => widget.onOpen(target);
      _recognizers.add(recognizer);
      spans.add(TextSpan(
        text: match,
        recognizer: recognizer,
        style: const TextStyle(color: AppColors.darkGreen, decoration: TextDecoration.underline),
      ));
      last = m.end;
    }
    if (last < widget.text.length) spans.add(TextSpan(text: widget.text.substring(last)));

    return Text.rich(TextSpan(style: widget.style, children: spans));
  }
}
