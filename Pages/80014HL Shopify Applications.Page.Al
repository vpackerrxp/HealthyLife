page 80014 "HL Shopify Applications"
{
    PageType = List;
    UsageCategory = Lists;
    ApplicationArea = All;
    SourceTable = "HL Shopify Disc Apps";
    InsertAllowed = false;
    //DeleteAllowed = false;
    Caption = 'Shopify Applications';    
  
    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("Shopify Discount App Type";rec."Shopify Discount App Type")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Shopify Disc App Code";rec."Shopify Disc App Code")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Shopify Disc App Description";rec."Shopify Disc App Description")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Shopify Value";rec."Shopify Value")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Shopify Disc Apply Type";rec."Shopify Disc Apply Type")
                {
                    ApplicationArea = All;
                }
            }
        }
    }
}