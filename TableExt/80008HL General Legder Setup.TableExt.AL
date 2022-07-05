tableextension 80008 "HL General Ledger Setup Ext" extends "General Ledger Setup"
{
    fields
    {
/*        field(80000;"Partner Volume Rebate Acc"; Code[20])
        {
            TableRelation = "G/L Account";
        }
        field(80001;"Marketing Rebate Acc"; Code[20])
        {
            TableRelation = "G/L Account";
        }
        field(80003;"Supply Chain Rebate Acc"; Code[20])
        {
            TableRelation = "G/L Account";
        }
        field(80005;"Auto Order Rebate Acc"; Code[20])
        {
            TableRelation = "G/L Account";
        }
        field(80006;"New DC Pipline Rebate Acc"; Code[20])
        {
            TableRelation = "G/L Account";
        }
        field(80008;"Palatability Rebate Acc"; Code[20])
        {
            TableRelation = "G/L Account";
        }
        field(80009;"Rebate Accural Acc"; Code[20])
        {
            TableRelation = "G/L Account";
        }
*/        field(80010;"Reconcillation Bank Acc"; Code[20])
        {
            TableRelation = "G/L Account";
        }
        field(80011;"Reconcillation Clearing Acc"; Code[20])
        {
            TableRelation = "G/L Account";
        }
/*        field(80012;"$0 Sales/Cust Make Good Acc"; Code[20])
        {
            TableRelation = "G/L Account";
        }*/
    }
}