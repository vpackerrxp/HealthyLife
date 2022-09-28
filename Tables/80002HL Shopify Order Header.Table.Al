table 80002 "HL Shopify Order Header"
{
    fields
    {
        field(10;ID; BigInteger)
        {
            AutoIncrement = true;
        }
        field(20;"Shopify Order ID"; BigInteger)
        {
            Editable = false;
        }
        field(25;"Shopify Order No."; BigInteger)
        {}
        field(30;"Transaction Date" ; Date)
        {
            Editable = false;
        }
        field(40;"Shopify Order Date" ; Date)
        {
            Editable = false;
        }
        field(50;"Shopify Order Currency"; Code[10])
        {
            Editable = false;
        }
        field(60;"Credit Card Total"; Decimal)
        {
            Editable = false;
        }
        field(70;"Gift Card Total";decimal)
        {
            Editable = false;
        }
        field(80;"Store Credit Total";decimal)
        {
            Editable = false;
        }
        field(90;"Freight Total";decimal)
        {
            Editable = false;
        }
        field(100;"Order Type";Option)
        {
            OptionMembers = Invoice,CreditMemo,Cancelled;
            Editable = false;
        }
        field(110;"BC Reference No.";Code[20])
        {}
        field(120;"Discount Total";decimal)
        {
            //Editable = false;
        }
        field(130;"NPF Shipment Status";option)
        {
            OptionMembers = InComplete,Complete;
            Editable = false;
        }
        field(140;"Shopify Order Status";Code[20])
        {
            Editable = false;
        }
        field(150;"Shopify Order Member Status";Code[20])
        {
            Editable = false;
        }
        field(160;"Order Total";Decimal)
        {
            Editable = false;
        }
        field(170;"Tax Total";decimal)
        {
            Editable = false;
        }
        field(200;"Order Status";Option)
        {
            OptionMembers = Open,Closed;
        }
        field(210;"Cash Receipt Status";option)
        {
            OptionMembers = UnApplied,Applied;
        }
        field(220;"Invoice Applied Status";option)
        {
            OptionMembers = UnApplied,Applied;
        }
        field(230;"Payment Gate Way";Text[25])
        {
           Editable = false;
         }
        field(240;"Processed Date";Date)
        {
           Editable = false;
        }
        field(250;"Processed Time";Text[15])
        {
           Editable = false;
        }
        field(260;"Proc Time";Time)
        {
           Editable = false;
        }
        field(270;"Transaction Type";text[20])
        {
           Editable = false;
         }
        field(280;"Reference No";text[25])
        {
           Editable = false;
        }
        field(290;"Shopify Financial Status";Text[30])
        {
            Editable = false;
        }
        field(300;"Refunds Checked";Boolean)
        {
            Editable = false;
        }
    }
    keys
    {
        key(PK;ID)
        {
            Clustered = true;
        }
        key(PK2;"Shopify Order ID")
        {
        }
        key(PK3;"Shopify Order No.")
        {
        }
    }
    trigger OnDelete()
    var
        Tab:Record "HL Shopify Order Lines";
        App:record "HL Shopfiy Order Applications";
        Excp:record "HL Shopify Order Exceptions";
    begin
        Tab.Reset();
        Tab.setrange(ShopifyID,ID);
        If Tab.findset then Tab.DeleteAll(True);
        App.Reset;
        App.Setrange(ShopifyID,ID);
        if App.Findset Then App.Deleteall(True);
        Excp.Reset;
        Excp.Setrange(ShopifyID,ID);
        if Excp.Findset Then Excp.Deleteall(True);
    end;
    trigger OnInsert()
    begin
        "Transaction Date" := TODAY;
        "Order Status" := "Order Status"::Open;
    end;
}