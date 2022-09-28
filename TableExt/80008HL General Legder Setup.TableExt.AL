tableextension 80008 "HL General Ledger Setup Ext" extends "General Ledger Setup"
{
    fields
    {
        field(80000;"Shopify Pay Clearing Acc"; Code[20])
        {
            TableRelation = "G/L Account";
        }
        field(80001;"AfterPay Clearing Acc"; Code[20])
        {
            TableRelation = "G/L Account";
        }
        field(80002;"PayPal Clearing Acc"; Code[20])
        {
            TableRelation = "G/L Account";
        }
        field(80003;"MarketPlace Clearing Acc"; Code[20])
        {
            TableRelation = "G/L Account";
        }
        field(80004;"Zip Clearing Acc"; Code[20])
        {
            TableRelation = "G/L Account";
        }
        field(80005;"Misc Clearing Acc"; Code[20])
        {
            TableRelation = "G/L Account";
        }
        field(80010;"Reconcillation Bank Acc"; Code[20])
        {
            TableRelation = "G/L Account";
        }
        field(80011;"Reconcillation Clearing Acc"; Code[20])
        {
            TableRelation = "G/L Account";
        }
        field(80012;"PartnerShip Rebate Acc"; Code[20])
        {
            TableRelation = "G/L Account";
        }
        field(80013;"Marketing Rebate Acc"; Code[20])
        {
            TableRelation = "G/L Account";
        }
        field(80014;"Sales Claim Rebate Acc"; Code[20])
        {
            TableRelation = "G/L Account";
        }

    }
}