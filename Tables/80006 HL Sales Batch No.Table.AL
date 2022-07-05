table 80006 "HL Sales Batch No"
{
    fields
    {
        field(10;ID; bigInteger)
        {
            AutoIncrement = true;
        }
        field(20;"Order Line ID"; bigInteger)
        {
        }
        field(30;"Batch No"; Code[30])
        {
        }
        field(40;"Batch Qty"; integer)
        {
        }
        field(50;"Expiry Date"; Date)
        {
        }
    }
   keys
    {
        key(KEY1; ID)
        {
            Clustered = true;
        }
    }
    
}