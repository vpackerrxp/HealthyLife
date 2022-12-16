page 80004 "HL Shopify Items"
{
    PageType = List;
    SourceTable = Item;
    SourceTableView = Where("Shopify Transfer Flag" = Const(true));
    PromotedActionCategoriesML = ENU = 'Healthy Life',
                                 ENA = 'Healthy Life';
    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
                field(ItemNo;rec."No.")
                {
                    ApplicationArea = Basic;
                }
                Field(Description; rec.Description)
                {
                    ApplicationArea = Basic;
                }
                field("Description2"; rec."Description 2")
                {
                    ApplicationArea = Basic;
                }
                field(UnitCost;rec."Unit Cost")
                {
                    ApplicationArea = Basic;
                }
                field(UnitPrice; rec."Unit Price")
                {
                    ApplicationArea = basic;
                }
                field(UOM; rec."Base Unit of Measure")
                {
                    ApplicationArea = Basic;
                }
                Field("Item Category Code"; rec."Catergory Name")
                {
                    ApplicationArea = Basic;
                }
                Field(ItemSubCategoryCode; rec."Sub Catergory Name")
                {
                    ApplicationArea = Basic;
                }
                Field(VendorNo; rec."Vendor No.")
                {
                    ApplicationArea = Basic;
                }
                Field(VendorItemNo; rec."Vendor Item No.")
                {
                    ApplicationArea = Basic;
                }
                Field(ShopifyProductID; rec."CRM Shopify Product ID")
                {
                    ApplicationArea = basic;
                }
                field(ShopifyProductVariantID; rec."Shopify Product Variant ID")
                {
                    ApplicationArea = Basic;
                }
                field(StatusFlag; rec."Shopify Transfer Flag")
                {
                    ApplicationArea = Basic;
                }
                field(PublishFlag; rec."Shopify Publish Flag")
                {
                    ApplicationArea = Basic;
                }
                field(ShopifyTitle; Get_Product_Titles())
                {
                    ApplicationArea = Basic;
                }
                field(AutoDelivery; rec."Auto Delivery")
                {
                    ApplicationArea = Basic;
                }
                field(PlatinumDisc; rec."Current PDisc")
                {
                    ApplicationArea = Basic;
                }
                field(GoldDisc; rec."Current GDisc")
                {
                    ApplicationArea = Basic;
                }
                field(SilverDisc;rec."Current SDisc")
                {
                    ApplicationArea = Basic;
                }
                field(AutoOrdDisc;rec."Current ADisc")
                {
                    ApplicationArea = Basic;
                }
                field(PlatinumAutoOrdDisc;rec."Current PlatADisc")
                {
                    ApplicationArea = Basic;
                }
                field(GoldAutoOrdDisc;rec."Current GoldADisc")
                {
                    ApplicationArea = Basic;
                }
                field(VIPDisc;rec."Current VDisc")
                {
                    ApplicationArea = Basic;
                }
                field(Width;rec."Current Width")
                {
                    ApplicationArea = Basic;
                }
                field(Length;rec."Current Length")
                {
                    ApplicationArea = Basic;
                }
                field(Height;rec."Current Height")
                {
                    ApplicationArea = Basic;
                }
                field(GTIN;rec.GTIN)
                {
                    ApplicationArea = Basic;
                }
                field(Parent;Get_Parent())
                {
                    ApplicationArea = Basic;
                }
                field(ClassificationLvl0;Get_Classification_Levels(0))
                {
                    ApplicationArea = Basic;
                }
                field(ClassificationLvl1;Get_Classification_Levels(1))
                {
                    ApplicationArea = Basic;
                }
                field(ClassificationLvl2;Get_Classification_Levels(2))
                {
                    ApplicationArea = Basic;
                }
                field(ClassificationLvl3;Get_Classification_Levels(3))
                {
                    ApplicationArea = Basic;
                }
                field(ClassificationLvl4;Get_Classification_Levels(4))
                {
                    ApplicationArea = Basic;
                }
                field(ClassificationLvl5;Get_Classification_Levels(5))
                {
                    ApplicationArea = Basic;
                }
            }
        }   
    }
    local procedure Get_Classification_Levels(Level:integer):text
    var
        PC:Record "HL Part Classification";
    Begin
        PC.Reset;
        PC.Setrange(Type,level);
        Case Level of 
            0:PC.Setrange(ID,Rec.ParID);
            1:PC.Setrange(ID,Rec.Sub1ID);
            2:PC.Setrange(ID,Rec.Sub2ID);
            3:PC.Setrange(ID,Rec.Sub3ID);
            4:PC.Setrange(ID,Rec.Sub4ID);
            5:PC.Setrange(ID,Rec.Sub5ID);
        end;
        If PC.Findset then
            Exit(PC.Name);
        Exit('');        
    End;


    local procedure Get_Product_Titles():text
    var
        Tst:Text;
    begin
        Tst := Rec."No.";
        If Tst.StartsWith('SKU') then
            Exit(Rec."Shopify Selling Option 1")
        else
            Exit(Rec."Shopify Title");    
    end;    
    local procedure Get_Parent():Code[20]
    var
        rel:record "HL Shopify Item Relations";
    begin
        Rel.Reset;
        Rel.Setrange("Child Item No.",rec."No.");
        If Rel.FindSet() then 
            Exit(Rel."Parent Item No.")
        else
            Exit('N/A');    
    end;  
}    
