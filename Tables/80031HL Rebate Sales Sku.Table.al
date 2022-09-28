table 80031 "HL Rebate Sales Sku"
{
    Caption = 'Rebate Sales SKU';
     
    fields
    {
        field(10; "Rebate Period"; integer)
        {
             Editable = False;
        }
        field(20; "Brand"; Code[30])
        {
            Editable = False;
        }
        field(30; "Supplier No."; Code[20])
        {
            FieldClass = FlowField;
            CalcFormula = lookup(Item."Vendor No." where("No."=field(SKU)));
            Editable = False;
        }
        field(40; SKU; Code[20])
        {
            Caption = 'SKU';
            Editable = False;
        }
        field(50;Description;Text[100])
        {
            FieldClass = FlowField;
            CalcFormula = lookup(Item.Description where("No."=field(SKU)));
            Editable = False;
        }
        field(60;"Category Code";Code[30])
        {
            FieldClass = FlowField;
            CalcFormula = lookup(Item."Shopify Category Name" where("No."=field(SKU)));
            Editable = False;
        }
        field(70;"Rebate %";Decimal)
        {
        }
        field(80;"Rebate Wholesale Cost";Decimal)
        {
            FieldClass = FlowField;
            CalcFormula = lookup(Item."Rebate Wholesale Cost" where("No."=field(SKU)));
            Editable = false;
        }
        field(90; "Used In Rebate Period";Boolean)
        {
            Caption = 'Used In Rebate Period';
        }
    }
    keys
    {
        key(PK; "Rebate Period","Brand",SKU)
        {
            Clustered = true;
        }
    }
}
