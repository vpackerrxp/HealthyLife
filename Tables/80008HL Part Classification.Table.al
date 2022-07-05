table 80008 "HL Part Classification"
{
    Caption = 'HL Part Classification';
   
    fields
    {
        field(10; ID; Integer)
        {
            Caption = 'ID';
            AutoIncrement = True;
        }
        field(20; "Type"; Option)
        {
            Caption = 'Type';
            OptionMembers = Parent,Sub1,Sub2,Sub3,Sub4,Sub5;
        }
        field(30; Name; Text[100])
        {
            Caption = 'Name';
        }
    }
    keys
    {
        key(PK; ID,"Type")
        {
            Clustered = true;
        }
    }
    trigger OnRename()
    begin
        Error('Rename not allowed');
    end;
    trigger OnDelete()
    var
        Item:record Item;
    begin
        Item.Reset;
        Item.Setrange(ParID,rec.ID);
        If Item.findset then
        begin
            If confirm('Removing parent record will also remove items with this parent and all levels below .. are you sure you wish to do this',false) then
                repeat
                    Clear(Item.ParID);
                    Clear(Item.Sub1ID);
                    Clear(Item.Sub2ID);
                    Clear(Item.Sub3ID);
                    Clear(Item.Sub4ID);
                    Clear(Item.Sub5ID);
                    Item.Modify(false);
                until Item.next = 0
            else    
                Error('');    
        end;
        Item.Reset;
        Item.Setrange(Sub1ID,rec.ID);
        If Item.findset then
        begin
            If confirm('Removing level 1 record will also remove items with this level and all levels below .. are you sure you wish to do this',false) then
                repeat
                    Clear(Item.Sub1ID);
                    Clear(Item.Sub2ID);
                    Clear(Item.Sub3ID);
                    Clear(Item.Sub4ID);
                    Clear(Item.Sub5ID);
                    Item.Modify(false);
                until Item.next = 0
            else    
                Error('');    
        end;        
        Item.Reset;
        Item.Setrange(Sub2ID,rec.ID);
        If Item.findset then
        begin
            If confirm('Removing level 2 record will also remove items with this level and all levels below .. are you sure you wish to do this',false) then
                repeat
                    Clear(Item.Sub2ID);
                    Clear(Item.Sub3ID);
                    Clear(Item.Sub4ID);
                    Clear(Item.Sub5ID);
                    Item.Modify(false);
                until Item.next = 0
            else    
                Error('');    
        end;        
        Item.Reset;
        Item.Setrange(Sub3ID,rec.ID);
        If Item.findset then
        begin
            If confirm('Removing level 3 record will also remove items with this level and all levels below .. are you sure you wish to do this',false) then
                repeat
                    Clear(Item.Sub3ID);
                    Clear(Item.Sub4ID);
                    Clear(Item.Sub5ID);
                    Item.Modify(false);
                until Item.next = 0
                else    
                Error('');    
        end;        
        Item.Reset;
        Item.Setrange(Sub4ID,rec.ID);
        If Item.findset then
        begin
            If confirm('Removing level 4 record will also remove items with this level and all levels below .. are you sure you wish to do this',false) then
                repeat
                    Clear(Item.Sub4ID);
                    Clear(Item.Sub5ID);
                    Item.Modify(false);
                until Item.next = 0
            else    
                Error('');    
        end;        
        Item.Reset;
        Item.Setrange(Sub5ID,rec.ID);
        If Item.findset then
            If confirm('Removing level 5 record will also remove items with this level .. are you sure you wish to do this',false) then
                Item.ModifyAll(Sub5ID,0,False)
            else    
                Error('');    
    end;
}
