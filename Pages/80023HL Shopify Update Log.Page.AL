page 80023 "HL Shopify Update Log"
{
    Caption = 'Shopify Update Log';
    PageType = List;
    UsageCategory = Lists;
    ApplicationArea = All;
    SourceTable = "HL Shopify Update Log";
    InsertAllowed = false;
    ModifyAllowed = false;
    PromotedActionCategoriesML = ENU = 'Healthy Life',
                                 ENA = 'Healthy Life';
   
    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("Error Date/Time"; rec."Error Date/Time")
                {
                    ApplicationArea = All;
                }
                field("Error Condition"; rec."Error Condition")
                {
                    ApplicationArea = All;
                }
           }
        }
        Area(FactBoxes)
        {
            part(WebServeError;"HL Webservice Error FB")
            {
                ApplicationArea = All;
                Caption = 'Picture';
                SubPageLink = ID = FIELD(ID);
           }
        }
   }
}