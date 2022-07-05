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
                   /* field("Rebate Accural Acc";rec."Rebate Accural Acc")
                    {
                        ApplicationArea = All;
                        ShowMandatory = true;
                    }
                      field("Partner Volume Rebate Acc"; rec."Partner Volume Rebate Acc")
                    {
                        ApplicationArea = All;
                        ShowMandatory = true;
                    }
                    field("Marketing Rebate Acc"; rec."Marketing Rebate Acc")
                    {
                        ApplicationArea = All;
                        ShowMandatory = true;
                    }

                    field("Supply Chain Rebate Acc"; rec."Supply Chain Rebate Acc")
                    {
                        ApplicationArea = All;
                        ShowMandatory = true;
                    }

                    field("Auto Order Rebate Acc";rec."Auto Order Rebate Acc")
                    {
                        ApplicationArea = All;
                        ShowMandatory = true;
                    }

                    field("New DC Pipline Rebate Acc";rec."New DC Pipline Rebate Acc")
                    {
                        ApplicationArea = All;
                        ShowMandatory = true;
                    }

                    field("Palatability Rebate Acc";rec."Palatability Rebate Acc")
                    {
                        ApplicationArea = All;
                        ShowMandatory = true;
                    }
                    field("$0 Sales/Cust Make Good Acc";rec."$0 Sales/Cust Make Good Acc")
                    {
                        ApplicationArea = All;
                        ShowMandatory = true;
                    }*/
                    field("Reconcillation Bank Acc";rec."Reconcillation Bank Acc")
                    {
                        ApplicationArea = All;
                        ShowMandatory = true;
                    }
                    field("Reconcillation Clearing Acc";rec."Reconcillation Clearing Acc")
                    {
                        ApplicationArea = All;
                        ShowMandatory = true;
                    }
                }
            }
        }
    }
}