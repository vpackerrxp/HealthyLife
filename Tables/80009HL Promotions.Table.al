table 80009 "HL Promotions"
{
    Caption = 'Promotions';
     
    fields
    {
        field(10; "Promotion Period"; integer)
        {
            Editable = False;
        }

        field(20; "Promotion Type"; Option)
        {
            Caption = 'Promotion Type';
            OptionMembers = Category,Brand;
            Editable = False;
        }
        field(30; "Promotion Code"; Code[30])
        {
            Editable = False;
        }
        field(40; "RRP Discount %"; Decimal)
        {
            MinValue = 0;
            MaxValue = 100;
        }
         field(50; "Promotion Start Date"; Date)
        {
            trigger OnValidate() 
            begin
                If (Rec."Promotion End Date" <> 0D) 
                and (Rec."Promotion Start Date" >= Rec."Promotion End Date") then
                    Error('Invalid Start Date Exceeds or equals End date')
            end;    
        }
        field(60; "Promotion End Date"; Date)
        {
            trigger OnValidate() 
            begin
                If (Rec."Promotion Start Date" <> 0D) AND (Rec."Promotion End Date" <= Rec."Promotion Start Date") then
                    Error('Invalid End Date Must Exceed Start Date')
                Else if (Rec."Promotion End Date" <> 0D) And (Rec."Promotion End Date" <= Today) then
                    Error('Invalid End Date is in the past or equal to today');    
            end;    
        }
        field(120; "Promotion SKU"; integer)
        {
            FieldClass = FlowField;
            CalcFormula = Count("HL Promotion Sku" Where("Promotion Type"=field("Promotion Type")
                                                        ,"Promotion Code"=field("Promotion Code")
                                                        ,"Promotion Period"=Field("Promotion Period")));
        }
       field(150; "Promotion Activation Date"; DateTime)
       {
            Editable = false;
       } 
    }
    keys
    {
        key(PK; "Promotion Period","Promotion Type","Promotion Code")
        {
            Clustered = true;
        }
    }
    trigger OnDelete()
    var
        PSku:Record "HL Promotion Sku";
    begin
        PSku.Reset;
        Psku.Setrange("Promotion Type","Promotion Type");
        PSku.Setrange("Promotion Code","Promotion Code");
        PSku.Setrange("Promotion Period","Promotion Period");
        If Psku.Findset then
            PSku.deleteall(true);
    end;
}
