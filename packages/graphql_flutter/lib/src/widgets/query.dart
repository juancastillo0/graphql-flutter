import 'package:flutter/widgets.dart';

import 'package:graphql/client.dart';

import 'package:graphql_flutter/src/widgets/graphql_provider.dart';

// method to call from widget to fetchmore queries
typedef FetchMore = Future<QueryResult> Function(FetchMoreOptions options);

typedef Refetch = Future<QueryResult?> Function();

typedef QueryBuilder = Widget Function(
  QueryResult result, {
  Refetch? refetch,
  FetchMore? fetchMore,
});

/// Builds a [Query] widget based on the a given set of [QueryOptions]
/// that streams [QueryResult]s into the [QueryBuilder].
class Query extends StatefulWidget {
  const Query({
    final Key? key,
    required this.options,
    required this.builder,
  }) : super(key: key);

  final QueryOptions options;
  final QueryBuilder builder;

  @override
  QueryState createState() => QueryState();
}

class QueryState extends State<Query> {
  ObservableQuery? observableQuery;
  GraphQLClient? _client;

  WatchQueryOptions get _options => widget.options.asWatchQueryOptions();

  void _initQuery() {
    observableQuery?.close();
    observableQuery = _client!.watchQuery(_options);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final GraphQLClient client = GraphQLProvider.of(context).value;
    if (client != _client) {
      _client = client;
      _initQuery();
    }
  }

  @override
  void didUpdateWidget(Query oldWidget) {
    super.didUpdateWidget(oldWidget);

    final GraphQLClient client = GraphQLProvider.of(context).value;

    final optionsWithOverrides = _options;
    optionsWithOverrides.policies = client.defaultPolicies.watchQuery
        .withOverrides(optionsWithOverrides.policies);

    if (!observableQuery!.options.equal(optionsWithOverrides)) {
      _initQuery();
    }
  }

  @override
  void dispose() {
    observableQuery?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QueryResult>(
      initialData: observableQuery?.latestResult ?? QueryResult.loading(),
      stream: observableQuery!.stream,
      builder: (
        BuildContext buildContext,
        AsyncSnapshot<QueryResult> snapshot,
      ) {
        return widget.builder(
          snapshot.data!,
          refetch: observableQuery!.refetch,
          fetchMore: observableQuery!.fetchMore,
        );
      },
    );
  }
}
