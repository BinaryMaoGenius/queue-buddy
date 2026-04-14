import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/ticket.dart';
import 'package:intl/intl.dart';

class PdfService {
  static Future<void> generateAndDownloadTicket(Ticket ticket) async {
    final pdf = pw.Document();

    final font = await PdfGoogleFonts.poppinsRegular();
    final fontBold = await PdfGoogleFonts.poppinsBold();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(20),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              mainAxisSize: pw.MainAxisSize.min,
              children: [
                pw.Text("SIRA - QUEUE BUDDY", style: pw.TextStyle(font: fontBold, fontSize: 18)),
                pw.Divider(),
                pw.SizedBox(height: 10),
                pw.Text("VOTRE NUMÉRO", style: pw.TextStyle(font: font, fontSize: 12)),
                pw.Text(ticket.numeroTicket, style: pw.TextStyle(font: fontBold, fontSize: 32)),
                pw.SizedBox(height: 10),
                pw.Text("${ticket.clientNom}", style: pw.TextStyle(font: font, fontSize: 14)),
                pw.Text("${ticket.typeOperation}", style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey700)),
                pw.SizedBox(height: 20),
                pw.Text(DateFormat('dd/MM/yyyy HH:mm').format(ticket.createdAt), style: pw.TextStyle(font: font, fontSize: 10)),
                pw.SizedBox(height: 20),
                pw.Divider(),
                pw.Text("Merci pour votre confiance", style: pw.TextStyle(font: font, fontSize: 10, fontStyle: pw.FontStyle.italic)),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'ticket_${ticket.numeroTicket}.pdf',
    );
  }
}
