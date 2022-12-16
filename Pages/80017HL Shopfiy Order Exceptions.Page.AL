page 80017 "HL Shopify Order Exceptions"
{
    Caption = 'Order Exceptions';
    PageType = List;
    UsageCategory = Lists;
    ApplicationArea = All;
    SourceTable = "HL Shopify Order Exceptions";
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    Editable = false;
    PromotedActionCategoriesML = ENU = 'Healthy Life',
                                 ENA = 'Healthy Life';
    
    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field(Exception; rec.Exception)
                {
                    ApplicationArea = All;
                }
            }
        }
    }
   
}