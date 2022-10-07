tableextension 80006 "HL Purchase Header Ext" extends "Purchase Header"
{
    fields
    {
         field(80000; "NPF ASN Status"; option)
        {
            OptionMembers = " ",PENDING,"NOT RECEIVED","RECEIVED WITH DISCREPANCIES",RECEIVED,"RECEIPT IN PROGRESS",QUARANTINE;
            //Editable = false;
        }
        field(80001; "Order Type"; option)
        {
            OptionMembers = Internal,NPF;
            trigger OnValidate()
            var
                Purchline:Record "Purchase Line";
                Flg:Boolean;
                win:Dialog;
                Cu:Codeunit "HL NPF Routines";
            begin
                Purchline.reset;
                Purchline.Setrange("Document Type",Rec."Document Type");
                Purchline.Setrange("Document No.",Rec."No.");
                Purchline.Setrange(Type,Purchline.Type::Item);
                Flg := Rec.Status = Rec.Status::released;
                if Flg then
                begin
                    Rec.Status := Rec.Status::Open;
                end;
                Rec.Modify(false);
                win.Open('Refreshing Lines ....');  
                If "Order Type" = "Order type"::NPF then
                begin
                    If Purchline.Findset then
                    repeat
                        CU.Purch_Rebates(Purchline);
                        Purchline.Modify(true); 
                    until PurchLine.next = 0;
                end
                else 
                begin
                    If Purchline.Findset then
                    repeat
                        Clear(Purchline."Line Rebate %");
                        Clear(Purchline."Indirect Cost %");
                        Purchline.Modify(false); 
                    until PurchLine.next = 0;
                end;
                if Flg then
                begin
                    Rec.Status := Rec.Status::Released;
                    Rec.Modify(false);
                end; 
                win.close;
            end;
        }
        field(80002; "NPF Booking Ref No"; text[100])
        {
        }
        field(80003; "Rebate Post Lock"; Boolean)
        {
        }
        field(80004; "Email Status"; Option)
        {
            OptionMembers = ,Sent;
            Editable = False;
        }

        /*field(80004; "Requested Receipt Time"; Time)
        {
        }
        */
    }
    trigger OnBeforeDelete()
    var 
        Excp:Record "HL Purch Exceptions";
    begin
        if Excp.Get(Rec."No.") then Excp.Delete;
    end;
}