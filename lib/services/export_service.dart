import 'dart:io';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import '../models/appliance.dart';
import '../models/consumption_snapshot.dart';

export 'package:share_plus/share_plus.dart' show XFile;

class ExportService {
  Future<String> generateCsv({
    required List<Appliance> appliances,
    required double costPerKwh,
    required String currency,
    List<ConsumptionSnapshot>? history,
  }) async {
    final rows = <List<dynamic>>[
      ['WattWise Energy Report'],
      ['Generated', DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())],
      ['Cost per kWh', '$currency${costPerKwh.toStringAsFixed(4)}'],
      [],
      ['Appliance', 'Power (W)', 'Hours/Day', 'Brand', 'Location', 'Daily kWh', 'Daily Cost', 'Monthly kWh', 'Monthly Cost'],
    ];

    double totalDaily = 0;
    for (final a in appliances) {
      final dailyKwh = a.dailyConsumption;
      totalDaily += dailyKwh;
      rows.add([
        a.name,
        a.isWatts ? a.powerRating : a.powerRating * 230,
        a.hoursPerDay,
        a.brand ?? '',
        a.location ?? '',
        dailyKwh.toStringAsFixed(2),
        '$currency${(dailyKwh * costPerKwh).toStringAsFixed(2)}',
        (dailyKwh * 30).toStringAsFixed(2),
        '$currency${(dailyKwh * 30 * costPerKwh).toStringAsFixed(2)}',
      ]);
    }

    rows.add([]);
    rows.add(['TOTAL', '', '', '', '', totalDaily.toStringAsFixed(2), '$currency${(totalDaily * costPerKwh).toStringAsFixed(2)}', (totalDaily * 30).toStringAsFixed(2), '$currency${(totalDaily * 30 * costPerKwh).toStringAsFixed(2)}']);

    if (history != null && history.isNotEmpty) {
      rows.addAll([
        [],
        ['Historical Data'],
        ['Date', 'Daily kWh', 'Daily Cost', 'Appliance Count'],
      ]);
      for (final s in history) {
        rows.add([
          DateFormat('yyyy-MM-dd').format(s.date),
          s.totalDailyKwh.toStringAsFixed(2),
          '$currency${s.totalDailyCost.toStringAsFixed(2)}',
          s.applianceCount,
        ]);
      }
    }

    return const ListToCsvConverter().convert(rows);
  }

  Future<pw.Document> generatePdf({
    required List<Appliance> appliances,
    required double costPerKwh,
    required String currency,
    List<ConsumptionSnapshot>? history,
  }) async {
    final pdf = pw.Document();
    final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

    double totalDaily = 0;
    for (final a in appliances) {
      totalDaily += a.dailyConsumption;
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text('WattWise Energy Report',
                style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
          ),
          pw.Paragraph(text: 'Generated: $dateStr  |  Rate: $currency${costPerKwh.toStringAsFixed(4)}/kWh'),
          pw.SizedBox(height: 10),
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
            cellStyle: const pw.TextStyle(fontSize: 8),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
            headers: ['Appliance', 'Watts', 'Hrs/Day', 'Location', 'kWh/Day', 'Cost/Day', 'kWh/Mo', 'Cost/Mo'],
            data: [
              ...appliances.map((a) {
                final d = a.dailyConsumption;
                return [
                  a.name,
                  (a.isWatts ? a.powerRating : a.powerRating * 230).toStringAsFixed(0),
                  a.hoursPerDay.toString(),
                  a.location ?? '-',
                  d.toStringAsFixed(2),
                  '$currency${(d * costPerKwh).toStringAsFixed(2)}',
                  (d * 30).toStringAsFixed(2),
                  '$currency${(d * 30 * costPerKwh).toStringAsFixed(2)}',
                ];
              }),
              [
                'TOTAL', '', '', '',
                totalDaily.toStringAsFixed(2),
                '$currency${(totalDaily * costPerKwh).toStringAsFixed(2)}',
                (totalDaily * 30).toStringAsFixed(2),
                '$currency${(totalDaily * 30 * costPerKwh).toStringAsFixed(2)}',
              ],
            ],
          ),
          if (history != null && history.isNotEmpty) ...[
            pw.SizedBox(height: 20),
            pw.Header(level: 1, child: pw.Text('Consumption History')),
            pw.TableHelper.fromTextArray(
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
              cellStyle: const pw.TextStyle(fontSize: 8),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
              headers: ['Date', 'Daily kWh', 'Daily Cost', 'Appliances'],
              data: history.map((s) => [
                    DateFormat('yyyy-MM-dd').format(s.date),
                    s.totalDailyKwh.toStringAsFixed(2),
                    '$currency${s.totalDailyCost.toStringAsFixed(2)}',
                    s.applianceCount.toString(),
                  ]).toList(),
            ),
          ],
        ],
      ),
    );

    return pdf;
  }

  Future<void> shareCsv({
    required List<Appliance> appliances,
    required double costPerKwh,
    required String currency,
    List<ConsumptionSnapshot>? history,
  }) async {
    final csvContent = await generateCsv(
      appliances: appliances,
      costPerKwh: costPerKwh,
      currency: currency,
      history: history,
    );
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/wattwise_report.csv');
    await file.writeAsString(csvContent);
    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'WattWise Energy Report',
    );
  }

  Future<void> sharePdf({
    required List<Appliance> appliances,
    required double costPerKwh,
    required String currency,
    List<ConsumptionSnapshot>? history,
  }) async {
    final pdf = await generatePdf(
      appliances: appliances,
      costPerKwh: costPerKwh,
      currency: currency,
      history: history,
    );
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/wattwise_report.pdf');
    await file.writeAsBytes(await pdf.save());
    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'WattWise Energy Report',
    );
  }
}
