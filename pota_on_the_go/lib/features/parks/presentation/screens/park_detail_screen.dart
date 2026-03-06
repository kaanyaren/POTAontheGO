import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../activations/data/models/activation_model.dart';
import '../../../activations/data/repositories/activation_repository.dart';
import '../../data/models/park_model.dart';

class ParkDetailScreen extends ConsumerStatefulWidget {
  const ParkDetailScreen({super.key, required this.park});

  final ParkModel park;

  @override
  ConsumerState<ParkDetailScreen> createState() => _ParkDetailScreenState();
}

class _ParkDetailScreenState extends ConsumerState<ParkDetailScreen> {
  bool _loadActivations = false;

  @override
  Widget build(BuildContext context) {
    final activationsAsync = _loadActivations
        ? ref.watch(parkActivationsProvider(widget.park.reference))
        : null;

    return Scaffold(
      appBar: AppBar(title: Text(widget.park.reference)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _ParkHeaderCard(park: widget.park),
          const SizedBox(height: 16),
          Card(
            child: ExpansionTile(
              title: const Text('Geçmiş Aktivasyonlar'),
              subtitle: Text(
                _loadActivations
                    ? 'Bu bölüm açıldığında veriler yüklenir.'
                    : 'Ağ isteğini geciktirmek için kapalı tutulur.',
              ),
              initiallyExpanded: _loadActivations,
              onExpansionChanged: (expanded) {
                if (expanded && !_loadActivations) {
                  setState(() => _loadActivations = true);
                }
              },
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              children: [
                if (!_loadActivations)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      onPressed: () => setState(() => _loadActivations = true),
                      icon: const Icon(Icons.download_outlined),
                      label: const Text('Aktivasyonları yükle'),
                    ),
                  )
                else
                  _ActivationList(activationsAsync: activationsAsync!),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivationList extends StatelessWidget {
  const _ActivationList({required this.activationsAsync});

  final AsyncValue<List<ActivationModel>> activationsAsync;

  @override
  Widget build(BuildContext context) {
    return activationsAsync.when(
      data: (activations) {
        if (activations.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('Bu park için aktivasyon kaydı bulunamadı.'),
          );
        }

        return Column(
          children: activations
              .map((activation) => _ActivationCard(activation: activation))
              .toList(growable: false),
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text('Aktivasyonlar alınamadı: $error'),
      ),
    );
  }
}

class _ParkHeaderCard extends StatelessWidget {
  const _ParkHeaderCard({required this.park});

  final ParkModel park;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(park.name, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text('Referans: ${park.reference}'),
            const SizedBox(height: 4),
            Text('Konum: ${park.locationDesc}'),
            const SizedBox(height: 4),
            Text('Koordinat: ${park.latitude}, ${park.longitude}'),
          ],
        ),
      ),
    );
  }
}

class _ActivationCard extends StatelessWidget {
  const _ActivationCard({required this.activation});

  final ActivationModel activation;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(Icons.history_toggle_off),
        title: Text('${activation.activator} • ${activation.qsos} QSO'),
        subtitle: Text('Tarih: ${activation.date}'),
      ),
    );
  }
}
