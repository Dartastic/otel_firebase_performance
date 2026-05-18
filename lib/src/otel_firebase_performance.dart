// Licensed under the Dartastic Pro Software License Agreement.
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';

import 'otel_firebase_performance_suppression.dart';

const _tracerName = 'dartastic_otel_libs_firebase_performance';

Tracer _tracer() => OTel.tracerProvider().getTracer(_tracerName);

class FirebasePerformanceResult {
  const FirebasePerformanceResult({
    this.traceName,
    this.traceDurationMs,
    this.httpMethod,
    this.httpUrl,
    this.httpResponseCode,
    this.requestPayloadSize,
    this.responsePayloadSize,
    this.responseContentType,
    this.metricName,
    this.metricValue,
    this.attributeName,
    this.attributeValue,
    this.collectionEnabled,
    this.instrumentationEnabled,
  });

  /// Custom trace name (`newTrace('checkout')`).
  final String? traceName;

  /// Custom trace duration in milliseconds.
  final int? traceDurationMs;

  /// HTTP method on `HttpMetric` (GET/POST/PUT/...).
  final String? httpMethod;
  final String? httpUrl;
  final int? httpResponseCode;

  final int? requestPayloadSize;
  final int? responsePayloadSize;
  final String? responseContentType;

  /// Custom metric set via `incrementMetric`/`putMetric`.
  final String? metricName;
  final int? metricValue;

  final String? attributeName;
  final String? attributeValue;

  final bool? collectionEnabled;

  /// Performance Monitoring instrumentation enabled at runtime.
  final bool? instrumentationEnabled;
}

class FirebasePerformanceCallResult<T> {
  const FirebasePerformanceCallResult({required this.value, this.result});
  final T value;
  final FirebasePerformanceResult? result;
}

/// Wraps a Firebase Performance call in a CLIENT span. [operation] is
/// one of `newTrace`, `traceStart`, `traceStop`, `newHttpMetric`,
/// `httpMetricStart`, `httpMetricStop`, `incrementMetric`, `putMetric`,
/// `getMetric`, `putAttribute`, `removeAttribute`, `getAttribute`,
/// `getAttributes`, `setPerformanceCollectionEnabled`,
/// `isPerformanceCollectionEnabled`.
Future<T> tracedFirebasePerformance<T>({
  required String operation,
  required Future<FirebasePerformanceCallResult<T>> Function() invoke,
}) async {
  if (firebasePerformanceInstrumentationSuppressed()) {
    final r = await invoke();
    return r.value;
  }
  final m = <String, Object>{
    'rpc.system': 'firebase_performance',
    'rpc.method': operation,
    'firebase_performance.operation': operation,
  };

  final span = _tracer().startSpan(
    'firebase_performance $operation',
    kind: SpanKind.client,
    attributes: OTel.attributesFromMap(m),
  );
  try {
    final r = await invoke();
    if (r.result != null) {
      final res = r.result!;
      final extras = <Attribute<Object>>[];
      if (res.traceName != null) {
        extras.add(OTel.attributeString(
          'firebase_performance.trace.name',
          res.traceName!,
        ));
      }
      if (res.traceDurationMs != null) {
        extras.add(OTel.attributeInt(
          'firebase_performance.trace.duration_ms',
          res.traceDurationMs!,
        ));
      }
      if (res.httpMethod != null) {
        extras.add(OTel.attributeString(
          'firebase_performance.http.method',
          res.httpMethod!,
        ));
      }
      if (res.httpUrl != null) {
        extras.add(OTel.attributeString(
          'firebase_performance.http.url',
          res.httpUrl!,
        ));
      }
      if (res.httpResponseCode != null) {
        extras.add(OTel.attributeInt(
          'firebase_performance.http.response_code',
          res.httpResponseCode!,
        ));
        if (res.httpResponseCode! >= 400) {
          span.setStatus(
            SpanStatusCode.Error,
            'Firebase Performance HTTP ${res.httpResponseCode}',
          );
        }
      }
      if (res.requestPayloadSize != null) {
        extras.add(OTel.attributeInt(
          'firebase_performance.http.request.payload_size',
          res.requestPayloadSize!,
        ));
      }
      if (res.responsePayloadSize != null) {
        extras.add(OTel.attributeInt(
          'firebase_performance.http.response.payload_size',
          res.responsePayloadSize!,
        ));
      }
      if (res.responseContentType != null) {
        extras.add(OTel.attributeString(
          'firebase_performance.http.response.content_type',
          res.responseContentType!,
        ));
      }
      if (res.metricName != null) {
        extras.add(OTel.attributeString(
          'firebase_performance.metric.name',
          res.metricName!,
        ));
      }
      if (res.metricValue != null) {
        extras.add(OTel.attributeInt(
          'firebase_performance.metric.value',
          res.metricValue!,
        ));
      }
      if (res.attributeName != null) {
        extras.add(OTel.attributeString(
          'firebase_performance.attribute.name',
          res.attributeName!,
        ));
      }
      if (res.attributeValue != null) {
        extras.add(OTel.attributeString(
          'firebase_performance.attribute.value',
          res.attributeValue!,
        ));
      }
      if (res.collectionEnabled != null) {
        extras.add(OTel.attributeBool(
          'firebase_performance.collection.enabled',
          res.collectionEnabled!,
        ));
      }
      if (res.instrumentationEnabled != null) {
        extras.add(OTel.attributeBool(
          'firebase_performance.instrumentation.enabled',
          res.instrumentationEnabled!,
        ));
      }
      if (extras.isNotEmpty) span.addAttributes(OTel.attributes(extras));
    }
    return r.value;
  } catch (e, st) {
    span.addAttributes(OTel.attributes([
      OTel.attributeString(
        ErrorResource.errorType.key,
        e.runtimeType.toString(),
      ),
    ]));
    span.recordException(e, stackTrace: st);
    span.setStatus(SpanStatusCode.Error, e.toString());
    rethrow;
  } finally {
    span.end();
  }
}
