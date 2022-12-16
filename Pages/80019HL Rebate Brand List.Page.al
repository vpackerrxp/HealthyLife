page 80019 "HL Rebate Brand List"
{
    Caption = 'Rebate Brand List';
    PageType = List;
    SourceTable = "HL Rebate Sales";
    SourceTableView = where("Rebate Period"=Const(1));
    Editable = false;
    PromotedActionCategoriesML = ENU = 'Healthy Life',
                                 ENA = 'Healthy Life';

    layout
    {
        area(content)
        {
            repeater(General)
            {
                field(Brand; Rec.Brand)
                {
                    ApplicationArea = All;
                }
            }
        }
    }
}
