page 80003 "HL Promotions"
{
    ApplicationArea = All;
    Caption = 'Promotions';
    PageType = Worksheet;
    SourceTable = "HL Promotions";
    UsageCategory = Tasks;
    InsertAllowed = False;
    //DeleteAllowed = False;
    PromotedActionCategoriesML = ENU = 'Healthy Life',
                                 ENA = 'Healthy Life';

    layout
    {
        area(content)
        {
            Group(Filters)
            {
                field("Type";PromoType)
                {
                    ApplicationArea = All;
                    Caption = 'Promotion Type Filter';
                    Style = Strong;
                    trigger OnValidate()
                    begin
                        Setfilters();
                    end;
                }
                field("P";Periods)
                {
                    ApplicationArea = All;
                    Caption = 'Periods Filter';
                    Style = Strong;
                    trigger OnValidate()
                    begin
                        Setfilters();
                    end;
                }
                field("Promotion Filter";vars)
                {
                    ApplicationArea = All;
                    Style = Strong;
                    trigger OnDrillDown()
                    var
                        PG:page "HL Promotion List";
                        Prom:record "HL Promotions";    
                    Begin
                        If PromoType <> PromoType::ALL then
                            Pg.Set_PromoType(PromoType - 1);
                        Pg.LookupMode := True;    
                        If Pg.RunModal() = Action::LookupOK then
                        begin
                            Pg.GetRecord(Prom);
                            Vars := Prom."Promotion Code";
                        end;
                        SetFilters();
                    End;
                    trigger OnAssistEdit()
                    begin
                        Clear(Vars);
                        SetFilters();
                    end;
                }
            }
            Group("Import/Export")
            {
                Field("A";'Export Promotions')
                {
                    ApplicationArea = All;
                    ShowCaption = False;
                    Style = StrongAccent;
                    trigger OnDrillDown()
                    var
                        Cu:Codeunit "HL Import Export Routines";
                    begin
                        If PromoType <> PromoType::ALL then
                           Case Strmenu('Export All Periods,Period 1,Period 2,Period 3',1) of
                                1: Cu.Export_Promotions(PromoType-1,0);
                                2: Cu.Export_Promotions(PromoType-1,1);
                                3: Cu.Export_Promotions(PromoType-1,2);
                                4: Cu.Export_Promotions(PromoType-1,3);
                           end    
                        else 
                            Message('Select a Promotion Type .. All is not valid');
                    end;    
                }
                Field("B";'Import Promotions')
                {
                    ApplicationArea = All;
                    ShowCaption = False;
                    Style = StrongAccent;
                    trigger OnDrillDown()
                    var
                        Cu:Codeunit "HL Import Export Routines";
                    begin
                        Cu.Import_Promotions();
                        CurrPage.Update(False); 
                    end;    
                }
            }    
            Group(Process)
            {
                Field("C";'Activate Promotion')
                {
                    ApplicationArea = All;
                    ShowCaption = False;
                    Style = StrongAccent;
                    trigger OnDrillDown()
                    begin
                        Activate_Promotion();
                        CurrPage.Update(false);
                    end;    
                }
            }
            repeater(General)
            {
                field("Promotion Period"; Rec."Promotion Period")
                {
                    ApplicationArea = All;
                    Style = Strong;
                }    
               field("Promotion Type"; Rec."Promotion Type")
                {
                    ApplicationArea = All;
                }
                field("Promotion Code";rec."Promotion Code")
                {
                    ApplicationArea = All;
                    Style = Strong;
                }
                field("RRP Discount %";rec."RRP Discount %")
                {
                    ApplicationArea = All;
                    trigger OnValidate()
                    begin
                        CurrPage.Update(true);
                    end;
                }
                field("Promotion Start Date"; Rec."Promotion Start Date")
                {
                    ApplicationArea = All;
                    trigger OnValidate()
                    begin
                        CurrPage.Update(true);
                    end;
                }
                field("Promotion End Date"; Rec."Promotion End Date")
                {
                    ApplicationArea = All;
                    trigger OnValidate()
                    begin
                        CurrPage.Update(true);
                    end;
                }
                field("Promotion SKU"; Rec."Promotion SKU")
                {
                    ApplicationArea = All;
                    trigger OnDrillDown()
                    var
                        PromoSku:Record "HL Promotion Sku";
                        Pg:page "HL Promotion SKU";
                    Begin
                        PromoSku.Reset;
                        PromoSku.Setrange("Promotion Type",Rec."Promotion Type");
                        PromoSku.Setrange("Promotion Code",rec."Promotion Code");
                        PromoSku.Setrange("Promotion Period",Rec."Promotion Period");
                        If PromoSku.findset then
                        begin
                            PG.SetTableView(PromoSku);
                            Pg.RunModal();
                        end;                  
                   End;    
                }
                field("Promotion Activation Date";Rec."Promotion Activation Date")
                {
                    ApplicationArea = All;
                }
            }    
        }
    }
    actions
    {
        area(Processing)
        {
            Action(Ref)
            {
                ApplicationArea = All;
                Caption = 'Refresh Promotion SKU''s';
                Image = Change;
                Promoted = true;
                PromotedIsBig = true;
                trigger OnAction()
                var
                    Item:record Item;
                    PromSKU:Record "HL Promotion Sku";
                    Prom:Record "HL Promotions";
                    Win:dialog;
                    Cnt:Integer;
                    i:Integer;
                begin
                    Clear(Cnt);
                    If Confirm('Refresh Promotional SKU''s Now?', True) then
                    begin
                        Win.Open('Refreshing SKU #1##############');
                        Prom.Reset;
                        If Prom.Findset then
                        Repeat
                            Item.Reset;
                            Item.Setrange(Type,Item.Type::Inventory);
                            If Prom."Promotion Type" = Prom."Promotion Type"::Category then
                                Item.Setrange("Shopify Category Name",Prom."Promotion Code")
                            else
                                Item.Setrange(Brand,Prom."Promotion Code");   
                            If Item.Findset then
                            repeat
                                Win.Update(1,Item."No.");
                                For i:= 1 to 3 do
                                Begin
                                    If Not PromSKU.Get(i,Prom."Promotion Type",Prom."Promotion Code",Item."No.") Then
                                    begin
                                        Cnt+=1;
                                        PromSKU.Init();
                                        PromSKU."Promotion Period" := i;
                                        PromSKU.Brand := Item.Brand;
                                        PromSKU."Promotion Type" := Prom."Promotion Type";
                                        PromSKU."Promotion Code" := Prom."Promotion Code";
                                        PromSKU.SKU := Item."No.";
                                        PromSKU.Insert()
                                    end;
                                end;    
                            until Item.next = 0;
                        Until Prom.Next = 0;
                        Win.close;
                        If Cnt > 0 then
                            Message('%1 New Promo SKUS found suggest Promotion Activation Required to include detected Promo SKU''s',Cnt);
                    end;        
                    CurrPage.update(false);
                end;
            }
        }        
    }
    Local Procedure Add_Items(Period:Integer;PromoType:Option Category,Brand;PromCode:code[30])
    var
        Item:record Item;
        PromSku:record "HL Promotion Sku";
    begin
        Item.Reset;
        If PromoType = PromoType::Brand then
            Item.Setrange(Brand,PromCode)
        else
            Item.Setrange("Shopify Category Name",PromCode);
        If Item.Findset then
        repeat
            If Not PromSKU.Get(Period,PromoType,PromCode,Item."No.") Then
            begin
                PromSKU.Init();
                PromSKU."Promotion Period" := Period;
                PromSKU.Brand := Item.Brand;
                PromSKU."Promotion Type" := PromoType;
                PromSKU."Promotion Code" := PromCode;
                PromSKU.SKU := Item."No.";
                PromSKU.Insert();
            end;
        until Item.next = 0;        
    end;
    trigger OnOpenPage()
    Var
        DimVal:record "Dimension Value";
        DefDim:record "Default Dimension";
        Item:record Item;
        Win:dialog;
        i:Integer;
    begin
        If GuiAllowed then Win.Open('Intialising Promotions .... #1##############');
        DimVal.Reset;
        DimVal.Setrange("Dimension Code",'DEPARTMENT');
        If DimVal.FindSet then
        repeat
            If GuiAllowed then Win.Update(1, DimVal.Name.Replace(',','_'));
            For i := 1 to 3 do
            Begin
                If Not Rec.Get(i,Rec."Promotion Type"::Category, DimVal.Name.Replace(',','_')) then
                begin
                    Rec.init;
                    Rec."Promotion Period" := i;
                    Rec."Promotion Type" := Rec."Promotion Type"::Category;
                    Rec."Promotion Code" := DimVal.Name.Replace(',','_');
                    Rec.insert();
                    Add_Items(i,Rec."Promotion Type",Rec."Promotion Code");
                end;
            end;        
        Until DimVal.Next = 0;
        DimVal.Setrange("Dimension Code",'BRAND');
        If DimVal.FindSet then
        repeat
            DefDim.Reset;
            DefDim.Setrange("Table ID",Database::Item);
            DefDim.Setrange("Dimension Code",Dimval."Dimension Code");
            DefDim.Setrange("Dimension Value Code",Dimval.Code);
            If DefDim.FindSet() Then
                If Item.Get(DefDim."No.") then
                begin
                    If GuiAllowed then Win.Update(1, Item.Brand);
                    For i:= 1 to 3 do
                    Begin
                        If Not Rec.Get(i,Rec."Promotion Type"::Brand,Item.Brand) then
                        begin
                            Rec.init;
                            Rec."Promotion Period" := i;
                            rec."Promotion Type" := Rec."Promotion Type"::Brand;
                            rec."Promotion Code" := Item.Brand;
                            Rec.insert();
                            Add_Items(i,Rec."Promotion Type",Rec."Promotion Code");
                        end;
                    end;
                end;        
        Until DimVal.Next = 0;
        If GuiAllowed then Win.Close;
        PromoType := PromoType::Category;
        Periods := Periods::All;
        Setfilters();
    end;
    local procedure Activate_Promotion()
    var
        Prom:Array[2] of record "HL Promotions";
        PromSku:Array[2] of record "HL Promotion Sku";
        Spricing:record "HL Shopfiy Pricing";
        Item:record Item;
        i,j:Integer;
        win:Dialog;
        Cu:Codeunit "HL Shopify Routines";
        RRP:Decimal;
        Cnt:Integer;
    Begin
        CurrPage.Update(True);
        Clear(Cnt);
        If Confirm('Activate Promotion Now ?',True) then
        Begin
            If GuiAllowed then Win.Open('Checking Promotion Date OverLaps #1#############');
            For i := 1 to 3 Do
            Begin
                Prom[1].Reset;
                Prom[1].Setrange("Promotion Period",i);
                Prom[1].Setfilter("RRP Discount %",'>0');
                Prom[1].Setfilter("Promotion Start Date",'<>%1',0D);
                Prom[1].Setfilter("Promotion End Date",'>%1',Today);
                If Prom[1].Findset then
                repeat
                    For j := 1 to 3 do
                    begin
                        If j <> i then 
                        Begin
                            Prom[2].Reset;
                            Prom[2].Setrange("Promotion Period",j);
                            Prom[2].Setfilter("RRP Discount %",'>0');
                            Prom[2].Setfilter("Promotion Start Date",'<>%1',0D);
                            Prom[2].Setfilter("Promotion End Date",'>%1',Today);
                            If Prom[2].Findset then
                                If (Prom[2]."Promotion Start Date" = Prom[1]."Promotion Start Date") Or
                                (Prom[2]."Promotion End Date" = Prom[1]."Promotion End Date") or
                                ((Prom[2]."Promotion Start Date" < Prom[1]."Promotion Start Date") AND 
                                (Prom[2]."Promotion End Date" >=  Prom[1]."Promotion Start Date")) Or
                                ((Prom[2]."Promotion End Date" > Prom[1]."Promotion End Date") AND 
                                (Prom[2]."Promotion Start Date" <= Prom[1]."Promotion End Date")) then
                                        Error(StrsubStno('Promotion Code %1 Promotion Dates Overlap .. Correct and Retry',Prom[2]."Promotion Code"));      
                        end;
                    end;    
                until Prom[1].next = 0;
            end;
            If GuiAllowed then 
            begin
                Win.Close;
                Win.Open('Checking Category/Brand Promotion Date OverLaps #1#############');
            end;    
            For i := 1 to 3 Do
            Begin
                Prom[1].Reset;
                Prom[1].Setrange("Promotion Period",i);
                Prom[1].SetRange("Promotion Type",Prom[1]."Promotion Type"::Category);
                Prom[1].Setfilter("RRP Discount %",'>0');
                Prom[1].Setfilter("Promotion Start Date",'<>%1',0D);
                Prom[1].Setfilter("Promotion End Date",'>%1',Today);
                If Prom[1].Findset then
                repeat
                    PromSku[1].Reset;
                    PromSku[1].Setrange("Promotion Period",i);
                    PromSku[1].SetRange("Promotion Type",Prom[1]."Promotion Type");
                    PromSku[1].Setrange("Promotion Code",Prom[1]."Promotion Code");
                    PromSku[1].Setrange("Used In Promotion",True);
                    If PromSku[1].FindSet() then
                    repeat
                        Item.Get(PromSku[1].SKU);
                        For j := 1 to 3 do
                        begin
                            // Look at the equivalent Brand SKU now across all the periods
                            PromSku[2].Reset;
                            PromSku[2].Setrange("Promotion Period",j);
                            PromSku[2].SetRange("Promotion Type",PromSku[2]."Promotion Type"::Brand);
                            PromSku[2].Setrange("Promotion Code",Item.Brand);
                            PromSku[2].Setrange(SKU,PromSku[1].SKU);
                            PromSku[2].Setrange("Used In Promotion",True);
                            If PromSku[2].Findset then
                            Begin
                                Win.update(1,PromSku[2]."Promotion Code");
                                // now get the brand promotions associated with this SKU
                                Prom[2].Reset;
                                prom[2].setrange("Promotion Period",PromSku[2]."Promotion Period");
                                Prom[2].Setrange("Promotion Type",PromSKU[2]."Promotion Type");
                                Prom[2].Setfilter("RRP Discount %",'>0');
                                Prom[2].Setfilter("Promotion Start Date",'<>%1',0D);
                                Prom[2].Setfilter("Promotion End Date",'>%1',Today);
                                If Prom[2].Findset then
                                    If  (Prom[2]."Promotion Start Date" = Prom[1]."Promotion Start Date") Or
                                        (Prom[2]."Promotion End Date" = Prom[1]."Promotion End Date") or
                                        ((Prom[2]."Promotion Start Date" < Prom[1]."Promotion Start Date") AND 
                                        (Prom[2]."Promotion End Date" >=  Prom[1]."Promotion Start Date")) Or
                                        ((Prom[2]."Promotion End Date" > Prom[1]."Promotion End Date") AND 
                                        (Prom[2]."Promotion Start Date" <= Prom[1]."Promotion End Date")) then
                                            Error(StrsubStno('Category %1 Promotion Dates Overlapp with Brand %2 Promotion Dates .. Correct and Retry',Prom[1]."Promotion Code",Prom[2]."Promotion Code"));
                            end;
                        end;
                    until PromSku[1].next = 0;
                until Prom[1].next = 0;
            end;
            If GuiAllowed then 
            begin
                Win.Close;
                Win.Open('Adding Promotion Pricing Entry For #1##################');
            end;
            Clear(Cnt);    
            Spricing.Reset;
            Spricing.Setrange("Promotion Entry",True);
            If Spricing.Findset then Spricing.DeleteAll();
            Prom[1].Reset;
            Prom[1].Setfilter("RRP Discount %",'>0');
            Prom[1].Setfilter("Promotion Start Date",'<>%1',0D);
            Prom[1].Setfilter("Promotion End Date",'>%1',Today);
            If Prom[1].Findset then
            repeat
                PromSku[1].Reset;
                PromSku[1].Setrange("Promotion Period",Prom[1]."Promotion Period");
                PromSku[1].SetRange("Promotion Type",Prom[1]."Promotion Type");
                PromSku[1].Setrange("Promotion Code",Prom[1]."Promotion Code");
                PromSku[1].Setrange("Used In Promotion",True);
                If PromSku[1].FindSet() then
                repeat
                    Spricing.Reset;
                    Spricing.Setrange("Item No.",PromSku[1].SKU);
                    Spricing.Setrange("Ending Date",0D);
                    Spricing.Setfilter("New RRP Price",'>0');
                    if Spricing.FindSet() then
                    begin
                        RRP := Spricing."New RRP Price";
                        Cnt +=1;    
                        Win.Update(1,PromSku[1].SKU);
                        If Not Spricing.get(PromSku[1].SKU,Prom[1]."Promotion Start Date") then
                        begin
                            Spricing.init;
                            Spricing."Item No." := PromSku[1].SKU;
                            Spricing."Starting Date" := Prom[1]."Promotion Start Date";
                            Spricing.Insert(False);
                        end;
                        Spricing."Promotion Code" := Prom[1]."Promotion Code";
                        Spricing."Promotion Period" := Prom[1]."Promotion Period";
                        Spricing."Promotion Entry" := True;
                        Spricing."Sell Price" := RRP - (RRP * Prom[1]."RRP Discount %"/100);
                        Spricing."Platinum Member Disc %" := 0;
                        Spricing."Platinum + Auto Disc %" := 0;
                        Spricing."Gold Member Disc %" := 0;
                        Spricing."Gold + Auto Disc %" := 0;
                        Spricing."Silver Member Disc %" := 0;
                        Spricing."Auto Order Disc %" := 0;
                        Spricing."VIP Disc %" := 0;
                        Spricing."New RRP Price" := RRP;
                        Spricing."Ending Date" := Prom[1]."Promotion End Date";
                        Spricing.Modify(False);
                    end;    
                Until PromSku[1].Next = 0;         
            until Prom[1].next = 0;
            Commit;
            If GuiAllowed then Win.Close;
            Cu.Correct_Sales_Prices('');
            Prom[1].Reset;
            if Prom[1]. Findset then
                Prom[1].ModifyAll("Promotion Activation Date",CurrentDateTime,False);
            If Cnt > 0 then
                Message('%1 Promotion SKU Price Entries have been created',Cnt);
        end;    
    End;
    local procedure Setfilters()
    Begin
        Rec.Reset;
        If PromoType <> PromoType::ALL then
            Rec.Setrange("Promotion Type",PromoType - 1);
        If Periods <> Periods::All then
            Rec.Setrange("Promotion Period",Periods);
        if Vars <> '' then 
            Rec.Setrange("Promotion Code",Vars);
        CurrPage.Update(False);        
    End;

    var
        PromoType:Option ALL,Category,Brand;
        Periods:Option All,"Period 1","Period 2","Period 3";
        Vars:code[30];

}
