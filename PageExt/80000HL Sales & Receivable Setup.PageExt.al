pageextension 80000 "HL Sales & Rec Setup Ext" extends "Sales & Receivables Setup"
{
   layout
    {
        addafter("Number Series")
        {
            group("Healthy Life")
            {
                Group(Shopify)
                {
                    Group("Production Shopify")
                    {
                        field("Shopify Connect URL"; rec."Shopify Connnect Url")
                        {
                            ApplicationArea = All;
                            ExtendedDatatype = URL;
                            ToolTip = 'Connect Url to access Shopify';
                            ShowMandatory = true;
                        }
                        field("Shopify API Key"; rec."Shopify API Key")
                        {
                            ApplicationArea = All;
                            ToolTip = 'API Key to access Shopify';
                            ShowMandatory = true;
                        }
                        field("Shopify Password"; rec."Shopify Password")
                        {
                            ApplicationArea = All;
                            ToolTip = 'Password to access Shopify';
                            ExtendedDatatype = Masked;
                            ShowMandatory = true;
                            trigger OnAssistEdit()
                            begin
                                Message(StrSubstNo('%1', rec."Shopify Password"))
                            end;
                        }
                    }
                    Group("Development Shopify")
                    {
                        field("Dev Shopify Connect URL"; rec."Dev Shopify Connnect Url")
                        {
                            ApplicationArea = All;
                            ExtendedDatatype = URL;
                            ToolTip = 'Connect Url to access Dev Shopify';
                            ShowMandatory = true;
                        }
                        field("Dev Shopify API Key"; rec."Dev Shopify API Key")
                        {
                            ApplicationArea = All;
                            ToolTip = 'API Key to access Dev Shopify';
                            ShowMandatory = true;
                        }
                        field("Dev Shopify Password";rec."Dev Shopify Password")
                        {
                            ApplicationArea = All;
                            ToolTip = 'Password to access Dev Shopify';
                            ExtendedDatatype = Masked;
                            ShowMandatory = true;
                            trigger OnAssistEdit()
                            begin
                                Message(StrSubstNo('%1', rec."Dev Shopify Password"))
                            end;
                         }
                    }
                    field("Shopify Acces Mode"; rec."Use Shopify Dev Access")
                    {
                        ApplicationArea = All;
                    }     
                    field("A";'TEST CONNNECTION')
                    {
                        ShowCaption = false; 
                        ApplicationArea = All;
                        Style = Strong;
                        trigger OnDrillDown()
                        var  
                            cu:Codeunit "HL Shopify Routines";
                            flg:array[3] of Boolean;
                        begin
                            rec.modify;
                            CurrPage.Update(True);
                            Commit;
                            rec.Get;
                            Flg[1] := (rec."Shopify Connnect Url" <> '')  
                                    ANd (rec."Shopify API Key" <> '')
                                    AND (rec."Shopify Password" <> '');
                            Flg[2] := (rec."Dev Shopify Connnect Url" <> '')  
                                    ANd (rec."Dev Shopify API Key" <> '')
                                    AND (rec."Dev Shopify Password" <> '');
                            Flg[3] := Flg[1] And Not rec."Use Shopify Dev Access";
                            If Not Flg[3] then Flg[3] := Flg[2] And rec."Use Shopify Dev Access";         
                            If Flg[3] then        
                            begin
                            if Confirm('Test Shopify Connection using supplied parameters now?',true) then
                                begin
                                    If Cu.Shopify_Test_Connection() then
                                        Message('Connect Successfull')
                                    else
                                        Message('Connect Unsuccessfull');    
                                end;    
                            end
                            else
                                Message('Please provide all Shopify parameters.');;                       
                        end;
                    }
                    field("Shopify Order No. Offset"; rec."Shopify Order No. Offset")
                    {
                        ApplicationArea = All;
                    }
                    field("Exception Email Address"; rec."Exception Email Address")
                    {
                        ApplicationArea = All;
                        ExtendedDatatype = EMail;
                        trigger OnAssistEdit()
                        var 
                            cu:Codeunit "HL Shopify Routines";
                        begin
                            rec.Modify;
                            Commit;
                            Rec.Get;
                            If Confirm('Send Test Email', true) then
                            begin
                                If Cu.Send_Email_Msg('Test Email','This is a test','') then
                                    Message('Email Sent Successfully')
                                else
                                    Message('Failed To Send Email');
                            end;  
                        end;
                    }
                    field("Order Process Count";rec."Order Process Count")
                    {
                        ApplicationArea = All;
                    }
                    field("Bypass Date Filter";rec."Bypass Date Filter")
                    {
                        ApplicationArea = All;
                    }
                }  
                Group(NPF)
                {
                    Group("Production NPF")
                    {
                        field("NPF Connect URL"; rec."NPF Connnect Url")
                        {
                            ApplicationArea = All;
                            ExtendedDatatype = URL;
                            ToolTip = 'Connect Url to access NPF';
                            ShowMandatory = true;
                        }
                        field("NPF UserName"; rec."NPF UserName")
                        {
                            ApplicationArea = All;
                            ToolTip = 'UserName to access NPF';
                            ShowMandatory = true;
                        }
                        field("NPF Password"; rec."NPF Password")
                        {
                            ApplicationArea = All;
                            ToolTip = 'Password to access NPF';
                            ExtendedDatatype = Masked;
                            ShowMandatory = true;
                            trigger OnAssistEdit()
                            begin
                                Message(StrSubstNo('%1', rec."NPF Password"))
                            end;
                         }
                        field("NPF Client Code"; rec."NPF Client Code")
                        {
                            ApplicationArea = All;
                            ToolTip = 'Client Code to access NPF';
                            ShowMandatory = true;
                        }
                    }
                    Group("Development NPF")
                    {
                        field("Dev NPF Connect URL"; rec."Dev NPF Connnect Url")
                        {
                            ApplicationArea = All;
                            ExtendedDatatype = URL;
                            Caption = 'Dev NPF Connect URL';
                            ToolTip = 'Connect Url to access Dev NPF';
                            ShowMandatory = true;
                        }
                        field("Dev NPF UserName"; rec."Dev NPF UserName")
                        {
                            ApplicationArea = All;
                            ToolTip = 'UserName to access Dev NPF';
                            ShowMandatory = true;
                        }
                        field("Dev NPF Password";rec."Dev NPF Password")
                        {
                            ApplicationArea = All;
                            ToolTip = 'Password to access Dev NPF';
                            ExtendedDatatype = Masked;
                            ShowMandatory = true;
                            trigger OnAssistEdit()
                            begin
                                Message(StrSubstNo('%1', rec."Dev NPF Password"))
                            end;
                        }
                        field("Dev NPF Client Code"; rec."Dev NPF Client Code")
                        {
                            ApplicationArea = All;
                            ToolTip = 'Client Code to access Dev NPF';
                            ShowMandatory = true;
                        }
                     }
                    field("NPF Acces Mode"; rec."Use NPF Dev Access")
                    {
                        ApplicationArea = All;
                    }     
                    field("B";'TEST CONNNECTION')
                    {
                        ShowCaption = false; 
                        ApplicationArea = All;
                        Style = Strong;
                        trigger OnDrillDown()
                        var  
                            cu:Codeunit "HL NPF Routines";
                            XMLDoc:XmlDocument;
                            CuXML:Codeunit "XML DOM Management";
                            CurrNode:XmlNode;
                            flg:array[3] of Boolean;
                        begin
                            CurrPage.Update(True);
                            Commit;
                            rec.Get;
                            Flg[1] := (rec."NPF Connnect Url" <> '')  
                                    ANd (rec."NPF Client Code" <> '')
                                    AND (rec."NPF UserName" <> '') 
                                    AND (rec."NPF Password" <> '');
                            Flg[2] := (rec."Dev NPF Connnect Url" <> '')  
                                    ANd (rec."Dev NPF Client Code" <> '') 
                                    AND (rec."Dev NPF UserName" <> '') 
                                    AND (rec."Dev NPF Password" <> '');
                            Flg[3] := Flg[1] And Not rec."Use NPF Dev Access";
                            If Not Flg[3] then Flg[3] := Flg[2] And rec."Use NPF Dev Access";         
                            If Flg[3] then        
                            begin
                            if Confirm('Test NPF Connection using supplied parameters now?',true) then
                                begin
                                    CU.Get_SOH(0,'*',XmlDoc);
                                    CurrNode := XMlDoc.AsXmlNode();
                                    If CurrNode.SelectSingleNode('ProductList',CurrNode) Then    
                                        Message('Connect Successfull')
                                    else
                                        Message('Connect Unsuccessfull');    
                                end;    
                            end
                            else
                                Message('Please provide all NPF parameters.');;                       
                        end;
                    }
                }
            }
        }        
    }
    actions
    {   
        addlast(Processing)
        {
/*            action(MSGS)
            {
                ApplicationArea = all;
                Caption = 'Reset the Transfer Flag';
                trigger OnAction()
                var
                    Item:array[2] of record Item;
                    rel:record "PC Shopify Item Relations";
                begin
                
                        Item[1].Reset;
                        Item[1].Setrange(Type,Item[1].type::"Non-Inventory");
                        If Item[1].findset then 
                        repeat
                            Item[1]."CRM Shopify Product ID" := Item[1]."Shopify Product ID";
                            Item[1]."Shopify Transfer Flag" := TRUE;
                            Rel.Reset;
                            Rel.Setrange("Parent Item No.",Item[1]."No.");
                            If Rel.findset then
                            repeat
                                Item[2].Get(Rel."Child Item No.");
                                Item[2]."CRM Shopify Product ID" := Item[1]."Shopify Product ID";
                                Item[2]."Shopify Transfer Flag" := TRUE;
                                Item[2].Modify(false);
                            until rel.next = 0;
                            Item[1].modify(false);    
                        until Item[1].next = 0;    
                    end;
            }
*/               
            action(MSGS2)
            {
                ApplicationArea = all;
                Caption = 'Clear Shopify';
                trigger OnAction()
                var
                   Cu:Codeunit "HL Shopify Routines";
                begin
                    if Confirm('Are you absolutely sure you wish to clear Shopify now?',False) THen                     
                        Cu.Clean_Shopify();
                end;
            }   
/*            action(MSGS3)
            {
                ApplicationArea = all;
                Caption = 'Copy Cost';
                trigger OnAction()
                var
                    PCPrice:Record "HL Purchase Pricing";
                    PPrice: Record "Purchase Price";
                    Item:record Item;
                begin
                    PCPRICE.reset;
                    If PCPrice.findset then PCPrice.Deleteall;
                    PPrice.reset;
                    If PPRice.findset then
                    repeat
                        PCPrice.init;
                        PCPrice."Item No." := PPrice."Item No.";
                        PCPrice."Supplier Code" := PPrice."Vendor No.";
                        PCPrice."Unit Cost" := PPrice."Direct Unit Cost";
                        PCPrice."Start Date" := PPrice."Starting Date";
                        PCPrice."End Date" := PPrice."Ending Date";
                        PCPrice.insert;        
                     until PPRice.next = 0;
                end;         
            }
*/                 
             /*   action(MSGS5)
            {
                ApplicationArea = all;
                Caption = 'Fix totals';
                trigger OnAction()
                var
                    CU:Codeunit "HL Job Queue Monitor";
                begin
                    Cu.run
                end;
            }
            */
            action(MSGS6)
            {
                ApplicationArea = all;
                Caption = 'Set Key Info Flag';
                trigger OnAction()
                var
                    Item:record Item;
                begin
                    Item.Reset;
                    Item.Setrange("Shopify Item",Item."Shopify Item"::Shopify);
                    Item.Setfilter("Shopify Product ID",'>0');    
                    if Item.Findset then Item.ModifyAll("Key Info Changed Flag",true,False);
                end;
            }
            action(MSGS6A)
            {
                ApplicationArea = all;
                Caption = 'Set Update Flag';
                trigger OnAction()
                var
                    Item:record Item;
                begin
                    Item.Reset;
                    Item.Setrange("Shopify Item",Item."Shopify Item"::Shopify);
                    Item.Setfilter("Shopify Product ID",'>0');    
                    if Item.Findset then Item.ModifyAll("Shopify Update Flag",true,false);
                end;
            }
            action(MSGS7)
            {
                ApplicationArea = all;
                Caption = 'Remove Shopify Duplicates';
                trigger OnAction()
                var
                   Cu:Codeunit "HL Shopify Routines";
                begin
                    if Confirm('Are you absolutely sure you wish to Remove Shopify Duplications now?',False) THen
                        Cu.Remove_Shopify_Duplicates();
                end;
            }
            action(MSGS8)
            {
                ApplicationArea = all;
                Caption = 'Fix Category name';
                trigger OnAction()
                var
                    DefDim:Record "Default Dimension";
                    Dim:record "Dimension value";
                    Item:record Item;
                begin
                    Item.reset;
                    Item.findset;
                    Repeat
                       If DefDim.Get(DATABASE::Item,Item."No.",'CATEGORY') then
                       begin
                            If Item."Catergory Name" = '' then
                                if Dim.Get(DefDim."Dimension Code",Defdim."Dimension Value Code") then
                                begin
                                    Item.validate("Catergory Name",Dim.Name);
                                    Item.modify(false);
                                end;
                       end;
                    until Item.next = 0; 
                end;      
            }
            action(MSGS7B)
            {
                ApplicationArea = all;
                Caption = 'TEST';
                trigger OnAction()
                var
                    Item:record Item;

                   //Cu:Codeunit "Cryptography Management";
                   //HashAlgorithmType: Option MD5,SHA1,SHA256,SHA384,SHA512;
                   //Cu:Codeunit "HL Shopify Routines";
                   //Cu:Codeunit "HL NPF Routines";
                   //cu:Codeunit "HL Shopify Routines";
                    //Shp:record "HL Shopify Order Header";
                    val:BigInteger;
                    CU:Codeunit Test;
                begin
                    //Cu.Get_Shopify_Orders(0);
                    Cu.Testrun();
                    //CU.Fix_Refunds();
                    //CU.Process_Refunds();
                   /* Shp.Reset;
                    Shp.Setrange("Order Status",Shp."Order Status"::Open);
                    Shp.Setrange("NPF Shipment Status",Shp."NPF Shipment Status"::Complete);
                    Shp.Setfilter("BC Reference No.",'SI*');
                    If SHP.findset then SHp.ModifyAll("BC Reference No.",'',False);
                    */

                    /*Item.Reset;
                    Item.Setfilter("Shopify Selling Option 2",'<>%1','');
                    If Item.Findset then Item.ModifyAll("Shopify Selling Option 2",'',False);
    `                */   
                    //Cu.Refresh_Payment_Info();
                   // Cu.Build_NPF_Inventory_Transaction();

                    //Item.reset;
                    //If Item.findset then Item.DeleteAll(TRue);
                   //Cu.Check_For_Price_Change();
                   //Cu.Refresh_Payment_Info();
                end;
            }            
         }
    }
  
}
