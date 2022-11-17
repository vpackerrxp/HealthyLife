page 80046 "HL Rebate Payments"
{
    PageType = Worksheet;
    Caption = 'Rebate Payments';
    ApplicationArea = All;
    UsageCategory = Tasks;
    SourceTable = Vendor;
    SourceTableTemporary = true;
    InsertAllowed = false;
    DeleteAllowed = false;
    
    layout
    {
        area(Content)
        {
            Group(Filter)
            {
               Field("Rebate Start Date Filter";RebDate[1])
                {
                    Caption = 'Rebate Start Date Filter';
                    ApplicationArea = All;
                    trigger OnValidate()
                    begin
                        If (RebDate[2] > 0D) and (RebDate[1] > RebDate[2]) then
                        begin
                            message('Invalid Start Date ...');
                            Clear(RebDate[1]);
                        end;
                        Refress_data_msg(True);
                    end;
                    trigger OnAssistEdit()
                    begin
                        Clear(RebDate[1]);
                        Refress_data_msg(True);
                    end;
                }
                Field("Rebate End Date Filter";RebDate[2])
                {
                    Caption = 'Rebate End Date Filter';
                    ApplicationArea = All;
                    trigger OnValidate()
                    begin
                       If (RebDate[1] > 0D) and (RebDate[2] < RebDate[1]) then
                        begin
                            message('Invalid End Date ...');
                            Clear(RebDate[2]);
                        end;        
                        Refress_data_msg(True);
                    end;
                    trigger OnAssistEdit()
                    begin
                        Clear(RebDate[2]);
                        Refress_data_msg(True);
                    end;
                }
                field("X";RefMsg)
                {
                    ApplicationArea = All;
                    Style = Unfavorable;
                    ShowCaption = false;
                    Editable = False;
                    trigger OnDrillDown()
                    begin
                        Calculate_ALL_Rebates(RebDate,'');    
                    end;
                }

                Field("Rebate Posting Date";PstDate)
                {
                    Caption = 'Rebate Posting Date';
                    ApplicationArea = All;
                }

            }
            repeater(A)
            {
                Field("Supplier No.";rec."No.")
                {
                    ApplicationArea = All;
                    Editable = false;
                    Style = Strong;
                }
                Field(Name;rec.Name)
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                Field("PartnerShip Rebate Total";rec."Partnership Rebate Total")
                {
                    Caption = 'PartnerShip Rebate Total';
                    ApplicationArea = All;
                    Editable = false;
                    Style = Favorable;
                    StyleExpr = Rec."Partnership Rebate Total" > 0;
                }
                Field("PartnerShip Rebate Claim";rec."Tax Liable")
                {
                    Caption = 'PartnerShip Rebate Claim';
                    ApplicationArea = All;
                    trigger OnValidate()
                    begin
                        If Rec."PartnerShip Rebate Total" = 0 then Clear(rec."Tax Liable");
                    end;
                }
                Field("Marketing Rebate Total";rec."Marketing Rebate Total")
                {
                    Caption = 'Marketing Rebate Total';
                    ApplicationArea = All;
                    Editable = false;
                    Style = Favorable;
                    StyleExpr = Rec."Marketing Rebate Total" > 0;
                }
                Field("Marketing Rebate Claim";rec."Block Payment Tolerance")
                {
                    Caption = 'Marketing Rebate Claim';
                    ApplicationArea = All;
                    trigger OnValidate()
                    begin
                        If Rec."Marketing Rebate Total" = 0 then Clear(rec."Block Payment Tolerance");
                    end;
                }
                Field("Sales Rebate Total";rec."Sales Rebate Total")
                {
                    Caption = 'Sales Rebate Total';
                    ApplicationArea = All;
                    Editable = false;
                    Style = Favorable;
                    StyleExpr = Rec."Sales Rebate Total" > 0;
                }
                Field("Supply Rebate Claim";rec."Foreign Vend")
                {
                    Caption = 'Sales Rebate Claim';
                    ApplicationArea = All;
                   trigger OnValidate()
                    begin
                        If rec."Sales Rebate Total" = 0 then Clear(rec."Foreign Vend");
                    end;
                }
                Field("Rebate Total";rec."Budgeted Amount")
                {
                    Caption = 'Rebate Total';
                    ApplicationArea = All;
                    Editable = false;
                }
                Field("";rec."Name 2")
                {
                    ShowCaption = false;
                    ApplicationArea = All;
                    Style = StrongAccent;
                    Editable = false;
                    trigger OnDrillDown()
                    begin
                        If rec."Name 2" <> '*' then Process_Rebates(RebDate);
                    end;
                }
            }    
            Group(Totals)
            {
                Field("PartnerShip Totals";Get_Totals(0))
                {
                    ApplicationArea = All;
                    Style = Strong;
                    Editable = false;
                }
                Field("Market Totals";Get_Totals(1))
                {
                    ApplicationArea = All;
                    Style = Strong;
                    Editable = false;
                }    
                Field("Sales Totals";Get_Totals(2))
                {
                    ApplicationArea = All;
                    Style = Strong;
                    Editable = false;
                }
                Field("All Rebate Totals";Get_Totals(3))
                {
                    ApplicationArea = All;
                    Style = Strong;
                    Editable = false;
                }
            }
        }
    }
    trigger OnOpenPage()
    var
        //Reb:Record "PC Purchase Rebates";
    begin
       // Reb.Reset;
       // Reb.Setrange(Brand,'');
       // If Reb.findset Then Reb.Deleteall;
        Lock_Unlock_Purchase_Orders(True);
        Clear(RebDate);
        Calculate_ALL_Rebates(RebDate,'');    
    end;
    trigger OnClosePage()
    begin
        Lock_Unlock_Purchase_Orders(false);
    end;
    local procedure Process_Rebates(Dat:array[2] of date)
    var
        PurchHdr:Record "Purchase Header";
        PurchLine:record "Purchase Line";
        PCrd:Record "Purch. Cr. Memo Hdr.";
        PCrdLine:record "Purch. Cr. Memo Line";
        i:integer;
        GenLed:Record "General Ledger Setup";
        Flg:Boolean;
        LineNo:integer;
        pg:page "Purchase Credit Memo";
        Res:Record "Reason Code";
        Reb:record "HL Purchase Rebates";
        SupReb:Record "HL Supplier Brand Rebates"; 
   begin
        If (rec."Budgeted Amount" > 0) And (Pstdate <> 0D) then
        begin
            if Confirm(strsubstno('Process Rebate Credits now using Posting Date %1?',Pstdate),true) then
            begin
                If not Res.Get('REBATES') then
                begin
                    Res.init;
                    Res.Code := 'REBATES';
                    Res.Insert();
                end;
                GenLed.get; 
                PurchHdr.Init;
                PurchHdr.Validate("Document Type",PurchHdr."Document Type"::"Credit Memo");
                PurchHdr.insert(true);
                PurchHdr.Validate("Buy-from Vendor No.",rec."No.");
                PurchHdr.validate("Posting Date",PstDate);
                PurchHdr."Your Reference" := StrSubStno('Rebates as of %1',TODAY);
                PurchHdr."Reason Code" := res.Code;
                PurchHdr.modify(True);
                Clear(LineNo);
                For i := 1 to 3 do
                begin
                    Case i of 
                        1: Flg := (rec."Partnership Rebate Total" > 0) AND rec."Tax Liable";
                        2: Flg := (rec."Sales Rebate Total" > 0) AND rec."Foreign Vend" ;
                        3: Flg := (rec."Marketing Rebate Total" > 0) AND rec."Block Payment Tolerance"
                    end;
                    if flg then
                    begin
                        SupReb.Reset();
                        SupReb.Setrange("Supplier No.",Rec."No.");
                        If SupReb.Findset then
                        Repeat
                            reb.reset;
                            reb.Setrange("Supplier No.",SupReb."Supplier No.");
                            Reb.Setrange(Brand,SupReb.Brand);
                            Reb.Setrange("Rebate Paid",False);
                            Case i of 
                                1: Reb.Setrange("Rebate Type",Reb."Rebate Type"::PartnerShip);
                                2: Reb.Setrange("Rebate Type",Reb."Rebate Type"::Sales);
                                3: Reb.Setrange("Rebate Type",Reb."Rebate Type"::Marketing);
                            end;    
                            If (Dat[1] <> 0D) And (Dat[2] <> 0D) then
                                Reb.Setrange("Rebate Date",Dat[1],Dat[2])
                            else if Dat[1] <> 0D then    
                                Reb.SetFilter("Rebate Date",'%1..',Dat[1])
                            else if Dat[2] <> 0D then    
                                Reb.SetFilter("Rebate Date",'..%1',Dat[2]);
                            If Reb.Findset then
                            begin
                                Reb.Calcsums("Rebate Value");
                                If Reb."Rebate Value" > 0 then
                                Begin
                                    Lineno += 10000;
                                    PurchLine.Init;
                                    Purchline.Validate("Document Type",PurchHdr."Document Type");
                                    PurchLine.validate("Document No.",PurchHdr."No.");
                                    Purchline.validate("Line No.",LineNo);
                                    PurchLine.insert(true);
                                    PurchLine.validate(Type,PurchLine.Type::"G/L Account");
                                    Case i of 
                                        1: 
                                        begin
                                            PurchLine.validate("No.",GenLed."PartnerShip Rebate Acc");
                                            If (Dat[1] <> 0D) and (Dat[2] <> 0D) then
                                                Purchline.Description := StrSubStno('%1 - %2 %3',Dat[1],Dat[2],SupReb."Volume Rebate %") + '% ' + SupReb.Brand + ' PartnerShip Rebate'
                                            else if (Dat[1] <> 0D) then
                                                Purchline.Description := StrSubStno('%1.. %2',Dat[1],SupReb."Volume Rebate %") + '% ' + SupReb.Brand + ' PartnerShip Rebate'
                                            else if (Dat[2] <> 0D) then
                                                Purchline.Description := StrSubStno('..%1 %2',Dat[2],SupReb."Volume Rebate %") + '% ' + SupReb.Brand + ' PartnerShip Rebate'
                                            else
                                                Purchline.Description := StrSubStno('%1 %2',TODAY,SupReb."Volume Rebate %") + '% ' + SupReb.Brand + ' PartnerShip Rebate';
                                        end;    
                                        2: 
                                        begin
                                            PurchLine.validate("No.",GenLed."Sales Claim Rebate Acc");
                                            If (Dat[1] <> 0D) and (Dat[2] <> 0D) then
                                                Purchline.Description := StrSubStno('%1 - %2 ',Dat[1],Dat[2]) + SupReb.Brand + ' Sales Rebate'
                                            else if (Dat[1] <> 0D) then
                                                Purchline.Description := StrSubStno('%1.. ',Dat[1]) + SupReb.Brand + ' Sales Rebate'
                                            else if (Dat[2] <> 0D) then
                                                Purchline.Description := StrSubStno('..%1 ',Dat[2]) + SupReb.Brand + ' Sales Rebate'
                                            else 
                                                Purchline.Description := StrSubStno('%1 ',TODAY)  + SupReb.Brand + ' Sales Rebate';
                                        end;
                                        3: 
                                            begin
                                                PurchLine.validate("No.",GenLed."Marketing Rebate Acc");
                                                If (Dat[1] <> 0D) and (Dat[2] <> 0D) then
                                                    Purchline.Description := StrSubStno('%1 - %2 %3',Dat[1],Dat[2],SupReb."Marketing Rebate %") + '% ' + SupReb.Brand + ' Marketing Rebate'
                                                else If (Dat[1] <> 0D) then
                                                    Purchline.Description := StrSubStno('%1.. %2',Dat[1],SupReb."Marketing Rebate %") + '% ' + SupReb.Brand + ' Marketing Rebate'
                                                else If (Dat[2] <> 0D) then
                                                    Purchline.Description := StrSubStno('..%1 %2',Dat[2],SupReb."Marketing Rebate %") + '% ' + SupReb.Brand + ' Marketing Rebate'
                                                else    
                                                    Purchline.Description := StrSubStno('%1 %2',Today,SupReb."Marketing Rebate %") + '% ' + SupReb.Brand + ' Marketing Rebate';
                                            end;
                                        end; 
                                        Purchline.validate("Direct Unit Cost",reb."Rebate Value");
                                        Purchline."Description 2" := SupReb.Brand;
                                        PurchLine.validate(Quantity,1);
                                        Purchline.Modify(True);
                                    end;    
                                end;
                            until SupReb.next = 0;
                        end;    
                    end;    
                    Commit;
                    Purchline.Reset;
                    Purchline.Setrange("Document Type",PurchHdr."Document Type");
                    PurchLine.Setrange("Document No.",PurchHdr."No.");
                    If Purchline.findset then
                    begin
                        PCrd.reset;
                        PCrd.Setrange("Pre-Assigned No.",PurchHdr."No.");
                        Pg.SetRecord(PurchHdr);
                        Pg.runmodal;
                        if PCrd.findset then 
                        begin
                            Reb.Reset;
                            If (Dat[1] <> 0D) And (Dat[2] <> 0D) then
                                Reb.Setrange("Rebate Date",Dat[1],Dat[2])
                            else if Dat[1] <> 0D then    
                                Reb.SetFilter("Rebate Date",'%1..',Dat[1])
                            else if Dat[2] <> 0D then    
                                Reb.SetFilter("Rebate Date",'..%1',Dat[2]);
                            Reb.Setrange("Rebate Paid",False);
                            PCrdLine.Reset;
                            PcrdLine.Setrange("Document No.",PCrd."No.");
                            Pcrdline.Setrange(Type,Pcrdline.Type::"G/L Account");
                            If PcrdLine.Findset then
                            repeat
                                Clear(Flg);
                                Case Pcrdline."No." of
                                    GenLed."PartnerShip Rebate Acc":
                                        Begin
                                            Reb.Setrange("Rebate Type",Reb."Rebate Type"::PartnerShip);
                                            Flg := True;
                                        end;       
                                    GenLed."Sales Claim Rebate Acc":
                                        begin;
                                            Reb.Setrange("Rebate Type",Reb."Rebate Type"::Sales);
                                            flg := True;
                                        end;      
                                    GenLed."Marketing Rebate Acc":
                                        begin
                                            Reb.Setrange("Rebate Type",Reb."Rebate Type"::Marketing);
                                            flg := True;
                                        end;    
                                end;
                                Reb.Setrange(Brand,PCrdline."Description 2");
                                if Flg and Reb.Findset then Reb.Modifyall("Rebate Paid",true);
                            Until PcrdLine.next = 0;
                        end
                        else
                        begin
                            Message('Posted Purchase Credit Note not found .. Deleting Purchases Credit Note');
                            PurchHdr.Delete(true);
                        end;
                    end
                    else
                        PurchHdr.Delete(true);
                    Clear(Rebdate);           
                    Calculate_ALL_Rebates(Dat,rec."No.");
                    CurrPage.update(false);        
            end;
        end     
        else
            Message('No Rebates To Process and or Posting Date Is Not Defined!');               
    end;
    local procedure Calculate_ALL_Rebates(Dat:Array[2] of Date;Vend:Code[20]);
    var
        Ven:record Vendor;
        Reb:record "HL Purchase Rebates";
        SupReb:record "HL Supplier Brand Rebates";
        flg:Boolean;
        Rebates:Array[3] of Decimal;
        GenLed:record "General Ledger Setup";
        win:dialog;
    begin
        Clear(flg);
        Genled.Get;
        rec.Reset;
        If rec.Findset then rec.DeleteAll(false);
        If GenLed."PartnerShip Rebate Acc" = '' then
        begin
            Message('PartnerShip Rebate Account is not defined in General Ledger Setup  .. Correct and Retry');
            Flg := true;
        end    
        else If GenLed."Marketing Rebate Acc" = '' then 
        begin 
            Message('Marketing Rebate Account is not defined in General Ledger Setup  .. Correct and Retry');
            flg := True;
        end    
        else If GenLed."Sales Claim Rebate Acc" = '' then 
        begin
            Message('Sales Claim Rebate Account is not defined in General Ledger Setup  .. Correct and Retry');
            flg := True;
        end;
        if Not flg then
        begin    
            Win.open('Calculating Rebates For Vendor #1############');    
            Ven.Reset;
            Ven.Setfilter("No.",'SUP-*');
            Ven.Setfilter(Name,'<>%1','');
            If Ven.findset then
            repeat
                SupReb.Reset();
                SupReb.Setrange("Supplier No.",Ven."No.");
                If SupReb.findset then
                begin
                    Win.update(1,Ven."No.");
                    rec."No." := Ven."No.";
                    rec.Name := Ven.Name;
                    Clear(rec."Partnership Rebate Total");
                    Clear(rec."Marketing Rebate Total");
                    Clear(rec."Sales Rebate Total");
                    Clear(rec."Budgeted Amount");
                    Clear(rec."Tax Liable");
                    Clear(rec."Foreign Vend");
                    clear(rec."Block Payment Tolerance");
                    rec."Name 2" := '*';
                    reb.reset;
                    reb.Setrange("Supplier No.",Ven."No.");
                    Reb.Setrange("Rebate Paid",False);
                    Reb.Setrange("Rebate Type",reb."Rebate Type"::PartnerShip);
                    If (Dat[1] <> 0D) And (Dat[2] <> 0D) then
                        Reb.Setrange("Rebate Date",Dat[1],Dat[2])
                    else if Dat[1] <> 0D then    
                        Reb.SetFilter("Rebate Date",'%1..',Dat[1])
                    else if Dat[2] <> 0D then    
                        Reb.SetFilter("Rebate Date",'..%1',Dat[2]);
                    If Reb.Findset then
                    begin
                        Reb.Calcsums("Rebate Value");
                        rec."Partnership Rebate Total" := Reb."Rebate Value";
                        rec."Budgeted Amount" += rec."Partnership Rebate Total";
                    end;
                    Reb.Setrange("Rebate Type",reb."Rebate Type"::Marketing);
                    If Reb.Findset then
                    begin
                        Reb.Calcsums("Rebate Value");
                        rec."Marketing Rebate Total" := Reb."Rebate Value";
                        rec."Budgeted Amount" += rec."Marketing Rebate Total";
                    end;
                    Reb.Setrange("Rebate Type",reb."Rebate Type"::Sales);
                    If Reb.Findset then
                    begin
                        Reb.Calcsums("Rebate Value");
                        rec."Sales Rebate Total" := Reb."Rebate Value";
                        rec."Budgeted Amount" += rec."Sales Rebate Total";
                    end;
                    if Rec."Budgeted Amount" > 0  then Rec."Name 2" := 'PROCESS';
                    rec.insert;
                end;    
            until Ven.next = 0;
            Rec.Reset;
            win.Close();
            Refress_data_msg(False);
            CurrPage.Update(false);
        end;        
    end;
    local procedure Lock_Unlock_Purchase_Orders(LckFlg:Boolean)
    var
        PurchHdr:Record "Purchase Header";
    begin
        PurchHdr.Reset;
        PurchHdr.Setrange("Document Type",PurchHdr."Document Type"::Order);
        PurchHdr.Setrange("Order type",PurchHdr."Order Type"::NPF);
        If PurchHdr.findset then PurchHdr.Modifyall("Rebate Post Lock",LckFlg,false);    
    end;
    local procedure Refress_data_msg(OnOff:boolean)
    begin
        Clear(RefMsg);
        If OnOff then RefMsg := 'Data Calculations Required .. Press To Refresh Data';
         CurrPage.update(false);
    end;
   Local procedure Get_Totals(Indx:integer):Decimal
    begin
        Rec.CalcSums("Partnership Rebate Total","Marketing Rebate Total","Sales Rebate Total","Budgeted Amount");
        Case Indx of
            0: Exit(Rec."Partnership Rebate Total");    
            1: Exit(Rec."Marketing Rebate Total");    
            2: Exit(Rec."Sales Rebate Total");    
            3: Exit(Rec."Budgeted Amount");    
        End;
    End;

    var 
        Flg:Boolean;
        Styler:text;
        RebDate:Array[2] of date;
        RefMsg:text;

        PstDate:date;
}