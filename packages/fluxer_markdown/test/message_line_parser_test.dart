import 'package:fluxer_markdown/src/contexts/fluxer_markdown_context.dart';
import 'package:fluxer_markdown/src/contexts/fluxer_markdown_features.dart';
import 'package:fluxer_markdown/src/parsing/message_line_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final FluxerMarkdownFeatures features = FluxerMarkdownFeatures.forContext(
    FluxerMarkdownContext.standardWithJumbo,
  );

  group('parseMessageContentStructure', () {
    test('preserves two blank lines between plain text lines', () {
      const String input = 'test line one\n\n\ntest line two';
      final List<MessageContentSegment> segments =
          parseMessageContentStructure(input, features);
      expect(segments, hasLength(1));
      expect(segments.first, isA<MessageTextFlowSegment>());
      expect(
        (segments.first as MessageTextFlowSegment).text,
        'test line one\n\n\ntest line two',
      );
    });

    test('parseMessageTextFlowParts matches web-style text nodes', () {
      const String input = 'test line one\n\n\ntest line two';
      final List<String> parts = parseMessageTextFlowParts(input, features);
      expect(parts, ['test line one\n\n\ntest line two']);
    });

    test('preserves single soft line break within a paragraph', () {
      const String input = 'line one\nline two';
      final List<MessageContentSegment> segments =
          parseMessageContentStructure(input, features);
      expect(segments, hasLength(1));
      expect(
        (segments.first as MessageTextFlowSegment).text,
        'line one\nline two',
      );
    });

    test('splits block markdown from surrounding text', () {
      const String input = 'before\n\n# heading\n\nafter';
      final List<MessageContentSegment> segments =
          parseMessageContentStructure(input, features);
      expect(segments, hasLength(3));
      expect(segments[0], isA<MessageTextFlowSegment>());
      expect((segments[0] as MessageTextFlowSegment).text, 'before\n\n');
      expect(segments[1], isA<MessageBlockMarkdownSegment>());
      expect((segments[1] as MessageBlockMarkdownSegment).text, '# heading');
      expect(segments[2], isA<MessageTextFlowSegment>());
      expect((segments[2] as MessageTextFlowSegment).text, 'after');
    });

    test('does not use line parsing for restricted inline reply context', () {
      expect(
        usesMessageLineParsing(FluxerMarkdownContext.restrictedInlineReply),
        isFalse,
      );
      expect(
        usesMessageLineParsing(FluxerMarkdownContext.standardWithJumbo),
        isTrue,
      );
    });
  });
}
