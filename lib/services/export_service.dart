import 'dart:io';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/expense.dart';
import '../models/site.dart';
import '../models/vendor.dart';
import '../models/organization.dart';

class ExportService {
  static final _dateFormat = DateFormat('dd/MM/yyyy');

  // Export expenses to Excel
  static Future<void> exportExpensesToExcel({
    required List<Expense> expenses,
    required Organization organization,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    var excel = Excel.createExcel();
    Sheet sheet = excel['Expenses Report'];

    // Header styling
    CellStyle headerStyle = CellStyle(
      fontFamily: getFontFamily(FontFamily.Calibri),
      bold: true,
      fontSize: 12,
      backgroundColorHex: ExcelColor.fromHexString('#1976D2'),
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
    );

    // Add company info
    sheet.cell(CellIndex.indexByString('A1')).value = TextCellValue('Organization:');
    sheet.cell(CellIndex.indexByString('B1')).value = TextCellValue(organization.name);
    sheet.cell(CellIndex.indexByString('A2')).value = TextCellValue('Report Generated:');
    sheet.cell(CellIndex.indexByString('B2')).value = TextCellValue(_dateFormat.format(DateTime.now()));
    
    if (startDate != null && endDate != null) {
      sheet.cell(CellIndex.indexByString('A3')).value = TextCellValue('Period:');
      sheet.cell(CellIndex.indexByString('B3')).value = TextCellValue(
          '${_dateFormat.format(startDate)} to ${_dateFormat.format(endDate)}');
    }

    // Headers (row 5)
    final headers = [
      'Date',
      'Site',
      'Vendor',
      'Category',
      'Description',
      'Amount (₹)',
      'Receipt'
    ];

    for (var i = 0; i < headers.length; i++) {
      var cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 4));
      cell.value = TextCellValue(headers[i]);
      cell.cellStyle = headerStyle;
    }

    // Data rows
    var rowIndex = 5;
    double totalAmount = 0;

    for (var expense in expenses) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex)).value =
          TextCellValue(_dateFormat.format(expense.expenseDate));
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex)).value =
          TextCellValue(expense.siteName ?? '');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex)).value =
          TextCellValue(expense.vendorName ?? 'N/A');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex)).value =
          TextCellValue(expense.category.toUpperCase());
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex)).value =
          TextCellValue(expense.description);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rowIndex)).value =
          DoubleCellValue(expense.amount);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: rowIndex)).value =
          TextCellValue(expense.receiptUrl != null ? 'Yes' : 'No');

      totalAmount += expense.amount;
      rowIndex++;
    }

    // Total row
    rowIndex++;
    var totalCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex));
    totalCell.value = TextCellValue('TOTAL:');
    totalCell.cellStyle = CellStyle(bold: true);

    var amountCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rowIndex));
    amountCell.value = DoubleCellValue(totalAmount);
    amountCell.cellStyle = CellStyle(bold: true);

    // Summary by category
    rowIndex += 3;
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex)).value =
        TextCellValue('SUMMARY BY CATEGORY');
    
    Map<String, double> categoryTotals = {};
    for (var expense in expenses) {
      categoryTotals[expense.category] = 
          (categoryTotals[expense.category] ?? 0) + expense.amount;
    }

    rowIndex++;
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex)).value = 
        TextCellValue('Category');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex)).value = 
        TextCellValue('Amount (₹)');
    
    rowIndex++;
    categoryTotals.forEach((category, amount) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex)).value =
          TextCellValue(category.toUpperCase());
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex)).value = 
          DoubleCellValue(amount);
      rowIndex++;
    });

    // Save and share file
    await _saveAndShareExcel(excel, 'Expenses_Report_${DateTime.now().millisecondsSinceEpoch}');
  }

  // Export sites to Excel
  static Future<void> exportSitesToExcel({
    required List<Site> sites,
    required Organization organization,
  }) async {
    var excel = Excel.createExcel();
    Sheet sheet = excel['Sites'];

    // Header
    final headers = ['Site Name', 'Location', 'Start Date', 'Status', 'Created On'];
    for (var i = 0; i < headers.length; i++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0)).value = 
          TextCellValue(headers[i]);
    }

    // Data
    var rowIndex = 1;
    for (var site in sites) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex)).value = 
          TextCellValue(site.name);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex)).value =
          TextCellValue(site.location ?? '');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex)).value =
          TextCellValue(site.startDate != null ? _dateFormat.format(site.startDate!) : '');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex)).value =
          TextCellValue(site.status.toUpperCase());
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex)).value =
          TextCellValue(_dateFormat.format(site.createdAt));
      rowIndex++;
    }

    await _saveAndShareExcel(excel, 'Sites_${DateTime.now().millisecondsSinceEpoch}');
  }

  // Export vendors to Excel
  static Future<void> exportVendorsToExcel({
    required List<Vendor> vendors,
    required Organization organization,
  }) async {
    var excel = Excel.createExcel();
    Sheet sheet = excel['Vendors'];

    // Header
    final headers = ['Vendor Name', 'Type', 'Contact', 'Email', 'Address'];
    for (var i = 0; i < headers.length; i++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0)).value = 
          TextCellValue(headers[i]);
    }

    // Data
    var rowIndex = 1;
    for (var vendor in vendors) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex)).value = 
          TextCellValue(vendor.name);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex)).value =
          TextCellValue(vendor.vendorType ?? '');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex)).value =
          TextCellValue(vendor.contactNumber ?? '');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex)).value =
          TextCellValue(vendor.email ?? '');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex)).value =
          TextCellValue(vendor.address ?? '');
      rowIndex++;
    }

    await _saveAndShareExcel(excel, 'Vendors_${DateTime.now().millisecondsSinceEpoch}');
  }

  // Save and share Excel file
  static Future<void> _saveAndShareExcel(Excel excel, String filename) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$filename.xlsx');
    
    final bytes = excel.encode();
    if (bytes != null) {
      await file.writeAsBytes(bytes);
      
      // Share the file
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: filename,
      );
    }
  }
}