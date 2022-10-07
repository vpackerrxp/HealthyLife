table 80033 "HL Track Item Relation Deletes"
{
    Caption = 'HL Track Item Relation Deletes';
    DataClassification = ToBeClassified;
    
    fields
    {
        field(10; "Parent SKU"; Code[20])
        {
        }
        field(20; "Child SKU"; Code[20])
        {
        }
        field(30; "Parent ID";BigInteger )
        {
        }
        field(40; "Child ID";BigInteger)
        {
        }
        field(50; Price; Decimal)
        {
        }
        field(60;"Parent Name"; text[100])
        {
        }
        field(70;"Child Name"; text[50])
        {
        }
        field(80;Position; Integer)
        {
        }
    }
    keys
    {
        key(PK; "Parent SKU","Child SKU")
        {
            Clustered = true;
        }
    }
}
