import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/listing.dart';
import '../utils/rwanda_ride_fare_estimate.dart';
import 'agents_service.dart';
import 'auth_service.dart';
import 'conversations_service.dart';
import 'google_directions_service.dart';
import 'google_places_service.dart';
import 'listings_service.dart';
import 'maps_api_key_channel.dart';
import 'message_translation_service.dart';
import 'perf_metrics_service.dart';
import 'perf_workflow_ids.dart';

/// Kigali-ish endpoints for repeatable Directions / fare timing (not user-specific).
const LatLng _kigaliRouteA = LatLng(-1.9403, 29.8739);
const LatLng _kigaliRouteB = LatLng(-1.9565, 30.0615);

class PerfBenchmarkService {
  PerfBenchmarkService._();
  static final PerfBenchmarkService _instance = PerfBenchmarkService._();
  factory PerfBenchmarkService() => _instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Runs real runtime measurements against current Firebase project + Maps APIs.
  ///
  /// Requires a signed-in user. For assignment workflow this works best when
  /// the signed-in user is a landlord and at least one registered agent exists.
  ///
  /// Returns [summaryJson] fields plus `workflow_history` for JSONL time-series.
  Future<Map<String, dynamic>> runBenchmarks({
    int runs = 5,
    String? assignmentAgentId,
    String? assignmentAgentUid,
  }) async {
    if (runs < 1) throw ArgumentError.value(runs, 'runs', 'must be >= 1');
    final uid = AuthService().currentUser?.uid;
    if (uid == null) throw StateError('You must be signed in to run benchmarks.');

    final metrics = PerfMetricsService()..reset();
    final apiKey = await MapsApiKeyChannel.resolvePlacesApiKey();
    final directions =
        apiKey.isNotEmpty ? GoogleDirectionsService(apiKey: apiKey) : null;
    final places =
        apiKey.isNotEmpty ? GooglePlacesService(apiKey: apiKey) : null;

    for (var i = 0; i < runs; i++) {
      metrics.setIteration(i);
      var workflowOk = true;
      String? listingId;
      String? assignmentId;
      try {
        // 1) Landlord listing upload (Storage + Firestore) — timed in ListingsService.
        final listing = await ListingsService().createListing(
          landlordId: uid,
          type: ListingType.apartment,
          title: 'Benchmark Listing #$i',
          description: 'Perf benchmark listing',
          location: 'Benchmark',
          price: '1000',
          imageBytes: const [],
        );
        listingId = listing.id;

        // 2) Listing verification simulation (super admin action)
        final verifySw = Stopwatch()..start();
        await _firestore.collection('listings').doc(listing.id).update({
          'status': ListingStatus.published.value,
          'verifiedBy': uid,
          'publishedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        verifySw.stop();
        metrics.addSample('verify_listing_update', verifySw.elapsedMilliseconds);

        // 3) Retrieval — search matches title/location/description (not id).
        final published = await ListingsService().getPublishedListings(
          searchQuery: 'Benchmark Listing',
        );
        final found = published.any((l) => l.id == listing.id);
        if (!found) workflowOk = false;

        // 4) Listing assignment create -> acceptance
        final a = await _resolveAssignmentAgent(
          overrideAgentId: assignmentAgentId,
          overrideAgentUid: assignmentAgentUid,
        );
        if (a != null) {
          final createAssnSw = Stopwatch()..start();
          final assn = await AgentsService().createAssignment(
            listingId: listing.id,
            agentId: a.agentId,
            landlordId: uid,
            agentUid: a.agentUid,
            agentName: a.agentName,
            listingTitle: listing.title,
          );
          createAssnSw.stop();
          metrics.addSample(
            'create_assignment',
            createAssnSw.elapsedMilliseconds,
          );
          assignmentId = assn.id;

          final acceptSw = Stopwatch()..start();
          await AgentsService().acceptAssignment(assn.id);
          acceptSw.stop();
          metrics.addSample('accept_assignment', acceptSw.elapsedMilliseconds);
          metrics.addSample(
            'listing_assignment',
            createAssnSw.elapsedMilliseconds + acceptSw.elapsedMilliseconds,
          );
        } else {
          workflowOk = false;
        }

        // 5) Chat send -> stream (message_latency summary field)
        final convo = await ConversationsService().getOrCreateConversation(
          listingId: listing.id,
          participantIds: [uid, 'benchmark_peer'],
          participantNames: {
            uid: 'Benchmark User',
            'benchmark_peer': 'Benchmark Peer',
          },
          listingTitle: listing.title,
          sharedLandlordAgentThread: false,
        );
        await ConversationsService().measureSendToReceiveLatency(
          conversationId: convo.id,
          senderId: uid,
          content: 'benchmark_ping_$i',
        );

        // 6) Message translate (ML Kit on-device when not web)
        final trSw = Stopwatch()..start();
        await MessageTranslationService.instance.translateIncoming(
          text: 'Bonjour, je voudrais visiter cet appartement.',
          messageId: 'perf_translate_$i',
          preferredLanguageLabel: 'English',
          translationEnabled: true,
        );
        trSw.stop();
        metrics.addSample('message_translate', trSw.elapsedMilliseconds);

        // 7) Rides: Directions round trip + local fare estimate (same user-visible stack)
        if (directions != null) {
          final rideSw = Stopwatch()..start();
          final route = await directions.getDrivingRoute(
            origin: _kigaliRouteA,
            destination: _kigaliRouteB,
          );
          final meters = route.route?.distanceMeters;
          if (meters != null && meters > 0) {
            estimateRwandaRideFareRwf(distanceMeters: meters);
          }
          rideSw.stop();
          final ok = route.route != null && route.errorDetail == null;
          metrics.addSample(
            'rides_estimate',
            rideSw.elapsedMilliseconds,
            ok: ok,
            error: ok ? null : (route.errorDetail ?? 'no_route'),
          );
          if (!ok) workflowOk = false;
        } else {
          metrics.addSample(
            'rides_estimate',
            0,
            ok: false,
            error: 'no_maps_api_key',
          );
        }

        // 8) Explore: Places autocomplete (biased to Rwanda)
        if (places != null) {
          final exSw = Stopwatch()..start();
          final preds = await places.autocomplete(input: 'cafe kigali');
          exSw.stop();
          final ok = preds.isNotEmpty;
          metrics.addSample(
            'explore_places',
            exSw.elapsedMilliseconds,
            ok: ok,
            error: ok ? null : 'zero_results',
          );
        } else {
          metrics.addSample(
            'explore_places',
            0,
            ok: false,
            error: 'no_maps_api_key',
          );
        }
      } catch (e) {
        workflowOk = false;
      } finally {
        metrics.addWorkflowResult(workflowOk);
        await _cleanupBenchmarkArtifacts(
          listingId: listingId,
          assignmentId: assignmentId,
        );
      }
    }

    final summary = metrics.summaryJson();
    final workflowHistory = metrics.buildWorkflowHistoryRecord(
      environment: <String, dynamic>{
        'runs': runs,
        'entrypoint': 'lib/dev/perf_probe_main.dart',
        'workflows': PerfWorkflowIds.chartOrder,
        'maps_api_configured': apiKey.isNotEmpty,
      },
    );

    return <String, dynamic>{
      ...summary,
      'workflow_history': workflowHistory,
    };
  }

  Future<_AssignmentAgent?> _resolveAssignmentAgent({
    String? overrideAgentId,
    String? overrideAgentUid,
  }) async {
    if (overrideAgentId != null &&
        overrideAgentId.isNotEmpty &&
        overrideAgentUid != null &&
        overrideAgentUid.isNotEmpty) {
      final ag = await AgentsService().getAgent(overrideAgentId);
      return _AssignmentAgent(
        agentId: overrideAgentId,
        agentUid: overrideAgentUid,
        agentName: ag?.fullName,
      );
    }

    final agents = await AgentsService().getAgents(registeredOnly: true);
    if (agents.isEmpty) return null;
    final first = agents.first;
    final uid = first.registeredUid;
    if (uid == null || uid.isEmpty) return null;
    return _AssignmentAgent(
      agentId: first.agentId,
      agentUid: uid,
      agentName: first.fullName,
    );
  }

  Future<void> _cleanupBenchmarkArtifacts({
    String? listingId,
    String? assignmentId,
  }) async {
    try {
      if (assignmentId != null) {
        await _firestore.collection('listing_assignments').doc(assignmentId).delete();
      }
    } catch (_) {}
    try {
      if (listingId != null) {
        await _firestore.collection('listings').doc(listingId).delete();
      }
    } catch (_) {}
  }
}

class _AssignmentAgent {
  const _AssignmentAgent({
    required this.agentId,
    required this.agentUid,
    this.agentName,
  });

  final String agentId;
  final String agentUid;
  final String? agentName;
}
