pageextension 80007 "HL Vendor Card Ext" extends "Vendor Card"
{
    PromotedActionCategoriesML = ENU = 'New,Process,Report,Approve,Request Approval,New Document,Navigate,Incoming Documents,Vendor,Healthy Life',
                                 ENA = 'New,Process,Report,Approve,Request Approval,New Document,Navigate,Incoming Documents,Vendor,Healthy Life';
    layout
    {
        Modify("E-Mail")
        {
            ApplicationArea = All;
            Caption = 'Accounts E-Mail'; 
        }
        addafter("E-Mail")
        {
            field("Sales E-Mail"; rec."Sales E-Mail")
            {
                ApplicationArea = All;
                Importance = Additional;
                ExtendedDatatype = EMail;
                
            }
            field("Operations E-Mail"; rec."Operations E-Mail")
            {
                ApplicationArea = All;
                Importance = Additional;
                ExtendedDatatype = EMail;
            }
        }
    }
    actions
    {
        addafter("Ven&dor")
        {
            Group("Healty Life")
            {
               /* Action(MsgA)
                {
                    ApplicationArea = all;
                    Caption = 'PO Line Disc %';
                    Image = Change;
                    Promoted = true;
                    PromotedCategory = Category10;
                    ToolTip = 'PO Line Disc % Maintenance';
                    trigger OnAction()
                    var
                        Pg:Page "HL Supplier Brand Rebates";
                    begin
                        Pg.Set_Page_Mode(3,rec."No.");
                        Pg.RunModal();     
                    end;
                }*/       
            }    
        }        
    }
}