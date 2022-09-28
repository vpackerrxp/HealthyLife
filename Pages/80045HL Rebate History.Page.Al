page 80045 "HL Rebate History"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "HL Purchase Rebates";
    SourceTableTemporary = true;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    Caption = 'Rebate History';
    layout
    {
        area(Content)
        {
            Group(Filters)
            {   
                field("From Rebate Date Filter"; TransFilter[1])
                {
                    ApplicationArea = All;
                    Style = Strong;
                    trigger OnValidate()
                    begin
                        If TransFilter[2] <> 0D then
                            if TransFilter[1] > TransFilter[2] then Clear(Transfilter[1]);
                        Refress_data_msg(True);
                    end;

                    trigger OnAssistEdit()
                    begin
                        Clear(transFilter[1]);
                        Refress_data_msg(True);
                    end;
                }
                field("To Rebate Date Filter"; TransFilter[2])
                {
                    ApplicationArea = All;
                    Style = Strong;
                    trigger OnValidate()
                    begin
                        If TransFilter[1] <> 0D then
                            if TransFilter[2] < TransFilter[1] then Clear(Transfilter[2]);
                        Refress_data_msg(True);
                    end;

                    trigger OnAssistEdit()
                    begin
                        Clear(transFilter[2]);
                        Refress_data_msg(True);
                    end;
                }
                field("Supplier Filter"; Supp)
                {
                    ApplicationArea = All;
                    Style = Strong;
                    trigger OnLookup(var Text: Text): Boolean
                    var
                        Vend:record Vendor;
                        Pg:Page "Vendor List";
                    begin
                        Clear(Supp);
                        Vend.reset;
                        Vend.Setfilter("No.",'SUP-*');
                        If Vend.Findset then
                        begin
                            Pg.SetTableView(Vend);
                            Pg.LookupMode := True;
                            If Pg.RunModal() = Action::LookupOK then
                            begin
                                Pg.GetRecord(Vend); 
                                Supp := Vend."No.";      
                                Refress_data_msg(True);
                           end;
                        end;
                    end;    
                    trigger OnAssistEdit()
                    begin
                        Clear(Supp);
                        Refress_data_msg(True);
                    end;
                }
                field("Brand Filter"; Bran)
                {
                    ApplicationArea = All;
                    Style = Strong;
                    trigger OnLookup(var Text: Text): Boolean
                    var
                        pg:page "HL Supplier Brand List";
                        rel:Record "HL Supplier Brand Rebates";
                    begin
                        Rel.Reset;
                        pg.SetTableView(rel);
                        pg.LookupMode := true;
                        If Pg.RunModal() = action::LookupOK then
                        begin
                            pg.GetRecord(Rel);
                            Bran := rel.Brand;
                            Refress_data_msg(True);
                        end;      
                    end; 
                    trigger OnAssistEdit()
                    begin
                        Clear(Bran);
                        Refress_data_msg(True);
                    end;
                }
                field("Rebate Type Filter";RebType)
                {
                    ApplicationArea = All;
                    Style = Strong;
                    trigger OnValidate();
                    begin
                        Refress_data_msg(True);
                    end;

                    trigger OnAssistEdit()
                    begin
                        Clear(RebType);
                        Refress_data_msg(True);
                    end;
                }
                field("Rebate Claim Filter";Claim)
                {
                    ApplicationArea = All;
                    Style = Strong;
                    trigger OnValidate();
                    begin
                        Refress_data_msg(True);
                    end;    
                    trigger OnAssistEdit()
                    begin
                        Clear(Claim);
                        Refress_data_msg(True);
                    end;
                }
                field("1";'Clear Filters')
                {
                    ApplicationArea = All;
                    Style = Strong;
                    ShowCaption = false;
                    trigger OnDrillDown()
                    begin
                        Clear(TransFilter);
                        Clear(Supp);
                        Clear(Bran);
                        Clear(RebType);
                        Clear(Claim);
                        Refress_data_msg(True);
                    end;
                }
              /* field("2";'Display Data')
                {
                    ApplicationArea = All;
                    Style = Strong;
                    ShowCaption = false;
                    trigger OnDrillDown()
                    begin
                        SetFilters();       
                    end;
                }
                */
                field("X";RefMsg)
                {
                    ApplicationArea = All;
                    Style = Unfavorable;
                    ShowCaption = false;
                    Editable = False;
                    trigger OnDrillDown()
                    begin
                        SetFilters();       
                    end;
                }
            }    
            repeater(GroupName)
            {
                
                field("Supplier No."; Rec."Supplier No.")
                {
                    ApplicationArea = All;
                }
                field(Brand; Rec.Brand)
                {
                    ApplicationArea = All;
                }
                field("Rebate Date"; Rec."Rebate Date")
                {
                    ApplicationArea = All;
                }
                field(SKU; Rec."Item No.")
                {
                    ApplicationArea = All;
                }
                field(Description; Get_Description)
                {
                    ApplicationArea = All;
                }
                field("Purchase/Sales Order No."; Get_Invoice(False))
                {
                    ApplicationArea = All;
                }
                field("Posted Doc No.";rec."Document No.")
                {
                    ApplicationArea = All;
                    Caption = 'Posted Document No.';
                    trigger OnDrillDown();
                    var
                        PPI:record "Purch. Inv. Header";
                        SINV:Record "Sales Invoice Header";
                    begin
                        If Rec."Rebate Type" = Rec."Rebate Type"::Sales then
                            If SINV.get(Rec."Document No.") then
                                PAGE.RunModal(PAGE::"Posted Sales Invoice",SINV)
                        else If PPI.get(Rec."Document No.") then
                                PAGE.RunModal(PAGE::"Posted Purchase Invoice",PPI);
                    end;
                }
                field("Invoice No."; Get_Invoice(True))
                {
                    ApplicationArea = All;
                }
                field("Rebate Type"; Rec."Rebate Type")
                {
                    ApplicationArea = All;
                    Style = Strong;
                 }
                field("Rebate %";Rec."Rebate %")
                {
                    ApplicationArea = All;
                }
                field("Rebated Unit Cost"; Get_Rebated_Cost_Qty_Value(0))
                {
                    ApplicationArea = All;
                }
                field("Rebated Qty"; Get_Rebated_Cost_Qty_Value(1))
                {
                    ApplicationArea = All;
                }
                field("Rebated Total Buy/Sell Value"; Get_Rebated_Cost_Qty_Value(2))
                {
                    ApplicationArea = All;
                }
                field("Rebated Total Discounted Value"; Get_Rebated_Cost_Qty_Value(3))
                {
                    ApplicationArea = All;
                }
                field("Rebate Value"; Rec."Rebate Value")
                {
                    ApplicationArea = All;
                    Style = Strong;
                }
            }
            Group(Totals)
            {
                Field("Record Count";Rec.Count)    
                {
                    ApplicationArea = All;
                    Style = Strong;
                }
                Field("Total Buy Value";Get_Buy_Total())
                {
                    ApplicationArea = All;
                    Style = Strong;
                }
                Field("Total Sell Value";Get_Sell_Total())
                {
                    ApplicationArea = All;
                    Style = Strong;
                }

                Field("Rebate Total";Get_Rebate_Total())
                {
                    ApplicationArea = All;
                    Style = Strong;
                }
            }
        }   
    }
    local procedure Get_Invoice(Mode:Boolean):Code[50]
    var
        PPI:record "Purch. Inv. Header";
        SINV:record "Sales Invoice Header";
    begin
        If Rec."Rebate Type" = Rec."Rebate Type"::Sales then
        Begin
            If SINV.Get(Rec."Document No.") then
            begin
                if Mode then
                    Exit(Sinv."External Document No.")
                else
                    Exit(Sinv."Order No.");    
            end;
        end 
        else If PPI.get(Rec."Document No.") then
        begin
            if Mode then
                Exit(PPI."Vendor Invoice No.")
            else
                Exit(PPI."Order No.");    
        end;
        Exit('');
    end;
    local procedure Get_Description():text
    var
        Item:record Item;
    begin
        If Item.Get(Rec."Item No.") then
            Exit(Item.Description)
        else
            Exit('');    
    end;
    local procedure Get_Rebated_Cost_Qty_Value(Mode:integer):Decimal
    var
        PurchInvLine:record "Purch. Inv. Line";
        SaleInvLine:record "Sales Invoice Line";
    begin
        If Rec."Rebate Type" = Rec."Rebate Type"::Sales then
        begin
            SaleInvLine.Reset;
            SaleInvLine.Setrange("Document No.",Rec."Document No.");
            SaleInvLine.Setrange("No.",Rec."Item No.");
            SaleInvLine.Setrange("Line No.",rec."Document Line No.");
            If SaleInvLine.Findset then
            begin
                Case Mode of
                    0 : exit(SaleInvLine."Unit Cost");
                    1 : exit(SaleInvLine.Quantity);
                    2 : exit(SaleInvLine.Amount);
                    3 : Exit(SaleInvLine."Line Discount Amount");
                end;    
            end             
        end;
        PurchInvLine.reset;
        PurchInvLine.setrange("Document No.",Rec."Document No.");
        PurchInvLine.Setrange("No.",Rec."Item No.");
        PurchInvLine.Setrange("Line No.",Rec."Document Line No.");
        if PurchInvLine.findset then
        begin
            Case Mode of
                0 : exit(PurchInvLine."Direct Unit Cost");
                1 : exit(PurchInvLine.Quantity);
                2 : exit(PurchInvLine.Amount);
                3 : Exit(PurchInvLine."Line Discount Amount");
            end;    
        end             
        else
            exit(0);    
    end;
    local procedure Get_Rebate_Total():Decimal
    begin
        rec.CalcSums("Rebate Value");
        Exit(Rec."Rebate Value");
    end;
    local procedure Get_Buy_Total():Decimal
    var
        Reb:record "HL Purchase Rebates";
        PurchInvLine:record "Purch. Inv. Line";
        Tot:Decimal;   
    begin
        If Rec.IsEmpty then Exit(0);
        Clear(Tot);
        Reb.CopyFilters(rec);
        If Reb.findset then
        repeat
            PurchInvLine.reset;
            PurchInvLine.setrange("Document No.",Reb."Document No.");
            PurchInvLine.Setrange("No.",Reb."Item No.");
            PurchInvLine.Setrange("Line No.",Reb."Document Line No.");
            if PurchInvLine.findset then
                Tot+= PurchInvLine.Amount;
        until Reb.next = 0;        
        exit(Tot);
    end;
    local procedure Get_Sell_Total():Decimal
    var
        Reb:record "HL Purchase Rebates";
        SinInvLine:record "Sales Invoice Line";
        Tot:Decimal;   
    begin
        If Rec.IsEmpty then Exit(0);
        Clear(Tot);
        Reb.CopyFilters(rec);
        If Reb.findset then
        repeat
            SinInvLine.reset;
            SinInvLine.setrange("Document No.",Reb."Document No.");
            SinInvLine.Setrange("No.",Reb."Item No.");
            SinInvLine.Setrange("Line No.",Reb."Document Line No.");
            if SinInvLine.findset then
                Tot+= SinInvLine.Amount;
        until Reb.next = 0;        
       exit(Tot);
    end;
    local procedure SetFilters()
    var
        PCR:record "HL Purchase Rebates";
        win:Dialog;
        i:Integer;
    begin
        win.Open('Rendering Data .. Record Count #1########');
        Rec.Reset();
        If Rec.Findset then Rec.DeleteAll(False);
        PCR.Reset;
        PCR.setfilter("Rebate Value",'>0');
        If Claim <> Claim::All then
            if Claim = Claim::Claimed then
                PCR.setrange("Rebate Paid",true)
            else
                PCR.setrange("Rebate Paid",false);
        if (TransFilter[1] <> 0D) AND (TransFilter[2] <> 0D) then
            PCR.SetRange("Rebate Date", TransFilter[1], TransFilter[2])
        else if (TransFilter[1] <> 0D) then
            PCR.Setfilter("Rebate Date", '%1..', TransFilter[1])
        else if (TransFilter[2] <> 0D) then
            PCR.Setfilter("Rebate Date", '..%1', TransFilter[2]);
        If Supp <> '' then PCR.Setrange("Supplier No.",Supp);
        If Bran <> '' then PCR.Setrange(Brand,Bran);
        If RebType <> RebType::All then PCR.setrange("Rebate Type",RebType - 1);
        Clear(i);
        If PCR.FindSet() then
        repeat
            i += 1;
            Win.Update(1,i);
            Rec.Copy(PCR);
            Rec.Insert(false);
        until PCR.next = 0;
        Win.close;
        Refress_data_msg(False);
        CurrPage.Update(False);
    end;
    local procedure Refress_data_msg(OnOff:boolean)
    begin
        Clear(RefMsg);
        If OnOff then RefMsg := 'Data Refresh Required .. Press To Refresh Data';
        CurrPage.update(false);
    end;
 
    Var
        Supp:code[20];
        Bran:Code[30];
        RebType: Option All,PartnerShip,Marketing,Sales;
        TransFilter: array[2] of date;
        Claim: Option All,Claimed,UnClaimed;
        RefMsg:text;
}