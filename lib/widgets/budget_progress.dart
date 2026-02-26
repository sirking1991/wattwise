import 'package:flutter/material.dart';

class BudgetProgress extends StatelessWidget {
  final double currentMonthlyConsumption;
  final double costPerKwh;
  final String currencySymbol;
  final double? monthlyBudget;
  final String budgetType;

  const BudgetProgress({
    super.key,
    required this.currentMonthlyConsumption,
    required this.costPerKwh,
    required this.currencySymbol,
    this.monthlyBudget,
    required this.budgetType,
  });

  @override
  Widget build(BuildContext context) {
    if (monthlyBudget == null) {
      return const SizedBox.shrink();
    }

    final budget = monthlyBudget!;
    final double currentValue;
    final String currentText;
    final String budgetText;

    if (budgetType == 'cost') {
      currentValue = currentMonthlyConsumption * costPerKwh;
      currentText = '$currencySymbol${currentValue.toStringAsFixed(2)}';
      budgetText = '$currencySymbol${budget.toStringAsFixed(2)}';
    } else {
      currentValue = currentMonthlyConsumption;
      currentText = '${currentValue.toStringAsFixed(2)} kWh';
      budgetText = '${budget.toStringAsFixed(2)} kWh';
    }

    final double progress = budget > 0 ? (currentValue / budget).clamp(0.0, 1.0) : 0.0;
    final double percentage = budget > 0 ? (currentValue / budget) * 100 : 0.0;

    final colorScheme = Theme.of(context).colorScheme;
    final Color progressColor;
    if (percentage > 90) {
      progressColor = colorScheme.error;
    } else if (percentage > 70) {
      progressColor = Colors.orange;
    } else {
      progressColor = colorScheme.primary;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.savings_outlined,
                  color: progressColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Monthly Budget',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: colorScheme.surfaceContainerHighest,
                color: progressColor,
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$currentText / $budgetText',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  '${percentage.toStringAsFixed(0)}% used',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: progressColor,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
