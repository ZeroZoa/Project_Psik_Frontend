import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../../../common/theme/app_colors.dart';
import '../../../../features/auth/domain/enums/skin_concern.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../data/repositories/cosmetics_repository.dart';
import '../providers/home_provider.dart';
import '../widgets/ingredient_info_card.dart';
import '../widgets/home_concern_section.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = context.read<CosmeticsRepository>();
    final authProvider = context.read<AuthProvider>();
    final userSkinConcerns = authProvider.skinConcerns;

    return ChangeNotifierProvider(
      create: (_) => HomeProvider(
        repository,
        userSkinConcerns: userSkinConcerns,
      )..init(),
      child: _HomeView(
        nickname: authProvider.nickname,
        userSkinConcerns: userSkinConcerns,
      ),
    );
  }
}

class _HomeView extends StatelessWidget {
  final String nickname;
  final List<SkinConcern> userSkinConcerns;

  const _HomeView({
    required this.nickname,
    required this.userSkinConcerns,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HomeProvider>();

    if (provider.isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: () async => await provider.init(),
        color: AppColors.primary,
        child: CustomScrollView(
          slivers: [

            // ── 상단 여백 (로그인 + 고민 설정된 경우) ──
            if (userSkinConcerns.isNotEmpty)
              const SliverToBoxAdapter(child: SizedBox(height: 5)),

            // ── 헤더  ──
            if (userSkinConcerns.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textTitle,
                            height: 1.4,
                          ),
                          children: [
                            TextSpan(
                              text: nickname.isNotEmpty ? nickname : '회원',
                              style: const TextStyle(color: AppColors.primary),
                            ),
                            const TextSpan(text: '님에게 딱 맞는 피부공식'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // ── 고민별 섹션 (로그인 + 고민 설정된 경우) ──
            if (userSkinConcerns.isNotEmpty)
              SliverList(
                delegate: SliverChildBuilderDelegate(
                      (context, index) {
                    final concern = userSkinConcerns[index];
                    final details =
                        provider.recommendedDetailMap[concern] ?? [];
                    return HomeConcernSection(
                      concern: concern,
                      details: details,
                      isFirst: index == 0,
                    );
                  },
                  childCount: userSkinConcerns.length,
                ),
              ),

            // ── Psik 추천 성분 (기타 or 비로그인 전체) ──
            if (provider.otherIngredientDetails.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (userSkinConcerns.isNotEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24),
                        child: Divider(
                          height: 1,
                          thickness: 1,
                          color: Color(0xFFE5E7EB),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        textBaseline: TextBaseline.ideographic,
                        children: [
                          Container(
                            width: 3.5,
                            height: 38,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 10),
                          SvgPicture.asset(
                            'assets/images/psik_text_logo.svg',
                            height: 38,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            userSkinConcerns.isNotEmpty
                                ? '이 추천하는 모든 성분'
                                : '이 추천하는 피부공식',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textTitle,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const Spacer(),
                          const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: AppColors.textSub2,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(42, 0, 42, 12),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: IngredientInfoCard(
                          detail: provider.otherIngredientDetails[index],
                        ),
                      );
                    },
                    childCount: provider.otherIngredientDetails.length,
                  ),
                ),
              ),
            ],
            const SliverToBoxAdapter(child: SizedBox(height: 48)),
          ],
        ),
      ),
    );
  }
}