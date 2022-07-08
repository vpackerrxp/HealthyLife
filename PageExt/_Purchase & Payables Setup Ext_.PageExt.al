pageextension 80206 "Purchase & Payables Setup Ext" extends "Purchases & Payables Setup"
{
    layout
    {
        addafter("Default Cancel Reason Code")
        {
            field("Last Exp. Purchase Invoice No.";rec."Last Exp. Purchase Invoice No.")
            {
                Caption = 'Last Exported Invoice No. to Woolworths';
                ApplicationArea = All;
            }
        }
    }
}
