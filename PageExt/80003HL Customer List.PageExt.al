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
                        Cu.Get_Shopify_Orders(0);
                    
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
         /*   action("HLE")
            {
                ApplicationArea = All;
                Caption = 'Sales Processing';
                Image = Change;
                Promoted = true;
                PromotedCategory = Category10;
                trigger OnAction()
                begin
                    Case StrMenu('Refunds,Zero $,Auto Delivery,Analysis',1) of
                        1:PAGE.RunModal(PAGE::"HL Refund Processing");
                        2:Page.RunModal(Page::"HL Zero Dollar Process");
                        3:Page.Runmodal(Page::"HL Auto Delivery Processing");
                        4:PAGE.RunModal(PAGE::"HL Sales Analysis");
                    end;
                end;
            }
        */    
            action("HLF")
            {
                ApplicationArea = All;
                Caption = 'Shopify Daily Reconciliation';
                Image = Change;
                Promoted = true;
                PromotedCategory = Category10;
                RunObject = Page "HL Shopify Order Recon";
            }
            action("HLG")
            {
                ApplicationArea = All;
                Caption = 'Execution Log';
                Image = Change;
                Promoted = true;
                PromotedCategory = Category10;
                RunObject = Page "HL Execution Log";
            }
        }    
    }
}