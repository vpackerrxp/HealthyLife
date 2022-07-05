page 80016 "HL Purch. Order Exceptions"
{
    Caption = 'Purchase Order Exceptions';
    PageType = List;
    UsageCategory = Lists;
    ApplicationArea = All;
    SourceTable = "HL Purch Exceptions";
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = True;
    
    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("Purchase Order No.";rec."Purchase Order No.")
                {
                    ApplicationArea = All;
                    trigger OnDrillDown()
                    var
                        PuchHdr:record "Purchase Header";
                        pg:Page "Purchase Order";
                    begin
                        If PuchHdr.Get(PuchHdr."Document Type"::Order,rec."Purchase Order No.") then
                        begin
                            Pg.SetRecord(PuchHdr);
                            Pg.RunModal();
                            CurrPage.update(false);
                       end;
                    end;
                }

                field("Exception Date";rec."Exception Date")
                {
                    ApplicationArea = All;
                    
                }
                field("Exception Qty Counts";rec."Exception Count")
                {
                    ApplicationArea = All;
                }
                field("Not On Order Exception Count";rec."Not On Order Exception Count")
                {
                    ApplicationArea = All;
                }
                field("Unknown SKU Exception Count";rec."Unknown SKU Exception Count")
                {
                    ApplicationArea = All;
                }
             }
        }
   }
}