page 80044 "HL Supplier Brand List"
{
    Caption = 'Supplier Brands';
    PageType = List;
    UsageCategory = Lists;
    ApplicationArea = All;
    SourceTable = "HL Supplier Brand Rebates";
    Editable = false;
    PromotedActionCategoriesML = ENU = 'Healthy Life',
                                 ENA = 'Healthy Life';
    
    layout
    {
     area(Content)
        {
             repeater(Group)
            {
                field(Brand; rec.Brand)
                {
                    ApplicationArea = All;
                }
           }
        }
    }
}    