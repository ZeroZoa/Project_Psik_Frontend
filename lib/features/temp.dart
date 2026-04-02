// 이 파일은 삭제 예정입니다.
// import 'package:flutter_svg/flutter_svg.dart';
// import 'package:provider/provider.dart';
//
// import '../../../../common/theme/app_colors.dart';
// import '../../../../features/auth/domain/enums/skin_concern.dart';
// import '../../../../features/auth/presentation/providers/auth_provider.dart';
// import '../../data/models/ingredient_detail_model.dart';
// import '../../data/repositories/cosmetics_repository.dart';
// import '../providers/home_provider.dart';
// import '../widgets/ingredient_info_card.dart';
//
// class HomeScreen extends StatelessWidget {
//   const HomeScreen({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     final repository = context.read<CosmeticsRepository>();
//     final authProvider = context.read<AuthProvider>();
//     final userSkinConcerns = authProvider.skinConcerns;
//
//     return ChangeNotifierProvider(
//       create: (_) => HomeProvider(
//         repository,
//         userSkinConcerns: userSkinConcerns,
//       )..init(),
//       child: _HomeView(
//         nickname: authProvider.nickname,
//         userSkinConcerns: userSkinConcerns,
//       ),
//     );
//   }
// }
//
// class _HomeView extends StatelessWidget {
//   final String nickname;
//   final List<SkinConcern> userSkinConcerns;
//
//   const _HomeView({
//     required this.nickname,
//     required this.userSkinConcerns,
//   });
//
//   Widget _buildConcernSection(
//       SkinConcern concern,
//       List<IngredientDetailModel> details,
//       ) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Padding(
//           padding: const EdgeInsets.fromLTRB(24, 32, 24, 14),
//           child: Row(
//             children: [
//               Expanded(
//                 child: Row(
//                   crossAxisAlignment: CrossAxisAlignment.baseline,
//                   textBaseline: TextBaseline.alphabetic,
//                   children: [
//                     Container(
//                       width: 3.5,
//                       height: 28,
//                       decoration: BoxDecoration(
//                         color: AppColors.primary,
//                         borderRadius: BorderRadius.circular(2),
//                       ),
//                     ),
//                     const SizedBox(width: 10),
//                     Text(
//                       concern.displayName,
//                       style: const TextStyle(
//                         fontSize: 20,
//                         fontWeight: FontWeight.w900,
//                         color: AppColors.textTitle,
//                         letterSpacing: -0.3,
//                       ),
//                     ),
//                     const SizedBox(width: 8),
//                     const Text(
//                       '맞춤 성분',
//                       style: TextStyle(
//                         fontSize: 13,
//                         fontWeight: FontWeight.w500,
//                         color: AppColors.textSub2,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               const Icon(
//                 Icons.keyboard_arrow_down_rounded,
//                 color: AppColors.textSub2,
//                 size: 20,
//               ),
//               const SizedBox(width: 2),
//             ],
//           ),
//         ),
//         if (details.isEmpty)
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 24),
//             child: Container(
//               padding: const EdgeInsets.all(24),
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(16),
//               ),
//               child: const Center(
//                 child: Text(
//                   '추천 성분이 없습니다.',
//                   style: TextStyle(color: AppColors.textSub2),
//                 ),
//               ),
//             ),
//           )
//         else
//           ListView.separated(
//             shrinkWrap: true,
//             physics: const NeverScrollableScrollPhysics(),
//             padding: const EdgeInsets.fromLTRB(40, 0, 40, 12),
//             itemCount: details.length,
//             separatorBuilder: (_, __) => const SizedBox(height: 16),
//             itemBuilder: (context, index) {
//               return IngredientInfoCard(detail: details[index]);
//             },
//           ),
//       ],
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final provider = context.watch<HomeProvider>();
//
//     if (provider.isLoading) {
//       return const Scaffold(
//         backgroundColor: AppColors.background,
//         body: Center(
//           child: CircularProgressIndicator(color: AppColors.primary),
//         ),
//       );
//     }
//
//     return Scaffold(
//       backgroundColor: AppColors.background,
//       body: RefreshIndicator(
//         onRefresh: () async => await provider.init(),
//         color: AppColors.primary,
//         child: CustomScrollView(
//           slivers: [
//
//             // ── 헤더 ──
//             if (userSkinConcerns.isNotEmpty)
//               SliverToBoxAdapter(
//                 child: Padding(
//                   padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
//                   child: RichText(
//                     text: TextSpan(
//                       style: const TextStyle(
//                         fontSize: 25,
//                         fontWeight: FontWeight.w900,
//                         color: AppColors.textTitle,
//                         height: 1.4,
//                       ),
//                       children: [
//                         TextSpan(
//                           text: nickname.isNotEmpty ? nickname : '회원',
//                           style: const TextStyle(color: AppColors.primary),
//                         ),
//                         const TextSpan(text: '님의 피부 고민에\n딱 맞는 피부 공식!'),
//                       ],
//                     ),
//                   ),
//                 ),
//               ),
//
//             // ── 고민별 섹션 (로그인 + 고민 설정된 경우) ──
//             if (userSkinConcerns.isNotEmpty)
//               SliverList(
//                 delegate: SliverChildBuilderDelegate(
//                       (context, index) {
//                     final concern = userSkinConcerns[index];
//                     final details =
//                         provider.recommendedDetailMap[concern] ?? [];
//                     return _buildConcernSection(concern, details);
//                   },
//                   childCount: userSkinConcerns.length,
//                 ),
//               ),
//
//             // ── Psik 추천 성분 (기타 or 비로그인 전체) ──
//             if (provider.otherIngredientDetails.isNotEmpty) ...[
//               SliverToBoxAdapter(
//                 child: Padding(
//                   padding: const EdgeInsets.fromLTRB(24, 32, 24, 14),
//                   child: Row(
//                     crossAxisAlignment: CrossAxisAlignment.center,
//                     children: [
//                       Container(
//                         width: 3.5,
//                         height: 32,
//                         decoration: BoxDecoration(
//                           color: AppColors.secondary,
//                           borderRadius: BorderRadius.circular(2),
//                         ),
//                       ),
//                       const SizedBox(width: 10),
//                       SvgPicture.asset(
//                         'assets/images/psik_text_logo.svg',
//                         height: 36,
//                       ),
//                       const SizedBox(width: 2),
//                       Text(
//                         userSkinConcerns.isNotEmpty
//                             ? '이 추천하는 다른 성분들이에요'
//                             : '이 추천하는 피부공식!',
//                         style: const TextStyle(
//                           fontSize: 15,
//                           fontWeight: FontWeight.w900,
//                           color: AppColors.textTitle,
//                           letterSpacing: -0.3,
//                         ),
//                       ),
//                       const Spacer(),
//                       const Icon(
//                         Icons.keyboard_arrow_down_rounded,
//                         color: AppColors.textSub2,
//                         size: 20,
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//               SliverPadding(
//                 padding: const EdgeInsets.fromLTRB(40, 0, 40, 12),
//                 sliver: SliverList(
//                   delegate: SliverChildBuilderDelegate(
//                         (context, index) {
//                       return Padding(
//                         padding: const EdgeInsets.only(bottom: 14),
//                         child: IngredientInfoCard(
//                           detail: provider.otherIngredientDetails[index],
//                         ),
//                       );
//                     },
//                     childCount: provider.otherIngredientDetails.length,
//                   ),
//                 ),
//               ),
//             ],
//             const SliverToBoxAdapter(child: SizedBox(height: 48)),
//           ],
//         ),
//       ),
//     );
//   }
// }