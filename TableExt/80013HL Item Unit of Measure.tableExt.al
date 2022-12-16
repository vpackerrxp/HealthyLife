tableextension 80013 "HL Item Unit of Measure" extends "Item Unit of Measure"
{
    fields
    {
        modify(Weight)
        {
            trigger OnAfterValidate()
            var
                Item:record Item;
            begin
                If rec.Weight <> xrec.Weight then
                begin
                    Item.Get(Rec."Item No.");
                    If Rec.Code = Item."Base Unit of Measure" then
                    begin
                        Item.Update_Parent();
                        Item.Update_WebService_Flag();
                        Item.Modify(False);
                    end;    
                end;
            end;
        }
    }
}
