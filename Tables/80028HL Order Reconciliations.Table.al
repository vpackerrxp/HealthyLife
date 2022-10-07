table 80028 "HL Order Reconciliations"
{
    Caption = 'Order Reconciliations';
   
    fields
    {
        field(10;"Shopify Order ID";BigInteger)
        {
            Editable = false;
        }
        field(20;"Shopify Order Type"; Option)
        {
            OptionMembers =  Invoice,Refund,Cancelled;
            Editable = false;
        }
        field(30;"Shopify Order No"; BigInteger)
        {
            Editable = false;
        }
        field(40;"Shopify Order Date" ; Date)
        {
            Editable = False;       
        }
        field(50;"Payment Gate Way";Option)
        {
            Editable = false;
            OptionMembers = ,"Shopify Pay",Paypal,AfterPay,Eway,MarketPlace,Misc;
        }
        field(60;"Reference No";text[25])
        {
            Editable = false;
        }
        field(70;"Order Total";Decimal)
        {
            //Editable = false;
        }
        field(80;"Apply Status";option)
        {
            OptionMembers = UnApplied,CashApplied,Completed;
            Editable = false;
        }
        field(90;"Shopify Display ID";BigInteger)
        {
            Editable = false;
            Caption = 'Shopify Order ID';
        }
        field(100;"Extra Refund Count";Integer)
        {
            Editable = false;
        }
        field(110;"Refund Shopify ID";BigInteger)
        {
            Editable = false;
        }
       
    }
    keys
    {
        key(PK;"Shopify Order ID","Shopify Order Type")
        {
            Clustered = true;
        }
        Key(Key1;"Order Total")
        {
        }

    }
}