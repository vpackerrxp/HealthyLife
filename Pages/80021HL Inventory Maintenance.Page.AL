page 80021 "HL Inventory Maintenance"
{
    Caption = 'Inventory Maintenance';
    PageType = Worksheet;
    UsageCategory = Tasks;
    ApplicationArea = All;
    SourceTable = Item;
    SourceTableView = where(type=Const(Inventory));
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
                field("Location Filter"; LOC)
                {
                    ApplicationArea = All;
                    TableRelation = Location where("Use As In-Transit"=Const(false),Code=filter(<>'QC'));
                    trigger OnValidate()
                    begin
                        SetFilters();
                    end;
                    trigger OnAssistEdit()
                    begin
                        Clear(LOC);
                        SetFilters();
                    end;
                }                   
                field("SKU Filter";Sku)
                {
                    ApplicationArea = all;
                    Style = Strong;
                    TableRelation = Item where(type=Const(Inventory));
                    trigger OnValidate()
                    begin 
                        If not SkuLst.Contains(Sku) then
                            Skulst += SKU + '|';
                        Clear(sku);
                        SetFilters();   
                    end;
                    trigger OnAssistEdit()
                    begin
                        Clear(SKU);
                        Clear(SkuLst);
                        SetFilters();   
                    end;
                }
                Field("Sku List";Skulst)
                {
                    ApplicationArea = All;
                    Style = Strong;
                    MultiLine = true;
                    Editable = false;    
                }        
                field("Supplier Filter";Supp)
                {
                    ApplicationArea = all;
                    Style = Strong;
                    TableRelation = Vendor where("No."=Filter('SUP-*'));
                    trigger OnValidate()
                    var
                        Ven:Record Vendor;
                    begin 
                        Clear(Name);
                        If Ven.get(Supp) then Name := Ven.Name;    
                        SetFilters();   
                    end;
                    trigger OnAssistEdit()
                    begin
                        Clear(Supp);
                        Clear(Name);
                        SetFilters();   
                    end;
                }
                /*  Group(Brand)
                {
                    ShowCaption = false;
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
                                If not BranLst.Contains(Rel.Brand) then
                                    Branlst += Rel.Brand + '|';
                                Clear(Bran);
                                SetFilters();   
                             end;      
                        end; 
                        trigger OnAssistEdit()
                        begin
                            Clear(Bran);
                            Clear(Branlst);
                            SetFilters();   
                        end;
                    }
                    Field("Brand List";Branlst)
                    {
                        ApplicationArea = All;
                        Style = Strong;
                        MultiLine = true;
                        Editable = false;    
                    }        
                }*/
                field("A";'Clear All Filters')
                {
                    ApplicationArea = all;
                    Style = Strong;
                    ShowCaption = false;
                    trigger OnDrillDown()
                    begin
                        Clear(Supp);
                        Clear(Loc);
                        Clear(name);
                        Clear(SkuLst);
                        CLear(SKU);
                        Clear(Bran);
                        Clear(Branlst);
                        Clear(Inc);
                        Rec.ClearMarks();
                        SetFilters();
                    end;    
                }
                field("B";'Refresh NPF Data')
                {
                    ApplicationArea = all;
                    Style = Strong;
                    ShowCaption = false;
                    trigger OnDrillDown()
                    var
                        Cu:Codeunit "HL NPF Routines";
                    begin
                        Clear(Supp);
                        Clear(Loc);
                        Clear(name);
                        Clear(SkuLst);
                        CLear(SKU);
                        Clear(Bran);
                        Clear(Branlst);
                        Clear(Inc);
                        Rec.ClearMarks();
                        SetFilters();
                        If Confirm('Refresh NPF Data Now',True) then
                            Cu.Build_NPF_Inventory_Levels('*');      
                    end;    
                }
                field("C";'Show Adjustments Only')
                {
                    ApplicationArea = all;
                    Style = Strong;
                    ShowCaption = false;
                    Enabled = EnbFlg;
                    trigger OnDrillDown()
                    var
                    begin
                        SetFilters();
                        if Rec.Findset then
                        repeat
                            rec.Mark(rec."NPF Inventory" - (rec.Inventory + rec."NPF Qty On PO") <> 0); 
                        Until Rec.next = 0;    
                        rec.MarkedOnly(true);
                        CurrPage.update(false);
                    end;
                }
                field("D";'Show All')
                {
                    ApplicationArea = all;
                    Style = Strong;
                    ShowCaption = false;
                    Enabled = EnbFlg;
                    trigger OnDrillDown()
                    var
                    begin
                        Rec.ClearMarks();
                        SetFilters();
                    end;
                }
            }    
            repeater(Group)
            {
                field("Item No."; rec."No.")
                {
                    ApplicationArea = All;
                    trigger OnDrillDown();
                    var
                        Pg:page "Item Card";
                    begin
                        Pg.SetRecord(Rec);
                        Pg.runmodal;     
                        CurrPage.update(false);
                     end;
                }
                field(Description; rec.Description)
                {
                    ApplicationArea = All;
                }
                field("Unit Cost"; rec."Unit Cost")
                {
                    ApplicationArea = All;
                }
                field("BC Inventory"; rec.Inventory)
                {
                    ApplicationArea = All;
                    Caption = 'BC Inventory';
                }
                field("Qty On PO"; rec."Qty. on Purch. Order")
                {
                    ApplicationArea = All;
                }
                field("NPF Qty On PO"; rec."NPF Qty On PO")
                {
                    ApplicationArea = All;
                    Caption = 'NPF Qty On PO';
                }
                field("NPF Inventory Qty"; rec."NPF Inventory")
                {
                    ApplicationArea = All;
                    Caption = 'NPF Inventory Qty';
                    Style = Strong;
                }
                field("Calc Adjust Qty Required";Adjst)
                {
                    ApplicationArea = All;
                    DecimalPlaces = 0:5;
                    Editable = false;
                    trigger OnAssistEdit()
                    var
                        Cu:Codeunit "HL NPF Routines";
                        Loc:record Location;
                        Item:Record Item;
                        //Res:Record "PC Fulfilo Inv. Delta Reasons";
                        //Res2:Record "PC Fulfilo Inv. Delta Reasons" temporary;
                        Qty:Decimal;
                    begin
                        If Adjst <> 0 Then 
                            If Confirm('Perform The Required Qty Adjustment Now',True) then
                            begin
                                Item.Get(Rec."No.");
                                Loc.Reset;
                                Loc.Setrange("Use As In-Transit",false);
                                Loc.Setfilter(Code,'<>QC');    
                                If Loc.Findset then
                                repeat
                                    Item.SetFilter("Location Filter",Loc.Code);
                                    Item.Calcfields(Inventory,"NPF Inventory","NPF Qty On PO");
                                    Qty := Item."NPF Inventory" - (Item.Inventory + Item."NPF Qty On PO");
                                    If Qty <> 0 then CU.Adjust_Inventory(Item,Loc.Code,qty);
                               until Loc.Next = 0;
                            end;    
                    end;
                }
                field("MA";'Manual Adjust')
                {
                    ApplicationArea = All;
                    ShowCaption = False;
                    Style = Strong;
                    trigger OnDrillDown()
                    var
                        Pg:page "HL Adjust Inventory";
                    begin
                        Pg.SetItem(rec."No.");
                        Pg.RunModal();
                        CurrPage.Update(false);
                    end;
                }

                field("Calc Adjustment Cost";Adjst * Rec."Unit Cost")
                {
                    ApplicationArea = All;
                    DecimalPlaces = 2:2;
                }
            }
            Group(Totals)
            {
                field("Record Count";Rec.Count)
                {
                        ApplicationArea = All;
                        Editable = false;
                }
                field("Total Adjust Costs";TotCst)
                {
                    ApplicationArea = All;
                    Editable = false;
                    trigger OnAssistEdit()
                    begin
                        TotCst := Calc_Adjust_Costs();
                        CurrPage.update(false);
                    end;
                }
            }                    
        }
    }
    actions
    {
        area(Processing)
        {
            action(Adjustments)
            {
                ApplicationArea = All;
                
                trigger OnAction();
                var
                    Item:record Item;
                    Loc:Record Location;
                    Qty:Decimal;
                    Cu:Codeunit "HL NPF Routines";
                    win:Dialog;
                    //Res:Record "PC Fulfilo Inv. Delta Reasons";
                    //Res2:Record "PC Fulfilo Inv. Delta Reasons" temporary;
                 begin
                    If Confirm('Do You Wish To Make The Required Qty Adjustments For All Locations Now',True) then
                    begin
                        win.Open('Adjusting SKU #1############ For Location #2########');
                        Clear(Loc);
                        SetFilters();
                        If Rec.Findset then
                        repeat
                            Item.Get(Rec."No.");
                            Loc.Reset;
                            Loc.Setrange("Use As In-Transit",false);
                            Loc.Setfilter(Code,'<>QC');    
                            If Loc.Findset then
                            repeat
                                Item.SetFilter("Location Filter",Loc.Code);
                                Item.Calcfields(Inventory,"NPF Inventory","NPF Qty On PO");
                                Qty := Item."NPF Inventory" - (Item.Inventory + Item."NPF Qty On PO");
                                If Qty <> 0 then
                                begin
                                    Win.update(1,Item."No.");
                                    win.update(2,Loc.Code); 
                                    CU.Adjust_Inventory(Item,Loc.Code,qty);
                               end;        
                            until Loc.Next = 0;
                        until rec.next = 0;
                        win.Close();            
                    end;
                end;
            }
        }
    }
    trigger OnOpenPage()
    var
        Cu:Codeunit "HL NPF Routines";
    begin
        Offset := 7;    
        Cu.Build_NPF_Inventory_Levels('*');
        Clear(Supp);
        Clear(Loc);
        Clear(name);
        Clear(SkuLst);
        CLear(SKU);
        Clear(Bran);
        Clear(Branlst);
        Clear(Inc);
        Rec.ClearMarks();
        SetFilters();
        EnbFlg := True;
    end;
    trigger OnAfterGetRecord()
    begin
        Clear(Adjst);
        Adjst := rec."NPF Inventory" - (rec.Inventory + rec."NPF Qty On PO");
    end;
    local procedure Calc_Adjust_Costs():Decimal
    var
        totCst:Decimal;
    begin
        Clear(TotCst);
        If rec.findset then
        repeat
            totCst += ABS((rec."NPF Inventory" - (rec.Inventory + rec."NPF Qty On PO")) * Rec."Unit Cost");
        until Rec.next = 0; 
        exit(Totcst);   
    end;
    local Procedure SetFilters()
    begin
        Rec.Reset;
        Rec.Setrange(Type,Rec.Type::Inventory);
        If Loc <> '' then rec.Setrange("Location Filter",LOC);
        If Supp <> '' then rec.SetRange("Vendor No.",SUPP);
        //if Branlst <> '' Then rec.SetFilter(Brand,Branlst.Remove(Branlst.LastIndexOf('|'),1));
        If Skulst <> '' then rec.Setfilter("No.",Skulst.Remove(Skulst.LastIndexOf('|'),1));
        TotCst := Calc_Adjust_Costs();
        CurrPage.update(false);   
    end;
     var
        Loc:code[10];
        Sku:Code[20];
        Supp:Code[20];
        Name:text;
        SkuLst:text;
        Adjst:decimal;
        TotCst:Decimal;
        EnbFlg:Boolean;
        Offset:Integer;
        Bran:Code[30];
        Branlst:text;
        Inc:Boolean;
            
}