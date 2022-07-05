pageextension 80016 "HL Sales Crd. Note Subform Ext" extends "Sales Cr. memo subform"
{
    layout
    {
        addafter("Unit Price")
        {
            field("Refund Reason"; rec."Refund Reason")
            {
                ApplicationArea = All;
                Caption = 'Refund Reason';
            }
        } 
   }
}    