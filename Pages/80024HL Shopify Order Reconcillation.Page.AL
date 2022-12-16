page 80024 "HL Shopify Order Recon"
{
    Caption = 'Shopify Order Reconciliation';
    PageType = Worksheet;
    UsageCategory = Tasks;
    ApplicationArea = All;
    SourceTable = "HL Shopify Order Header";
    InsertAllowed = false;
    //ModifyAllowed = false;
    DeleteAllowed = false;
    PromotedActionCategoriesML = ENU = 'Healthy Life',
                                 ENA = 'Healthy Life';
   
    layout
    {
        area(Content)
        {
            Group(Filters)
            {
                field("From Shopify Date Filter"; Recondate[1])
                {
                    ApplicationArea = All;
                    Style = Strong;
                    trigger OnValidate()
                    begin
                        If Recondate[2] <> 0D then
                            if Recondate[1] > Recondate[2] then Clear(Recondate[1]);
                        SetFilters();
                    end;

                    trigger OnAssistEdit()
                    begin
                        Clear(Recondate[1]);
                        SetFilters();
                    end;
                }
                field("To Shopify Date Filter"; Recondate[2])
                {
                    ApplicationArea = All;
                    Style = Strong;
                    trigger OnValidate()
                    begin
                        If Recondate[1] <> 0D then
                            if Recondate[2] < Recondate[1] then Clear(Recondate[2]);
                        SetFilters();
                    end;

                    trigger OnAssistEdit()
                    begin
                        Clear(Recondate[2]);
                        SetFilters();
                    end;
                }
               field("From Banking Date Filter"; Bankdate[1])
                {
                    ApplicationArea = All;
                    Style = Strong;
                    trigger OnValidate()
                    begin
                        If BankDate[2] <> 0D then
                            if Bankdate[1] > Bankdate[2] then Clear(Bankdate[1]);
                        SetFilters();
                    end;

                    trigger OnAssistEdit()
                    begin
                        Clear(Bankdate[1]);
                        SetFilters();
                    end;
                }
                field("From Banking Start Time Filter"; Banktime[1])
                {
                    ApplicationArea = All;
                    Style = Strong;
                    trigger OnValidate()
                    begin
                        If BankTime[2] <> 0T then
                            if BankTime[1] > BankTime[2] then Clear(BankTime[1]);
                        SetFilters();
                    end;

                    trigger OnAssistEdit()
                    begin
                        Clear(BankTime[1]);
                        SetFilters();
                    end;
                }
                 field("To Banking Date Filter"; Bankdate[2])
                {
                    ApplicationArea = All;
                    Style = Strong;
                    trigger OnValidate()
                    begin
                        If Bankdate[1] <> 0D then
                            if Bankdate[2] < Bankdate[1] then Clear(Bankdate[2]);
                        SetFilters();
                    end;

                    trigger OnAssistEdit()
                    begin
                        Clear(Bankdate[2]);
                        SetFilters();
                    end;
                }
                field("To Banking Start Time Filter"; BankTime[2])
                {
                    ApplicationArea = All;
                    Style = Strong;
                    trigger OnValidate()
                    begin
                        If BankTime[1] <> 0T then
                            if BankTime[2] < BankTime[1] then Clear(BankTime[2]);
                        SetFilters();
                    end;

                    trigger OnAssistEdit()
                    begin
                        Clear(BankTime[2]);
                        SetFilters();
                    end;
                }
                field("Payment Type Filter"; PayType)
                {
                    ApplicationArea = All;
                    Style = Strong;
                    trigger OnValidate()
                    begin
                        SetFilters();
                    end;

                    trigger OnAssistEdit()
                    begin
                        Clear(PayType);
                        SetFilters();
                    end;
                }
                field("Transaction Type Filter"; TransType)
                {
                    ApplicationArea = All;
                    Style = Strong;
                    trigger OnValidate()
                    begin
                        SetFilters();
                    end;

                    trigger OnAssistEdit()
                    begin
                        Clear(TransType);
                        SetFilters();
                    end;
                }
                field("Cash Receipts Filter"; Crec)
                {
                    ApplicationArea = All;
                    Style = Strong;
                    trigger OnValidate()
                    begin
                        SetFilters();
                    end;
                    trigger OnAssistEdit()
                    begin
                        Clear(Crec);
                        SetFilters();
                    end;
                }
                 field("Invoice Applied Filter"; Inv)
                {
                    ApplicationArea = All;
                    Style = Strong;
                    trigger OnValidate()
                    begin
                        SetFilters();
                    end;

                    trigger OnAssistEdit()
                    begin
                        Clear(Inv);
                        SetFilters();
                    end;
                }
               field("Shopify Order No Filter"; ordNo)
                {
                    ApplicationArea = All;
                    Style = Strong;
                    trigger OnValidate()
                    begin
                        SetFilters();
                    end;

                    trigger OnAssistEdit()
                    begin
                        Clear(OrdNo);
                        SetFilters();
                    end;
                }
                Field("C";'Check Invoice Reconciliation')
                {
                    ApplicationArea = All;
                    ShowCaption = False;
                    Style = Strong;
                    trigger OnDrillDown()
                    begin
                        PAGE.RunModal(PAGE::"HL Check Inv Reconciliations");
                    end;    
                }
                Field("Correction Value";CorrVal)
                {
                    ApplicationArea = All;
                    Style = Strong;
                    trigger OnValidate()
                    begin
                        If Confirm(StrSubstNo('Add Correction Value %1 Now',CorrVal),True) then
                        begin
                            If Not rec.get(0) then
                            begin
                                rec.init;
                                rec."Shopify Order ID" := 0;
                                Rec."BC Reference No." := 'CORRECTION';
                                Rec.insert;
                            end;
                            rec."Processed Date" := Today;
                            Rec."Processed Time" := Format(Time);
                            Rec."Cash Receipt Status" := Rec."Cash Receipt Status"::Applied;
                            Rec."Invoice Applied Status" := Rec."Invoice Applied Status"::Applied;
                            rec."Order Total" := Corrval;
                            rec."Order Type" := Rec."Order Type"::Invoice;
                            If Corrval < 0 then
                                rec."Order Type" := Rec."Order Type"::CreditMemo;
                            Rec.Modify;
                        end;    
                    end;
                }        
            }    
            repeater(Group)
            {
                field("Shopify Order No.";rec."Shopify Order No.")
                {
                    ApplicationArea = All;
                }
                field("Order Type";rec."Order Type")
                {
                    ApplicationArea = All;
                }

                field("Shopify Order Date";rec."Shopify Order Date")
                {
                    ApplicationArea = All;
                }
                field("Shopify Order Currency";rec."Shopify Order Currency")
                {
                    ApplicationArea = All;
                }
                field("Shopify Financial Status";rec."Shopify Financial Status")
                {
                    ApplicationArea = All;
                    Style = Strong;
                }
                field("Shopify Order Status";rec."Shopify Order Status")
                {
                    ApplicationArea = All;
                    Style = Strong;
                }
                field("Freight Total";rec."Freight Total")
                {
                    ApplicationArea = All;
                }
                field("Discount Total";rec."Discount Total")
                {
                    ApplicationArea = All;
                }
                field("Order Total";rec."Order Total")
                {
                    ApplicationArea = All;
                    Style = Strong;
                }
                field("Tax Total";rec."Tax Total")
                {
                    ApplicationArea = All;
                }
                field("BC Reference No.";rec."BC Reference No.")
                {
                    ApplicationArea = All;
                    trigger OnDrillDown()
                    var
                        SinvHdr:Record "Sales Invoice Header";
                        SCrdHdr:Record "Sales Cr.Memo Header";
                        SoHdr:Record "Sales Header";
                    begin
                        if SinvHdr.get(rec."BC Reference No.") then
                            Page.RunModal(Page::"Posted Sales Invoice",SinvHdr)
                        else if ScrdHdr.get(rec."BC Reference No.") then
                            Page.RunModal(Page::"Posted Sales Credit Memo",ScrdHdr)
                        else if SoHdr.get(Sohdr."Document Type"::"Credit Memo",rec."BC Reference No.") then
                            Page.RunModal(Page::"Sales Credit Memo",ScrdHdr)
                        else if SoHdr.get(Sohdr."Document Type"::"Invoice",rec."BC Reference No.") then
                            Page.RunModal(Page::"Sales Order",Sohdr);
                    end;
                }
                field("Transaction Type";rec."Transaction Type")
                {
                    ApplicationArea = All;
                    Style = Strong;
                 }
                field("Payment Gate Way";rec."Payment Gate Way")
                {
                    ApplicationArea = All;
                }
                field("Processed Date";rec."Processed Date")
                {
                    ApplicationArea = All;
                    Caption = 'Banking Date';
                }
                field("Processed Time";rec."Processed Time")
                {
                    ApplicationArea = All;
                    Caption = 'Banking Time';
                }
                field("Reference No.";rec."Reference No")
                {
                    ApplicationArea = All;
                }
                field("Shopify Order Id";rec."Shopify Order ID")
                {
                    ApplicationArea = All;
                }
                field("Cash Receipts Status";rec."Cash Receipt Status")
                {
                    ApplicationArea = All;
                    Style = Favorable;
                    StyleExpr = rec."Cash Receipt Status" = rec."Cash Receipt Status"::Applied;
                 }
                field("Invoice Applied Status";rec."Invoice Applied Status")
                {
                    ApplicationArea = All;
                    Style = Favorable;
                    StyleExpr = rec."Invoice Applied Status" = rec."Invoice Applied Status"::Applied;
                }
             }
            Group(Totals)
            {
                field("No of Orders";Rec.Count())
                {
                    ApplicationArea = All;
                    Style = Strong;
                }
                field("Sales Order Totals";Get_Sales_Totals())
                {
                    ApplicationArea = All;
                    Style = Strong;
                }
                field("Refund Order Totals";Get_Refund_Totals())
                {
                    ApplicationArea = All;
                    Style = Strong;
                }
                field("BC Order Totals";Get_BC_Totals())
                {
                    ApplicationArea = All;
                    Style = Strong;
                }
                field("Expected Bank Total";Get_Sales_Totals())
                {
                    ApplicationArea = All;
                    Style = Strong;
                }
                field("Order Totals Unprocessed";Get_Unprocessed_Totals())
                {
                    ApplicationArea = All;
                    Style = Strong;
                }
            }
        }
    }
    
    actions
    {
        area(Processing)
        {
            action("Process Cash Receipts")
            {
                ApplicationArea = All;
                trigger OnAction();
                var
                    Cu:Codeunit "HL Reconcillations";
                begin
                    If PayType <> PayType::" " then
                    begin 
                        If Confirm('Process Cash Receipts For Displayed Records Now',True) then
                        begin
                            Cu.Build_Cash_Receipts(rec,today);
                            SetFilters();
                        end 
                    end       
                    else
                        Message('Select A Pay Type filter');
                end;
            }
        }
    }
    local procedure Get_Sales_Totals():Decimal
    var
        Ordhdr:Record "HL Shopify Order Header";        
    begin
        Ordhdr.CopyFilters(Rec);
        If (TransType = TransType::" ") Or (TransType = TransType::sale) then
            Ordhdr.Setrange("Transaction Type",'sale')
        else
            exit(0);    
        Ordhdr.CalcSums("Order Total");
        Ordhdr.Calcsums("Tax Total");
        Exit(Ordhdr."Order Total" - Ordhdr."Tax Total");
    end;
    local procedure Get_Refund_Totals():Decimal
    var
        OrdHdr:Record "HL Shopify Order Header";        
    begin
        OrdHdr.CopyFilters(Rec);
        OrdHdr.SetFilter("BC Reference No.",'PSCR*');
        OrdHdr.CalcSums("Order Total");
        OrdHdr.Calcsums("Tax Total");
        Exit(OrdHdr."Order Total" + Ordhdr."Tax Total");
    end;
    local procedure Get_BC_Totals():Decimal
    var
        OrdrHdr:record "HL Shopify Order Header";
        Tot:Decimal;
    begin
        OrdrHdr.CopyFilters(rec);    
        OrdrHdr.SetFilter("BC Reference No.",'PSI*');
        OrdrHdr.CalcSums("Order Total");
        Tot := OrdrHdr."Order Total";
        OrdrHdr.CalcSums("Tax Total");
        Tot -= OrdrHdr."Tax Total";
        OrdrHdr.SetFilter("BC Reference No.",'PSCR*');
        OrdrHdr.CalcSums("Order Total");
        Tot-= OrdrHdr."Order Total";
        OrdrHdr.CalcSums("Tax Total");
        Tot += OrdrHdr."Tax Total";
        If OrdrHdr.Get(0) then Tot+= OrdrHdr."Order Total";
        Exit(Tot);
    end;
    local procedure Get_Unprocessed_Totals():Decimal
    var
        Tot:Decimal;
    begin
        Tot := Get_Sales_Totals();
        If tot > 0 then Tot -= Get_BC_Totals();
        exit(Tot);
    end;
    local procedure SetFilters()
    begin
        rec.Reset;
        if (Recondate[1] <> 0D) AND (Recondate[2] <> 0D) then
            rec.SetRange("Shopify Order Date", Recondate[1], Recondate[2])
        else if (Recondate[1] <> 0D) then
            rec.Setfilter("Shopify Order Date", '%1..', Recondate[1])
        else if (Recondate[2] <> 0D) then
            rec.Setfilter("Shopify Order Date", '..%1', Recondate[2]);
        if (Bankdate[1] <> 0D) AND (Bankdate[2] <> 0D) then
            rec.SetRange("Processed Date", Bankdate[1], Bankdate[2])
        else if (Bankdate[1] <> 0D) then
            rec.Setfilter("Processed Date", '%1..', Bankdate[1])
        else if (Bankdate[2] <> 0D) then
            rec.Setfilter("Processed Date", '..%1', Bankdate[2]);
        if (BankTime[1] <> 0T) AND (BankTime[2] <> 0T) then
            rec.SetRange("Proc Time", BankTime[1],BankTime[2])
        else if (BankTime[1] <> 0T) then
            rec.Setfilter("Proc Time", '%1..',BankTime[1])
        else if (BankTime[2] <> 0T) then
            rec.Setfilter("Proc Time", '..%1',BankTime[2]);
        If Crec <> Crec::" "  then Rec.setrange("Cash Receipt Status",Crec -1);
        If Inv <> Inv::" "  then Rec.setrange("Invoice Applied Status",Inv -1);
        case TransType of
            TransType::sale: Rec.setrange("Transaction Type",'sale');
            TransType::refund: Rec.setrange("Transaction Type",'refund');
            TransType::promotion: Rec.setrange("Transaction Type",'promotion');
        end;
        case payType of
            PayType::shopify_payments: Rec.setrange("Payment Gate Way",'shopify_payments');
            payType::paypal: Rec.setrange("Payment Gate Way",'paypal');
            payType::after_pay: Rec.setfilter("Payment Gate Way",'afterpay|Afterpay');
            PayType::zip: Rec.Setfilter("Payment Gate Way",'zip*');
            PayType::misc: Rec.setFilter("Payment Gate Way",'<>shopify*&<>pay*&<>*fter*&<>zip*');
        end;
        IF OrdNo <> 0 then rec.Setrange("Shopify Order No.",OrdNo);
        Currpage.Update(False);
    end;
     var
        Recondate:Array[2] of Date;
        Bankdate:array[2] of date;
        BankTime:array[2] of time;
        Crec: option " ",UnApplied,Applied;
        Inv: option " ",UnApplied,Applied;
        TransType: option " ",sale,refund,promotion;
        PayType: option " ",shopify_payments,paypal,after_pay,zip,misc;
        OrdNo:Integer;
        CorrVal:Decimal;
}