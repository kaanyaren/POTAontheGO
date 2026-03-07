import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/callsign_profile_model.dart';
import '../../data/repositories/callsign_repository.dart';

final callsignProfileProvider = FutureProvider.autoDispose
    .family<CallsignProfileModel, String>((ref, callsign) {
      final repository = ref.watch(callsignRepositoryProvider);
      return repository.getCallsignProfile(callsign);
    });

class CallsignInfoScreen extends ConsumerWidget {
  const CallsignInfoScreen({super.key, required this.callsign});

  final String callsign;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final normalizedCallsign = callsign.trim().toUpperCase();
    final profileAsync = ref.watch(callsignProfileProvider(normalizedCallsign));

    return Scaffold(
      appBar: AppBar(title: const Text('Çağrı İşareti Profili')),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => _ErrorState(
          message: '$error',
          onRetry: () {
            ref.invalidate(callsignProfileProvider(normalizedCallsign));
          },
        ),
        data: (profile) => _CallsignProfileContent(
          profile: profile,
          normalizedCallsign: normalizedCallsign,
        ),
      ),
    );
  }
}

class _CallsignProfileContent extends StatelessWidget {
  const _CallsignProfileContent({
    required this.profile,
    required this.normalizedCallsign,
  });

  final CallsignProfileModel profile;
  final String normalizedCallsign;

  @override
  Widget build(BuildContext context) {
    final displayCallsign = profile.callsign.isEmpty
        ? normalizedCallsign
        : profile.callsign;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      children: [
        _ProfileHeaderCard(profile: profile, displayCallsign: displayCallsign),
        const SizedBox(height: 14),
        _StatSectionCard(
          title: 'Aktivatör İstatistikleri',
          icon: Icons.radio_rounded,
          tone: const Color(0xFF1D6A37),
          children: [
            _StatRow(label: 'Aktivasyon', value: profile.activator.activations),
            _StatRow(label: 'Park', value: profile.activator.parks),
            _StatRow(label: 'QSO', value: profile.activator.qsos),
          ],
        ),
        const SizedBox(height: 12),
        _StatSectionCard(
          title: 'Deneme İstatistikleri',
          icon: Icons.explore_rounded,
          tone: const Color(0xFF2F7F33),
          children: [
            _StatRow(label: 'Aktivasyon', value: profile.attempts.activations),
            _StatRow(label: 'Park', value: profile.attempts.parks),
            _StatRow(label: 'QSO', value: profile.attempts.qsos),
          ],
        ),
        const SizedBox(height: 12),
        _StatSectionCard(
          title: 'Hunter İstatistikleri',
          icon: Icons.track_changes_rounded,
          tone: const Color(0xFF316B62),
          children: [
            _StatRow(label: 'Park', value: profile.hunter.parks),
            _StatRow(label: 'QSO', value: profile.hunter.qsos),
          ],
        ),
        const SizedBox(height: 12),
        _StatSectionCard(
          title: 'Ödüller',
          icon: Icons.workspace_premium_rounded,
          tone: const Color(0xFF4B6B1D),
          children: [
            _StatRow(label: 'Ödül Sayısı', value: profile.awards),
            _StatRow(label: 'Endorsement', value: profile.endorsements),
          ],
        ),
      ],
    );
  }
}

class _ProfileHeaderCard extends StatelessWidget {
  const _ProfileHeaderCard({
    required this.profile,
    required this.displayCallsign,
  });

  final CallsignProfileModel profile;
  final String displayCallsign;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1D4B2F), Color(0xFF143622)],
        ),
        border: Border.all(color: const Color(0xFF3F6B4D), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ProfileAvatar(
                  imageUrl: profile.gravatarUrl,
                  fallbackLetter: displayCallsign.isNotEmpty
                      ? displayCallsign[0]
                      : '?',
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayCallsign,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        profile.name.isEmpty
                            ? 'İsim bilgisi yok'
                            : profile.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: const Color(0xFFE8F4EC),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.place_rounded,
                            size: 18,
                            color: Color(0xFFCDE6D6),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              profile.qth.isEmpty
                                  ? 'QTH bilgisi bulunmuyor'
                                  : profile.qth,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: const Color(0xFFD3E8DB),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _SummaryBadge(
                  label: 'Ödüller',
                  value: profile.awards,
                  icon: Icons.workspace_premium_rounded,
                ),
                _SummaryBadge(
                  label: 'Endorsement',
                  value: profile.endorsements,
                  icon: Icons.check_circle_rounded,
                ),
                _SummaryBadge(
                  label: 'Aktivasyon',
                  value: profile.activator.activations,
                  icon: Icons.bolt_rounded,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.imageUrl, required this.fallbackLetter});

  final String? imageUrl;
  final String fallbackLetter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget fallbackAvatar() {
      return ColoredBox(
        color: const Color(0xFF2B6040),
        child: Center(
          child: Text(
            fallbackLetter,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      );
    }

    return Container(
      width: 86,
      height: 86,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: imageUrl == null
          ? fallbackAvatar()
          : Image.network(
              imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, _error, _stackTrace) => fallbackAvatar(),
            ),
    );
  }
}

class _SummaryBadge extends StatelessWidget {
  const _SummaryBadge({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final int value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.white.withValues(alpha: 0.12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: const Color(0xFFE8F4EC)),
            const SizedBox(width: 6),
            Text(
              '$label: $value',
              style: theme.textTheme.labelMedium?.copyWith(
                color: const Color(0xFFE8F4EC),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatSectionCard extends StatelessWidget {
  const _StatSectionCard({
    required this.title,
    required this.icon,
    required this.tone,
    required this.children,
  });

  final String title;
  final IconData icon;
  final Color tone;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: tone.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(7),
                    child: Icon(icon, size: 18, color: tone),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            DecoratedBox(
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainer.withValues(
                  alpha: 0.5,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Column(children: children),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Text(
            value.toString(),
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  size: 34,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(height: 10),
                Text(
                  'Profil bilgisi alınamadı',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(message, textAlign: TextAlign.center),
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Tekrar dene'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
