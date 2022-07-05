page 80002 "HL Part Classifications"
{
    Caption = 'Part Classifications';
    PageType = Worksheet;
    SourceTable = "HL Part Classification";
    InsertAllowed = true;
    ModifyAllowed = True;
    DeleteAllowed = true;
        
    layout
    {
        area(content)
        {
            repeater(General)
            {
                field(ID; Rec.ID)
                {
                   ApplicationArea = All;
                   Visible = False;
                }
                field("Type"; Rec."Type")
                {
                    ApplicationArea = All;
                    Visible = false;
                }
                field(Name; Rec.Name)
                {
                   ApplicationArea = All;
                }
            }
        }
    }
    procedure SetPageMode(Mode:Option Parent,Sub1,Sub2,Sub3,Sub4,Sub5)
    begin
        rec.Setrange(Type,Mode)
    end;
}
