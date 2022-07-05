table 80003 "HL Shopify Order Lines"
{
    fields
    {
        field(10;ID; BigInteger)
        {
            AutoIncrement = true;
        }
        field(20;"ShopifyID";BigInteger)
        {
        }
        field(25;"Order Line ID";BigInteger)
        {
        }
        field(26;"Order Line No";Integer)
        {
        }
        field(30;"Shopify Order ID";BigInteger)
        {
        }
        field(40;"Item No."; Code[20])
        {
            TableRelation = Item."No." where("No."=filter('SKU*'));
        }
        field(50;"Location Code";Code[10])
        {
            TableRelation = Location where("Use As In-Transit"=Const(false));
        }
        field(60;"Unit Of Measure";Code[10])
        {
            TableRelation = "Unit of Measure";
        }
        field(70;"Order Qty";Decimal)
        {
        }
        field(80;"Unit Price";Decimal)
        {
        }
        field(90;"Base Amount";Decimal)
        {
        }
        field(100;"Tax Amount";Decimal)
        {
        }
        field(110;"Discount Amount";Decimal)
        {
        }
        field(120;"NPF Shipment Qty";Decimal)
        {
        }
        field(130;"Shopify Application Index";integer)
        {
        }
        field(140;"Shopify Application ID";integer)
        {
        }
        field(150;"Bundle Item No.";Code[20])
        {
            TableRelation = Item."No." where("No."=filter('SKU-9*'));
        }
        field(160;"Bundle Order Qty";Decimal)
        {
        }
        field(170;"Bundle Unit Price";Decimal)
        {
        }
        field(180;"BOM Qty";Decimal)
        {
        }
        field(190;"Auto Delivered";boolean)
        {
           Editable = false;
        }
        field(200;"Batch No";Integer)
        {
            FieldClass = FlowField;
            CalcFormula = count("HL Sales Batch No" where("Order Line ID" = field(ID)));
        }
        field(210;"Not Supplied";boolean)
        {
           //Editable = false;
        }
        field(220;"Is NPF Item";boolean)
        {
           //Editable = false;
        }
    }
    keys
    {
        key(PK; ID)
        {
            Clustered = true;
        }
    }
    trigger OnDelete()
    var
        Batch:Record "HL Sales Batch No";
    begin
        Batch.Reset;
        Batch.Setrange("Order Line ID",ID);
        If Batch.FindSet then Batch.DeleteAll();
    end;
}