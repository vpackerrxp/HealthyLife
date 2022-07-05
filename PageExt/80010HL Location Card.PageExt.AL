pageextension 80010 "HL Location Card Ext" extends "Location Card"
{
    layout
    {
        addafter("Address & Contact")
        {

            Group("Healthy Life")
            {
                field("NPF Warehouse ID"; rec."NPF Warehouse ID")
                {
                    ApplicationArea = All;
                }
                field("NPF Warehouse Description"; rec."NPF Warehouse Description")
                {
                    ApplicationArea = All;
                }
            }
        }
    }
}