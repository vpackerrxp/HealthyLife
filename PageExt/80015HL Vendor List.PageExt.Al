pageextension 80015 "HL Vendor List Ext" extends "Vendor List"
{
    PromotedActionCategoriesML = ENU ='New,Process,Report,New Document,Vendor,Navigate,Healthy Life',
                                 ENA = 'New,Process,Report,New Document,Vendor,Navigate,Healthy Life';

    actions
    {
        addlast(processing)
        {
            Action(Msg1)
            {
                ApplicationArea = all;
                Caption = 'Vendor Rebates';
                Image = Change;
                Promoted = true;
                PromotedCategory = Category7;
                ToolTip = 'Manages Vendor Rebates';
                RunObject = Page  "HL Rebate Payments";
            }
            Action(Msg2)
            {
                ApplicationArea = all;
                Caption = 'Rebate History';
                Image = Change;
                Promoted = true;
                PromotedCategory = Category7;
                ToolTip = 'Displays Rebate History';
                trigger OnAction()
                var
                    Pg:Page "HL Rebate History";
                begin
                    Pg.RunModal();     
                end;
            }
           
            /*
            Action(MsgA)
            {
                ApplicationArea = all;
                Caption = 'PO Line Disc %';
                Image = Change;
                Promoted = true;
                PromotedCategory = Category7;
                ToolTip = 'PO Line Disc % Maintenance';
                trigger OnAction()
                var
                    Pg:Page "HL Supplier Brand Rebates";
                begin
                    Pg.Set_Page_Mode(3,'');
                    Pg.RunModal();     
                end;  
            }    
            Action(MsgB)
            {
                ApplicationArea = all;
                Caption = 'Cost Analysis';
                Image = Change;
                Promoted = true;
                PromotedCategory = Category7;
                ToolTip = 'Product Cost Analysis';
                RunObject = PAGE "HL Cost Analysis";
            }*/    
       }    
    }
}