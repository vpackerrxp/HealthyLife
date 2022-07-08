codeunit 80203 "Exp Posted Purch. Inv. to WW"
{
    Permissions = TableData "Purch. Inv. Header"=imd;

    trigger OnRun()begin
        ExportPurchaseInvoices();
    end;
    procedure ExportPurchaseInvoices()var Vendors: Record Vendor;
    PurchInvoiceHeader: record "Purch. Inv. Header";
    PurchInvoiceHeader2: record "Purch. Inv. Header";
    PurchaseSetup: Record "Purchases & Payables Setup";
    LastPurchaseInvoiceNo: code[20];
    CRLF: tEXT[2];
    TAB: Char;
    BlobTmp: CODEUNIT "Temp Blob";
    OutStrm: OutStream;
    Instrm: InStream;
    Filename: text;
    begin
        PurchaseSetup.get();
        PurchInvoiceHeader.setfilter("No.", '>%1', PurchaseSetup."Last Exp. Purchase Invoice No.");
        if PurchInvoiceHeader.FindFirst()then begin
            repeat Vendors.get(PurchInvoiceHeader."Pay-to Vendor No.");
                vendors.testfield("Woolworths Vendor No.");
            until PurchInvoiceHeader.next = 0;
            // create file
            CRLF[1]:=13;
            CRLF[2]:=10;
            TAB:=9;
            BlobTmp.CreateOutStream(OutStrm);
            OutStrm.WriteText('HL Vendor No.' + ',');
            OutStrm.WriteText('WW Vendor No.' + ',');
            OutStrm.WriteText('Vendor Name' + ',');
            OutStrm.WriteText('Vendor Invoice No.' + ',');
            OutStrm.WriteText('Healthy Life Invoice No.' + ',');
            OutStrm.WriteText('Posting Date' + ',');
            OutStrm.WriteText('Due Date' + ',');
            OutStrm.WriteText('Amount Excluding GST' + ','); //GS 04/08/2021
            OutStrm.WriteText('GST Amount' + ','); //GS 04/08/2021
            OutStrm.WriteText('Amount Including GST' + CRLF);
            If PurchInvoiceHeader.FindFirst()then begin
                repeat PurchInvoiceHeader.calcfields(Amount, "Amount Including VAT");
                    Vendors.get(PurchInvoiceHeader."Pay-to Vendor No.");
                    vendors.testfield("Woolworths Vendor No.");
                    OutStrm.WriteText(PurchInvoiceHeader."Pay-to Vendor No." + ',');
                    OutStrm.WriteText(vendors."Woolworths Vendor No." + ',');
                    OutStrm.WriteText(Vendors.Name + ',');
                    OutStrm.WriteText(PurchInvoiceHeader."Vendor Invoice No." + ',');
                    OutStrm.WriteText(PurchInvoiceHeader."No." + ',');
                    OutStrm.WriteText(format(PurchInvoiceHeader."Posting Date", 0, '<Day,2>/<Month,2>/<Year4>') + ',');
                    OutStrm.WriteText(format(PurchInvoiceHeader."Due Date", 0, '<Day,2>/<Month,2>/<Year4>') + ',');
                    //GS 04/08/2021>>
                    OutStrm.WriteText(format(PurchInvoiceHeader."Amount", 0, '<Precision,2:2><Standard Format,2>') + ',');
                    OutStrm.WriteText(format(PurchInvoiceHeader."Amount Including VAT" - PurchInvoiceHeader."Amount", 0, '<Precision,2:2><Standard Format,2>') + ',');
                    //<<
                    OutStrm.WriteText(format(PurchInvoiceHeader."Amount Including VAT", 0, '<Precision,2:2><Standard Format,2>') + CRLF);
                    PurchInvoiceHeader2.get(PurchInvoiceHeader."No.");
                    PurchInvoiceHeader2."Date Payment Exported to WW":=workdate;
                    PurchInvoiceHeader2."Payment Exported to WW":=true;
                    PurchInvoiceHeader2.modify;
                    LastPurchaseInvoiceNo:=PurchInvoiceHeader."No.";
                until PurchInvoiceHeader.next = 0;
                if LastPurchaseInvoiceNo <> '' then begin
                    PurchaseSetup."Last Exp. Purchase Invoice No.":=LastPurchaseInvoiceNo;
                    PurchaseSetup.Modify();
                end;
                FileName:='Purchase_Invoice.csv';
                BlobTmp.CreateInStream(InStrm);
                DownloadFromStream(Instrm, 'Purchase_Invoice_File', '', '', FileName);
            end;
        end;
    end;
}
