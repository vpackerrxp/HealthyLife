page  80008 "HL Shopify Parent List"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = Item;
    SourceTableTemporary = True;
    SourceTableView = Where(Type=Const("Non-Inventory"),"No."=filter('PAR-*'),"Shopify Item"=Const(Shopify));
    InsertAllowed = false;
    DeleteAllowed = false;
    ModifyAllowed = false;
    Caption = 'Shopify Parent Management';
      
    layout
    {
        area(Content)
        {
            Group(Filters)
            {
                Field("Title Filter";title)
                {
                    ApplicationArea = All;
                    trigger OnValidate()
                    begin
                        SetFilters;
                    end;    
                    trigger OnAssistEdit()
                    begin
                        Clear(title);
                        SetFilters();
                     end;
                }
                Field("Transfered To Shopify Filter";Op)
                {
                    ApplicationArea = All;
                    Style = Strong;
                    trigger OnValidate()
                    begin
                        SetFilters;
                     end;
                    trigger OnAssistEdit()
                    begin
                        Clear(Op);
                        SetFilters;
                    end;
                }
                Field("";'Show No Children')
                {
                    ApplicationArea = All;
                    Style = Strong;
                    ShowCaption = False;   
                    trigger OnDrillDown()
                    begin
                        Rec.Reset;
                        Rec.Setrange(Type,Rec.Type::"Non-Inventory");
                        Rec.SetFilter("shopify Title",'<>%1','');
                        rec.Setrange("Shopify Child Count",0);
                        Rec.Setfilter("No.",'PAR-*');
                        CurrPage.update(false);
                    end;
                }
                Field("A";'Show All')
                {
                    ApplicationArea = All;
                    Style = Strong;
                    ShowCaption = False;   
                    trigger OnDrillDown()
                    begin
                        rec.reset;
                        rec.Setrange(Type,rec.Type::"Non-Inventory");
                        rec.Setrange("Shopify Item", rec."Shopify Item"::Shopify);
                        Rec.Setfilter("No.",'PAR-*');
                        CurrPage.update(false); 
                    end;
                }
            }
            repeater(GroupName)
            {
                field("Parent Sku No."; rec."No.")
                {
                    ApplicationArea = All;
                    Editable = false;
                    Caption = 'Parent Sku No.';
                    trigger OnDrillDown()
                    var
                        pg:Page "Item Card";
                        Item:record Item;
                    begin
                        Item.get(rec."No.");    
                        pg.SetRecord(Item);
                        Pg.RunModal();
                    end; 
                }
                field("Target Parent Sku No."; rec."No. 2")
                {
                    ApplicationArea = All;
                    Editable = false;
                    Caption = 'Target Parent Sku No.';
                    trigger OnDrillDown()
                    var
                        pg:Page "Item List";
                        Item:record Item;
                    begin
                        Item.Reset;
                        Item.Setrange(Type,Item.TYpe::"Non-Inventory");
                        Item.Setrange("Shopify Item",Item."Shopify Item"::Shopify);
                        Item.Setfilter("No.",'PAR-*');
                        If Item.Findset then
                        Begin
                            Pg.SetTableView(Item);
                            Pg.LookupMode(true);
                            If Pg.RunModal() = Action::LookupOK then
                            begin
                                Pg.GetRecord(Item);
                                Rec."No. 2" := Item."No.";
                                Rec.Modify(False);
                            end;
                            CurrPage.Update(false);
                        end;    
                    end; 
                }
                field(Description; rec.Description)
                {
                    ApplicationArea = All;
                    Editable = false;
                    trigger OnDrillDown()
                    begin
                        Show_Relations();
                    end;
                }
                field("Shopify Title"; rec."Shopify Title")
                {
                    ApplicationArea = All;
                    trigger OnDrillDown()
                    begin
                        Show_Relations();
                    end;
                }
               field("Is In Shopify";rec."Is In Shopify Flag")
                {
                    ApplicationArea = All;
                    Editable = false;
                    Caption = 'Transfered To Shopify';
                    StyleExpr = Styler;
                    trigger OnDrillDown()
                    begin
                        Show_Relations();
                    end;
                }
                field("Children SKU Count"; rec."Shopify Child Count")
                {
                    ApplicationArea = All;
                    trigger OnDrillDown()
                    begin
                        Show_Relations();
                    end;
                }
            }    
            Group(Footer)
            {
                Field("Record Count";Rec.Count)
                {
                    ApplicationArea = all;
                    Style = Strong;
                }
            }
        }
    }
    actions
    {
        area(Processing)
        {
            Action(Msg4)
            {
                ApplicationArea = all;
                Caption = 'Import Parent/Child Shopify Items';
                Image = Change;
                Promoted = true;
                ToolTip = 'Imports Parent/Child Shopify Combinations';
                trigger OnAction()
                var
                    Cu:Codeunit "HL Import Export Routines";
                begin
                    If Confirm('Import Parent/Child Relations Now?',True) then
                        Cu.Build_Import_Export_Item_Relations();
                end;
            } 
            action(Msg)
            {
                ApplicationArea = All;
                Caption = 'Shopify Delete';
                Image = Change;
                Promoted = true;
                PromotedIsBig = true;
                trigger OnAction();
                var
                    Cu:Codeunit "HL Shopify Routines";
                    Win:Dialog;
                    Temp:Record Item temporary;
                begin
                    If Confirm('Are You Sure You Wish To Delete All Marked Items From Shopify Now?',True) then
                    begin
                        Win.Open('Removing Shopify Item #1##############');
                        CurrPage.SetSelectionFilter(rec);
                        temp.DeleteAll(False);
                        If rec.findSet then
                        repeat
                            temp.Copy(Rec);
                            Temp.insert(false);
                        until rec.Next = 0; 
                        Temp.Reset;        
                        If Temp.Findset then
                        repeat
                            Win.update(1,Temp."No.");
                            Cu.Delete_Items(Temp."No.",false);  
                        until Temp.Next = 0
                        else
                            Message('Nothing Found Marked for Removal');
                        Clear(title);    
                        rec.Reset;
                        rec.SetRange(Type,rec.Type::"Non-Inventory");
                        rec.Setrange("Shopify Item",rec."Shopify Item"::Shopify);
                        win.Close();    
                    end;
                end;    
            }
            action(Msg2)
            {
                ApplicationArea = All;
                Caption = 'Parent/Child Relations With Shopify Delete';
                Image = Change;
                Promoted = true;
                PromotedIsBig = true;
                trigger OnAction();
                var
                    Win:Dialog;
                    Temp:Record Item temporary;
                    Rel:record "HL Shopify Item Relations";
                    Cu:Codeunit "HL Shopify Routines";
                begin
                    If Confirm('Are You Sure You Wish To Delete All Marked Parents Relationships Now?',True) then
                    begin
                        Win.Open('Removing Shopify Parent RelationShip #1##############');
                        CurrPage.SetSelectionFilter(rec);
                        temp.DeleteAll(False);
                        If rec.findSet then
                        repeat
                            temp.Copy(Rec);
                            Temp.insert(false);
                        until rec.Next = 0; 
                        Temp.Reset;        
                        If Temp.Findset then
                        repeat
                            Win.update(1,Temp."No.");
                            Cu.Delete_Items(Temp."No.",false);  
                            rel.Reset();
                            Rel.Setrange("Parent Item No.",temp."no.");
                            if Rel.findset Then Rel.DeleteAll();    
                        until Temp.Next = 0
                        else
                            Message('Nothing Found Marked for Removal');
                        Clear(title);    
                        rec.Reset;
                        rec.SetRange(Type,rec.Type::"Non-Inventory");
                        rec.Setrange("Shopify Item",rec."Shopify Item"::Shopify);
                        win.Close();    
                    end;
                end;    
            }
            action(Msg3)
            {
                ApplicationArea = All;
                Caption = 'Parent/Child Movements With Shopify Delete';
                Image = Change;
                Promoted = true;
                PromotedIsBig = true;
                trigger OnAction();
                var
                    Win:Dialog;
                    Temp:Record Item temporary;
                    Pos:integer;
                    Child:Code[20];
                    Rel:Array[2] of record"HL Shopify Item Relations";
                    Rel2:Record "HL Shopify Item Relations";
                    Cu:Codeunit "HL Shopify Routines";
                    Flg:Boolean;
                begin
                    If Confirm('Are You Sure You Wish To Move All Marked Parents Relationships To Target Parents Now?',True) then
                    begin
                        Win.Open('Moving Shopify Parent RelationShip #1##############');
                        CurrPage.SetSelectionFilter(rec);
                        temp.DeleteAll(False);
                        If rec.findSet then
                        repeat
                            temp.Copy(Rec);
                            If Temp."No." <> Temp."No. 2" then
                                Temp.insert(false);
                        until rec.Next = 0; 
                        Temp.Reset;        
                        If Temp.Findset then
                        repeat
                            Win.update(1,Temp."No.");
                            Cu.Delete_Items(Temp."No.",false);
                            Clear(Flg);
                            Rel[1].Reset;
                            Rel[1].SetCurrentKey("Child Position");
                            Rel[1].Setrange("Parent Item No.",Temp."No. 2");
                            If Rel[1].Findlast then
                                Pos := Rel[1]."Child Position";          
                            Rel[2].Reset();
                            Rel[2].Setrange("Parent Item No.",temp."no.");
                            if Rel[2].findset Then
                            repeat
                                Child := Rel[2]."Child Item No.";
                                Rel[2].Delete(False);
                                Rel[1].Reset;
                                Rel[1].Setrange("Parent Item No.",Temp."No. 2");
                                Rel[1].Setrange("Child Item No.",Child);
                                If Not Rel[1].Findset then
                                begin
                                    Flg := True;    
                                    Pos += 1;    
                                    Rel[1].Init;
                                    Rel[1]."Parent Item No." := Temp."No. 2";
                                    Rel[1]."Child Item No." := Child;
                                    Rel[1]."Child Position" := Pos;
                                    Rel[1].Insert(True)
                                end;
                            Until Rel[2].next = 0;
                            If Flg then
                            begin
                                Rel[1].Reset;
                                Rel[1].Setrange("Parent Item No.",Temp."No. 2");
                                IF Rel[1].findset then
                                    Rel[1].Modifyall("Update Required",True,False);
                                Cu.Process_Items(Temp."No. 2",false);
                                Rec.Delete(False);    
                            end;
                        until Temp.Next = 0
                        else
                            Message('Nothing Found Marked for Movement');
                        Clear(title);    
                        rec.Reset;
                        win.Close();    
                    end;
                end;    
            }
           action(Ms2)
            {
                ApplicationArea = All;
                Caption = 'Parent To Child Dimension Update';
                Image = Change;
                Promoted = true;
                PromotedIsBig = true;
                trigger OnAction();
                var
                    Win:Dialog;
                    DefDim:Array[2] of Record "Default Dimension";
                    Rel:array[2] of record "HL Shopify Item Relations";
                    Par:Code[20];
                    Item:record Item;
                    dim:record "Dimension Value";
                begin
                    If Confirm('Are You Sure You Wish Update Child Dimensions Based On Parent Dimensions Now?',True) then
                    begin
                        Clear(Par);
                        Win.Open('Updating Child Item #1##############');
                        Rel[1].Reset;
                        If Rel[1].Findset then
                        repeat
                            If Par <> Rel[1]."Parent Item No." then
                            begin
                                Par := Rel[1]."Parent Item No.";
                                Rel[2].Reset;
                                REL[2].Setrange("Parent Item No.",Par);
                                If Rel[2].Findset then
                                repeat
                                    DefDim[1].Reset;
                                    Defdim[1].Setrange("Table ID",Database::Item);
                                    DefDim[1].Setrange("No.",Rel[2]."Child Item No.");
                                    If DefDim[1].Findset then DefDim[1].Deleteall;
                                until Rel[2].Next = 0;    
                                DefDim[1].Reset;
                                Defdim[1].Setrange("Table ID",Database::Item);
                                Defdim[1].Setrange("No.",Par);
                                If DefDim[1].findset then
                                repeat
                                    If Rel[2].Findset then
                                    repeat
                                        Defdim[2].Copy(Defdim[1]);
                                        Defdim[2]."No." := Rel[2]."Child Item No.";
                                        win.update(1,Rel[2]."Child Item No.");
                                        If DefDim[2]."Dimension Code" in ['CATEGORY','SUB-CATEGORY'] then
                                        begin
                                            Item.Get(Rel[2]."Child Item No.");
                                            If DefDim[2]."Dimension Code" = 'CATEGORY' then
                                            begin
                                                If Dim.Get('CATEGORY',DefDim[2]."Dimension Value Code") then
                                                    Item.Validate("Catergory Name",Dim.Name);
                                            end 
                                            else 
                                               If Dim.Get('SUB-CATEGORY',DefDim[2]."Dimension Value Code") then
                                                    Item.validate("Sub Catergory Name",Dim.Name);
                                            Item.Modify(False);
                                        end;    
                                        DefDim[2].insert;
                                    until Rel[2].next = 0;
                                until DefDim[1].next = 0;    
                            end;
                        until Rel[1].Next = 0;
                    end;
                end;
            }
        }
    }
    trigger OnInit()
    var
        Item:Record Item;
    begin
        Rec.Reset;
        If Rec.Findset Then Rec.DeleteAll(False);
        Item.Reset;
        Item.Setrange(Type,Item.TYpe::"Non-Inventory");
        Item.Setrange("Shopify Item",Item."Shopify Item"::Shopify);
        Item.Setfilter("No.",'PAR-*');
        If Item.Findset then
        repeat
            Rec.Copy(Item);
            Rec."No. 2" := Rec."No.";
            Rec.Insert(False);
        Until Item.Next = 0;    
    end;
    trigger OnAfterGetRecord()
    begin
        Styler := 'unfavorable';
        If rec."Is In Shopify Flag" Then Styler := 'favorable';
    end;
    Local procedure SetFilters()
    begin
        Rec.Reset;
        If title <> '' then rec.SetFilter("Shopify Title",'%1',StrsubStno('*%1*',Title));
        If Op <> Op::All then
            If  Op = Op::Yes then
                rec.Setrange("Is In Shopify Flag",True)
            else
                rec.Setrange("Is In Shopify Flag",false);
        CurrPage.Update(false);        
    end;

    local procedure Show_Relations()
    var
        Pg:page "HL Shopify Item Relations";
    begin
        Pg.SetParent(rec."No.");
        Pg.RunModal();
        CurrPage.update(false);
    end;
    var
        title:text;
        Styler:text;
        Op:Option All,Yes,No;
}
