pageextension 80011 "HL Genral Ledger Setup Ext" extends "General Ledger Setup"
{
    layout
    {   //dimension Tag
        addafter(Control1900309501)
        {

            Group("Healthy Life")
            {
                Group(Rebates)
                {
                    field("PartnerShip Rebate Acc";Rec."PartnerShip Rebate Acc")
                    {
                        ApplicationArea = All;
                        ShowMandatory = true;
                    }
                    field("Marketing Rebate Acc";Rec."Marketing Rebate Acc")
                    {
                        ApplicationArea = All;
                        ShowMandatory = true;
                    }
                    field("Sales Claim Rebate Acc";rec."Sales Claim Rebate Acc")
                    {
                        ApplicationArea = All;
                        ShowMandatory = true;
                    }
                }
                Group(Reconcilation)
                {
                    field("Reconcillation Bank Acc";rec."Reconcillation Bank Acc")
                    {
                        ApplicationArea = All;
                        ShowMandatory = true;
                    }
                    field("Shopify Pay Clearing Acc";rec."Shopify Pay Clearing Acc")
                    {
                        ApplicationArea = All;
                        ShowMandatory = true;
                        Visible = False;
                    }
                    field("PayPal Clearing Acc";rec."PayPal Clearing Acc")
                    {
                        ApplicationArea = All;
                        ShowMandatory = true;
                    }
                    field("MarketPlace Clearing Acc";rec."MarketPlace Clearing Acc")
                    {
                        ApplicationArea = All;
                        ShowMandatory = true;
                    }
                    field("AfterPay Clearing Acc";rec."AfterPay Clearing Acc")
                    {
                        ApplicationArea = All;
                        ShowMandatory = true;
                    }
                    field("Zip Clearing Acc";rec."Zip Clearing Acc")
                    {
                        ApplicationArea = All;
                        ShowMandatory = true;
                        Caption = 'Eway Clearing Acc';
                    }
                    field("Misc Clearing Acc";rec."Misc Clearing Acc")
                    {
                        ApplicationArea = All;
                        ShowMandatory = true;
                    }
                }
            }
        }
    }
}