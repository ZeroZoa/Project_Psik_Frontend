import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../common/theme/app_colors.dart';
import '../../../../common/widgets/login_modal.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../community/data/models/comment_model.dart';
import '../../../community/data/models/post_model.dart';
import '../../../community/presentation/widgets/post_card.dart';
import '../../../diary/data/models/skin_diary_response.dart';
import '../../../home/data/models/product_model.dart';
import '../providers/mypage_provider.dart';

class MypageScreen extends StatefulWidget {
  const MypageScreen({super.key});

  @override
  State<MypageScreen> createState() => _MypageScreenState();
}

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
              Icon(Icons.lock_outline, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text('로그인이 필요한 서비스입니다',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => showLoginModal(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
                child: const Text('로그인하기',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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

              // ── 30일 다이어리 그래프 ──
              if (provider.recentDiaries.isNotEmpty)
                _DiaryStatsSection(diaries: provider.recentDiaries),

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
            ],
          ),
        ),
      ),
    );
  }

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
                  await context.push('/profile-edit');
                  if (context.mounted) context.read<MypageProvider>().fetchMyInfo();
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

  String _formatDate(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
    if (diff.inHours < 24) return '${diff.inHours}시간 전';
    if (diff.inDays < 7) return '${diff.inDays}일 전';
    return '${dateTime.month}.${dateTime.day}';
  }
}

// ── 30일 다이어리 그래프 섹션 (통합) ──
class _DiaryStatsSection extends StatelessWidget {
  final List<SkinDiaryResponse> diaries;

  const _DiaryStatsSection({required this.diaries});

  @override
  Widget build(BuildContext context) {
    final spots1 = <FlSpot>[]; // 피부점수
    final spots2 = <FlSpot>[]; // 수면시간
    final spots3 = <FlSpot>[]; // 물 섭취량
    final now = DateTime.now();

    for (final diary in diaries) {
      final daysAgo = now.difference(diary.recordDate).inDays.toDouble();
      final x = (30 - daysAgo).clamp(0.0, 30.0);
      spots1.add(FlSpot(x, diary.skinScore.toDouble()));
      spots2.add(FlSpot(x, ((diary.sleepTimeMinutes ?? 0) / 60.0)));
      spots3.add(FlSpot(x, ((diary.waterIntakeMl ?? 0) / 1000.0)));
    }

    for (final s in [spots1, spots2, spots3]) {
      s.sort((a, b) => a.x.compareTo(b.x));
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('최근 30일 피부 기록',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textTitle)),
          const SizedBox(height: 8),

          // 범례
          Row(
            children: [
              _Legend(color: AppColors.primary, label: '피부점수'),
              const SizedBox(width: 12),
              _Legend(color: Color(0xFF6366F1), label: '수면(h)'),
              const SizedBox(width: 12),
              _Legend(color: Color(0xFF0EA5E9), label: '수분(L)'),
            ],
          ),
          const SizedBox(height: 12),

          SizedBox(
            height: 160,
            child: diaries.isEmpty
                ? const Center(
                child: Text('기록 없음',
                    style: TextStyle(color: AppColors.textSub2, fontSize: 13)))
                : LineChart(
              LineChartData(
                minX: 0, maxX: 30, minY: 0, maxY: 12,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 3,
                  getDrawingHorizontalLine: (_) =>
                  const FlLine(color: Color(0xFFE5E7EB), strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 10,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) return const Text('30일 전', style: TextStyle(fontSize: 9, color: AppColors.textSub2));
                        if (value == 30) return const Text('오늘', style: TextStyle(fontSize: 9, color: AppColors.textSub2));
                        return const SizedBox();
                      },
                    ),
                  ),
                ),
                lineBarsData: [
                  _lineBar(spots: spots1, color: AppColors.primary),
                  _lineBar(spots: spots2, color: const Color(0xFF6366F1)),
                  _lineBar(spots: spots3, color: const Color(0xFF0EA5E9)),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (touchedSpots) =>
                        touchedSpots.map((spot) {
                          final labels = ['점', 'h', 'L'];
                          final unit = labels[spot.barIndex];
                          return LineTooltipItem(
                            '${spot.y.toStringAsFixed(1)}$unit',
                            TextStyle(
                              color: spot.bar.color,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          );
                        }).toList(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  LineChartBarData _lineBar({required List<FlSpot> spots, required Color color}) {
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      color: color,
      barWidth: 2,
      isStrokeCapRound: true,
      dotData: FlDotData(
        show: spots.length <= 10,
        getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
          radius: 3,
          color: color,
          strokeColor: Colors.white,
          strokeWidth: 1.5,
        ),
      ),
      belowBarData: BarAreaData(show: false),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;

  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12, height: 3, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSub2, fontWeight: FontWeight.w500)),
      ],
    );
  }
}