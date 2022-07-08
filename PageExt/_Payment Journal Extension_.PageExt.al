pageextension 80204 "Payment Journal Extension" extends "Payment Journal"
{
    actions
    {
        addafter(CancelExport)
        {
            action(ExportWWFile)
            {
                Caption = 'Export Woolworths file';
                ApplicationArea = Basic, Suite;
                Image = Export;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Export the Payment file to Woolworths';

                trigger Onaction()var GeneralJournalLine: Record "Gen. Journal Line";
                Vendors: Record Vendor;
                PurchInvoiceHeader: record "Purch. Inv. Header";
                CRLF: tEXT[2];
                TAB: Char;
                BlobTmp: CODEUNIT "Temp Blob";
                OutStrm: OutStream;
                Instrm: InStream;
                Filename: text;
                begin
                    GeneralJournalLine.setrange("Journal Template Name", rec."Journal Template Name");
                    GeneralJournalLine.setrange("Journal Batch Name", rec."Journal Batch Name");
                    if GeneralJournalLine.FindFirst()then begin
                        repeat GeneralJournalLine.testfield("Account Type", rec."Account Type"::Vendor);
                            GeneralJournalLine.testfield("Account No.");
                            GeneralJournalLine.testfield(Amount);
                            Vendors.get(GeneralJournalLine."Account No.");
                            vendors.testfield("Woolworths Vendor No.");
                        until GeneralJournalLine.next = 0;
                        // create file
                        CRLF[1]:=13;
                        CRLF[2]:=10;
                        TAB:=9;
                        BlobTmp.CreateOutStream(OutStrm);
                        OutStrm.WriteText('Vendor No.' + ',');
                        OutStrm.WriteText('Vendor Name' + ',');
                        OutStrm.WriteText('Vendor Invoice No.' + ',');
                        OutStrm.WriteText('HL Reference' + ',');
                        OutStrm.WriteText('Posting Date' + ',');
                        OutStrm.WriteText('Amount' + CRLF);
                        If GeneralJournalLine.FindFirst()then begin
                            repeat Vendors.get(GeneralJournalLine."Account No.");
                                vendors.testfield("Woolworths Vendor No.");
                                OutStrm.WriteText(vendors."Woolworths Vendor No." + ',');
                                OutStrm.WriteText(Vendors.Name + ',');
                                if GeneralJournalLine."External Document No." <> '' then OutStrm.WriteText(GeneralJournalLine."External Document No." + ',')
                                else
                                begin
                                    if(GeneralJournalLine."Applies-to Doc. Type" = GeneralJournalLine."Applies-to Doc. Type"::invoice) and (GeneralJournalLine."Applies-to Doc. No." <> '')then begin
                                        PurchInvoiceHeader.get(GeneralJournalLine."Applies-to Doc. No.");
                                        OutStrm.WriteText(PurchInvoiceHeader."Vendor Invoice No." + ',');
                                    end end;
                                OutStrm.WriteText(GeneralJournalLine."Applies-to Doc. No." + ',');
                                OutStrm.WriteText(format(GeneralJournalLine."Posting Date", 0, '<Day,2>/<Month,2>/<Year4>') + ',');
                                OutStrm.WriteText(format(GeneralJournalLine.Amount, 0, '<Precision,2:2><Standard Format,2>') + CRLF);
                            until GeneralJournalLine.next = 0;
                            FileName:='Payment_File.csv';
                            BlobTmp.CreateInStream(InStrm);
                            DownloadFromStream(Instrm, 'Payment_File', '', '', FileName);
                        end;
                    end;
                end;
            }
        }
    }
}
