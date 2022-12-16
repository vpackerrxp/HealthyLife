page 80034 "HL Shopify Member Status"
{
    PageType = List;
    SourceTable = "HL Shopify Order Header";
    SourceTableView = Where("Shopify Order Member Status" = filter(''));
    PromotedActionCategoriesML = ENU = 'Healthy Life',
                                 ENA = 'Healthy Life';
    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
                field(ShopifyOrdID;rec."Shopify Order ID")
                {
                    ApplicationArea = Basic;
                }
                field(ShopifyMemberStatus;rec."Shopify Order Member Status")
                {
                    ApplicationArea = Basic;
                }
            }
        }
    }
}            
