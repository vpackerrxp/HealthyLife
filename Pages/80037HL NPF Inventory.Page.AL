page 80037 "HL NPF SOH"
{
    PageType = Worksheet;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "HL NPF Inventory";
    Caption = 'Stock On Hand';     
    layout
    {
      area(Content)
        {
            Group(Filters)
            {
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
                field("Expiry Date Filter";ExpDate)
                {
                    ApplicationArea = all;
                    Style = Strong;
                    trigger OnValidate()
                    var
                        Batch:Record "HL NPF SOH Batches";
                        pg:Page "HL NPF SOH Batches";
                    begin
                        If Expdate <> 0D then
                        begin
                            If Confirm(StrSubstNo('Show SKU''s with expiry date <= %1',ExpDate),True) then
                            begin
                                Batch.Reset;
                                Batch.Setrange("Expiry Date",0D,Expdate);
                                If Batch.findset then
                                begin
                                    pg.Editable := false;
                                    pg.Caption := 'Expired SKU''s';
                                    Pg.SetTableView(Batch);
                                    Pg.RunModal();
                                end
                                else
                                    Message('No SKU''s exist within this expiry date filter period');
                            end; 
                            Clear(ExpDate);
                        end;    
                    end;
                    trigger OnAssistEdit()
                    begin
                        Clear(ExpDate)
                    end;
                }
                field("B";'Refresh SOH Data')
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
                        Clear(ExpDate);
                        If Confirm('Refresh SOH Data Now',True) then
                            Cu.Build_NPF_Inventory_Levels('*');      
                        SetFilters();
                    end;    
        
                }
                field("C";'Show All Batches')
                {
                    ApplicationArea = all;
                    Style = Strong;
                    ShowCaption = false;
                    trigger OnDrillDown()
                    var
                        Pg:Page "HL NPF SOH Batches Display";
                    begin
                        Pg.RunModal();   
                    end;    
                }
                field("D";'Delta Inventory Adjustments')
                {
                    ApplicationArea = all;
                    Style = Strong;
                    ShowCaption = false;
                    trigger OnDrillDown()
                    var
                        Pg:Page "HL Delta Inventory";
                    begin
                        Pg.RunModal();   
                    end;    
                }
            }    
            repeater(GroupName)
            {
                field(SKU;rec.SKU)
                {
                    ApplicationArea = All;
                }
                field(Description;rec.Description)
                {
                    ApplicationArea = All;
                }
                field("Location Code";rec."Location Code")
                {
                    ApplicationArea = All;
                }
                field(Qty;rec.Qty)
                {
                    ApplicationArea = All;
                    Style = Strong;
                    Caption = 'Stock On Hand';
                }
            }
            part(BatchLine;"HL NPF SOH Batches")
            {
                ApplicationArea = all;
                
                SubPageLink = SKU = FIELD(SKU);
            }
        }
    }
    local Procedure SetFilters()
    begin
        Rec.Reset;
        If Skulst <> '' then rec.Setfilter(SKU,Skulst.Remove(Skulst.LastIndexOf('|'),1));
        CurrPage.update(false);   
    end;
       
    var
        SkuNo:Code[20];
        SkuLst:text;
        ExpDate:date;

}