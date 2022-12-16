page 80013 "HL Shopify Order Applications"
{
    PageType = List;
    UsageCategory = Lists;
    ApplicationArea = All;
    SourceTable = "HL Shopfiy Order Applications";
    PromotedActionCategoriesML = ENU = 'Healthy Life',
                                 ENA = 'Healthy Life';
 
    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field(ShopifyOrderID; rec."Shopify Order ID")
                {
                    ApplicationArea = Basic;
                }
                field(ShopifyType;rec."Shopify App Type")
                {
                    ApplicationArea = Basic;
                }
                field(ShopifyDiscAppDesc;rec."Shopify Disc App Description")
                {
                    ApplicationArea = Basic;
                }
                field(ShopifyDiscAppValue;rec."Shopify Disc App Value")
                {
                    ApplicationArea = Basic;
                }
                field(ShopifyAppIndex;rec."Shopify Disc App Index")
                {
                    ApplicationArea = Basic;
                }
            }
        }
    }
}