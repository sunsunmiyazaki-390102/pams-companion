import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/knowledge_asset.dart';
import '../models/knowledge_link.dart';
import '../models/knowledge_link_type.dart';
import '../models/knowledge_type.dart';
import '../repositories/knowledge_asset_repository.dart';
import '../repositories/knowledge_link_repository.dart';

class KnowledgeNetworkGraphScreen
    extends StatefulWidget {
  const KnowledgeNetworkGraphScreen({
    super.key,
  });

  @override
  State<KnowledgeNetworkGraphScreen> createState() =>
      _KnowledgeNetworkGraphScreenState();
}

class _KnowledgeNetworkGraphScreenState
    extends State<KnowledgeNetworkGraphScreen> {
  final KnowledgeAssetRepository _knowledgeRepository =
      KnowledgeAssetRepository();

  final KnowledgeLinkRepository _linkRepository =
      KnowledgeLinkRepository();

  late Future<_KnowledgeGraphData> _graphDataFuture;

  @override
  void initState() {
    super.initState();

    _graphDataFuture = _loadGraphData();
  }

  Future<_KnowledgeGraphData> _loadGraphData() async {
    final results = await Future.wait<Object>([
      _knowledgeRepository.findAll(),
      _linkRepository.findAll(),
    ]);

    return _KnowledgeGraphData(
      knowledgeAssets:
          results[0] as List<KnowledgeAsset>,
      links:
          results[1] as List<KnowledgeLink>,
    );
  }

  Future<void> _reload() async {
    setState(() {
      _graphDataFuture = _loadGraphData();
    });

    await _graphDataFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Knowledge Network Graph',
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(
                24,
                24,
                24,
                12,
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        child: Icon(
                          Icons.account_tree_outlined,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Knowledge Graph',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Knowledge同士の関係を'
                    'ノードと線で表示します。',
                  ),
                ],
              ),
            ),
            Expanded(
              child:
                  FutureBuilder<_KnowledgeGraphData>(
                future: _graphDataFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                      child:
                          CircularProgressIndicator(),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding:
                            const EdgeInsets.all(24),
                        child: Text(
                          'Knowledge Graphの'
                          '読み込みに失敗しました。\n'
                          '${snapshot.error}',
                          textAlign:
                              TextAlign.center,
                        ),
                      ),
                    );
                  }

                  final graphData =
                      snapshot.data;

                  if (graphData == null) {
                    return const Center(
                      child: Text(
                        'Graphデータが'
                        '見つかりません。',
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: _reload,
                    child: ListView(
                      physics:
                          const AlwaysScrollableScrollPhysics(),
                      padding:
                          const EdgeInsets.fromLTRB(
                        24,
                        12,
                        24,
                        24,
                      ),
                      children: [
                        _GraphSummaryCard(
                          knowledgeCount:
                              graphData
                                  .knowledgeAssets
                                  .length,
                          linkCount:
                              graphData.links.length,
                        ),
                        const SizedBox(height: 16),
                        if (graphData
                            .knowledgeAssets
                            .isEmpty)
                          const Card(
                            child: Padding(
                              padding:
                                  EdgeInsets.all(24),
                              child: Text(
                                '表示できるKnowledgeが'
                                'ありません。',
                                textAlign:
                                    TextAlign.center,
                              ),
                            ),
                          )
                        else
                          _KnowledgeGraphCanvas(
                            knowledgeAssets:
                                graphData
                                    .knowledgeAssets,
                            links:
                                graphData.links,
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KnowledgeGraphData {
  const _KnowledgeGraphData({
    required this.knowledgeAssets,
    required this.links,
  });

  final List<KnowledgeAsset> knowledgeAssets;
  final List<KnowledgeLink> links;
}

class _GraphSummaryCard extends StatelessWidget {
  const _GraphSummaryCard({
    required this.knowledgeCount,
    required this.linkCount,
  });

  final int knowledgeCount;
  final int linkCount;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.stretch,
          children: [
            const Row(
              children: [
                CircleAvatar(
                  child: Icon(
                    Icons.analytics_outlined,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Graphデータ',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _GraphDataRow(
              label: 'Knowledge',
              count: knowledgeCount,
            ),
            const SizedBox(height: 12),
            _GraphDataRow(
              label: 'KnowledgeLink',
              count: linkCount,
            ),
          ],
        ),
      ),
    );
  }
}

class _GraphDataRow extends StatelessWidget {
  const _GraphDataRow({
    required this.label,
    required this.count,
  });

  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
          ),
        ),
        Text(
          '$count件',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _KnowledgeGraphCanvas
    extends StatelessWidget {
  const _KnowledgeGraphCanvas({
    required this.knowledgeAssets,
    required this.links,
  });

  final List<KnowledgeAsset> knowledgeAssets;
  final List<KnowledgeLink> links;

  @override
  Widget build(BuildContext context) {
    final colorScheme =
        Theme.of(context).colorScheme;

    final graphHeight = math.max(
      360.0,
      80.0 +
          (knowledgeAssets.length * 156.0),
    ).toDouble();

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(
                8,
                8,
                8,
                16,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.hub_outlined,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Knowledge Network',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: graphHeight,
              child: LayoutBuilder(
                builder: (
                  context,
                  constraints,
                ) {
                  final nodeWidth = math
                      .min(
                        260.0,
                        math.max(
                          120.0,
                          constraints.maxWidth -
                              32.0,
                        ),
                      )
                      .toDouble();

                  const nodeHeight = 104.0;
                  const verticalInterval =
                      156.0;

                  final nodeRects =
                      <String, Rect>{};

                  for (
                    var index = 0;
                    index <
                        knowledgeAssets.length;
                    index++
                  ) {
                    final knowledge =
                        knowledgeAssets[index];

                    final left =
                        (constraints.maxWidth -
                                nodeWidth) /
                            2;

                    final top =
                        40.0 +
                        (index *
                            verticalInterval);

                    nodeRects[
                        knowledge.knowledgeId] =
                        Rect.fromLTWH(
                      left,
                      top,
                      nodeWidth,
                      nodeHeight,
                    );
                  }

                  return CustomPaint(
                    painter:
                        _KnowledgeGraphPainter(
                      links: links,
                      nodeRects: nodeRects,
                      lineColor:
                          colorScheme.outline,
                      labelBackgroundColor:
                          colorScheme.surface,
                      labelTextColor:
                          colorScheme.onSurface,
                    ),
                    child: Stack(
                      children: [
                        for (
                          final knowledge
                              in knowledgeAssets
                        )
                          Positioned.fromRect(
                            rect: nodeRects[
                                knowledge
                                    .knowledgeId]!,
                            child:
                                _GraphKnowledgeNode(
                              knowledge:
                                  knowledge,
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GraphKnowledgeNode
    extends StatelessWidget {
  const _GraphKnowledgeNode({
    required this.knowledge,
  });

  final KnowledgeAsset knowledge;

  @override
  Widget build(BuildContext context) {
    final colorScheme =
        Theme.of(context).colorScheme;

    return Material(
      color:
          colorScheme.primaryContainer,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outlineVariant,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor:
                  colorScheme.surface,
              child: Icon(
                Icons.lightbulb_outline,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      knowledge.content,
                      maxLines: 3,
                      overflow:
                          TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight:
                            FontWeight.bold,
                        color: colorScheme
                            .onPrimaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    KnowledgeType.displayName(
                      knowledge.knowledgeType,
                    ),
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(
                          color: colorScheme
                              .onPrimaryContainer,
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
}

class _KnowledgeGraphPainter
    extends CustomPainter {
  const _KnowledgeGraphPainter({
    required this.links,
    required this.nodeRects,
    required this.lineColor,
    required this.labelBackgroundColor,
    required this.labelTextColor,
  });

  final List<KnowledgeLink> links;
  final Map<String, Rect> nodeRects;
  final Color lineColor;
  final Color labelBackgroundColor;
  final Color labelTextColor;

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (
      var index = 0;
      index < links.length;
      index++
    ) {
      final link = links[index];

      final fromRect =
          nodeRects[link.fromKnowledgeId];

      final toRect =
          nodeRects[link.toKnowledgeId];

      if (fromRect == null ||
          toRect == null) {
        continue;
      }

      if (link.fromKnowledgeId ==
          link.toKnowledgeId) {
        continue;
      }

      final isDownward =
          toRect.center.dy >
              fromRect.center.dy;

      final start = isDownward
          ? fromRect.bottomCenter
          : fromRect.topCenter;

      final end = isDownward
          ? toRect.topCenter
          : toRect.bottomCenter;

      final curveOffset =
          ((index % 5) - 2) * 18.0;

      final controlPoint = Offset(
        start.dx + curveOffset,
        (start.dy + end.dy) / 2,
      );

      final path = Path()
        ..moveTo(
          start.dx,
          start.dy,
        )
        ..quadraticBezierTo(
          controlPoint.dx,
          controlPoint.dy,
          end.dx,
          end.dy,
        );

      canvas.drawPath(
        path,
        linePaint,
      );

      _drawArrowHead(
        canvas: canvas,
        paint: linePaint,
        controlPoint: controlPoint,
        end: end,
      );

      final labelPosition =
          _quadraticPoint(
        start: start,
        control: controlPoint,
        end: end,
        t: 0.5,
      );

      _drawLinkLabel(
        canvas: canvas,
        position: labelPosition,
        text:
            KnowledgeLinkType.displayName(
          link.linkType,
        ),
      );
    }
  }

  Offset _quadraticPoint({
    required Offset start,
    required Offset control,
    required Offset end,
    required double t,
  }) {
    final inverseT = 1 - t;

    return Offset(
      (inverseT * inverseT * start.dx) +
          (2 *
              inverseT *
              t *
              control.dx) +
          (t * t * end.dx),
      (inverseT * inverseT * start.dy) +
          (2 *
              inverseT *
              t *
              control.dy) +
          (t * t * end.dy),
    );
  }

  void _drawArrowHead({
    required Canvas canvas,
    required Paint paint,
    required Offset controlPoint,
    required Offset end,
  }) {
    final angle = math.atan2(
      end.dy - controlPoint.dy,
      end.dx - controlPoint.dx,
    );

    const arrowLength = 12.0;
    const arrowAngle = math.pi / 6;

    final firstPoint = Offset(
      end.dx -
          arrowLength *
              math.cos(
                angle - arrowAngle,
              ),
      end.dy -
          arrowLength *
              math.sin(
                angle - arrowAngle,
              ),
    );

    final secondPoint = Offset(
      end.dx -
          arrowLength *
              math.cos(
                angle + arrowAngle,
              ),
      end.dy -
          arrowLength *
              math.sin(
                angle + arrowAngle,
              ),
    );

    canvas.drawLine(
      end,
      firstPoint,
      paint,
    );

    canvas.drawLine(
      end,
      secondPoint,
      paint,
    );
  }

  void _drawLinkLabel({
    required Canvas canvas,
    required Offset position,
    required String text,
  }) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: labelTextColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout();

    const horizontalPadding = 8.0;
    const verticalPadding = 4.0;

    final backgroundRect =
        Rect.fromCenter(
      center: position,
      width:
          textPainter.width +
          (horizontalPadding * 2),
      height:
          textPainter.height +
          (verticalPadding * 2),
    );

    final backgroundPaint = Paint()
      ..color = labelBackgroundColor
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        backgroundRect,
        const Radius.circular(8),
      ),
      backgroundPaint,
    );

    final borderPaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        backgroundRect,
        const Radius.circular(8),
      ),
      borderPaint,
    );

    textPainter.paint(
      canvas,
      Offset(
        position.dx -
            (textPainter.width / 2),
        position.dy -
            (textPainter.height / 2),
      ),
    );
  }

  @override
  bool shouldRepaint(
    covariant _KnowledgeGraphPainter
        oldDelegate,
  ) {
    return oldDelegate.links != links ||
        oldDelegate.nodeRects !=
            nodeRects ||
        oldDelegate.lineColor !=
            lineColor ||
        oldDelegate.labelBackgroundColor !=
            labelBackgroundColor ||
        oldDelegate.labelTextColor !=
            labelTextColor;
  }
}
