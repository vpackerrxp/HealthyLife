tableextension 80201 "Posted Purchase Invoice Ext" extends "Purch. Inv. Header"
{
    fields
    {
        field(80200;"Payment Exported to WW";Boolean)
        {
            Caption = 'Payment Exported to WW';
            DataClassification = ToBeClassified;
        }
        field(80201;"Date Payment Exported to WW";Date)
        {
            Caption = 'Date Payment Exported to WW';
            DataClassification = ToBeClassified;
        }
    }
}
