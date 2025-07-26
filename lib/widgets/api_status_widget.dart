import 'package:flutter/material.dart';
import '../services/api_client.dart';

class ApiStatusWidget extends StatefulWidget {
  const ApiStatusWidget({super.key});

  @override
  State<ApiStatusWidget> createState() => _ApiStatusWidgetState();
}

class _ApiStatusWidgetState extends State<ApiStatusWidget> {
  Map<String, dynamic>? _healthStatus;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkHealth();
  }

  Future<void> _checkHealth() async {
    setState(() {
      _isLoading = true;
    });

    final result = await ApiClient.healthCheck();
    
    setState(() {
      _healthStatus = result;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'System Status',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: _checkHealth,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_healthStatus != null) ...[
              _buildStatusRow(
                'Overall Status',
                _healthStatus!['success'] ? 'Healthy' : 'Error',
                _healthStatus!['success'] ? Colors.green : Colors.red,
              ),
              if (_healthStatus!['data'] != null) ...[
                const SizedBox(height: 8),
                _buildStatusRow(
                  'Firebase',
                  _healthStatus!['data']['firebase'] ?? 'Unknown',
                  _healthStatus!['data']['firebase'] == 'connected'
                      ? Colors.green
                      : Colors.red,
                ),
                const SizedBox(height: 8),
                _buildStatusRow(
                  'Cloudinary',
                  _healthStatus!['data']['cloudinary'] ?? 'Unknown',
                  _healthStatus!['data']['cloudinary'] == 'connected'
                      ? Colors.green
                      : Colors.red,
                ),
              ],
              const SizedBox(height: 16),
              Text(
                'Last checked: ${DateTime.now().toString().substring(0, 19)}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ] else if (_isLoading) ...[
              const Center(child: CircularProgressIndicator()),
            ] else ...[
              const Text('Unable to check system status'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, String status, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color),
          ),
          child: Text(
            status,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}