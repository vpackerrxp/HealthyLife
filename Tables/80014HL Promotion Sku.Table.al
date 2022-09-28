table 80014 "HL Promotion Sku"
{
    Caption = 'Promotion SKU';
     
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
            Caption = 'Promotion Code';
            Editable = False;
        }
        field(40; SKU; Code[20])
        {
            Caption = 'SKU';
            Editable = False;
        }
        field(50; Description;Text[100])
        {
            FieldClass = FlowField;
            CalcFormula = lookup(Item.Description where("No."=field(SKU)));
            Editable = False;
        }
        field(60; Brand;Code[30])
        {
            Editable = False;
        }
        field(70;"Category Code";Code[30])
        {
            FieldClass = FlowField;
            CalcFormula = lookup(Item."Shopify Category Name" where("No."=field(SKU)));
            Editable = False;
        }
        field(80;"Promotion Price";Decimal)
        {
            FieldClass = FlowField;
            CalcFormula = lookup("HL Shopfiy Pricing"."Sell Price" where("Item No."=field(SKU),
                                            "Promotion Code"=field("Promotion Code")
                                            ,"Promotion Period"=field("Promotion Period"),"Promotion Entry"=const(True)));
            Editable = False;                                
        }
        field(90; "Used In Promotion";Boolean)
        {
            Caption = 'Used In Promotion';
        }
    }
    keys
    {
        key(PK; "Promotion Period","Promotion Type","Promotion Code",SKU)
        {
            Clustered = true;
        }
    }
    trigger OnDelete()
    var
       HLPrice:Record "HL Shopfiy Pricing";
    Begin
        HLPrice.Reset;
        HLPrice.Setrange("Item No.",Rec.Sku);
        HLPrice.Setrange("Promotion Code",Rec."Promotion Code");
        HLPrice.Setrange("Promotion Period",Rec."Promotion Period");
        HLPrice.Setrange("Promotion Entry",True);
        If HLPrice.Findset then HLPrice.Delete;
    end;     
}
