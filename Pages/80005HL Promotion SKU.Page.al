page 80005 "HL Promotion SKU"
{
    Caption = 'HL Promotion SKU';
    PageType = Worksheet;
    SourceTable = "HL Promotion Sku";
    InsertAllowed = False;
    DeleteAllowed = false;

    layout
    {
        area(content)
        {
            Group(Filters)
            {
                field("Brand Filter";vars)
                {
                    ApplicationArea = All;
                    Style = Strong;
                    trigger OnDrillDown()
                    var
                        PG:page "HL Promotion List";
                        Prom:record "HL Promotions";    
                    Begin
                        Pg.Set_Brand_List(Rec);
                        Pg.LookupMode := True;    
                        If Pg.RunModal() = Action::LookupOK then
                        begin
                            Pg.GetRecord(Prom);
                            Vars := Prom."Promotion Code";
                        end;
                        SetFilters();
                    End;
                    trigger OnAssistEdit()
                    begin
                        Clear(Vars);
                        SetFilters();
                    end;
                }

                field("Use In Promotion Filter";PromUsed)
                {
                    ApplicationArea = All;
                    Style = Strong;
                    trigger OnValidate()
                    begin
                        SetFilters();
                    End;
                    trigger OnAssistEdit()
                    begin
                        Clear(PromUsed);
                        SetFilters();
                    end;
                }
            }    
            Group(Change)
            { 
               field("A"; 'Set SKU As Promotion Included')
                {
                    ApplicationArea = All;
                    ShowCaption = False;
                    Style = StrongAccent;
                    trigger OnDrillDown()
                    var
                        PromoSku:record "HL Promotion Sku";
                    begin
                        If Confirm('Set All displayed Items as Promotion Included Now',False) then
                        begin
                            PromoSku.CopyFilters(Rec);
                            PromoSku.ModifyAll("Used In Promotion",True);  
                            CurrPage.Update(false);
                        end;      
                    end;
                }
                field("B"; 'Set SKU As Not Promotion Included')
                {
                    ApplicationArea = All;
                    ShowCaption = False;
                    Style = StrongAccent;
                    trigger OnDrillDown()
                    var
                        PromoSku:record "HL Promotion Sku";
                    begin
                        If Confirm('Set All displayed Items as Not Promotion Included Now',False) then
                        begin
                            PromoSku.CopyFilters(Rec);
                            PromoSku.ModifyAll("Used In Promotion",False);  
                            CurrPage.Update(false);
                        end;      
                    end;
                }
            }    
            repeater(General)
            {
                field(SKU; Rec.SKU)
                {
                    ApplicationArea = All;
                    trigger OnDrillDown()
                    var
                        Item:record Item;
                        Pg:Page "Item Card";
                    Begin
                        Item.Get(rec.SKU);
                        Pg.SetRecord(Item);
                        Pg.RunModal();
                    End;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                }
                field(Brand;rec.Brand)
                {
                    ApplicationArea = All;
                    //Visible = Rec."Promotion Type" <> Rec."Promotion Type"::Brand;
                }
                field("Category Code";rec."Category Code")
                {
                    ApplicationArea = All;
                    //Visible = Rec."Promotion Type" <> Rec."Promotion Type"::Category;
                }
                field("Promotion Price";rec."Promotion Price")
                {
                    ApplicationArea = All;
                    trigger OnDrillDown()
                    var
                        HLPrice:record "HL Shopfiy Pricing";
                        Pg:Page "HL Shopify Pricing";
                    begin
                        HLPrice.Reset;
                        HLPrice.Setrange("Item No.",Rec.Sku);
                        HLPrice.Setrange("Promotion Code",Rec."Promotion Code");
                        HLPrice.Setrange("Promotion Entry",true);
                        If HLPrice.Findset then
                        begin
                            Pg.SetTableView(HLPrice); 
                            Pg.RunModal();       
                        end;    
                    end;    
                }
                field("Used In Promotion";Rec."Used In Promotion")
                {
                    ApplicationArea = All;
                    trigger OnValidate()
                    begin
                        CurrPage.update(True);
                    end;
                }
            }
        }
    }
    trigger OnOpenPage()
    begin
        PromSku.reset;
        PromSku.CopyFilters(Rec);
    end;
    local procedure Setfilters()
    Begin
        PromSku.Setrange(Brand);
        PromSku.Setrange("Used In Promotion");
        If Vars <> '' then
            PromSku.Setrange(Brand,vars);
        If PromUsed <> PromUsed::ALL then
        begin
            If PromUsed = PromUsed::Included then
                PromSku.Setrange("Used In Promotion",True)
            else
                PromSku.Setrange("Used In Promotion",false);
        end; 
        Rec.CopyFilters(PromSku);
        CurrPage.Update(False);    
    End;
    var
        vars:Code[30];
        PromUsed:Option ALL,Included,"Not Included";
        PromSku:record "HL Promotion Sku";
}
