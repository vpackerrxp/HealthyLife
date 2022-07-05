page  80035 "HL Sales Batch No"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "HL Sales Batch No";
    Caption = 'Sales Batch No';
    Editable = false;
    
    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
                ShowCaption = false;    
                field("Batch No."; Rec."Batch No")
                {
                    ApplicationArea = All;
                }
                field("Batch Qty"; rec."Batch Qty")
                {
                    ApplicationArea = All;
                }
                field("Expiry Date"; rec."Expiry Date")
                {
                    ApplicationArea = All;
                }
            }
        }
    }
}