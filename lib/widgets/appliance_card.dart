import 'package:flutter/material.dart';
import '../models/appliance.dart';

class ApplianceCard extends StatelessWidget {
  final Appliance appliance;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool showLocation;
  final double costPerKwh;
  final String currencySymbol;

  const ApplianceCard({
    super.key,
    required this.appliance,
    required this.onEdit,
    required this.onDelete,
    this.showLocation = true,
    this.costPerKwh = 0.0,
    this.currencySymbol = '\$',
  });

  @override
  Widget build(BuildContext context) {
    final dailyCost = appliance.dailyConsumption * costPerKwh;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appliance.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${appliance.powerRating} ${appliance.isWatts ? 'watts' : 'amps'} · ${appliance.hoursPerDay} hrs/day',
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                    if (appliance.brand != null || appliance.location != null) ...[
                      const SizedBox(height: 4),
                      if (appliance.brand != null)
                        Text(
                          'Brand: ${appliance.brand}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                        ),
                      if (showLocation && appliance.location != null)
                        Text(
                          'Location: ${appliance.location}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                        ),
                    ],
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${appliance.dailyConsumption.toStringAsFixed(2)} kWh',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      if (costPerKwh > 0)
                        Text(
                          '$currencySymbol${dailyCost.toStringAsFixed(2)}/day',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                        ),
                      Text(
                        'per day',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    color: Theme.of(context).colorScheme.error,
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Delete Appliance'),
                          content: Text('Are you sure you want to delete ${appliance.name}?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('CANCEL'),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                                onDelete();
                              },
                              style: TextButton.styleFrom(
                                foregroundColor: Theme.of(context).colorScheme.error,
                              ),
                              child: const Text('DELETE'),
                            ),
                          ],
                        ),
                      );
                    },
                    tooltip: 'Delete',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
