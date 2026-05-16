// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:dartastic_opentelemetry/testing.dart';
import 'package:otel_firebase_performance/otel_firebase_performance.dart';
import 'package:test/test.dart';

void main() {
  late TestHarness harness;
  late InMemorySpanExporter spans;

  setUpAll(() async {
    harness = await maybeInitializeOtelForTest(
      serviceName: 'otel_firebase_performance-test',
    );
    spans = harness.spans;
  });

  setUp(() => harness.clear());

  Map<String, Object> attrsOf(Span s) =>
      {for (final a in s.attributes.toList()) a.key: a.value};

  test('traceStop records trace name + duration', () async {
    await tracedFirebasePerformance<String>(
      operation: 'traceStop',
      invoke: () async => const FirebasePerformanceCallResult(
        value: 'ok',
        result: FirebasePerformanceResult(
          traceName: 'checkout_flow',
          traceDurationMs: 842,
          metricName: 'items',
          metricValue: 3,
        ),
      ),
    );
    final a = attrsOf(spans.findSpanByName('firebase_performance traceStop')!);
    expect(a['firebase_performance.trace.name'], 'checkout_flow');
    expect(a['firebase_performance.trace.duration_ms'], 842);
  });

  test('httpMetric 5xx sets span error', () async {
    await tracedFirebasePerformance<String>(
      operation: 'httpMetricStop',
      invoke: () async => const FirebasePerformanceCallResult(
        value: 'ok',
        result: FirebasePerformanceResult(
          httpMethod: 'POST',
          httpUrl: 'https://api.example.com/checkout',
          httpResponseCode: 503,
        ),
      ),
    );
    expect(
      spans.findSpanByName('firebase_performance httpMetricStop')!.status,
      SpanStatusCode.Error,
    );
  });

  test('suppression skips spans', () async {
    await runWithoutFirebasePerformanceInstrumentationAsync(() async {
      await tracedFirebasePerformance<String>(
        operation: 'newTrace',
        invoke: () async => const FirebasePerformanceCallResult(value: 'v'),
      );
    });
    expect(spans.findSpansStartingWith('firebase_performance '), isEmpty);
  });
}
