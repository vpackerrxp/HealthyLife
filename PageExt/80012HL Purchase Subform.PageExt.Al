pageextension 80012 "HL Purchase Order Subform Ext" extends "Purchase Order Subform"
{
    layout
    {
        addafter(Description)
        {
            field("Vendor Item No.";rec."Vendor Item No.")
            {
                ApplicationArea = All;
            }    
        }
        addafter("Location Code")
        {
            field("Line Rebate %"; rec."Line Rebate %")
            {
                ApplicationArea = All;
            }
        }
        addafter(Quantity)
        {
            Field("Quantity (base)";rec."Quantity (base)")
            {
                ApplicationArea = All;
                Visible = TRue;
                Editable = False;
            }

            field("NPF Recvd Qty";rec."NPF Recvd Qty")
            {
                ApplicationArea = All;
                StyleExpr = Styler1;
                Caption = 'NPF Recvd Qty(Base)';
            }
            field("Original Order Qty";rec."Original Order Qty")
            {
                ApplicationArea = All;
            }
            field("Original Order Qty(Base)";rec."Original Order Qty(Base)")
            {
                ApplicationArea = All;
            }
            field("Original Order UOM";rec."Original Order UOM")
            {
                ApplicationArea = All;
            }
        } 
    }
    actions
    {
        addafter("O&rder")
        {
            Group("Healthy Life")
            {
                action(Msg)
                {
                    ApplicationArea = All;
                    Caption = 'NPF Exceptions';
                    Image = Filter;
                    ToolTip = 'Filters Lines To NPF Exceptions';
                    trigger OnAction()
                    var
                        PH:Record "Purchase Header";    
                    begin
                        Case StrMenu('Show NPF Qty Exceptions,Show NPF Addition Exceptions,Show All Lines',1) of
                            1:
                            begin
                                If Ph.get(Rec."Document Type",rec."Document No.") then
                                begin
                                    If (Ph."Order Type" = PH."Order Type"::NPF) 
                                        and ((Ph."NPF ASN Status" = Ph."NPF ASN Status"::RECEIVED) Or (Ph."NPF ASN Status" = Ph."NPF ASN Status"::"RECEIVED WITH DISCREPANCIES"))  then
                                    begin
                                        Rec.Reset;
                                        Rec.Setrange("Document Type",Ph."Document Type");
                                        rec.Setrange("Document No.",Ph."No.");
                                        Rec.Setfilter("NPF Recvd Qty",'>-1');
                                        If rec.findset then
                                        repeat
                                            rec.mark(Rec."Quantity (base)" <> Rec."NPF Recvd Qty");
                                        until rec.next = 0;
                                        rec.MarkedOnly(true); 
                                        CurrPage.update(false);
                                    end;
                                end;
                            end;
                            2:
                            begin
                                If Ph.get(Rec."Document Type",rec."Document No.") then
                                begin
                                    If (Ph."Order Type" = PH."Order Type"::NPF) 
                                        and ((Ph."NPF ASN Status" = Ph."NPF ASN Status"::RECEIVED) Or (Ph."NPF ASN Status" = Ph."NPF ASN Status"::"RECEIVED WITH DISCREPANCIES"))  then
                                    begin
                                        Rec.Reset;
                                        Rec.Setrange("Document Type",Ph."Document Type");
                                        rec.Setrange("Document No.",Ph."No.");
                                        Rec.Setrange("Original Order Qty",0);
                                        If rec.findset then
                                        repeat
                                            rec.mark(True);
                                        until rec.next = 0;
                                        rec.MarkedOnly(true); 
                                        CurrPage.update(false);
                                    end;
                                end;
                            end;
                            3:
                            begin
                                If Ph.get(Rec."Document Type",rec."Document No.") then
                                    if (Ph."Order Type" = PH."Order Type"::NPF) then 
                                    begin
                                        Rec.Reset;
                                        Rec.Setrange("Document Type",Ph."Document Type");
                                        rec.Setrange("Document No.",Ph."No.");
                                        CurrPage.update(false);
                                    end;    
                            end;
                        end;    
                    end;
                }
                action(Msg2)
                {
                    ApplicationArea = All;
                    Caption = 'Auto Approve Qty Exceptions';
                    Image = Filter;
                    ToolTip = 'Auto Approves NPF Qty Exceptions';
                    trigger OnAction()
                    var
                        PH:Record "Purchase Header"; 
                        cnt:Integer;
                        ItemUnit:Record "Item Unit of Measure"; 
                        Cst:Decimal;
                        Item:record Item;  
                    begin
                        If Ph.get(Rec."Document Type",rec."Document No.") then
                        begin;
                            If (Ph."Order Type" = PH."Order Type"::NPF) 
                                        and ((Ph."NPF ASN Status" = Ph."NPF ASN Status"::RECEIVED) Or (Ph."NPF ASN Status" = Ph."NPF ASN Status"::"RECEIVED WITH DISCREPANCIES"))  then
                            begin
                                Rec.Reset;
                                Rec.Setrange("Document Type",Ph."Document Type");
                                rec.Setrange("Document No.",Ph."No.");
                                Rec.Setfilter("NPF Recvd Qty",'>-1');
                                If rec.findset then
                                repeat
                                    rec.mark(Rec."Quantity (Base)" <> Rec."NPF Recvd Qty");
                                until rec.next = 0;
                                rec.MarkedOnly(true); 
                                If Rec.Count > 0 then 
                                begin
                                    Cnt := Rec.Count;
                                    if Confirm('Auto Approve All Qty Exceptions Now',false) then
                                    begin
                                        Ph.Status := Ph.Status::Open;
                                        Ph.modify(false);
                                        Rec.Reset;
                                        Rec.Setrange("Document Type",Ph."Document Type");
                                        rec.Setrange("Document No.",Ph."No.");
                                        Rec.Setfilter("NPF Recvd Qty",'>-1');
                                        If rec.findset then
                                        repeat
                                            If Rec."Quantity (Base)" <> Rec."NPF Recvd Qty" then
                                            begin
                                                ItemUnit.Get(rec."No.",Rec."Unit of Measure Code");
                                                If ItemUnit."Qty. per Unit of Measure" = 1 then     
                                                    rec.validate(Quantity,Rec."NPF Recvd Qty")
                                                else
                                                begin
                                                    Cst := Rec."Unit Cost"/ItemUnit."Qty. per Unit of Measure";
                                                    Item.Get(Rec."No.");
                                                    Rec.Validate("Unit of Measure Code",Item."Base Unit of Measure");
                                                    rec.validate(Quantity,Rec."NPF Recvd Qty");
                                                    Rec.validate("Direct Unit Cost",Cst);
                                                end;    
                                                Rec.modify;
                                            end;    
                                        until rec.next = 0;
                                        Message('%1 NPF Qty Exceptions have been auto approved',Cnt);
                                    end;
                                end;
                                Rec.Reset;
                                Rec.Setrange("Document Type",Ph."Document Type");
                                rec.Setrange("Document No.",Ph."No.");
                                CurrPage.update(false);
                            end;
                        end;
                    end;
                }
                action(Msg3)
                {
                    ApplicationArea = All;
                    Caption = 'Refresh Lines';
                    trigger OnAction()
                    var
                        PH:Record "Purchase Header"; 
                    begin
                        If Ph.get(Rec."Document Type",rec."Document No.") then
                        begin;
                            Rec.Reset;
                            Rec.Setrange("Document Type",Ph."Document Type");
                            rec.Setrange("Document No.",Ph."No.");
                            If rec.findset then
                            repeat
                                Rec.Validate("Unit of Measure Code");
                                Rec.modify(false);
                            until Rec.next = 0;  
                            CurrPage.update(false);  
                        end;
                    end;
                }         
            }
        }
    }
    trigger OnAfterGetRecord()
    begin
        If (rec."Quantity (base)" <> rec."NPF Recvd Qty") AND (rec."NPF Recvd Qty" <> -1) then
            Styler1 := 'unfavorable'
        else
            Styler1 := 'standard';
    end;
    var 
        Styler1:text;

}  