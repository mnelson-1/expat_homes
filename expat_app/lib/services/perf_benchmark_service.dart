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

const String _kPostsCollection = 'posts';
const String _kCommissionSlipsCollection = 'commission_slips';

class PerfBenchmarkService {
  PerfBenchmarkService._();
  static final PerfBenchmarkService _instance = PerfBenchmarkService._();
  factory PerfBenchmarkService() => _instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Runs real runtime measurements for [benchmarkRole]: `landlord`, `agent`, or `expat`.
  ///
  /// Role is read from `PERF_PROBE_BENCHMARK_ROLE` (dart-define). Unknown values
  /// default to landlord-shaped probes.
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

    const rawRole = String.fromEnvironment(
      'PERF_PROBE_BENCHMARK_ROLE',
      defaultValue: 'unspecified',
    );
    final benchmarkRole = _normalizeBenchmarkRole(rawRole);

    final metrics = PerfMetricsService()..reset();
    final apiKey = await MapsApiKeyChannel.resolvePlacesApiKey();
    final directions =
        apiKey.isNotEmpty ? GoogleDirectionsService(apiKey: apiKey) : null;
    final places =
        apiKey.isNotEmpty ? GooglePlacesService(apiKey: apiKey) : null;

    for (var i = 0; i < runs; i++) {
      metrics.setIteration(i);
      if (benchmarkRole == 'agent') {
        await _runAgentIteration(metrics, uid, i);
      } else if (benchmarkRole == 'expat') {
        await _runExpatIteration(metrics, uid, i, directions, places);
      } else {
        await _runLandlordIteration(
          metrics,
          uid,
          i,
          assignmentAgentId: assignmentAgentId,
          assignmentAgentUid: assignmentAgentUid,
        );
      }
    }

    final summary = metrics.summaryJson(benchmarkRole: benchmarkRole);
    final workflowHistory = metrics.buildWorkflowHistoryRecord(
      benchmarkRole: benchmarkRole,
      environment: <String, dynamic>{
        'runs': runs,
        'entrypoint': 'lib/dev/perf_probe_main.dart',
        'workflows': PerfWorkflowIds.chartOrderForRole(benchmarkRole),
        'maps_api_configured': apiKey.isNotEmpty,
        'benchmark_role': benchmarkRole,
      },
    );

