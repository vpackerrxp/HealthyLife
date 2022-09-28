page 80011 "HL Promotion List"
{
    Caption = 'Promotion List';
    PageType = List;
    SourceTable = "HL Promotions";
    SourceTableView =  where("Promotion Period"=Const(1));
    Editable = False;
     layout
    {
        area(content)
        {
            repeater(General)
            {
                field("Promotion Code"; Rec."Promotion Code")
                {
                    ApplicationArea = All;
                }
            }
        }
    }
    procedure Set_PromoType(PType:Option Category,Brand)
    begin
        rec.Setrange("Promotion Type",Ptype);
    end;
    Procedure Set_Brand_List(var PromoSku:record "HL Promotion Sku")
    var
        PromSku:record "HL Promotion Sku";
    begin
        Rec.ClearMarks();
        Rec.Setrange("Promotion Type",Rec."Promotion Type"::Brand);
        Rec.Findset;
        Repeat
            PromSku.CopyFilters(PromoSku);
            PromSku.Setrange(Brand,rec."Promotion Code");
            If PromSku.Findset then
                Rec.Mark(True);    
        Until Rec.Next = 0;
        Rec.MarkedOnly(true);    
    end;




}
