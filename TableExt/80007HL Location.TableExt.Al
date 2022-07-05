tableextension 80007 "HL Locations Ext" extends Location
{
    fields
    {
        field(80000; "NPF Warehouse ID"; option)
        {
            OptionMembers = "0","1","2","3","4","5","6","7","8","9","10","11","12";
            trigger OnValidate()
            begin
                case "NPF Warehouse ID" of
                    0:Clear("NPF Warehouse Description");
                    1:"NPF Warehouse Description" := 'Melbourne Warehouse TEST';
                    2:"NPF Warehouse Description" := '';
                    3:"NPF Warehouse Description" := 'Melbourne Warehouse';
                    4:"NPF Warehouse Description" := 'Sydney Warehouse';
                    5:"NPF Warehouse Description" := 'Perth Warehouse,';
                    6:"NPF Warehouse Description" := 'Brisbane Warehouse';
                    7:"NPF Warehouse Description" := 'Sydney Warehouse TEST';
                    8:"NPF Warehouse Description" := 'Perth Warehouse TEST';
                    9:"NPF Warehouse Description" := 'Brisbane Warehouse TEST';
                    10:"NPF Warehouse Description" := '';
                    11:"NPF Warehouse Description" := '';
                    12:"NPF Warehouse Description" := '';
                end;      
            end;
        }
        
        field(80001; "NPF Warehouse Description"; Text[50])
        {
            Editable = false;     
        }
    }
    
}