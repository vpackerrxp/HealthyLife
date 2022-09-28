table 80030 "HL Rebate Sales"
{
    Caption = 'Rebate Sales';
     
    fields
    {
        field(10; "Rebate Period"; integer)
        {
            Editable = False;
        }
        field(30; "Brand"; Code[30])
        {
            Editable = False;
        }
        field(50; "Rebate Sale Start Date"; Date)
        {
            trigger OnValidate() 
            begin
                If (Rec."Rebate Sale End Date" <> 0D) 
                and (Rec."Rebate Sale Start Date" >= Rec."Rebate Sale End Date") then
                    Error('Invalid Start Date Exceeds or equals End date');
                If Rec."Rebate Sale Start Date" <> Xrec."Rebate Sale Start Date" then
                    Clear(rec."Rebate Activation Date");
            end;    
        }
        field(60; "Rebate Sale End Date"; Date)
        {
            trigger OnValidate() 
            begin
                If (Rec."Rebate Sale Start Date" <> 0D) AND (Rec."Rebate Sale End Date" <= Rec."Rebate Sale Start Date") then
                    Error('Invalid End Date Must Exceed Start Date');
                If Rec."Rebate Sale End Date" <> Xrec."Rebate Sale End Date" then
                    Clear(rec."Rebate Activation Date");
            end;    
        }
        field(120; "Rebate Sales SKU"; integer)
        {
            FieldClass = FlowField;
            CalcFormula = Count("HL Rebate Sales Sku" Where(Brand=field(Brand)
                                                        ,"Rebate Period"=Field("Rebate Period")));
        }
       field(150; "Rebate Activation Date"; DateTime)
       {
            Editable = false;
       } 
    }
    keys
    {
        key(PK; "Rebate Period",Brand)
        {
            Clustered = true;
        }
    }
    trigger OnDelete()
    var
        RSku:Record "HL Rebate Sales Sku";
    begin
        RSku.Reset;
        RSku.Setrange(Brand,Brand);
        RSku.Setrange("Rebate Period","Rebate Period");
        If Rsku.Findset then
            RSku.deleteall(true);
    end;
}
