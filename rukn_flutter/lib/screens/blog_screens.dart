import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/config.dart';
import '../core/format.dart';
import '../core/theme.dart';
import '../l10n/i18n.dart';
import '../services/content_service.dart';
import '../widgets/common.dart';
import '../widgets/product_widgets.dart';

class BlogListScreen extends StatefulWidget {
  const BlogListScreen({super.key});

  @override
  State<BlogListScreen> createState() => _BlogListScreenState();
}

class _BlogListScreenState extends State<BlogListScreen> {
  List<Article>? _posts;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final p = await ContentService.blogPosts(limit: 50);
      if (mounted) setState(() => _posts = p.where((a) => !const ['policy', 'about', 'gold-rule'].contains(a.slug)).toList());
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;
    Widget body;
    if (_error != null) {
      body = ErrorView(onRetry: _load);
    } else if (_posts == null) {
      body = const LoadingView();
    } else if (_posts!.isEmpty) {
      body = MessageState(icon: Icons.menu_book_outlined, title: i18n.t('noArticles'));
    } else {
      body = RefreshIndicator(
        onRefresh: _load,
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: _posts!.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (_, i) {
            final a = _posts![i];
            return CardBox(
              padding: EdgeInsets.zero,
              color: Colors.white,
              onTap: () => context.push('/blog/${Uri.encodeComponent(a.slug)}'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (a.image != null) ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(16)), child: AspectRatio(aspectRatio: 16 / 8, child: NetImage(a.image!))),
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          StatusChip(label: a.badge ?? i18n.t('blog'), color: AppColors.darkGreen),
                          const Spacer(),
                          Text(i18n.t('readMinutes', {'n': a.readMinutes(i18n.lang)}), style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                        ]),
                        const SizedBox(height: 8),
                        Text(a.title(i18n.lang), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, height: 1.4)),
                        const SizedBox(height: 4),
                        Text(a.excerpt(i18n.lang), maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.muted, height: 1.5)),
                        if (a.publishedAt != null) ...[
                          const SizedBox(height: 6),
                          Text(formatDate(a.publishedAt, i18n.lang), style: const TextStyle(color: AppColors.muted, fontSize: 11.5)),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );
    }
    return Scaffold(appBar: AppBar(title: Text(i18n.t('blog'))), body: body);
  }
}

class ArticleScreen extends StatefulWidget {
  const ArticleScreen({super.key, required this.slug});
  final String slug;

  @override
  State<ArticleScreen> createState() => _ArticleScreenState();
}

class _ArticleScreenState extends State<ArticleScreen> {
  Article? _article;
  bool _loading = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final a = await ContentService.blogPost(widget.slug);
      if (mounted) setState(() => _article = a);
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;
    final a = _article;
    Widget body;
    if (_loading) {
      body = const LoadingView();
    } else if (_error != null) {
      body = ErrorView(onRetry: _load);
    } else if (a == null) {
      body = MessageState(
        icon: Icons.article_outlined,
        title: i18n.t('articleNotFound'),
        action: widget.slug == 'policy' ? () => launchUrl(Uri.parse(AppConfig.privacyPolicyUrl(i18n.lang))) : null,
        actionLabel: i18n.t('openOnWebsite'),
      );
    } else {
      body = ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        children: [
          Text(a.title(i18n.lang), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, height: 1.35)),
          const SizedBox(height: 8),
          Text(
            [if (a.publishedAt != null) formatDate(a.publishedAt, i18n.lang), i18n.t('readMinutes', {'n': a.readMinutes(i18n.lang)})].join(' · '),
            style: const TextStyle(color: AppColors.muted),
          ),
          if (a.image != null) ...[
            const SizedBox(height: 14),
            ClipRRect(borderRadius: BorderRadius.circular(14), child: NetImage(a.image!)),
          ],
          const SizedBox(height: 16),
          HtmlWidget(
            a.content(i18n.lang),
            textStyle: const TextStyle(fontSize: 15.5, height: 1.8),
            onTapUrl: (url) => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
          ),
        ],
      );
    }
    return Scaffold(appBar: AppBar(title: Text(a?.title(i18n.lang) ?? '', maxLines: 1, overflow: TextOverflow.ellipsis)), body: body);
  }
}
