import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../common/theme/app_colors.dart';
import '../../../../common/widgets/login_modal.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../community/data/models/comment_model.dart';
import '../../../community/data/models/post_model.dart';
import '../../../community/presentation/widgets/post_card.dart';
import '../../../home/data/models/product_model.dart';
import '../providers/mypage_provider.dart';
import '../widgets/mypage_diary_stats_section.dart';

/// 마이페이지 화면 진입점
/// - 비로그인 시 로그인 유도 UI 표시
/// - 프로필 헤더 / 30일 다이어리 그래프 / 활동 섹션 메뉴 / 섹션별 콘텐츠 구성
class MypageScreen extends StatefulWidget {
  const MypageScreen({super.key});

  @override
  State<MypageScreen> createState() => _MypageScreenState();
}

/// [MypageScreen]의 State — 활동 섹션 선택 인덱스 관리
/// 관리 상태: _selectedSection (0:내 글 / 1:좋아요 / 2:댓글 단 글 / 3:내 댓글 / 4:샀어요)
class _MypageScreenState extends State<MypageScreen> {
  // 선택된 활동 섹션 인덱스 (0: 내 글, 1: 좋아요, 2: 댓글 단 글, 3: 내 댓글, 4: 샀어요)
  int _selectedSection = 0;

  final List<({String label, IconData icon})> _sections = const [
    (label: '내 글', icon: Icons.edit_note_rounded),
    (label: '좋아요', icon: Icons.favorite_border_rounded),
    (label: '댓글 단 글', icon: Icons.chat_bubble_outline_rounded),
    (label: '내 댓글', icon: Icons.comment_outlined),
    (label: '샀어요', icon: Icons.shopping_bag_outlined),
  ];

