import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../common/theme/app_colors.dart';
import '../../../../common/widgets/login_modal.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../chat/presentation/view/chat_modal.dart';
import '../../../community/presentation/widgets/post_card.dart';
import '../../../home/data/models/ingredient_summary_model.dart';
import '../../data/repositories/search_repository.dart';
import '../providers/search_provider.dart';

/// 검색 화면 진입점
/// - [SearchProvider]를 생성해 [_SearchView]에 주입
/// - 성분 / 게시글 통합 검색 지원
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

/// [SearchScreen]의 메인 뷰 — 검색창 + 결과 목록
class _SearchView extends StatefulWidget {
  const _SearchView();

  @override
  State<_SearchView> createState() => _SearchViewState();
}

/// [_SearchView]의 State — TextEditingController 생명주기 관리
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
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          // 비로그인이면 로그인 모달 → 로그인 성공 시 챗봇 열기
          final isAuthenticated = context.read<AuthProvider>().isAuthenticated;
          if (!isAuthenticated) {
            await showLoginModal(context);
            if (!context.mounted) return;
            if (!context.read<AuthProvider>().isAuthenticated) return;
          }
          if (!context.mounted) return;
          showChatModal(context);
        },
        icon: const Icon(Icons.auto_awesome_rounded),
        label: const Text('AI 성분 상담'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
      body: Column(
        children: [
          // ── 검색창 — 입력 시 provider.search 호출, X 버튼으로 초기화 ──
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

          // ── 결과 영역 — 로딩 / 빈 키워드 / 결과 없음 / 결과 있음 4가지 상태 분기 ──
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
                // ── 성분 결과 섹션 ──
                if (hasIngredients) ...[
                  _SectionHeader(
                    label: '성분',
                    count: provider.ingredientResults.length,
                  ),
                  ...provider.ingredientResults.map(
                        (item) => _IngredientResultItem(item: item),
                  ),
                ],

                // ── 게시글 결과 섹션 ──
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

/// 검색 결과 섹션 헤더 — 카테고리명 + 결과 건수 표시
/// [_SearchViewState] build 내 성분 / 게시글 섹션에서 재사용
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

/// 성분 검색 결과 아이템 — 한/영 성분명 + 타입 뱃지 + 피부 고민 태그 + 효과 요약
/// 탭 시 [IngredientDetailScreen] (`/ingredients/:id`)으로 이동
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