import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/estimate.dart';
import '../database/database_helper.dart';

class CloudSyncService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final User? _user = FirebaseAuth.instance.currentUser;

  CollectionReference get _estimatesCol => _db.collection('estimates');

  /// Saves both locally and to Firestore
  Future<void> saveEstimate(Estimate estimate) async {
    if (_user == null) return;

    // 1. Save locally
    if (estimate.id != null) {
      await DatabaseHelper.instance.update(estimate);
    } else {
      await DatabaseHelper.instance.create(estimate);
    }

    // 2. Save to cloud
    try {
      // Find by user & company name to prevent duplicates if sync is loose
      final query = await _estimatesCol
          .where('userId', isEqualTo: _user!.uid)
          .where('companyName', isEqualTo: estimate.companyName)
          .where('createdAt', isEqualTo: estimate.createdAt)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        // Update
        await _estimatesCol.doc(query.docs.first.id).update(estimate.toFirestore());
      } else {
        // Create new doc
        await _estimatesCol.add(estimate.toFirestore());
      }
    } catch (e) {
      debugPrint("Firestore Sync Error: $e");
    }
  }

  /// Initial sync: Fetch cloud documents and merge them into local SQLite
  Future<void> performInitialSync() async {
    if (_user == null) return;
    debugPrint("Starting cloud sync for ${_user!.uid}...");

    try {
      final snapshot = await _estimatesCol.where('userId', isEqualTo: _user!.uid).get();
      
      final cloudEstimates = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Estimate.fromMap(data);
      }).toList();

      for (var cloudItem in cloudEstimates) {
        // Logic: if companyName + userId + createdAt exists locally, skip or update?
        // Let's check locally
        final localRes = await DatabaseHelper.instance.readAll(_user!.uid);
        final matches = localRes.where((l) => 
          l.companyName == cloudItem.companyName && 
          l.createdAt == cloudItem.createdAt);

        if (matches.isEmpty) {
          // New from cloud
          await DatabaseHelper.instance.create(cloudItem);
          debugPrint("Synced new item: ${cloudItem.companyName}");
        } else {
          // Potentially update local if cloud is "source of truth", but ignoring for now to avoid local overwrite
        }
      }
    } catch (e) {
      debugPrint("Sync failed: $e");
    }
  }
}
