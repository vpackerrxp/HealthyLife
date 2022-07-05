page 80039 "HL NPF SOH Batches"
{
    PageType = listPart;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "HL NPF SOH Batches";
    Caption = 'Batches';
    Editable = false;
    DeleteAllowed = False;
      
    layout
    {
        area(Content)
        {
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
                field("Batch No.";rec."Batch No.")
                {
                    ApplicationArea = All;
                    Style = Strong;
                }
                field("Batch Qty";Rec."Batch Qty")
                {
                    ApplicationArea = All;
                    Style = Strong;
                }
                field("Expiry Date";Rec."Expiry Date")
                {
                    ApplicationArea = All;
                    Style = Strong;
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
                        Pg.SetItem(rec.SKU);
                        Pg.RunModal();
                        CurrPage.Update(false);
                    end;
                }

            }
        }
    }

  }