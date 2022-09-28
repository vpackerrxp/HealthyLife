pageextension 80003 "HL Customer List Ext" extends "Customer List"
{
   PromotedActionCategoriesML = ENU = 'New,Process,Report,Approve,New Document,Request Approval,Customer,Navigate,Prices & Discounts,Healthy Life',
                                ENA = 'New,Process,Report,Approve,New Document,Request Approval,Customer,Navigate,Prices & Discounts,Healthy Life';

    actions
    {
        addafter("Return Orders")
        {
            action("HLA")
            {
                ApplicationArea = All;
                Caption = 'Retrieve Shopify Orders';
                Image = Change;
                Promoted = true;
                PromotedCategory = Category10;
                trigger OnAction()
                var
                    Cu: Codeunit "HL Shopify Routines";
                begin
                    If Confirm('Retrieve Orders From Shopify Now?',True) then
                        Cu.Get_Shopify_Orders(0,0);
                    
                end;
            }
            action("HLB")
            {
                ApplicationArea = All;
                Caption = 'Shopify Orders';
                Image = Change;
                Promoted = true;
                PromotedCategory = Category10;
                RunObject = Page "HL Shopify Orders";
            }
            action("HLC")
            {
                ApplicationArea = All;
                Caption = 'Process Shopify Orders';
                Image = Change;
                Promoted = true;
                PromotedCategory = Category10;
                trigger OnAction()
                var 
                    Cu:Codeunit "HL Shopify Routines";
                begin
                    If Confirm('Process Shopify Orders Now?',True) then
                        Cu.Process_Orders(false,0);
                                       
                end;
            }
            action("HLD")
            {
                ApplicationArea = All;
                Caption = 'Shopify Discount Applications';
                Image = Change;
                Promoted = true;
                PromotedCategory = Category10;
                RunObject = Page "HL Shopify Applications";
            }
            action("HLP")
            {
                ApplicationArea = All;
                Caption = 'Shopify Promotions';
                Image = Change;
                Promoted = true;
                PromotedCategory = Category10;
                RunObject = Page "HL Promotions";
            }
            action("HLE")
            {
                ApplicationArea = All;
                Caption = 'Sale Rebates Maintenance';
                Image = Change;
                Promoted = true;
                PromotedCategory = Category10;
                trigger OnAction()
                begin
                    PAGE.RunModal(PAGE::"HL Rebate Sales");
                end;
            }
            action("HLR")
            {
                ApplicationArea = All;
                Caption = 'Shopify Refund Checks';
                Image = Change;
                Promoted = true;
                PromotedCategory = Category10;
                RunObject = Page "HL Refund Checks";
            }
            action("HLF")
            {
                ApplicationArea = All;
                Caption = 'Shopify Daily Reconciliation';
                Image = Change;
                Promoted = true;
                PromotedCategory = Category10;
                RunObject = Page "HL Order Reconciliation";
            }
            action("HLF1")
            {
                ApplicationArea = All;
                Caption = 'OLd Shopify Daily Reconciliation';
                Image = Change;
                Promoted = true;
                PromotedCategory = Category10;
                RunObject = Page "HL Shopify Order Recon";;
            }
             Action(Msg8)
            {
                ApplicationArea = All;
                Caption = 'Setup';
                Image = Change;
                Promoted = true;
                PromotedCategory = Category11;
                RunObject = Page "Sales & Receivables Setup";
            }
            action("HLG")
            {
                ApplicationArea = All;
                Caption = 'Daily Execution Log';
                Image = Change;
                Promoted = true;
                PromotedCategory = Category10;
                RunObject = Page "HL Execution Log";
            }
        }    
    }
}