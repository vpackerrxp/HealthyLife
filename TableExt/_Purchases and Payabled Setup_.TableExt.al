tableextension 80202 "Purchases and Payabled Setup" extends "Purchases & Payables Setup"
{
    fields
    {
        field(80200;"Last Exp. Purchase Invoice No.";Code[20])
        {
            Caption = 'Last Exported Purchase Invoice No.';
            DataClassification = ToBeClassified;
        }
    }
}
