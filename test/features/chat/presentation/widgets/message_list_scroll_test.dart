import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Minimal reproduction of the chat center-sliver scroll layout.
class CenterSliverScrollHarness extends StatefulWidget {
  const CenterSliverScrollHarness({
    required this.initialCount,
    this.pivotIndex,
    super.key,
  });

  final int initialCount;
  final int? pivotIndex;

  @override
  CenterSliverScrollHarnessState createState() =>
      CenterSliverScrollHarnessState();
}

class CenterSliverScrollHarnessState extends State<CenterSliverScrollHarness> {
  final ScrollController scrollController = ScrollController();
  final GlobalKey centerKey = GlobalKey();
  late List<int> _preCenterItems;
  late List<int> _postCenterItems;

  @override
  void initState() {
    super.initState();
    _resetItems(widget.initialCount);
  }

  void _resetItems(int count) {
    final List<int> items = List<int>.generate(count, (int i) => i);
    if (widget.pivotIndex == null) {
      _preCenterItems = items;
      _postCenterItems = const [];
      return;
    }
    final int pivot = widget.pivotIndex!.clamp(0, items.length - 1);
    _preCenterItems = items.sublist(0, pivot + 1);
    _postCenterItems = pivot + 1 < items.length
        ? items.sublist(pivot + 1)
        : const [];
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  void prependItems(int count) {
    setState(() {
      _preCenterItems = <int>[
        ...List<int>.generate(count, (int i) => -count + i),
        ..._preCenterItems,
      ];
    });
  }

  void appendPreCenterNewestItem() {
    setState(() {
      final int next = _preCenterItems.isEmpty ? 0 : _preCenterItems.last + 1;
      _preCenterItems = <int>[..._preCenterItems, next];
    });
  }

  void appendPostCenterItems(int count) {
    setState(() {
      final int start = _postCenterItems.isEmpty
          ? (_preCenterItems.isEmpty ? 0 : _preCenterItems.last + 1)
          : _postCenterItems.last + 1;
      _postCenterItems = <int>[
        ..._postCenterItems,
        ...List<int>.generate(count, (int i) => start + i),
      ];
    });
  }

  double? get scrollOffset =>
      scrollController.hasClients ? scrollController.position.pixels : null;

  void scrollToMiddle() {
    if (!scrollController.hasClients) {
      return;
    }
    scrollController.jumpTo(scrollController.position.maxScrollExtent / 2);
  }

  void scrollToTop() {
    if (!scrollController.hasClients) {
      return;
    }
    scrollController.jumpTo(scrollController.position.maxScrollExtent);
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      controller: scrollController,
      reverse: true,
      center: centerKey,
      slivers: [
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (BuildContext context, int index) {
              final int item = _postCenterItems[index];
              return SizedBox(
                key: ValueKey<int>(item),
                height: 48,
                child: Text('post $item'),
              );
            },
            childCount: _postCenterItems.length,
          ),
        ),
        SliverPadding(
          key: centerKey,
          padding: EdgeInsets.zero,
          sliver: const SliverToBoxAdapter(child: SizedBox.shrink()),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (BuildContext context, int index) {
              final int item = _preCenterItems[_preCenterItems.length - 1 - index];
              return SizedBox(
                key: ValueKey<int>(item),
                height: 48,
                child: Text('pre $item'),
              );
            },
            childCount: _preCenterItems.length,
          ),
        ),
      ],
    );
  }
}

void main() {
  testWidgets('pre-center prepend keeps scroll offset stable', (tester) async {
    final GlobalKey<CenterSliverScrollHarnessState> harnessKey =
        GlobalKey<CenterSliverScrollHarnessState>();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CenterSliverScrollHarness(
            key: harnessKey,
            initialCount: 20,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    harnessKey.currentState!.scrollToTop();
    await tester.pumpAndSettle();
    final double offsetBefore = harnessKey.currentState!.scrollOffset!;
    harnessKey.currentState!.prependItems(10);
    await tester.pumpAndSettle();
    final double offsetAfter = harnessKey.currentState!.scrollOffset!;
    expect(offsetAfter, closeTo(offsetBefore, 1));
  });

  testWidgets('scroll offset increases when scrolled up', (tester) async {
    final GlobalKey<CenterSliverScrollHarnessState> harnessKey =
        GlobalKey<CenterSliverScrollHarnessState>();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 400,
            child: CenterSliverScrollHarness(
              key: harnessKey,
              initialCount: 50,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final double bottomOffset = harnessKey.currentState!.scrollOffset!;
    harnessKey.currentState!.scrollToTop();
    await tester.pumpAndSettle();
    final double topOffset = harnessKey.currentState!.scrollOffset!;
    expect(topOffset, greaterThan(bottomOffset));
    expect(bottomOffset, lessThan(24));
  });

  testWidgets('pinned pivot keeps offset when appending post-center page', (
    tester,
  ) async {
    final GlobalKey<CenterSliverScrollHarnessState> harnessKey =
        GlobalKey<CenterSliverScrollHarnessState>();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 400,
            child: CenterSliverScrollHarness(
              key: harnessKey,
              initialCount: 50,
              pivotIndex: 10,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    harnessKey.currentState!.scrollToMiddle();
    await tester.pumpAndSettle();
    final double offsetBefore = harnessKey.currentState!.scrollOffset!;
    harnessKey.currentState!.appendPostCenterItems(30);
    await tester.pumpAndSettle();
    final double offsetAfter = harnessKey.currentState!.scrollOffset!;
    expect(offsetAfter, closeTo(offsetBefore, 1));
  });

  testWidgets('first post-center item keeps offset at middle scroll', (
    tester,
  ) async {
    final GlobalKey<CenterSliverScrollHarnessState> harnessKey =
        GlobalKey<CenterSliverScrollHarnessState>();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 400,
            child: CenterSliverScrollHarness(
              key: harnessKey,
              initialCount: 50,
              pivotIndex: 49,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    harnessKey.currentState!.scrollToMiddle();
    await tester.pumpAndSettle();
    final double offsetBefore = harnessKey.currentState!.scrollOffset!;
    harnessKey.currentState!.appendPostCenterItems(1);
    await tester.pumpAndSettle();
    final double offsetAfter = harnessKey.currentState!.scrollOffset!;
    expect(offsetAfter, closeTo(offsetBefore, 1));
  });
}