  /// 인증 사용자 진입 시 프로필 / 내 글 목록 / 최근 30일 다이어리 초기 로드
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final isAuthenticated = context.read<AuthProvider>().isAuthenticated;
      if (isAuthenticated) {
        final provider = context.read<MypageProvider>();
        provider.fetchMyInfo();
        provider.fetchMyPosts();
        provider.fetchRecentDiaries();
      }
    });
  }

  /// 활동 섹션 탭 핸들러 — 동일 섹션 재탭 시 무시
  /// 섹션 인덱스에 따라 [MypageProvider]의 해당 fetch 메서드 호출
  void _onSectionTap(int index) {
    if (_selectedSection == index) return;
    setState(() => _selectedSection = index);
    final provider = context.read<MypageProvider>();
    switch (index) {
      case 0: provider.fetchMyPosts(); break;
      case 1: provider.fetchLikedPosts(); break;
      case 2: provider.fetchCommentedPosts(); break;
      case 3: provider.fetchMyComments(); break;
      case 4: provider.fetchOwnedProducts(); break;
    }
  }

  /// 로그아웃 확인 다이얼로그 표시
  /// 확인 시 [AuthProvider.logout] 호출
  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('로그아웃',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          content: const Text('정말 로그아웃 하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text('취소', style: TextStyle(color: Colors.grey.shade600)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                await context.read<AuthProvider>().logout();
              },
              child: const Text('로그아웃',
                  style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  /// 회원 탈퇴 확인 다이얼로그 — 취소 불가 안내 포함
  void _showWithdrawDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('회원 탈퇴',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          content: const Text(
            '탈퇴하면 계정 정보와 개인 데이터가 삭제됩니다.\n작성한 게시글과 댓글은 "탈퇴한 사용자"로 표시되며 복구할 수 없습니다.',
            style: TextStyle(fontSize: 14, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text('취소', style: TextStyle(color: Colors.grey.shade600)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                final success = await context.read<AuthProvider>().withdraw();
                if (context.mounted) {
                  if (success) {
                    context.go('/home');
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('탈퇴 처리 중 오류가 발생했습니다. 다시 시도해주세요.')),
                    );
                  }
                }
              },
              child: const Text('탈퇴하기',
                  style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAuthenticated = context.watch<AuthProvider>().isAuthenticated;

    if (!isAuthenticated) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: 100, color: Colors.grey.shade400),
              const SizedBox(height: 20),
              Text('로그인이 필요해요',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => showLoginModal(context),
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.all(Colors.white),
                  foregroundColor: WidgetStateProperty.all(AppColors.primary),
                  overlayColor: WidgetStateProperty.resolveWith<Color?>((states) {
                    if (states.contains(WidgetState.hovered)) {
                      return AppColors.primary.withValues(alpha: 0.08);
                    }
                    if (states.contains(WidgetState.pressed)) {
                      return AppColors.primary.withValues(alpha: 0.15);
                    }
                    return Colors.transparent;
                  }),
                  shape: WidgetStateProperty.all(RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: const BorderSide(color: AppColors.primary, width: 2),
                  )),
                  padding: WidgetStateProperty.all(
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                  elevation: WidgetStateProperty.all(0),
                  shadowColor: WidgetStateProperty.all(Colors.transparent),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SvgPicture.asset(
                      'assets/images/psik_text_logo.svg',
                      height: 36,
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      '로그인',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    final provider = context.watch<MypageProvider>();

    if (provider.isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        onRefresh: () async {
          await provider.fetchMyInfo();
          await provider.fetchRecentDiaries();
        },
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── 프로필 헤더 ──
              _buildProfileHeader(provider),

              // ── 30일 다이어리 그래프 — 피부점수/수면/수분 3개 라인 차트 ──
              if (provider.recentDiaries.isNotEmpty)
                MypageDiaryStatsSection(diaries: provider.recentDiaries),

              const SizedBox(height: 8),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Divider(height: 1, color: Color(0xFFE5E7EB)),
              ),
              const SizedBox(height: 16),

              // ── 활동 섹션 선택 ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _sections.asMap().entries.map((entry) {
                    final i = entry.key;
                    final section = entry.value;
                    final isSelected = _selectedSection == i;
                    return InkWell(
                      onTap: () => _onSectionTap(i),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                        child: Row(
                          children: [
                            Icon(section.icon,
                                size: 18,
                                color: isSelected ? AppColors.primary : AppColors.textSub2),
                            const SizedBox(width: 12),
                            Text(
                              section.label,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                color: isSelected ? AppColors.primary : AppColors.textBody,
                              ),
                            ),
                            const Spacer(),
                            Icon(Icons.chevron_right_rounded,
                                size: 18,
                                color: isSelected ? AppColors.primary : Colors.grey.shade300),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Divider(height: 1, color: Color(0xFFE5E7EB)),
              ),

              // ── 선택된 섹션 콘텐츠 ──
              _buildSelectedContent(provider),

              const SizedBox(height: 16),

              // ── 문의하기 ──
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                child: SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => context.push('/inquiry'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.textBody,
                      backgroundColor: AppColors.surface,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('문의하기',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600)),
                  ),
                ),
              ),

              // ── 로그아웃 ──
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                child: SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: _showLogoutDialog,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.error.withValues(alpha: 0.8),
                      backgroundColor: AppColors.error.withValues(alpha: 0.05),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('로그아웃',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  ),
                ),
              ),

              // ── 회원 탈퇴 ──
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                child: Center(
                  child: TextButton(
                    onPressed: _showWithdrawDialog,
                    child: const Text(
                      '회원 탈퇴',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        decoration: TextDecoration.underline,
                        decorationColor: Colors.grey,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 프로필 헤더 위젯 — 아바타 + 닉네임/이메일 + 프로필 수정 버튼
  /// ADMIN 권한 보유 시 관리자 페이지 버튼 추가 표시
  /// 프로필 수정 후 복귀 시 [MypageProvider.fetchMyInfo] 재조회
  Widget _buildProfileHeader(MypageProvider provider) {
    final member = provider.member;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: AppColors.surface,
                backgroundImage: member?.profileImageUrl != null
                    ? NetworkImage(member!.profileImageUrl!)
                    : null,
                child: member?.profileImageUrl == null
                    ? const Icon(Icons.person, size: 30, color: Colors.grey)
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member?.nickname ?? '사용자',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textTitle),
                    ),
                    if (member?.email != null) ...[
                      const SizedBox(height: 2),
                      Text(member!.email!,
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                    ],
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: () async {
                  final provider = context.read<MypageProvider>(); // await 전에 미리 캡처
                  await context.push('/profile-edit');
                  if (context.mounted) provider.fetchMyInfo();
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFE5E7EB)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                icon: const Icon(Icons.edit_outlined, size: 14, color: AppColors.textSub2),
                label: const Text('프로필 수정',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSub2)),
              ),
            ],
          ),
          if (context.read<AuthProvider>().isAdmin) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => context.push('/admin'),
                icon: const Icon(Icons.admin_panel_settings_outlined, color: AppColors.primary, size: 16),
                label: const Text('관리자 페이지',
                    style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 13)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 선택된 활동 섹션에 따라 콘텐츠 위젯 분기
  /// 탭 로딩 중이면 로딩 인디케이터 표시
  Widget _buildSelectedContent(MypageProvider provider) {
    if (provider.isTabLoading) {
      return const Padding(
        padding: EdgeInsets.all(40),
        child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    switch (_selectedSection) {
      case 0: return _buildPostList(provider.myPosts);
      case 1: return _buildPostList(provider.likedPosts);
      case 2: return _buildPostList(provider.commentedPosts);
      case 3: return _buildCommentList(provider.myComments);
      case 4: return _buildOwnedProductList(provider.ownedProducts);
      default: return const SizedBox();
    }
  }

  /// 게시글 목록 위젯 — 내 글 / 좋아요 / 댓글 단 글 섹션 공통 사용
  /// 비어있으면 안내 문구 표시
  Widget _buildPostList(List<PostModel> posts) {
    if (posts.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(40),
        child: Center(child: Text('게시글이 없습니다.', style: TextStyle(color: AppColors.textSub2))),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: posts.length,
      itemBuilder: (context, index) => PostCard(
        post: posts[index],
        onTap: () => context.push('/community/${posts[index].postId}'),
      ),
    );
  }

  /// 내 댓글 목록 위젯 — 내용 + 좋아요 수 + 작성일 표시
  /// 비어있으면 안내 문구 표시
  Widget _buildCommentList(List<CommentModel> comments) {
    if (comments.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(40),
        child: Center(child: Text('댓글이 없습니다.', style: TextStyle(color: AppColors.textSub2))),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: comments.length,
      itemBuilder: (context, index) {
        final comment = comments[index];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.grey.shade100, width: 0.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(comment.content,
                  style: const TextStyle(fontSize: 14, color: AppColors.textBody, height: 1.4),
                  maxLines: 3, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.favorite, size: 14,
                      color: comment.likedByMe ? AppColors.error : Colors.grey.shade400),
                  const SizedBox(width: 4),
                  Text('${comment.likeCount}',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                  const Spacer(),
                  Text(_formatDate(comment.createdAt),
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  /// 샀어요 제품 목록 위젯 — 이미지 + 브랜드/이름/가격 표시
  /// 탭 시 [ProductDetailScreen] (`/products/:id`)으로 이동
  /// 비어있으면 안내 문구 표시
  Widget _buildOwnedProductList(List<ProductModel> products) {
    if (products.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(40),
        child: Center(child: Text('샀어요한 제품이 없습니다.', style: TextStyle(color: AppColors.textSub2))),
      );
    }
    final currencyFormat = NumberFormat('#,###', 'ko_KR');
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return GestureDetector(
          onTap: () => context.push('/products/${product.id}', extra: product),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade100),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 2))],
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 64, height: 64, color: AppColors.surface,
                    child: (product.imageUrl != null && product.imageUrl!.isNotEmpty)
                        ? Image.network(product.imageUrl!, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_outlined, color: Colors.grey))
                        : const Icon(Icons.shopping_bag_outlined, color: Colors.grey),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (product.brand != null && product.brand!.isNotEmpty)
                        Text(product.brand!,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSub2)),
                      Text(product.name,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textTitle),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      if (product.price != null) ...[
                        const SizedBox(height: 4),
                        Text('${currencyFormat.format(product.price)}원',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.primary)),
                      ],
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 댓글 작성 시간 상대 표시 헬퍼
  /// 60분 미만 → N분 전 / 24시간 미만 → N시간 전 / 7일 미만 → N일 전 / 이상 → M.D 형식
  String _formatDate(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
    if (diff.inHours < 24) return '${diff.inHours}시간 전';
    if (diff.inDays < 7) return '${diff.inDays}일 전';
    return '${dateTime.month}.${dateTime.day}';
  }
}