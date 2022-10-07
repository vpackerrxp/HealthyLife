page 80026 "HL Purchase Email Confirmation"
{
    Caption = 'Purchase Email Confirmation';
    PageType = Worksheet;
    SourceTable = "Purchase Header";
    layout
    {
        area(content)
        {

            group("Order Details")
            {
                Editable = False;    
                field("PO Number";Rec."No.")
                {
                    ApplicationArea = all;
                    Caption = 'Purchase Order No';
                    Style = Strong;
                } 
                field("Supplier No.";Rec."Buy-from Vendor No.")
                {
                    ApplicationArea = all;
                    Caption = 'Supplier No.';
                    Style = Strong;
                } 
                field("Supplier Name";Rec."Buy-from Vendor Name")
                {
                    ApplicationArea = all;
                    Caption = 'Supplier Name';
                    Style = Strong;
                } 
                field("Order Line Count";Get_Order_Count())
                {
                    ApplicationArea = all;
                    Caption = 'Order Line Count';
                    Style = Strong;
                } 
                field("Total Ordered Qty";Get_Order_Qty())
                {
                    ApplicationArea = all;
                    Caption = 'Total Ordered Qty';
                    Style = Strong;
                } 
                field("Order Value";Get_Order_Total())
                {
                    ApplicationArea = all;
                    Style = Strong;
                    Caption = 'Total Order Value';
                } 
            }
            Group(Email)
            {
                Editable = true;
                field("Current Email Recipent(s)";OpEm)
                {
                    ApplicationArea = all;
                    Editable = False;
                    Style = Strong;
                } 
                field("Primary Email Recipent";EmailRecp[1])
                {
                    ApplicationArea = all;
                    Style = Strong;
                }
                field("2nd Email Recipent";EmailRecp[2])
                {
                    ApplicationArea = all;
                    Style = Strong;
                }
                field("3rd Email Recipent";EmailRecp[3])
                {
                    ApplicationArea = all;
                    Style = Strong;
                }
                field("4th Email Recipent";EmailRecp[4])
                {
                    ApplicationArea = all;
                    Style = Strong;
                }
                field("X";'Send Email')
                {
                    ApplicationArea = all;
                    ShowCaption = False;
                    Editable = False;
                    Style = StrongAccent;
                    trigger OnDrillDown()
                    var
                        Msg:text;
                        Recip:text;
                        i:Integer;
                        Cu:Codeunit "HL Shopify Routines";
                        CuN:Codeunit "HL NPF Routines";
                    begin
                        Clear(Recip);
                        Msg := 'Email PO To Recipents ';
                        For i := 1 to ArrayLen(EmailRecp) do
                            If EmailRecp[i].Contains('@') then
                            Begin
                                Msg += EmailRecp[i] + ',';
                                Recip += EmailRecp[i] + ';';
                            end;         
                        Msg := Msg.Remove(Msg.LastIndexOf(','),1);
                        Recip := Recip.Remove(Recip.LastIndexOf(';'),1);
                        Msg += ' Now?'; 
                        If Strlen(Recip) <= 200 then
                        begin       
                            if Confirm(Msg,True) then
                                CU.Send_PO_Email(rec,Recip);
                            Rec.Status := Rec.Status::Released;
                            Rec.Modify(False);
                            Commit;   
                            If CuN.Create_Update_ASN(Rec) then
                                Message('NPF ASN Creation Successfull')
                            else
                                Message('NPF ASN Creation UnSuccessfull');
                            CurrPage.Close();
                        end 
                        Else 
                            Message('Recipent address overflow .. reduce number of recipents');        
                    end;
                }
            }
            part(PurchLines; "Purchase Order Subform")
            {
                ApplicationArea = All;
                Editable = Rec."Buy-from Vendor No." <> '';
                Enabled = Rec."Buy-from Vendor No." <> '';
                SubPageLink = "Document No." = FIELD("No.");
                UpdatePropagation = SubPart;
            }
        }
    }
    trigger OnOpenPage()
    begin
        OpEm:= Get_Email_Recipent();
    end;

    Local procedure Get_Email_Recipent():text
    Var
        Vend:Record Vendor;
        Flds:list of [Text];
        i:Integer;
    Begin
        Clear(EmailRecp);
        If Vend.Get(Rec."Buy-from Vendor No.") then
        Begin
            Flds := Vend."Operations E-Mail".Split(';');
            For i := 1 to Flds.Count do
                EmailRecp[i] := Flds.Get(i);
            Exit(Vend."Operations E-Mail");
        end;    
        exit('');   
    End;
    local procedure Get_Order_Total():Decimal
    Begin
        Rec.CalcFields("Amount Including VAT");
        Exit(Rec."Amount Including VAT");
    End;
    local procedure Get_Order_Count():Integer
    var
        PurchLine:Record "Purchase Line";
    Begin
        PurchLine.reset;
        PurchLine.Setrange("Document Type",Rec."Document Type");
        PurchLine.SetRange("Document No.",Rec."No.");
        PurchLine.Setrange(Type,PurchLine.Type::Item);
        Exit(PurchLine.Count);
    End;
    local procedure Get_Order_Qty():Decimal
    var
        PurchLine:Record "Purchase Line";
    Begin
        PurchLine.reset;
        PurchLine.Setrange("Document Type",Rec."Document Type");
        PurchLine.SetRange("Document No.",Rec."No.");
        PurchLine.Setrange(Type,PurchLine.Type::Item);
        If PurchLine.Findset then
        begin
            PurchLine.CalcSums(Quantity);
            Exit(PurchLine.Quantity);
        end;    
        Exit(0);
    End;
    var
        EmailRecp:Array[4] of Text;
        OpEm:Text;
}
