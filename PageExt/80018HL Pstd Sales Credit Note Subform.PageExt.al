pageextension 80018 "HL Pstd Sales Crd.Note Subfrm" extends "Posted Sales Cr. Memo Subform"
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
            field("Claim Status"; rec."Claim Status")
            {
                ApplicationArea = All;
                Caption = 'Claim Status';
            }
        } 
   }
}    