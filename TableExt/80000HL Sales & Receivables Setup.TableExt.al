tableextension 80000 "HL Sales & Receivables Ext " extends "Sales & Receivables Setup" 
{
    fields
    {
        field(80000; "Shopify Connnect Url"; Text[150])
        {}
        field(80001; "Shopify API Key"; text[50])
        {}
        field(80002; "Shopify Password"; text[50])
        {}
        field(80003; "NPF Connnect Url"; Text[150])
        {}
        field(80007; "NPF UserName"; text[50])
        {}
        field(80008; "NPF Password"; text[50])
        {}
        field(80009; "NPF Client Code"; text[50])
        {}
         field(80011; "Dev Shopify Connnect Url"; Text[150])
        {}
        field(80012; "Dev Shopify API Key"; text[50])
        {}
        field(80013; "Dev Shopify Password"; text[50])
        {}
        field(80014; "Dev NPF Connnect Url"; Text[150])
        {}
        field(80018; "Dev NPF UserName"; text[80])
        {}
        field(80019; "Dev NPF Password"; text[50])
        {}
        field(80020; "Dev NPF Client Code"; text[50])
        {}
        field(80022; "Use Shopify Dev Access"; Boolean)
        {}
        field(80023; "Use NPF Dev Access"; Boolean)
        {}
        field(80024; "Shopify Order No. Offset"; integer)
        {
            InitValue = 10;
            MinValue = 10;
        }
        field(80025; "Exception Email Address"; text[80])
        {}
        field(80026; "Order Process Count"; integer)
        {}

        field(80027; "Bypass Date Filter"; boolean)
        {}
        field(80028; "Gift Card Order Index"; Biginteger)
        {}
    }
}