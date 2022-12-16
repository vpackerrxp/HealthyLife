page 80015 "HL Rebate Sales SKU"
{
    Caption = 'Rebate Sales SKU';
    PageType = Worksheet;
    SourceTable = "HL Rebate Sales Sku";
    PromotedActionCategoriesML = ENU = 'Healthy Life',
                                 ENA = 'Healthy Life';
    
    layout
    {
        area(content)
        {
            Group(Change)
            { 
               field("A"; 'Set SKU As Rebate Included')
                {
                    ApplicationArea = All;
                    ShowCaption = False;
                    Style = StrongAccent;
                    trigger OnDrillDown()
                    var
                        RSku:record "HL Rebate Sales SKU";
                    begin
                        If Confirm('Set All displayed Items as Rebate Included Now',False) then
                        begin
                            RSku.CopyFilters(Rec);
                            RSku.ModifyAll("Used In Rebate Period",True);  
                            CurrPage.Update(false);
                        end;      
                    end;
                }
                field("B"; 'Set SKU As Not Rebate Included')
                {
                    ApplicationArea = All;
                    ShowCaption = False;
                    Style = StrongAccent;
                    trigger OnDrillDown()
                    var
                        RSku:record "HL Rebate Sales SKU";
                    begin
                        If Confirm('Set All displayed Items as Not Rebate Included Now',False) then
                        begin
                            RSku.CopyFilters(Rec);
                            RSku.ModifyAll("Used In Rebate Period",false);  
                            CurrPage.Update(false);
                        end;      
                    end;
                }
            }    
            repeater(General)
            {
                field(SKU; Rec.SKU)
                {
                    ApplicationArea = All;
                    trigger OnDrillDown()
                    var
                        Item:record Item;
                        Pg:Page "Item Card";
                    Begin
                        Item.Get(rec.SKU);
                        Pg.SetRecord(Item);
                        Pg.RunModal();
                    End;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                }
                field("Category Code"; Rec."Category Code")
                {
                    ApplicationArea = All;
                }
                field("Rebate %"; Rec."Rebate %")
                {
                    ApplicationArea = All;
                }
                field("Rebate Wholesale Cost";rec."Rebate Wholesale Cost")
                {
                    ApplicationArea = All;
                }
                field("Used In Rebate Period";rec."Used In Rebate Period")
                {
                    ApplicationArea = All;
                }
            }
        }
    }
}
