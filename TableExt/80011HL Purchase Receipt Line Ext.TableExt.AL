tableextension 80011 "HL Purchase Receipt Line Ext" extends "Purch. Rcpt. Line"
{
    fields
    {
        field(80000; "Line Rebate %"; Decimal)
        {
            editable = false;
        }
        field(80001; "NPF Recvd Qty"; Decimal)
        {
            editable = false;
        }
        field(80002; "Original Order Qty"; Decimal)
        {
            editable = false;
        }
        field(80003; "Original Order Qty(Base)"; Decimal)
        {
            editable = false;
            DecimalPlaces = 0 : 5;
        }
        field(80004; "Original Order UOM"; Code[10])
        {
            editable = false;
        }        
        field(80005;"Brand"; Code[30])
        {
            editable = false;
        }
        field(80006;"Rebate Supplier No."; Code[20])
        {
            editable = false;
        }
     }
}
