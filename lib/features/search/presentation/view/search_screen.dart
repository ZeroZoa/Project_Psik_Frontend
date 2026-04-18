import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../common/theme/app_colors.dart';
import '../../../community/presentation/widgets/post_card.dart';
import '../../../home/data/models/ingredient_summary_model.dart';
import '../../data/repositories/search_repository.dart';
import '../providers/search_provider.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SearchProvider(context.read<SearchRepository>()),
      child: const _SearchView(),
    );
  }
}

class _SearchView extends StatefulWidget {
  const _SearchView();

  @override
  State<_SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<_SearchView> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SearchProvider>();
    final hasIngredients = provider.ingredientResults.isNotEmpty;
    final hasPosts = provider.postResults.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // ── 검색창 ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
              ),
              child: TextField(
                controller: _controller,
                onChanged: (v) => provider.search(newKeyword: v),
                onSubmitted: (v) => provider.search(newKeyword: v),
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: '성분명, 게시글 키워드로 검색',
                  hintStyle: const TextStyle(fontSize: 14, color: AppColors.textSub1),
                  prefixIcon: const Icon(Icons.search, color: AppColors.textSub2, size: 20),
                  suffixIcon: _controller.text.isNotEmpty
                      ? IconButton(
                    icon: const Icon(Icons.close, size: 18, color: AppColors.textSub2),
                    onPressed: () {
                      _controller.clear();
                      provider.clear();
                    },
                  )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),

          // ── 결과 ──
          Expanded(
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : provider.keyword.isEmpty
                ? const Center(
              child: Text(
                '성분명이나 게시글 키워드로 검색해보세요.',
                style: TextStyle(color: AppColors.textSub2, fontSize: 14),
              ),
            )
                : (!hasIngredients && !hasPosts)
                ? const Center(
              child: Text(
                '검색 결과가 없습니다.',
                style: TextStyle(color: AppColors.textSub2, fontSize: 14),
              ),
            )
                : ListView(
              children: [
                // ── 성분 결과 ──
                if (hasIngredients) ...[
                  _SectionHeader(
                    label: '성분',
                    count: provider.ingredientResults.length,
                  ),
                  ...provider.ingredientResults.map(
                        (item) => _IngredientResultItem(item: item),
                  ),
                ],

                // ── 게시글 결과 ──
                if (hasPosts) ...[
                  if (hasIngredients)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Divider(height: 1, color: Color(0xFFE5E7EB)),
                    ),
                  _SectionHeader(
                    label: '게시글',
                    count: provider.postResults.length,
                  ),
                  ...provider.postResults.map(
                        (post) => PostCard(
                      post: post,
                      onTap: () => context.push('/community/${post.postId}'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── 섹션 헤더 ──
class _SectionHeader extends StatelessWidget {
  final String label;
  final int count;

  const _SectionHeader({required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textTitle)),
          const SizedBox(width: 6),
          Text('$count건',
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSub2)),
        ],
      ),
    );
  }
}

// ── 성분 결과 아이템 ──
class _IngredientResultItem extends StatelessWidget {
  final IngredientSummaryModel item;

  const _IngredientResultItem({required this.item});

  @override
  Widget build(BuildContext context) {
    final parts = item.name.split('/');
    final korean = parts[0].trim();
    final english = parts.length > 1 ? parts[1].trim() : null;

    return InkWell(
      onTap: () => context.push('/ingredients/${item.id}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(korean,
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textTitle)),
                      if (english != null) ...[
                        const SizedBox(width: 6),
                        Text(english,
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppColors.primary)),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(item.typeTitle,
                            style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary)),
                      ),
                      if (item.skinConcerns.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item.skinConcerns.take(3).map((c) => '#$c').join(' '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSub2,
                                fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (item.effectSummary.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(item.effectSummary,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSub2)),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textSub2, size: 18),
          ],
        ),
      ),
    );
  }
}