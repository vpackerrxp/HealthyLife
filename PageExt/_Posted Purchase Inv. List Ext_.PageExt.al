pageextension 80205 "Posted Purchase Inv. List Ext" extends "Posted Purchase Invoices"
{
    layout
    {
        addafter(Closed)
        {
            field("Payment Exported to WW";Rec."Payment Exported to WW")
            {
                ToolTip = 'Specifies the value of the Payment Exported to WW field';
                ApplicationArea = All;
            }
            field("Date Payment Exported to WW";Rec."Date Payment Exported to WW")
            {
                ToolTip = 'Specifies the value of the Date Payment Exported to WW field';
                ApplicationArea = All;
            }
        }
    }
    actions
    {
        addafter("Update Document")
        {
            action(ExportWWFile)
            {
                Caption = 'Export the Purchase Invoice file to Woolworths';
                ApplicationArea = Basic, Suite;
                Image = Export;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Export the Purchase Invoice file to Woolworths';

                trigger Onaction()var ExportPaymentFile: Codeunit "Exp Posted Purch. Inv. to WW";
                begin
                    ExportPaymentFile.Run();
                end;
            /*
                Vendors: Record Vendor;
                PurchInvoiceHeader: record "Purch. Inv. Header";
                PurchInvoiceHeader2: record "Purch. Inv. Header";
                CRLF: tEXT[2];
                TAB: Char;
                BlobTmp: CODEUNIT "Temp Blob";
                OutStrm: OutStream;
                Instrm: InStream;
                Filename: text;

            begin
                PurchInvoiceHeader.setrange("Payment Exported to WW", false);
                if PurchInvoiceHeader.FindFirst() then begin
                    repeat
                        Vendors.get(PurchInvoiceHeader."Pay-to Vendor No.");
                    //vendors.testfield("Woolworths Vendor No.");
                    until PurchInvoiceHeader.next = 0;

                    // create file
                    CRLF[1] := 13;
                    CRLF[2] := 10;
                    TAB := 9;
                    BlobTmp.CreateOutStream(OutStrm);
                    OutStrm.WriteText('HL Vendor No.' + ',');
                    OutStrm.WriteText('WW Vendor No.' + ',');
                    OutStrm.WriteText('Vendor Name' + ',');
                    OutStrm.WriteText('Vendor Invoice No.' + ',');
                    OutStrm.WriteText('Healthy Life Invoice No.' + ',');
                    OutStrm.WriteText('Posting Date' + ',');
                    OutStrm.WriteText('Amount' + CRLF);
                    If PurchInvoiceHeader.FindFirst() then begin
                        repeat
                            PurchInvoiceHeader.calcfields("Amount Including VAT");
                            Vendors.get(PurchInvoiceHeader."Pay-to Vendor No.");
                            //vendors.testfield("Woolworths Vendor No.");
                            OutStrm.WriteText(PurchInvoiceHeader."Pay-to Vendor No." + ',');
                            OutStrm.WriteText(vendors."Woolworths Vendor No." + ',');
                            OutStrm.WriteText(Vendors.Name + ',');
                            OutStrm.WriteText(PurchInvoiceHeader."Vendor Invoice No." + ',');
                            OutStrm.WriteText(PurchInvoiceHeader."No." + ',');
                            OutStrm.WriteText(format(PurchInvoiceHeader."Posting Date", 0, '<Day,2>/<Month,2>/<Year4>') + ',');
                            OutStrm.WriteText(format(PurchInvoiceHeader."Amount Including VAT", 0, '<Precision,2:2><Standard Format,2>') + CRLF);
                            PurchInvoiceHeader2.get(PurchInvoiceHeader."No.");
                            PurchInvoiceHeader2."Date Payment Exported to WW" := workdate;
                            //PurchInvoiceHeader2."Payment Exported to WW" := true;
                            PurchInvoiceHeader2.modify;
                        until PurchInvoiceHeader.next = 0;
                        FileName := 'Purchase_Invoice.csv';
                        BlobTmp.CreateInStream(InStrm);
                        DownloadFromStream(Instrm, 'Purchase_Invoice_File', '', '', FileName);

                    end;

                end;
            end;
            */
            }
        }
    }
}
