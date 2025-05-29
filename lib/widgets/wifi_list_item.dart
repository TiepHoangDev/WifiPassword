import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:provider/provider.dart';

import '../models/wifi_network.dart';
import '../providers/wifi_provider.dart';

class WifiListItem extends StatelessWidget {
  final WifiNetwork network;
  final bool isAvailable;
  final bool isConnected;
  final VoidCallback onTap;
  final VoidCallback? onConnect;

  const WifiListItem({
    Key? key,
    required this.network,
    required this.isAvailable,
    required this.isConnected,
    required this.onTap,
    this.onConnect,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final wifiProvider = Provider.of<WifiProvider>(context, listen: false);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 4.0),
      child: InkWell(
        onTap: onTap,
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
                              if (onConnect != null) {
                                onConnect!();
                              } else {
                                wifiProvider.connectToNetwork(network);
                              }
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
}
