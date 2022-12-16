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

        field(80029; "Refund Order Lookback Period"; integer)
        {
            MinValue = 1;
            InitValue = 2;
            MaxValue = 4;
            Caption = 'Refund Order Lookback Period in Weeks';
        }
        field(80030; "Debug Start Date"; Date)
        {
        }
        field(80031; "Debug End Date"; Date)
        {
        }
        field(80032; "Ext Refund Order Lookback Per"; integer)
        {
            MinValue = 1;
            InitValue = 2;
            MaxValue = 4;
            Caption = 'Extra Refund Order Lookback Period in Months';
        }
        field(80033; "Web Service Oauth2 URL";Text[80])
        {
        }
        field(80034; "Web Service API URL";Text[80])
        {
        }
        field(80035; "Web Service ClientID";Text[80])
        {
        }
        field(80036; "Web Service Client Secret";Text[80])
        {
        }
        Field(80037;"Oauth2 Token";Text[1500])
        {
            Editable = False;
        }
        field(80038; "Shopify Excpt Email Address"; text[80])
        {
            Caption = 'Shopify Update Exceptions Email Address';
        }
        Field(80039;"By Pass Child Structure Check";boolean)
        {
        }
        field(80040; "Web Service Audience URL";Text[80])
        {
        }
     }
}