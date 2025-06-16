import 'package:flutter/material.dart';

class ManagePrivacyScreen extends StatefulWidget {
  const ManagePrivacyScreen({super.key});

  @override
  State<ManagePrivacyScreen> createState() => _ManagePrivacyScreenState();
}

class _ManagePrivacyScreenState extends State<ManagePrivacyScreen> {
  bool allowAds = true;
  bool allowAnalytics = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        backgroundColor: Colors.red,
        title: const Text('Manage Privacy', style: TextStyle(color: Colors.white)),
        elevation: 1,
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: ListTile(
              leading: const Icon(Icons.privacy_tip, color: Colors.red, size: 32),
              title: const Text('Privacy Policy', style: TextStyle(fontWeight: FontWeight.bold)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Privacy Policy'),
                    content: const Text('Your privacy policy text or link goes here.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 14),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: SwitchListTile(
              activeColor: Colors.red,
              value: allowAds,
              onChanged: (val) => setState(() => allowAds = val),
              title: const Text('Allow personalized ads', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Control whether you see personalized ads.'),
              secondary: const Icon(Icons.ad_units, color: Colors.red),
            ),
          ),
          const SizedBox(height: 14),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: SwitchListTile(
              activeColor: Colors.red,
              value: allowAnalytics,
              onChanged: (val) => setState(() => allowAnalytics = val),
              title: const Text('Allow analytics', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Share anonymous usage data to improve the app.'),
              secondary: const Icon(Icons.analytics, color: Colors.red),
            ),
          ),
          const SizedBox(height: 14),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: ListTile(
              leading: const Icon(Icons.delete_forever, color: Colors.red, size: 32),
              title: const Text('Delete My Data',
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Delete All Data?'),
                    content: const Text('This will remove all your data from this device.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          // TODO: Clear user data here
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Your data has been deleted.')),
                          );
                        },
                        child: const Text('Delete', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
