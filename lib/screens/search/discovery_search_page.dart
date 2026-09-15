import 'package:flutter/material.dart';

import '../../services/global_search_service.dart';
import '../../navigation/search_navigation.dart';
import '../../widgets/discovery_search_field.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/search_result_tile.dart';

class DiscoverySearchPage extends StatefulWidget {
  final GlobalSearchService? service;
  final String initialQuery;
  const DiscoverySearchPage({super.key, this.service, this.initialQuery = ''});
  @override
  State<DiscoverySearchPage> createState() => _DiscoverySearchPageState();
}

class _DiscoverySearchPageState extends State<DiscoverySearchPage> {
  late final controller = TextEditingController(text: widget.initialQuery);
  late String query = widget.initialQuery;
  late final search = widget.service ?? GlobalSearchService();
  bool loading = true;
  bool failed = false;
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      failed = false;
    });
    try {
      await search.load();
      if (mounted) setState(() => loading = false);
    } catch (_) {
      if (mounted) {
        setState(() {
          loading = false;
          failed = true;
        });
      }
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final results = search.search(query);
    return Scaffold(
      appBar: AppBar(title: const Text('Discover search')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: DiscoverySearchField(
                controller: controller,
                autofocus: true,
                onChanged: (value) => setState(() => query = value),
              ),
            ),
            if (!loading && !failed)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  query.trim().isEmpty
                      ? 'Explore categories and challenges'
                      : query.trim().length == 1
                      ? 'Type at least 2 characters'
                      : '${results.length == 60 ? 'Top 60' : results.length} results',
                ),
              ),
            Expanded(
              child: loading
                  ? const Center(child: CircularProgressIndicator())
                  : failed
                  ? EmptyState(
                      icon: Icons.cloud_off_outlined,
                      title: 'Unable to load search',
                      message: 'Please try again.',
                      actionLabel: 'Retry',
                      onAction: load,
                    )
                  : query.trim().length == 1
                  ? const EmptyState(
                      icon: Icons.travel_explore,
                      title: 'Follow your curiosity',
                      message: 'Type at least 2 characters to explore.',
                    )
                  : results.isEmpty
                  ? const EmptyState(
                      icon: Icons.search_off,
                      title: 'No results found',
                      message:
                          'Try an experience, challenge, place or variety.',
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      itemCount: results.length,
                      itemBuilder: (context, index) => SearchResultTile(
                        result: results[index],
                        onTap: () =>
                            openSearchResult(context, results[index], search),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
