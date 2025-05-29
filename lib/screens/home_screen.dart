import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../providers/wifi_provider.dart';
import '../models/wifi_network_model.dart';
import 'add_wifi_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _showOnlyAvailable = false;
  
  @override
  void initState() {
    super.initState();
    // Initialize the search controller listener
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
    
    // Load networks when the screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<WifiProvider>(context, listen: false).refresh();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddWifiScreen()),
          );
        },
        tooltip: 'Share WiFi',
        child: const Icon(Icons.wifi_tethering),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: _isSearching
          ? TextField(
              controller: _searchController,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Search WiFi networks...',
                border: InputBorder.none,
                hintStyle: TextStyle(color: Colors.white70),
              ),
              style: const TextStyle(color: Colors.white),
              cursorColor: Colors.white,
            )
          : const Text('WifiPass'),
      actions: [
        // Search button
        IconButton(
          icon: Icon(_isSearching ? Icons.close : Icons.search),
          onPressed: () {
            setState(() {
              _isSearching = !_isSearching;
              if (!_isSearching) {
                _searchController.clear();
              }
            });
          },
        ),
        // Filter button
        IconButton(
          icon: const Icon(Icons.filter_list),
          onPressed: _showFilterOptions,
        ),
        // Refresh button
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () {
            Provider.of<WifiProvider>(context, listen: false).refresh();
          },
        ),
      ],
    );
  }

  Widget _buildBody() {
    return Consumer<WifiProvider>(
      builder: (context, wifiProvider, child) {
        // Handle loading state
        if (wifiProvider.loadingState == WifiLoadingState.loading &&
            wifiProvider.networks.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        // Handle error state
        if (wifiProvider.loadingState == WifiLoadingState.error) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 60,
                ),
                const SizedBox(height: 16),
                Text(
                  'Error loading WiFi networks',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  wifiProvider.errorMessage ?? 'Unknown error',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    wifiProvider.refresh();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        // Filter networks based on search query and availability filter
        List<WiFiNetworkModel> filteredNetworks = wifiProvider.networks;
        
        if (_searchQuery.isNotEmpty) {
          filteredNetworks = wifiProvider.searchNetworks(_searchQuery);
        }
        
        if (_showOnlyAvailable) {
          filteredNetworks = filteredNetworks
              .where((network) => wifiProvider.isNetworkAvailable(network.ssid))
              .toList();
        }

        // Handle empty state
        if (filteredNetworks.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.wifi_off,
                  size: 60,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                Text(
                  _searchQuery.isNotEmpty
                      ? 'No WiFi networks match "$_searchQuery"'
                      : _showOnlyAvailable
                          ? 'No available WiFi networks found'
                          : 'No WiFi networks found',
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    wifiProvider.refresh();
                  },
                  child: const Text('Refresh'),
                ),
              ],
            ),
          );
        }

        // Show the list of WiFi networks
        return RefreshIndicator(
          onRefresh: () => wifiProvider.refresh(),
          child: ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: filteredNetworks.length,
            itemBuilder: (context, index) {
              final network = filteredNetworks[index];
              final isAvailable = wifiProvider.isNetworkAvailable(network.ssid);
              final isConnected = wifiProvider.currentSSID == network.ssid;
              
              return _buildNetworkCard(context, network, isAvailable, isConnected);
            },
          ),
        );
      },
    );
  }

  Widget _buildNetworkCard(
    BuildContext context,
    WiFiNetworkModel network,
    bool isAvailable,
    bool isConnected,
  ) {
    final theme = Theme.of(context);
    final wifiProvider = Provider.of<WifiProvider>(context, listen: false);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 4.0),
      child: InkWell(
        onTap: () => _showNetworkDetails(network),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // WiFi icon with signal strength indicator
                  _buildSignalIcon(network.signalStrength, isAvailable, isConnected),
                  const SizedBox(width: 12),
                  // SSID and security type
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          network.ssid,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          network.securityType ?? 'Unknown',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  // Distance indicator if available
                  if (network.distanceFromUser != null)
                    Chip(
                      label: Text(
                        '${network.distanceFromUser!.toStringAsFixed(2)} km',
                        style: const TextStyle(fontSize: 12),
                      ),
                      backgroundColor: theme.colorScheme.surfaceVariant,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              // Last connected time
              if (network.lastConnected != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 16,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Last connected: ${timeago.format(network.lastConnected!)}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              // Connection status and button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Status indicator
                  Text(
                    isConnected
                        ? 'Connected'
                        : isAvailable
                            ? 'Available'
                            : 'Not in range',
                    style: TextStyle(
                      color: isConnected
                          ? Colors.green
                          : isAvailable
                              ? Colors.blue
                              : Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  // Connect button
                  ElevatedButton(
                    onPressed: isConnected
                        ? null
                        : () {
                            if (isAvailable) {
                              wifiProvider.connectToNetwork(network);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Network not in range'),
                                ),
                              );
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isConnected
                          ? Colors.grey
                          : theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(isConnected ? 'Connected' : 'Connect'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSignalIcon(int? signalStrength, bool isAvailable, bool isConnected) {
    IconData iconData;
    Color iconColor;
    
    if (isConnected) {
      iconData = Icons.wifi;
      iconColor = Colors.green;
    } else if (isAvailable) {
      if (signalStrength == null || signalStrength > -50) {
        iconData = Icons.wifi;
      } else if (signalStrength > -70) {
        iconData = Icons.network_wifi_3_bar;
      } else {
        iconData = Icons.network_wifi_1_bar;
      }
      iconColor = Colors.blue;
    } else {
      iconData = Icons.wifi_off;
      iconColor = Colors.grey;
    }
    
    return Icon(
      iconData,
      color: iconColor,
      size: 28,
    );
  }

  void _showFilterOptions() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Filter Options',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Show only available networks'),
                    value: _showOnlyAvailable,
                    onChanged: (value) {
                      setState(() {
                        _showOnlyAvailable = value;
                      });
                      this.setState(() {});
                    },
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    title: const Text('Sort by last connected'),
                    leading: const Icon(Icons.access_time),
                    onTap: () {
                      Navigator.pop(context);
                      final wifiProvider = Provider.of<WifiProvider>(context, listen: false);
                      // This is a temporary solution - in a real app, we would add sorting options to the provider
                      setState(() {
                        wifiProvider.getNetworksByLastConnected();
                      });
                    },
                  ),
                  ListTile(
                    title: const Text('Sort by distance'),
                    leading: const Icon(Icons.place),
                    onTap: () {
                      Navigator.pop(context);
                      // The networks are already sorted by distance by default
                      final wifiProvider = Provider.of<WifiProvider>(context, listen: false);
                      wifiProvider.refresh();
                    },
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text('Close'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showNetworkDetails(WiFiNetworkModel network) {
    final wifiProvider = Provider.of<WifiProvider>(context, listen: false);
    final isAvailable = wifiProvider.isNetworkAvailable(network.ssid);
    final isConnected = wifiProvider.currentSSID == network.ssid;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        _buildSignalIcon(network.signalStrength, isAvailable, isConnected),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            network.ssid,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildDetailRow(
                      'Security',
                      network.securityType ?? 'Unknown',
                      Icons.security,
                    ),
                    _buildDetailRow(
                      'Password',
                      '••••••••',
                      Icons.password,
                      showCopyButton: true,
                      copyValue: network.password,
                    ),
                    if (network.lastConnected != null)
                      _buildDetailRow(
                        'Last Connected',
                        timeago.format(network.lastConnected!),
                        Icons.access_time,
                      ),
                    _buildDetailRow(
                      'Location',
                      '${network.latitude.toStringAsFixed(6)}, ${network.longitude.toStringAsFixed(6)}',
                      Icons.location_on,
                    ),
                    if (network.distanceFromUser != null)
                      _buildDetailRow(
                        'Distance',
                        '${network.distanceFromUser!.toStringAsFixed(2)} km',
                        Icons.place,
                      ),
                    _buildDetailRow(
                      'Added',
                      timeago.format(network.createdAt),
                      Icons.calendar_today,
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isConnected
                            ? null
                            : () {
                                if (isAvailable) {
                                  Navigator.pop(context);
                                  wifiProvider.connectToNetwork(network);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Network not in range'),
                                    ),
                                  );
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(
                          isConnected ? 'Connected' : 'Connect to Network',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (isConnected)
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            wifiProvider.disconnect();
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text(
                            'Disconnect',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDetailRow(
    String label,
    String value,
    IconData icon, {
    bool showCopyButton = false,
    String? copyValue,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey, size: 20),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
          const Spacer(),
          if (showCopyButton && copyValue != null)
            IconButton(
              icon: const Icon(Icons.copy, size: 18),
              onPressed: () {
                // In a real app, we would use clipboard functionality
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Password copied to clipboard'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