    return <String, dynamic>{
      ...summary,
      'workflow_history': workflowHistory,
    };
  }

  String _normalizeBenchmarkRole(String raw) {
    final r = raw.trim().toLowerCase();
    if (r == 'landlord' || r == 'agent' || r == 'expat') return r;
    return 'landlord';
  }

  Future<void> _runLandlordIteration(
    PerfMetricsService metrics,
    String uid,
    int i, {
    String? assignmentAgentId,
    String? assignmentAgentUid,
  }) async {
    var workflowOk = true;
    String? listingId;
    String? assignmentId;
    try {
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

      final verifySw = Stopwatch()..start();
      await _firestore.collection('listings').doc(listing.id).update({
        'status': ListingStatus.published.value,
        'verifiedBy': uid,
        'publishedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      verifySw.stop();
      metrics.addSample('verify_listing_update', verifySw.elapsedMilliseconds);

      final published = await ListingsService().getPublishedListings(
        searchQuery: 'Benchmark Listing',
      );
      final found = published.any((l) => l.id == listing.id);
      if (!found) {
        metrics.addSample(
          'fetch_listings',
          0,
          ok: false,
          error: 'benchmark_listing_not_in_search_results',
        );
      }

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
        metrics.addSample(
          'listing_assignment',
          0,
          ok: false,
          error: 'no_agent_available',
        );
      }

      final paySw = Stopwatch()..start();
      await _firestore
          .collection(_kCommissionSlipsCollection)
          .where('landlordId', isEqualTo: uid)
          .limit(50)
          .get();
      paySw.stop();
      metrics.addSample('landlord_payment_workflow', paySw.elapsedMilliseconds);

      final msgSw = Stopwatch()..start();
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
      await MessageTranslationService.instance.translateIncoming(
        text: 'Bonjour, je voudrais visiter cet appartement.',
        messageId: 'perf_translate_$i',
        preferredLanguageLabel: 'English',
        translationEnabled: true,
      );
      msgSw.stop();
      metrics.addSample('landlord_messaging', msgSw.elapsedMilliseconds);
    } catch (_) {
      workflowOk = false;
    } finally {
      metrics.addWorkflowResult(workflowOk);
      await _cleanupBenchmarkArtifacts(
        listingId: listingId,
        assignmentId: assignmentId,
      );
    }
  }

  Future<void> _runAgentIteration(
    PerfMetricsService metrics,
    String uid,
    int i,
  ) async {
    var workflowOk = true;
    String? agentIdForBio;
    String? originalBio;
    try {
      final paySw = Stopwatch()..start();
      await _firestore
          .collection(_kCommissionSlipsCollection)
          .where('agentUid', isEqualTo: uid)
          .limit(50)
          .get();
      paySw.stop();
      metrics.addSample('agent_payment_workflow', paySw.elapsedMilliseconds);

      final assnSw = Stopwatch()..start();
      await _firestore
          .collection(kAssignmentsCollection)
          .where('agentUid', isEqualTo: uid)
          .limit(50)
          .get();
      assnSw.stop();
      metrics.addSample('agent_listing_assignment', assnSw.elapsedMilliseconds);

      final profile = await AuthService().getCurrentUserProfile();
      final agentId = profile?.agentId?.trim();
      if (agentId == null || agentId.isEmpty) {
        metrics.addSample(
          'agent_bio_view_update',
          0,
          ok: false,
          error: 'no_agent_id',
        );
      } else {
        agentIdForBio = agentId;
        final licensed = await AgentsService().getAgent(agentId);
        originalBio = licensed?.bio ?? '';
        final bioSw = Stopwatch()..start();
        await AgentsService().updateLicensedAgentProfile(
          agentId,
          bio: '$originalBio [perf$i]'.trim(),
        );
        bioSw.stop();
        metrics.addSample('agent_bio_view_update', bioSw.elapsedMilliseconds);
      }
    } catch (_) {
      workflowOk = false;
    } finally {
      if (agentIdForBio != null && originalBio != null) {
        try {
          await AgentsService().updateLicensedAgentProfile(
            agentIdForBio,
            bio: originalBio,
          );
        } catch (_) {}
      }
      metrics.addWorkflowResult(workflowOk);
    }
  }

  Future<void> _runExpatIteration(
    PerfMetricsService metrics,
    String uid,
    int i,
    GoogleDirectionsService? directions,
    GooglePlacesService? places,
  ) async {
    var workflowOk = true;
    try {
      // Community: query succeeds even when collection is empty — do not fail the iteration.
      final commSw = Stopwatch()..start();
      try {
        await _firestore
            .collection(_kPostsCollection)
            .where('scope', isEqualTo: 'feed')
            .limit(30)
            .get();
        commSw.stop();
        metrics.addSample(
          PerfWorkflowIds.expatCommunityWorkflow,
          commSw.elapsedMilliseconds,
        );
      } catch (e) {
        commSw.stop();
        metrics.addSample(
          PerfWorkflowIds.expatCommunityWorkflow,
          commSw.elapsedMilliseconds,
          ok: false,
          error: 'firestore_posts_query_failed',
        );
      }

      // Explore: Places optional — record partial failure without failing whole iteration.
      if (places != null) {
        final exploreSw = Stopwatch()..start();
        try {
          await places.autocomplete(input: 'cafe kigali');
          exploreSw.stop();
          metrics.addSample(
            PerfWorkflowIds.expatExploreArea,
            exploreSw.elapsedMilliseconds,
          );
        } catch (e) {
          exploreSw.stop();
          metrics.addSample(
            PerfWorkflowIds.expatExploreArea,
            exploreSw.elapsedMilliseconds,
            ok: false,
            error: 'places_autocomplete_failed',
          );
        }
      } else {
        metrics.addSample(
          PerfWorkflowIds.expatExploreArea,
          0,
          ok: false,
          error: 'maps_not_configured',
        );
      }

      // Rides: Directions + fare estimate — API errors are partial failures.
      if (directions != null) {
        final ridesSw = Stopwatch()..start();
        try {
          final route = await directions.getDrivingRoute(
            origin: _kigaliRouteA,
            destination: _kigaliRouteB,
          );
          final meters = route.route?.distanceMeters;
          if (meters != null && meters > 0) {
            estimateRwandaRideFareRwf(distanceMeters: meters);
          }
          final routeOk = route.route != null && route.errorDetail == null;
          ridesSw.stop();
          metrics.addSample(
            PerfWorkflowIds.expatRidesMaps,
            ridesSw.elapsedMilliseconds,
            ok: routeOk,
            error: routeOk ? null : 'directions_failed',
          );
        } catch (e) {
          ridesSw.stop();
          metrics.addSample(
            PerfWorkflowIds.expatRidesMaps,
            ridesSw.elapsedMilliseconds,
            ok: false,
            error: 'directions_exception',
          );
        }
      } else {
        metrics.addSample(
          PerfWorkflowIds.expatRidesMaps,
          0,
          ok: false,
          error: 'maps_not_configured',
        );
      }

      // Listing inquiry: missing listings is optional data — partial sample only.
      try {
        final published = await ListingsService().getPublishedListings(
          searchQuery: '',
        );
        if (published.isEmpty) {
          metrics.addSample(
            PerfWorkflowIds.expatListingInquiryMessaging,
            0,
            ok: false,
            error: 'no_published_listing',
          );
        } else {
          final listing = published.first;
          final inqSw = Stopwatch()..start();
          final convo = await ConversationsService().getOrCreateConversation(
            listingId: listing.id,
            participantIds: [uid, 'benchmark_peer'],
            participantNames: {
              uid: 'Benchmark Expat',
              'benchmark_peer': 'Benchmark Peer',
            },
            listingTitle: listing.title,
            sharedLandlordAgentThread: false,
          );
          await ConversationsService().measureSendToReceiveLatency(
            conversationId: convo.id,
            senderId: uid,
            content: 'expat_inquiry_$i',
          );
          await MessageTranslationService.instance.translateIncoming(
            text: 'Is this listing still available?',
            messageId: 'perf_expat_tr_$i',
            preferredLanguageLabel: 'English',
            translationEnabled: true,
          );
          inqSw.stop();
          metrics.addSample(
            PerfWorkflowIds.expatListingInquiryMessaging,
            inqSw.elapsedMilliseconds,
          );
        }
      } catch (e) {
        metrics.addSample(
          PerfWorkflowIds.expatListingInquiryMessaging,
          0,
          ok: false,
          error: 'listing_inquiry_failed',
        );
      }
    } catch (_) {
      workflowOk = false;
    } finally {
      metrics.addWorkflowResult(workflowOk);
    }
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
        await _firestore
            .collection(kAssignmentsCollection)
            .doc(assignmentId)
            .delete();
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
