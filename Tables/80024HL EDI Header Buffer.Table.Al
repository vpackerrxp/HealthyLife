table 80024 "HL EDI Header Buffer"
{
    fields
    {
        Field(10;ID;integer)
        {
            AutoIncrement = true;
        }
        field(20;"Response Type"; option)
        {
            OptionMembers = ,Response,Dispatch,Invoice;
        }
        field(30;"Purchase Order No."; Code[20])
        {
        }
        field(40;"Date Received"; date)
        {
        }
        field(50;"Supplier No."; Code[20])
        {
        }
    }
    keys
    {
        key(Key1; ID)
        {
            Clustered = true;
        }
    }
    trigger OnDelete()
    var
        EDI:record "HL EDI Line Buffer";
    begin
        EDI.reset;
        EDI.Setrange(ID,ID);
        If EDI.findset then EDI.DeleteAll();
    end;
}