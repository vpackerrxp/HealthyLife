table 80017 "HL NPF Inventory"
{
    DataClassification = ToBeClassified;
    
    fields
    {
        field(10;SKU; Code[20])
        {    
        }
        field(15;Description;Text[100])
        {
            FieldClass = FlowField;
            CalcFormula = lookup(Item.Description where("No."=Field(SKU)));
        }
        field(20;"Location Code"; Code[10])
        {    
        }
        field(30;Qty; decimal)
        {    
        }
        field(40;"Update Flag"; Boolean)
        {    
        }
     
     }
    
    keys
    {
        key(Key1; SKU,"Location Code")
        {
            Clustered = true;
        }
    }
trigger OnDelete()
var
    Batches:Record "HL NPF SOH Batches";
begin
    Batches.Reset;
    Batches.setrange(SKU,SKU);
    Batches.setrange("Location Code","Location Code");
    If Batches.findset then Batches.DeleteAll();
end;





}