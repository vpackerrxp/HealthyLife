page 80012 "HL Rebate Sales"
{
    Caption = 'Rebate Sales';
    PageType = Worksheet;
    SourceTable = "HL Rebate Sales";
    
    layout
    {
        area(content)
        {
            Group(Filters)
            {
                field("P";Periods)
                {
                    ApplicationArea = All;
                    Caption = 'Periods Filter';
                    Style = Strong;
                    trigger OnValidate()
                    begin
                        Clear(ShowImp);  
                        Setfilters();
                    end;
                }
                field("Brand Filter";vars)
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
                            Vars := rel.Brand;
                            SetFilters();
                        end;      
                    end; 
                    trigger OnAssistEdit()
                    begin
                        Clear(Vars);
                        SetFilters();
                    end;
                }
                field("Show Import/Export";ShowImp)
                {
                    ApplicationArea = All;
                    Style = Strong;
                    trigger OnValidate()
                    var
                    Begin
                        If ShowImp then
                            Periods := Periods::"1"
                        else
                            Periods := Periods::All;   
                        Setfilters();
                    end;
                }
            }
            Group(Process)
            {
               Field("C";'Activate Rebates')
                {
                    ApplicationArea = All;
                    ShowCaption = False;
                    Style = StrongAccent;
                    trigger OnDrillDown()
                    begin
                        Activate_Rebates();
                        CurrPage.Update(false);
                    end;    
                }
            }
            repeater(General)
            {
                field("Import/Export";Msg)
                {
                    ApplicationArea = All;
                    Style = Strong;
                    Editable = False;
                    trigger OnDrillDown()
                    var
                        Cu:Codeunit "HL Import Export Routines";
                    begin
                        If Msg.ToUpper().Contains('IMPORT') then
                            Case Strmenu('Export ' + Rec.Brand +',Import',1) of
                                1:Cu.Export_Rebates(Rec.Brand);
                                2:
                                begin
                                    Cu.Import_Rebates(Vars);
                                    Periods := Periods::All;
                                    Clear(ShowImp);
                                    Setfilters();
                                end;    
                            end;    
                    end;    
                }
                field("Rebate Period"; Rec."Rebate Period")
                {
                    ApplicationArea = All;
                }
                field(Brand; Rec.Brand)
                {
                    ApplicationArea = All;
                }
                field("Rebate Sale Start Date"; Rec."Rebate Sale Start Date")
                {
                    ApplicationArea = All;
                }
                field("Rebate Sale End Date"; Rec."Rebate Sale End Date")
                {
                    ApplicationArea = All;
                }
                field("Rebate Sales SKU"; Rec."Rebate Sales SKU")
                {
                    ApplicationArea = All;
                    trigger OnDrillDown()
                    var
                        RebSku:Record "HL Rebate Sales Sku";
                        Pg:page "HL Rebate Sales SKU";
                    Begin
                        RebSku.Reset;
                        RebSku.Setrange("Rebate Period",rec."Rebate Period");
                        RebSku.Setrange(Brand,Rec.Brand);
                        If RebSku.findset then
                        begin
                            PG.SetTableView(rebSku);
                            Pg.RunModal();
                        end;                  
                   End;    
                }
                field("Rebate Activation Date";rec."Rebate Activation Date")
                {
                    ApplicationArea = All;
                }
                
            }
        }
    }

    trigger OnOpenPage()
    Var
        DimVal:record "Dimension Value";
        DefDim:record "Default Dimension";
        Item:record Item;
        Win:dialog;
        i:Integer;
    begin
        If GuiAllowed then Win.Open('Intialising Rebates .... #1############');
        DimVal.Reset;
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
                    For i:= 1 to 20 do
                    Begin
                        If Not Rec.Get(i,Item.Brand) then
                        begin
                            Rec.init;
                            Rec."Rebate Period" := i;
                            rec.Brand := Item.Brand;
                            Rec.insert();
                            Add_Items(i,Rec.Brand);
                        end;
                    end;
                end;        
        Until DimVal.Next = 0;



        If GuiAllowed then Win.Close;
        Periods := Periods::All;
        Setfilters();
    end;
    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        DateT:DateTime;
    begin
        Clear(DateT);
        Rec.Reset;
        Rec.SetRange("Rebate Activation Date",DateT);
        If Rec.FindSet() then
            Error('All Rebates have not been activated .. correct and retry');
    end;
    trigger OnAfterGetRecord()
    begin
        Msg := '*';
        If Rec."Rebate Period" = 1 then
            Msg:= 'Import/Export';
    end;
    local procedure Activate_Rebates()
    var
        Reb:Array[2] of record "HL Rebate Sales";
        i,j:Integer;
        win:Dialog;
        dTime:DateTime;
    Begin
        CurrPage.Update(True);
        If Confirm('Activate Rebate Now ?',True) then
        Begin
            Clear(Dtime);
            Reb[1].Reset;
            If Reb[1].FindSet() then
                Reb[1].ModifyAll("Rebate Activation Date",Dtime,False);
            If GuiAllowed then Win.Open('Checking Rebate Date OverLaps #1#############');
            For i := 1 to 20 Do
            Begin
                Reb[1].Reset;
                Reb[1].Setrange("Rebate Period",i);
                Reb[1].Setfilter("Rebate Sale Start Date",'<>%1',0D);
                Reb[1].Setfilter("Rebate Sale End Date",'<>%1',0D);
                If Reb[1].Findset then
                repeat
                    For j := 1 to 20 do
                    begin
                        if j <> i then
                        begin 
                            Reb[2].Reset;
                            Reb[2].Setrange("Rebate Period",j);
                            Reb[2].Setfilter("Rebate Sale Start Date",'<>%1',0D);
                            Reb[2].Setfilter("Rebate Sale End Date",'<>%1',0D);
                            If Reb[2].Findset then
                                If (Reb[2]."Rebate Sale Start Date" = Reb[1]."Rebate Sale Start Date") Or
                                (Reb[2]."Rebate Sale End Date" = Reb[1]."Rebate Sale End Date") or
                                ((Reb[2]."Rebate Sale Start Date" < Reb[1]."Rebate Sale Start Date") AND 
                                (Reb[2]."Rebate Sale End Date" >=  Reb[1]."Rebate Sale Start Date")) Or
                                ((Reb[2]."Rebate Sale End Date" > Reb[1]."Rebate Sale End Date") AND 
                                (Reb[2]."Rebate Sale Start Date" <= Reb[1]."Rebate Sale End Date")) then
                                        Error(StrsubStno('Brand %1 Rebate Sale Dates Overlap .. Correct and Retry',Reb[2].Brand)); 
                        end;                     
                    end;
                until Reb[1].next = 0;
            end;
            If GuiAllowed then Win.Close;
            Reb[1].Reset;
            If Reb[1].FindSet() then
                Reb[1].ModifyAll("Rebate Activation Date",CurrentDateTime,False);
            CurrPage.Update(false);    
        end;
    end;

    Local Procedure Add_Items(Period:Integer;Brand:code[30])
    var
        Item:record Item;
        RSku:record "HL Rebate Sales Sku";
    begin
        Item.Reset;
        Item.Setrange(Brand,Brand);
        If Item.Findset then
        repeat
            If Not RSKU.Get(Period,Brand,Item."No.") Then
            begin
                RSKU.Init();
                RSKU."Rebate Period" := Period;
                RSKU.Brand := Item.Brand;
                RSKU.SKU := Item."No.";
                RSkU."Rebate Wholesale Cost" := Item."Rebate Wholesale Cost";
                RSKU.Insert();
            end;
        until Item.next = 0;        
    end;
    local procedure Setfilters()
    Begin
        Rec.Reset;
         If Periods <> Periods::All then
            Rec.Setrange("Rebate Period",Periods);
        if Vars <> '' then 
            Rec.Setrange(Brand,Vars);
        CurrPage.Update(False);        
    End;
    var
        Vars:code[30];
        Periods:Option All,"1","2","3","4","5","6","7","8"
                        ,"9","10","11","12","13","14","15",
                        "16","17","18","19","20";
        Msg:text;
        ShowImp:Boolean;
}
