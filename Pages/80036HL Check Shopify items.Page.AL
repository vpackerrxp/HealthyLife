page 80036 "HL Check Shopify Items"
{
    PageType = Worksheet;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = Item;
    SourceTableTemporary = True;
    Caption = 'Check Shopify Items';
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            Group(Process)
            {
                field("1";'Check Shopify Items')
                {
                    ApplicationArea = All;
                    ShowCaption = false;
                    trigger OnDrillDown()
                    var
                        Win:Dialog;
                        Item:record Item;
                        Cnt:Integer;
                        CU:Codeunit "HL Shopify Routines";
                        Rel:record "HL Shopify Item Relations";
                    begin
                        If Confirm('Check Shopify Items Now',True) then
                        begin
                            Win.Open('Checking Parent #1############ Status -> #2#######');
                            if Rec.findset then Rec.DeleteAll(false);
                            Item.Reset;
                            Item.Setrange(Type,Item.Type::"Non-Inventory");
                            Item.Setfilter("No.",'PAR-*');
                            Item.Setfilter("Shopify Product ID",'>0');
                            If Item.findset then
                            repeat
                                win.update(1,Item."No.");
                                Cu.Check_Product_ID(Item,cnt);
                                Rel.reset;
                                Rel.Setrange("Parent Item No.",Item."No.");
                                Rel.Setrange("Un Publish Child",False);
                                if Rel.Findset then
                                    If Cnt <> Rel.Count then
                                    begin
                                        win.update(2,'FAIL');    
                                        Rec.init;
                                        Rec."No." := Item."No.";
                                        Rec."Price Unit Conversion" := Rel.count;
                                        Rec."Statistics Group" := Cnt;
                                        rec."Is In Shopify Flag" := Item."Is In Shopify Flag";
                                        Rec.Insert(false);          
                                    end
                                    else 
                                       win.update(2,'PASS');    
                            until Item.Next = 0;
                            Win.close;
                            CurrPage.update(false);
                        end;
                    end;
                }
                field("2";'Fix Items')
                {
                    ApplicationArea = All;
                    ShowCaption = false;
                    trigger OnDrillDown()
                    var
                        Item:record Item;
                        i:Integer;
                        Cnt:Integer;
                        CU:Codeunit "HL Shopify Routines";
                        Rel:record "HL Shopify Item Relations";
                    begin
                        If Confirm('Fix Shopify Items Now',True) then
                        begin
                            Rec.reset;
                            if Rec.findset then
                            repeat
                                Clear(i);
                                Rel.Reset;
                                Rel.SetCurrentKey("Child Position");
                                Rel.Setrange("Parent Item No.",Rec."No.");
                                Rel.Setrange("Un Publish Child",False);
                                If rel.FindSet() then
                                begin
                                    Cnt := Rel.Count;
                                    repeat
                                        Item.get(rel."Child Item No.");
                                        Clear(Item."Shopify Product Variant ID");
                                        Item.modify(false);
                                        Rel."Child Position" := i;
                                        i+=1;
                                        rel.modify(false);
                                    until rel.next = 0;
                                    Item.Get(rec."No.");
                                    Item."Shopify Update Flag" := True;
                                    Item.modify(false);
                                    Cu.Process_Items(Item."No.");
                                    Item."Shopify Update Flag" := True;
                                    Item.modify(false);
                                    Cu.Process_Items(Item."No.");    
                                    Cu.Check_Product_ID(Rec,Cnt);
                                    if Cnt = Rel.Count then rec.Delete(false);
                                end;
                            until rec.next = 0;
                            CurrPage.update(false);           
                        end;
                    end;        
                }
            }
            repeater(GroupName)
            {
               field(SKU; rec."No.")
                {
                    ApplicationArea = All;
                    trigger OnDrillDown()
                    var
                        pg:page "Item Card";
                        Item:record Item;
                    begin
                        Item.get(rec."No.");
                        pg.SetRecord(Item);
                        Pg.RunModal();
                    end;
                    trigger OnAssistEdit()
                    var
                        rel:record "HL Shopify Item Relations";
                        Item:Record Item;
                        CU:Codeunit "HL Shopify Routines";
                        i:Integer;
                    begin
                        Clear(i);
                        Rel.Reset;
                        Rel.SetCurrentKey("Child Position");
                        Rel.Setrange("Parent Item No.",Rec."No.");
                        Rel.Setrange("Un Publish Child",False);
                        If rel.FindSet() then
                        begin
                            repeat
                                Item.get(rel."Child Item No.");
                                Clear(Item."Shopify Product Variant ID");
                                Item.modify(false);
                                Rel."Child Position" := i;
                                i+=1;
                                rel.modify(false);
                            until rel.next = 0;
                            Cu.Process_Items(Rec."No.");
                            Cu.Process_Items(Rec."No.");    
                            Message(Cu.Check_Product_ID(Rec,i));
                        end;    
                    end;
                }
                field(t1;Rec."Price Unit Conversion")
                 {
                    ApplicationArea = All;
                    Caption = 'Child Count';
                }
                field(t2;Rec."Statistics Group")
                {
                    ApplicationArea = All;
                    Caption = 'Reported Child Count';
                    trigger OnDrillDown()
                    var
                        Cu:Codeunit "HL Shopify Routines";
                        i:Integer;
                    begin
                        Message(Cu.Check_Product_ID(Rec,i));
                    end;
                }
                field(t3;Rec."Is In Shopify Flag")
                {
                    ApplicationArea = All;
                    Caption = 'Is In Shopify';
                }

            }
        }
    }
}