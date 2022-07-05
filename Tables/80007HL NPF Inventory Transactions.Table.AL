table 80007 "HL NPF Inventory Transactions"
{
    fields
    {
        field(10;"Transaction ID"; Integer)
        {
            Editable = false;
        }
        field(20;"PostingDateTime"; DateTime)
        {
            Editable = false;
        }
        field(30;"SKU"; Code[20])
        {
            Editable = false;
        }
        field(40;Qty; decimal)
        {
            Editable = false;
        }
        field(50;UOM; Code[10])
        {
            Editable = false;
        }
        field(60;"Batch No"; Code[20])
        {
            Editable = false;
        }
        field(70;"Expiry Date"; date)
        {
            Editable = false;
        }
        field(80;"Transaction Type"; text[50])
        {
            Editable = false;
        }
        field(90;"Transaction Name"; Text[50])
        {
            Editable = false;
        }
        field(100;"Reason Description"; text[80])
        {
            Editable = false;
        }
        field(110;"Adjusted Status"; option)
        {
            Editable = false;
            OptionMembers =  Unajusted,Adjusted;
        }
    }
    keys
    {
        key(Key1;"Transaction ID" )
        {
            Clustered = true;
        }
    }
 
}