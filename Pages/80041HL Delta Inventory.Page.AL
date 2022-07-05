page 80041 "HL Delta Inventory"
{
    PageType = Worksheet;
    ApplicationArea = All;
    UsageCategory = Tasks;
    SourceTable = "HL NPF Inventory Transactions";
    Caption = 'Delta Inventory Adjustments';
       
    layout
    {
        area(Content)
        {
            group(Filters)
            {
                field("From Posting Date Filter"; PostDate[1])
                {
                    ApplicationArea = All;
                    Style = Strong;
                    trigger OnValidate()
                    begin
                        If Postdate[2] <> 0D then
                            if Postdate[1] > Postdate[2] then Clear(Postdate[1]);
                        SetFilters();
                    end;

                    trigger OnAssistEdit()
                    begin
                        Clear(POstdate[1]);
                        SetFilters();
                    end;
                }
                field("To Posting Date Filter"; Postdate[2])
                {
                    ApplicationArea = All;
                    Style = Strong;
                    trigger OnValidate()
                    begin
                        If Postdate[1] <> 0D then
                            if Postdate[2] < Postdate[1] then Clear(Postdate[2]);
                        SetFilters();
                    end;

                    trigger OnAssistEdit()
                    begin
                        Clear(Postdate[2]);
                        SetFilters();
                    end;
                }
                field("SKU Filter";SkuNo)
                {
                    ApplicationArea = all;
                    Style = Strong;
                    TableRelation = Item where(type=Const(Inventory));
                    trigger OnValidate()
                    begin 
                        If not SkuLst.Contains(SkuNo) then
                            Skulst += SKUNo + '|';
                        Clear(skuNo);
                        SetFilters();   
                    end;
                    trigger OnAssistEdit()
                    begin
                        Clear(SKUNo);
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
                field("Adjustment Filter";Adjust)
                {
                    ApplicationArea = All;
                    Style = Strong;
                    trigger OnValidate()
                    begin
                       SetFilters();
                    end;
                }
                field("A";'Refresh Inventory Deltas')
                {
                    ApplicationArea = all;
                    Style = Strong;
                    ShowCaption = false;
                    trigger OnDrillDown()
                    var
                        Cu:Codeunit "HL NPF Routines";
                    begin
                        Clear(SKUNo);
                        Clear(SkuLst);
                        Clear(PostDate);
                        If Confirm('Refresh Inventory Delta Data Now',True) then
                            Cu.Build_NPF_Inventory_Transaction();     
                        SetFilters();
                    end;    
                }
            }    
            repeater(GroupName)
            {
                field("Transaction ID";rec."Transaction ID")
                {
                    ApplicationArea = All;
                }
                field(PostingDateTime;rec.PostingDateTime)
                {
                    ApplicationArea = All;
                }
                field(SKU;rec.SKU)
                {
                    ApplicationArea = All;
                    trigger OnDrillDown()
                    var
                        Pg:Page "Item Card";
                        Item:record Item;
                    begin
                        if Item.Get(rec.SKU) then
                        begin
                            Pg.SetRecord(Item);
                            Pg.RunModal();
                        end;    
                    end;    

                }
                field(Qty;rec.Qty)
                {
                    ApplicationArea = All;
                    trigger OnDrillDown()
                    var
                        Cu:Codeunit "HL NPF Routines";
                        item:record Item;
                        val:Decimal;
                    begin
                        If Rec."Adjusted Status" = Rec."Adjusted Status"::Unajusted then
                        begin
                            Clear(Val);
                            Case Strmenu(StrSubstNo('Postive Adjust Qty = %1,Negective Adjust Qty = %1',Rec.Qty),1) of
                                1: val := Rec.Qty;
                                2: val := -Rec.Qty;
                            end;
                            if Val <> 0 then
                            begin    
                                if Item.Get(Rec.SKU) then
                                begin
                                    If Cu.Adjust_Inventory(item,'NSW',val) then 
                                    begin
                                        rec."Adjusted Status" := Rec."Adjusted Status"::Adjusted;
                                        Rec.Modify();
                                    end 
                                    else
                                        Message(GetLastErrorText());
                                    CurrPage.Update(False);
                                end;           
                            end;
                        end;
                    end;    
                }
                field("Current Stock Level";Get_Stock_Level())
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field(UOM;rec.UOM)
                {
                    ApplicationArea = All;
                }
                field("Batch No";rec."Batch No")
                {
                    ApplicationArea = All;
                }
                field("Expiry Date";rec."Expiry Date")
                {
                    ApplicationArea = All;
                }
                field("Transaction Type";rec."Transaction Type")
                {
                    ApplicationArea = All;
                }
                field("Transaction Name";rec."Transaction Name")
                {
                    ApplicationArea = All;
                }
                field("Reason Description";rec."Reason Description")
                {
                    ApplicationArea = All;
                }
                field("Adjusted Status";rec."Adjusted Status")
                {
                    ApplicationArea = All;
                    StyleExpr = Styler;
                }
            }
        }
    }
    trigger OnAfterGetRecord()
    begin
        Styler := 'unfavorable';
        If rec."Adjusted Status" = Rec."Adjusted Status"::Adjusted then
            Styler := 'favorable';
    end;
    local Procedure SetFilters()
    begin
        Rec.Reset;
        if (Postdate[1] <> 0D) AND (Postdate[2] <> 0D) then
            rec.SetRange(PostingDateTime,Createdatetime(Postdate[1],0T), CreatedateTime(Postdate[2],0T))
        else if (Postdate[1] <> 0D) then
            rec.Setfilter(PostingDateTime, '%1..',CreateDateTime(Postdate[1],0T))
        else if (Postdate[2] <> 0D) then
            rec.Setfilter(PostingDateTime, '..%1', CreateDateTime(Postdate[2],0T));
        If Skulst <> '' then rec.Setfilter(SKU,Skulst.Remove(Skulst.LastIndexOf('|'),1));
        if Adjust <> Adjust::All then
            Rec.Setrange("Adjusted Status",Adjust-1);
        CurrPage.update(false);   
    end;
    local procedure Get_Stock_Level():Decimal
    var 
        Item:Record Item;
    begin
        If Item.Get(rec.SKU) then
        begin
            Item.CalcFields(Inventory);
            Exit(Item.Inventory);
        end
        else 
            exit(0);    
    end;       
    var
        SkuNo:Code[20];
        SkuLst:text;
        PostDate:Array[2] of date;
        Adjust:Option All,Unadjusted,Adjusted;
        Styler:text;


}