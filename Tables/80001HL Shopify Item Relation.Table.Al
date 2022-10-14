table 80001 "HL Shopify Item Relations"
{
   fields
    {
        field(10;"Parent Item No."; Code[20])
        {
            Editable = false;
            NotBlank = true;
            trigger OnValidate()
            var
                item:record Item;
            begin
                if Not Item.get("Parent Item No.") then
                    Error(Strsubstno('Parent Item %1 Does Not Exist',"Parent Item No."));
            end;
        }
        field(20;"Child Item No."; Code[20])
        {
            NotBlank = true;
            trigger OnValidate()
            var
                item:record Item;
            begin
                if Not Item.get("Child Item No.") then
                    Error(Strsubstno('Child Item %1 Does Not Exist',"Child Item No."));
            end;
        }
        field(30;"Child Description"; Text[100])
        {
            FieldClass = FlowField;
            CalcFormula = Lookup(Item.Description WHERE ("No."=FIELD("Child Item No.")));
        }
        field(40;"Child Position"; integer)
        {
            trigger OnValidate()
            var
                Item:record Item;
            begin
                If rec."Child Position" <> xRec."Child Position" then
                begin
                    Item.get(Rec."Child Item No.");
                    Item.Update_WebService_Flag();
                    Item.Modify(false);
                end;    
            end;        
        }
        field(50;"Un Publish Child"; Boolean)
        {
            //editable = false;
            trigger OnValidate()
            var
                Item:record Item;
            begin
                If rec."Un Publish Child" <> xRec."Un Publish Child" then
                begin
                    Item.get(Rec."Child Item No.");
                    Item.Update_WebService_Flag();
                    Item.Modify(False);
                end;    
            end;        
        }
        field(60;"Move To Parent"; Code[20])
        {
            TableRelation = Item where(Type=Const("Non-Inventory"),"Shopify Item"=const(Shopify));
            trigger OnValidate()
            begin
                If "Move To Parent" = "Parent Item No." then Clear("Move To Parent");       
            end;    
        }
        field(70;"Update Required"; Boolean)
        {
            Editable = false;
        }
    }
    keys
    {
        key(Key1; "Parent Item No.","Child Item No.")
        {
            Clustered = true;
        }
        key(Key2; "Child Position")
        {
        }
    }
    trigger OnInsert()
    var
        Item:Record Item;
    begin
        If Item.Get("Child Item No.") then 
        begin
            Check_duplicates();
            Item."Is Child Flag" := True;
            Item."Web Service Update Flag" := true;
            Item.Modify(False);
        end;
        If Item.Get("Parent Item No.") then
        begin
            Item."Shopify Update Flag" := True;
            Item.Modify(false);
        end;    
    end;
    trigger OnModify()
    var
        Item:record Item;
    begin
        Check_duplicates();
        If Item.Get("Parent Item No.") then
        begin
            Item."Shopify Update Flag" := True;
            Item.Modify(false);
        end;    
    end;
    trigger OnDelete()
    var
        Item:Array[2] of Record Item;
        DelTrck:record "HL Track Item Relation Deletes";
    begin
        If Item[1].Get("Child Item No.") then 
            If Item[1]."Is In Shopify Flag" Then Error('Delete is not possible Child Item still exists in shopify')     
        else
            error('Child Item does not exist');
        If Item[2].Get("Parent Item No.") then
        begin
            Item[2]."Shopify Update Flag" := True;
            Item[2].Modify(false);
        end;
        DelTrck.init;
        DelTrck."Parent SKU" := Rec."Parent Item No.";
        DelTrck."Child SKU" := Rec."Child Item No.";
        DelTrck.insert;
        DelTrck."Parent ID" := Item[2]."Shopify Product ID";
        DelTrck."Child ID" := Item[1]."Shopify Product Variant ID";
        DelTrck.Price := Item[1]."Current Price";
        DelTrck."Parent Name" := Item[2]."Shopify Title";
        DelTrck."Child Name" := Item[1]."Shopify Selling Option 1";
        DelTrck.Position := Rec."Child Position";
        DelTrck.Modify(false);
    end;
    trigger OnRename()
    begin
        Error('Rename Not Valid');
    end;
    local procedure Check_duplicates()
    var
         rel:Record "HL Shopify Item Relations";
    begin
        rel.reset;
        rel.Setrange("Child Item No.","Child Item No.");
        rel.Setfilter("Parent Item No.",'<>%1',"Parent Item No.");
        if Rel.Findset then Error('Already defined as child item of %1',Rel."Parent Item No.");                  
     end;
 
}