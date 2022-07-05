tableextension 80012 "HL Bom Ext" extends "BOM Component"
{
    fields
    {
        field(80000; "Bundle Price Value %"; Decimal)
        {
            MaxValue = 100;
            trigger OnValidate()
            var
                Bom:Record "BOM Component";
            begin
                Bom.Reset;
                Bom.Setrange("Parent Item No.",Rec."Parent Item No.");
                Bom.Setfilter("No.",'<>%1',Rec."No.");
                If Bom.Findset then
                begin 
                    Bom.CalcSums("Bundle Price Value %");
                    If "Bundle Price Value %" + Bom."Bundle Price Value %" > 100 then
                        error('Total Bundle Price Values % exceeds 100 %');     
                end;
            end;
        }
    }
}