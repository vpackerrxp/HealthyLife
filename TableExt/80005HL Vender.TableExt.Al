tableextension 80005 "HL Vendor Ext" extends Vendor
{
    fields
    {
        field(80000; "Sales E-Mail"; text[80])
        {}
        field(80001; "Operations E-Mail"; text[80])
        {}
        field(80002; "Partnership Rebate Total";Decimal)
        {}
        field(80003; "Marketing Rebate Total"; Decimal)
        {}
        field(80004; "Sales Rebate Total"; Decimal)
        {}






        field(80200;"Woolworths Vendor No.";Code[20])
        {
            Caption = 'Woolworths Vendor No.';
        }








/*        field(80002; "Marketing Rebate Total"; Decimal)
        {}
        field(80003; "Supply Chain Rebate Total"; Decimal)
        {}
         field(80005; "Volume Rebate Total"; Decimal)
        {
        }
*/        
    }
}