table 80018 "HL NPF SOH Batches"
{
    fields
    {
        field(10;SKU; Code[20])
        {
            Editable = false;
        }
        field(20;Description;Text[100])
        {
            FieldClass = FlowField;
            CalcFormula = lookup(Item.Description where("No."=Field(SKU)));
        }
        field(30;"Location Code"; Code[10])
        {
            Editable = false;
        }
        field(40;"Batch No."; Code[30])
        {
            Editable = false;
        }
        field(50;"Batch Qty"; Decimal)
        {
            Editable = false;
        }
        field(60;"Expiry Date"; Date)
        {
            Editable = false;
        }
     }
    
    keys
    {
        key(Key1;SKU,"Batch No.")
        {
            Clustered = true;
        }
    }
    
}