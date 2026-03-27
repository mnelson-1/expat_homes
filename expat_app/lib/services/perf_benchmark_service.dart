import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/listing.dart';
import 'agents_service.dart';
import 'auth_service.dart';
import 'conversations_service.dart';
import 'listings_service.dart';
import 'perf_metrics_service.dart';

class PerfBenchmarkService {
  PerfBenchmarkService._();
  static final PerfBenchmarkService _instance = PerfBenchmarkService._();
  factory PerfBenchmarkService() => _instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Runs real runtime measurements against current Firebase project.
  ///
  /// Requires a signed-in user. For assignment workflow this works best when
  /// the signed-in user is a landlord and at least one registered agent exists.
  Future<Map<String, dynamic>> runBenchmarks({
    int runs = 5,
    String? assignmentAgentId,
    String? assignmentAgentUid,
  }) async {
    if (runs < 1) throw ArgumentError.value(runs, 'runs', 'must be >= 1');
    final uid = AuthService().currentUser?.uid;
    if (uid == null) throw StateError('You must be signed in to run benchmarks.');

    final metrics = PerfMetricsService()..reset();

    for (var i = 0; i < runs; i++) {
      var workflowOk = true;
      String? listingId;
      String? assignmentId;
      try {
        // 1) Listing create
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
        // NOTE: this uses direct update from current signed-in user and may fail
        // if rules disallow this actor from publishing.
        final verifySw = Stopwatch()..start();
        await _firestore.collection('listings').doc(listing.id).update({
          'status': ListingStatus.published.value,
          'verifiedBy': uid,
          'publishedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        verifySw.stop();
        metrics.addSample('verify_listing_update', verifySw.elapsedMilliseconds);

        // 3) Retrieval (published listings fetch)
        final published = await ListingsService().getPublishedListings(
          searchQuery: listing.id,
        );
        final found = published.any((l) => l.id == listing.id);
        if (!found) workflowOk = false;

        // 4) Agent assignment create -> acceptance simulation
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
        } else {
          workflowOk = false;
        }

        // 5) Message latency: send -> stream observed
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
    // Required output format keys.
    return <String, dynamic>{
      'response_time_avg_ms': summary['response_time_avg_ms'],
      'response_time_max_ms': summary['response_time_max_ms'],
      'workflow_success_rate': summary['workflow_success_rate'],
      'message_latency_ms': summary['message_latency_ms'],
      'notes': summary['notes'],
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

