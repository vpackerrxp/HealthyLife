page 80040 "HL NPF SOH Batches Display"
{
    PageType = Worksheet;
    ApplicationArea = All;
    UsageCategory = Tasks;
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
            }
        }
    }
  }