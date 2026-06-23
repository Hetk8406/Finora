import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../database/database_helper.dart';
import '../models/estimate.dart';
import '../widgets/estimate_card.dart';
import '../services/auth_service.dart';
import '../services/cloud_sync_service.dart';
import 'add_estimate_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();
  final CloudSyncService _syncService = CloudSyncService();
  final User? _user = FirebaseAuth.instance.currentUser;
  
  List<Estimate> _estimates = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initialSync();
  }

  Future<void> _initialSync() async {
    // 1. Load local results first
    if (_user != null) {
      await _loadEstimates();
    }
    
    // 2. Perform background sync from cloud
    await _syncService.performInitialSync();
    
    // 3. Reload from local after sync
    await _loadEstimates();
  }

  Future<void> _loadEstimates() async {
    if (_user == null) return;
    final data = await DatabaseHelper.instance.readAll(_user!.uid);
    setState(() {
      _estimates = data;
      _isLoading = false;
    });
  }

  void _handleLogout() async {
    await _authService.signOut();
    if (mounted) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const LoginScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text('Finora'),
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Hero(tag: 'logo', child: Image.asset('assets/logo.png')),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.grey),
            onPressed: _handleLogout,
            tooltip: 'Logout',
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadEstimates,
          ),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator()) 
        : _estimates.isEmpty
          ? _emptyState()
          : RefreshIndicator(
              onRefresh: _loadEstimates,
              child: ListView.builder(
                itemCount: _estimates.length,
                itemBuilder: (context, index) => EstimateCard(
                  estimate: _estimates[index],
                  onDeleted: _loadEstimates,
                  onEdited: _loadEstimates,
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddEstimateScreen()),
          );
          if (result == true) _loadEstimates();
        },
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Estimate', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.description_outlined, size: 60, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text('No estimates yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF9CA3AF))),
          const Text('Create your first professional estimate now', style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
        ],
      ),
    );
  }
}
