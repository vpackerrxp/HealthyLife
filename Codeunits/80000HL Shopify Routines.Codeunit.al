codeunit 80000 "HL Shopify Routines"
{
    var
        Paction:Option GET,POST,DELETE,PATCH,PUT;
        WsError:text;
        ShopifyBase:Label '/admin/api/2021-04/';
      
    trigger OnRun()
    Var
        Log:record "HL Execution Log";
        i:Integer;
     begin
         For i:= 1 to 3 do
        begin    
            Log.init;
            Clear(Log.ID);
            log.insert;
            Commit;
            Log."Execution Start Time" := CurrentDateTime;
            case i of
                1:
                begin
                    Log."Operation" := 'Synchronise Shopify Items';
                    If Process_Items('') then
                        Log.Status := Log.Status::Pass
                    else
                        log."Error Message" := CopyStr(GetLastErrorText,1,250);
                end;
                2:
                begin
                    Log."Operation" := 'Retrieve Shopify Orders';
                    if Get_Shopify_Orders(0) then
                        Log.Status := Log.Status::Pass
                    else
                       log."Error Message" := CopyStr(GetLastErrorText,1,250);
               end;
                3:
                begin
                    Log."Operation" := 'Process Shopify Orders';
                    If Process_Orders(false,0) then 
                        Log.Status := Log.Status::Pass
                    else
                        log."Error Message" := CopyStr(GetLastErrorText,1,250);
                end;
            end;
            Log."Execution Time" := CurrentDateTime;
            log.Modify();
            Commit;
        end;
        House_Keeping();   
    end;
    // General Routine to provide the Rest Api Calls
    // Arguments Passed via the support RESTAPI Table,distcionary of the HTTP parms list,payload Data
    local procedure CallRESTWebService(var RestRec : Record "HL RESTWebServiceArguments";Parms:Dictionary of [text,text];Data:text) : Boolean
    var
        Client : HttpClient;
        Headers : HttpHeaders;
        RequestMessage : HttpRequestMessage ;
        ResponseMessage : HttpResponseMessage;
        Content : HttpContent;
        AuthText : text;
        HttpUrl :text;
        i:Integer;  
        ParmKeys: List of [Text];
        ParmVals: List of [Text];
        ParmData:text;
    begin
        RequestMessage.Method := Format(RestRec.RestMethod);
        HttpUrl := RestRec.URL;
        If Parms.Count > 0 then
        begin
            If not HttpUrl.EndsWith('?') then HttpUrl += '?';
            ParmKeys := Parms.Keys();
            ParmVals := Parms.Values();
            If Parms.Count > 1 then
            begin
                for i:= 1 to Parms.Count - 1 do
                begin
                    ParmKeys.Get(i,ParmData);
                    HttpUrl += ParmData + '=';
                    ParmVals.Get(i,ParmData);
                    HttpUrl += ParmData + '&';
                end;
            end 
            else
                i:= 0;
            i+=1;        
            ParmKeys.Get(i,ParmData);
            HttpUrl += ParmData + '=';
            ParmVals.Get(i,ParmData);
            HttpUrl += ParmData;
        end;
        RequestMessage.SetRequestUri(HttpUrl);
        if not RequestMessage.GetHeaders(Headers) then exit(false);
        if RestRec."Access Token" <> '' then
        begin
            If RestRec."Token Type" =  RestRec."Token Type"::Shopify then
                Headers.Add('Authorization', 'Basic ' + RestRec."Access Token")
            else
                Headers.Add('Authorization', 'Bearer ' + RestRec."Access Token");
        end;
        if RestRec.Accept <> '' then Headers.Add('Accept', RestRec."Accept");
        If Restrec.RestMethod  in [RestRec.RestMethod::POST
                                  ,RestRec.RestMethod::PUT,RestRec.RestMethod::PATCH] then
        begin
            // get the payload data now
            Content.WriteFrom(Data);
            if Not Content.GetHeaders(Headers) Then Exit(false);
            Headers.Clear();
            Headers.Add('Content-Type','application/json');
            RequestMessage.Content := Content;  
        end; 
        Client.Clear();
        If Client.Send(RequestMessage, ResponseMessage) then
        begin        
            Headers := ResponseMessage.Headers;
            RestRec.SetResponseHeaders(Headers);
            Content := ResponseMessage.Content;
            RestRec.SetResponseContent(Content);
            EXIT(ResponseMessage.IsSuccessStatusCode);
        end
        else
            Exit(False);    
    end;
    // routine to handle All Shopify API Calls
    procedure Shopify_Data(Method:option;Request:text;Parms:Dictionary of [text,text];Payload:Text;var Data:jsonobject): boolean
    var
       Setup:Record "Sales & Receivables Setup";
       Ws:Record "HL RestWebServiceArguments";
       Cu:Codeunit "Base64 Convert";
    begin
        Setup.get;
        Clear(WsError);
        Ws.init;
        If Setup."Use Shopify Dev Access" then
        Begin 
            Ws.URL := Setup."Dev Shopify Connnect Url";
            ws."Access Token" := cu.ToBase64(Setup."Dev Shopify API Key" + ':' + Setup."Dev Shopify Password");
        End
        else
        begin
            Ws.URL := Setup."Shopify Connnect Url";
            ws."Access Token" := cu.ToBase64(Setup."Shopify API Key" + ':' + Setup."Shopify Password");
         end;
        Ws.Url += Request;
        ws."Token Type" := ws."Token Type"::Shopify;
        Ws.RestMethod := Method;
        if CallRESTWebService(ws,Parms,Payload) then
           exit(Data.ReadFrom(ws.GetResponseContentAsText()))
        else
        begin
            WsError := ws.GetResponseContentAsText(); 
            exit(false);
        end;
    end; 
    local procedure House_Keeping()
    var
        Logs:record "Job Queue Log Entry";
    begin
        Logs.Reset;
        Logs.Setrange("Object Type to Run",Logs."Object Type to Run"::Codeunit);
        Logs.setrange("Object ID to Run",Codeunit::"HL Shopify Routines");
        Logs.Setrange(Status,Logs.Status::Success);
        Logs.Setfilter("End Date/Time",'<%1',CreateDateTime(Calcdate('-5D',Today),0T));
        If Logs.Findset then Logs.DeleteAll(false);
    end;
    local procedure Update_Error_Log(Err:text)
    var
        Log:record "HL Shopify Update Log";
    begin
        Log.init;
        Clear(log.ID);
        Log.insert;
        Log."Error Date/Time" := CurrentDateTime();
        Log."Error Condition" := Err;
        Log."Web Service Error" := Copystr(WsError,1,2048);
        Log.Modify;
    end;
    Procedure Check_For_Price_Change()
    var
        Sprice:array[2] of record "HL Shopfiy Pricing";
        ChMsg:text;
    begin
        Clear(ChMsg);    
        Sprice[1].Reset;
        Sprice[1].Setrange("Ending Date",CalcDate('1D',Today));
         If Sprice[1].findset then
        repeat
            Sprice[2].Reset;
            Sprice[2].Setrange("Item No.",Sprice[1]."Item No.");
            Sprice[2].Setrange("Starting Date",Sprice[1]."Ending Date");        
            If Sprice[2].Findset then CHMsg += Check_Change(Sprice[1],Sprice[2]); 
        Until Sprice[1].next = 0;
        If Strlen(ChMsg) > 0 then Send_Email_Msg('Price Change Alerts',ChMsg,'');
    end;
    local procedure Check_Change(Sp1:record"HL Shopfiy Pricing";SP2:record "HL Shopfiy Pricing"):text
    var
        Msg:text; 
        Flg:Boolean;
        CRLF:Text[2];
    Begin
        CRLF[1] := 13;
        CRLF[2] := 10;
        Clear(Flg);
        Msg := SP1."Item No." +  ' ';
        if  Sp1."New RRP Price" <> Sp2."New RRP Price" then
        begin
            Msg += StrsubStno('Current RRP = %1,New RRP = %2,',SP1."New RRP Price",SP2."New RRP Price");
            Flg := True;
        end;    
        if  Sp1."Sell Price" <> Sp2."Sell Price" then
        begin
            Msg += StrsubStno('Current SellPrice = %1,New SellPrice = %2,',SP1."Sell Price",SP2."Sell Price");
            Flg := True;
        end;    
        if  Sp1."Platinum Member Disc %" <> Sp2."Platinum Member Disc %" then
        begin
            Msg += StrsubStno('Current Platinum Member Discount = %1,New Platinum Member Discount = %2,',SP1."Platinum Member Disc %",SP2."Platinum Member Disc %");
            Flg := True;
        end;    
        if  Sp1."Gold Member Disc %" <> Sp2."Gold Member Disc %" then
        begin
            Msg += StrsubStno('Current Gold Member Discount = %1,New Gold Member Discount = %2,',SP1."Gold Member Disc %",SP2."Gold Member Disc %");
            Flg := True;
        end;    
        if  Sp1."Silver Member Disc %" <> Sp2."Silver Member Disc %" then
        begin
            Msg += StrsubStno('Current Silver Member Discount = %1,New Silver Member Discount = %2,',SP1."Silver Member Disc %",SP2."Silver Member Disc %");
            Flg := True;
        end;    
        if  Sp1."Auto Order Disc %" <> Sp2."Auto Order Disc %" then
        begin
            Msg += StrsubStno('Current Auto Order Discount = %1,New Auto Order Discount = %2,',SP1."Auto Order Disc %",SP2."Auto Order Disc %");
            Flg := True;
        end;    
        if  Sp1."VIP Disc %" <> Sp2."VIP Disc %" then
        begin
            Msg += StrsubStno('Current VIP Discount = %1,New VIP Discount = %2,',SP1."VIP Disc %",SP2."VIP Disc %");
            Flg := True;
        end;    
        If Flg then
            Exit(Msg.Remove(Msg.LastIndexOf(','),1) + ' As @ ' + Format(Sp2."Starting Date") + CRLF)
        else
            exit('');        
    End;
    local Procedure Refresh_Product_Pricing(ItemNo:code[20])
    var
        Item:record Item;
        Rel:record "HL Shopify Item Relations";
        Filt:text;
    Begin
        // See if email alerts required for a price change or not
        Check_For_Price_Change();
        Clear(Filt);
        if ItemNo <> '' then
        begin
            Rel.Reset;
            Rel.Setrange("Parent Item No.",ItemNo);
            If Rel.findset then
            repeat
                Filt += Rel."Child Item No." + '|';
            until Rel.next = 0
            else
                exit;    
        end;
        Item.Reset;
        Item.Setrange(Type,Item.Type::Inventory);
        If Filt <> '' then
            Item.Setfilter("No.",Filt.Remove(Filt.LastIndexOf('|'),1));
        If Item.Findset then
        repeat
            Item.Validate("Current Price",Item.Get_Price());
            Item.Validate("Current RRP",Item."Unit Price");
            Item.validate("Current PDisc",Item.Get_Shopify_Disc(0));
            Item.validate("Current GDisc",Item.Get_Shopify_Disc(1));
            Item.validate("Current SDisc",Item.Get_Shopify_Disc(2));
            Item.validate("Current VDisc",Item.Get_Shopify_Disc(3));
            Item.validate("Current ADisc",Item.Get_Shopify_Disc(4));
            Item.validate("Current PlatADisc",Item.Get_Shopify_Disc(5));
            Item.validate("Current GoldADisc",Item.Get_Shopify_Disc(6));
            Item.Validate("Current Width",Item.Get_Product_Size(0));
            Item.Validate("Current Length",Item.Get_Product_Size(1));
            Item.Validate("Current Height",Item.Get_Product_Size(2));
            Item.Modify(False);
        until Item.next = 0;    
        Commit;
    End;
// Checks to ensure the Variants are aligned properly to the parent 
    local Procedure Check_Product_Structure(Var Item:Record Item)
    var
        Rel:record "HL Shopify Item Relations";
        flg:Boolean;
        Item2:record Item;
        i:integer;
        hasZero:Integer;
        Cnt:Integer;
    begin
        Clear(Flg);
        Clear(i);
        Clear(hasZero);
        Rel.Reset;
        Rel.SetCurrentKey("Child Position");
        Rel.Setrange("Un Publish Child",False);
        Rel.Setrange("Parent Item No.",Item."No.");
        If Rel.Findset then
        begin
            i:= Rel.Count;
            repeat
                If Item2.Get(Rel."Child Item No.") then
                begin; 
                    Flg := Item2."Shopify Product Variant ID" > 0;
                    If Item2."Shopify Product Variant ID" = 0 then hasZero +=1;
                end;     
            until (Rel.next = 0) or Flg;
        end;    
        // see if anything assigned now
        If Not Flg then exit;
        Check_Product_ID(Item,Cnt);
        If (Cnt <> i) or (hasZero > 0) then
        begin
            Clear(i);
            Rel.Findset;
            repeat
                Item2.Get(Rel."Child Item No.");
                Clear(Item2."Shopify Product Inventory ID");
                Item2.Modify(false);
                Rel."Child Position" := i;
                i+=1;
                Rel.modify(false);    
            until Rel.Next = 0;
        end;
    end;
    //rountine to Process Item transfers to shopify
    procedure Process_Items(ItemFilt:Code[20]):Boolean
    var
        Item:array[2] of Record Item;
        JsObj:jsonObject;
        JsObj1:jsonObject;
        JsArry:jsonArray;
        Data:JsonObject;
        JsToken:array[2] of JsonToken;
        PayLoad:text;
        Parms:Dictionary of [text,text];
        wind:Dialog;
        Rel:record "HL Shopify Item Relations";
        i:Integer;
        price:Decimal;
        Flg:Boolean;
        ItTxt:text;
        Log:record "HL Shopify Update Log";
        ItemUnit:record "Item Unit of Measure";
        ItemNo:Code[20];
    begin
        // prep for any changes to parents
        if GuiAllowed then Wind.Open('Refreshing Product Sell Prices');
        Refresh_Product_Pricing(ItemFilt);
        Item[1].reset;
        If Itemfilt <> '' then
            Item[1].Setrange("No.",ItemFilt);
        Item[1].Setrange("Shopify Update Flag",True);
        Item[1].Setrange("Shopify Item",Item[1]."Shopify Item"::Shopify);
        If Item[1].FindSet() then
        repeat
            Rel.Reset();
            Rel.Setrange("Parent Item No.",Item[1]."No.");
            If Rel.FindSet() then 
                rel.Modifyall("Update Required",true,false);
            Clear(Item[1]."Shopify Update Flag");
            Item[1].Modify(False);
        until Item[1].Next = 0;
        Commit;
        // start by doing any brand new items
        If GuiAllowed then 
        begin
            Wind.Close;
            Wind.Open('Creating Shopify Item #1################');
        end;    
        Clear(JsObj);
        Clear(Jsobj1);
        Clear(Parms);
        Item[1].reset;
        If Itemfilt <> '' then
            Item[1].Setrange("No.",ItemFilt);
        Item[1].Setrange("Shopify Item",Item[1]."Shopify Item"::Shopify);
        // ensure they have a title always
        Item[1].Setfilter("Shopify Title",'<>%1','');
        Item[1].SetRange("Shopify Product ID",0); 
        If Item[1].findset then
        repeat
            Clear(Jsobj);
            Clear(Jsobj1);
            // ensure it's not a child item
            Flg := True; 
            Rel.Reset();
            Rel.Setrange("Child Item No.",Item[1]."No.");
            If Not Rel.findset then
            begin
                // see if this is a parent without any children
                ItTxt :=  Item[1]."No.";
                // see if this is a parent but has no item relations defined
                If ItTxt.StartsWith('PAR-') then
                begin
                    Rel.reset;
                    Rel.Setrange("Parent Item No.",Item[1]."No.");
                    Flg := Rel.findset;
                end;
                If Flg then
                begin    
                    // see if this is a parent without any children
                    Rel.reset;
                    Rel.Setrange("Parent Item No.",Item[1]."No.");
                    If Rel.Findset then Flg := Rel.Count > 0;
                end; 
                If Flg then
                begin 
                    If GuiAllowed then Wind.Update(1,Item[1]."No."); 
                    JsObj.Add('title',Item[1]."Shopify Title");
                    JsObj.Add('status','active');
                    Clear(Jsobj1);
                    JsObj1.Add('product',JsObj);
                    JsObj1.WriteTo(PayLoad);
                    Sleep(20);
                    If Shopify_Data(Paction::POST,ShopifyBase + 'products.json',Parms,Payload,Data) then
                    Begin
                        Data.Get('product',JsToken[1]);
                        JsToken[1].AsObject().SelectToken('variants',JsToken[2]);
                        JsArry := jstoken[2].AsArray(); 
                        JsArry.Get(0,JsToken[1]);       
                        Jstoken[1].SelectToken('product_id',JsToken[2]);
                        Item[1]."Shopify Product ID" := JsToken[2].AsValue().AsBigInteger();
                        Jstoken[1].SelectToken('id',JsToken[2]);
                        Item[1]."Shopify Product Variant ID" := JsToken[2].AsValue().AsBigInteger();
                        Jstoken[1].SelectToken('inventory_item_id',JsToken[2]);
                        Item[1]."Shopify Product Inventory ID" := JsToken[2].AsValue().AsBigInteger();
                        Item[1]."CRM Shopify Product ID" := Item[1]."Shopify Product ID"; 
                        Item[1]."Shopify Transfer Flag" := true;  // flag the creation of a new Item
                        Item[1]."Shopify Publish Flag" := True;  // flag as a new Item 
                        Item[1]."Is In Shopify Flag" := True;
                        Clear(Item[1]."Is Child Flag");
                        Rel.reset;
                        Rel.Setrange("Parent Item No.",Item[1]."No.");
                        If Rel.Findset then 
                        Begin
                            rel.Modifyall("Update Required",true,false);
                            Item[1]."Purchasing Blocked" := true;
                        end;    
                        item[1].modify(false);
                     end
                    else
                        Update_Error_Log(StrSubstNo('Failed to create item %1 in Shopify',Item[1]."No."));
                end;
            end;        
        until Item[1].next = 0;
        Commit;
        If GuiAllowed then 
        begin
            wind.Close();
            Wind.open('Updating Shopify Item           #1#################\'
                     +'Creating/Updating Shopify Child #2#################');
        end;
        //now we do the items that exist by updating the created/updating Product Variant
        //no need to worry about title now
        Item[1].Reset;
        If Itemfilt <> '' then
            Item[1].Setrange("No.",ItemFilt);
        Item[1].SetFilter("Shopify Product ID",'>0'); 
        Item[1].Setrange("Shopify Item",Item[1]."Shopify Item"::Shopify);
        If Item[1].findset then
        repeat
            If GuiAllowed then Wind.Update(1,Item[1]."No.");
             // make sure it's not Parent item now 
            Rel.Reset;
            Rel.SetCurrentKey("Child Position");
            Rel.Setrange("Parent Item No.",Item[1]."No.");
            if not Rel.findset then
            begin 
                If GuiAllowed then Wind.Update(2,Item[1]."No.");
                Clear(Jsobj);
                Clear(Jsobj1);
                JsObj.Add('id',Item[1]."Shopify Product Variant ID");
                JsObj.Add('sku',Item[1]."No.");
                If Item[1]."Shopify Selling Option 1" <> '' Then    
                    JsObj.Add('option1',Item[1]."Shopify Selling Option 1");
                //If Item[1]."Shopify Selling Option 2" <> '' Then    
                //    JsObj.Add('option2',Item[1]."Shopify Selling Option 2");
                price := Item[1].Get_Price();
                JsObj.Add('price',Format(price,0,'<Precision,2><Standard Format,1>'));
                if Price < Item[1]."Unit Price" then
                    JsObj.Add('compare_at_price',Format(Item[1]."Unit Price",0,'<Precision,2><Standard Format,1>'))
                else
                    JsObj.Add('compare_at_price','');
                JsObj.Add('inventory_management','shopify');
                JsObj.Add('barcode',Item[1].GTIN);
                JsObj.Add('taxable',Item[1]."Price Includes VAT");
                If ItemUnit.Get(Item[1]."No.",Item[1]."Base Unit of Measure") then
                begin
                    JsObj.Add('weight',Format(ItemUnit.Weight,0,'<Precision,3><Standard Format,1>'));
                    JsObj.Add('weight_unit','kg');
                end;     
                jsObj1.Add('variant',JsObj);
                JsObj1.WriteTo(PayLoad);
                If Shopify_Data(Paction::PUT,
                         ShopifyBase + 'variants/'+ Format(Item[1]."Shopify Product Variant ID") +'.json'
                         ,Parms,Payload,Data) then
                begin
                    Clear(Item[1]."Is Child Flag");
                    Item[1].Modify(false);
                end
                else
                    Update_Error_Log(StrSubstNo('Failed to update Standalone Item %1 with variant ID %2',Item[1]."No.",Item[1]."Shopify Product Variant ID"));    
            end
            else
            begin
                Clear(i);
                Rel.Setrange("Update Required",true);
                Rel.Setrange("Un Publish Child",False);
                if Rel.Findset then
                begin
                    Check_Product_Structure(Item[1]);
                    repeat
                        i+=1;
                        Item[2].Get(Rel."Child Item No.");
                        If GuiAllowed then Wind.Update(2,Item[2]."No.");
                        Clear(Jsobj);
                        Clear(Jsobj1);
                        JsObj.Add('sku',Item[2]."No.");
                        JsObj.Add('option1',Item[2]."Shopify Selling Option 1");
                        //If Item[2]."Shopify Selling Option 2" <> '' Then    
                        //    JsObj.Add('option2',Item[2]."Shopify Selling Option 2");
                        price := Item[2].Get_Price();
                        JsObj.Add('price',format(price,0,'<Precision,2><Standard Format,1>'));
                        if (Price < Item[2]."Unit Price")  then
                            JsObj.Add('compare_at_price',format(Item[2]."Unit Price",0,'<Precision,2><Standard Format,1>'))
                        else
                            JsObj.Add('compare_at_price','');
                        JsObj.Add('inventory_management','shopify');
                        JsObj.Add('barcode',Item[2].GTIN);
                        JsObj.Add('taxable',Item[2]."Price Includes VAT");
                        If ItemUnit.Get(Item[2]."No.",Item[2]."Base Unit of Measure") then
                        begin
                            JsObj.Add('weight',Format(ItemUnit.Weight,0,'<Precision,3><Standard Format,1>'));
                            JsObj.Add('weight_unit','kg');
                        end;     
                        If (Item[2]."Shopify Product Variant ID" = 0) then
                        begin
                            if i = 1 then
                            begin;
                                Clear(Item[2]."Shopify Product ID");
                                Item[2]."Shopify Product Variant ID" := Item[1]."Shopify Product Variant ID";
                                Item[2]."Shopify Product Inventory ID" := Item[1]."Shopify Product Inventory ID";
                                Item[2]."Shopify Transfer Flag" := true;  // flag the creation of a new Item variant
                                Item[2]."Is In Shopify Flag" := True;
                                Item[2]."Is Child Flag" := True;
                                Item[2]."CRM Shopify Product ID" := Item[1]."CRM Shopify Product ID";
                                Clear(Item[2]."Key Info Changed Flag");
                                Item[2].Modify(false);
                            end
                        end;
                        jsObj1.Add('variant',JsObj);
                        Clear(PayLoad);
                        JsObj1.WriteTo(PayLoad);
                        If (Item[2]."Shopify Product Variant ID" = 0) then    
                        begin
                            If Shopify_Data(Paction::POST,
                                ShopifyBase + 'products/'+ Format(Item[1]."Shopify Product ID") +'/variants.json'
                                ,Parms,Payload,Data) then
                            begin     
                                Data.Get('variant',JsToken[1]);
                                Jstoken[1].SelectToken('id',JsToken[2]);
                                Clear(Item[2]."Shopify Product ID");
                                Item[2]."Shopify Product Variant ID" := JsToken[2].AsValue().AsBigInteger();
                                Jstoken[1].SelectToken('inventory_item_id',JsToken[2]);
                                Item[2]."Shopify Product Inventory ID" := JsToken[2].AsValue().AsBigInteger();
                                Item[2]."Shopify Transfer Flag" := true;  // flag the creation of a new Item
                                Item[2]."Is In Shopify Flag" := True;
                                Item[2]."Is Child Flag" := True;
                                Item[2]."CRM Shopify Product ID" := Item[1]."CRM Shopify Product ID";
                                Clear(Item[2]."Key Info Changed Flag");
                                item[2].modify(false);
                            end
                            else
                                Update_Error_Log(StrSubstNo('Failed to create Child Item %1 with Parent Item %2 using Product ID %3',Item[2]."No.",Item[1]."No.",Item[1]."Shopify Product ID"));
                        end        
                        else
                        begin
                            If Shopify_Data(Paction::PUT,
                                ShopifyBase + 'variants/'+ Format(Item[2]."Shopify Product Variant ID") + '.json'
                                ,Parms,Payload,Data) Then
                            begin
                                Item[2]."Is Child Flag" := True;
                                Clear(Item[2]."Key Info Changed Flag");
                                Item[2]."CRM Shopify Product ID" := Item[1]."CRM Shopify Product ID";
                                Clear(Item[2]."Shopify Product ID");
                                item[2].modify(false);
                            end
                            else
                                Update_Error_Log(StrSubstNo('Failed to update Child Item %1 with Parent Item %2 using Product ID %3,Variant ID %4',Item[2]."No."
                                                                ,Item[1]."No.",Item[1]."Shopify Product ID",Item[2]."Shopify Product Variant ID"));
                                
                        end;    
                    until Rel.next = 0;
                end;    
            end;
            Commit;
        Until Item[1].next = 0;
        If GuiAllowed then 
        begin
            wind.Close();
            Wind.open('Updating Shopify Parent    #1##################\'
                     +'Organising Shopify Child   #2##################');
        end;
        Clear(Parms);
        Item[1].Reset;
        If Itemfilt <> '' then
            Item[1].Setrange("No.",ItemFilt);
        Item[1].Setrange("Is Child Flag",False);
        Item[1].Setrange("Shopify Item",Item[1]."Shopify Item"::Shopify);
        If Item[1].findset then
        repeat
            If GuiAllowed then Wind.Update(1,Item[1]."No.");
            Clear(JsObj);
            Clear(jsobj1);
            Clear(JsArry); 
            Clear(flg);
            Rel.Reset;
            Rel.SetCurrentKey("Child Position");
            Rel.Setrange("Parent Item No.",Item[1]."No.");
            Rel.Setrange("Update Required",true);
            Rel.Setrange("Un Publish Child",False);
            If Rel.findset then
                If Rel.Count > 1 then
                repeat
                    Item[2].Get(Rel."Child Item No.");
                    If GuiAllowed then Wind.Update(2,Item[2]."No.");
                    If Item[2]."Shopify Product Variant ID" > 0 then
                    begin
                        If Not Flg then
                        Begin
                            Item[1]."Shopify Product Variant ID" := Item[2]."Shopify Product Variant ID";
                            Item[1].Modify(False);
                        end;    
                        flg := true;
                        Clear(Jsobj);
                        JsObj.Add('id',Item[2]."Shopify Product Variant ID");
                        JsArry.Add(JsObj.AsToken());
                    end; 
                until Rel.next = 0;
            if Flg then
            begin
                Clear(Jsobj);
                jsObj.Add('variants',JsArry);
                JsObj.Add('id',Item[1]."Shopify Product ID");
                JsObj1.add('product',Jsobj);
                Clear(PayLoad);
                Clear(Data);
                JsObj1.WriteTo(PayLoad);
                If Not Shopify_Data(Paction::PUT,
                         ShopifyBase + 'products/'+ Format(Item[1]."Shopify Product ID") +'.json'
                         ,Parms,Payload,Data) then Update_Error_Log(StrSubstNo('Failed to Organise Children of Parent Item %1 Using Product ID %2'
                                                                    ,Item[1]."No.",Item[1]."Shopify Product ID"));     
            end;
            // remove Any parents with no children
            ItTxt := Item[1]."No.";
            Item[1].CalcFields("Shopify Child Count");
            If (Item[1]."Shopify Child Count" = 0) AND Ittxt.StartsWith('PAR-') then
            begin 
                if Shopify_Data(Paction::DELETE,ShopifyBase + 'products/' + Format(Item[1]."Shopify Product ID") + '.json'
                                        ,Parms,PayLoad,Data) then
                begin                        
                    Clear_Flags(Item[1]);
                    // ensure they are not done next time 
                    Clear(Item[1]."Shopify Item");
                    Item[1].Modify(False);                              
                end;
            end;
            Rel.Reset;
            Rel.Setrange("Parent Item No.",Item[1]."No.");
            If Rel.findset then Rel.ModifyAll("Update Required",false,false);
        Until Item[1].next = 0;
        // here we unpublish created items
        If GuiAllowed then
        begin 
            Wind.Close; 
            Wind.open('Unpublishing Shopify Item #1#################');
        end;
        Item[1].Reset;    
        If Itemfilt <> '' then
            Item[1].Setrange("No.",ItemFilt);
        Item[1].Setrange("Shopify Publish Flag",True);
        Item[1].Setrange("Shopify Item",Item[1]."Shopify Item"::Shopify);
        Item[1].SetFilter("Shopify Product ID",'>0');
         If Item[1].findset then
        repeat
            If GuiAllowed then Wind.Update(1,Item[1]."No.");
            Clear(Jsobj);
            Clear(Jsobj1);
            JsObj.Add('id',Item[1]."Shopify Product ID");
            JsObj.Add('published',false);
            jsObj1.Add('product',JsObj);
            JsObj1.WriteTo(PayLoad);
            if Not Shopify_Data(Paction::PUT,
                       ShopifyBase + 'products/'+ Format(Item[1]."Shopify Product ID") + '.json'
                            ,Parms,Payload,Data) then
                Update_Error_Log(StrSubstNo('Failed to Unpublish Parent Item %1 Using Product ID %2'
                                                ,Item[1]."No.",Item[1]."Shopify Product ID"));              
        until Item[1].Next = 0;
        If GuiAllowed then
        begin 
            Wind.Close; 
            Wind.open('Refreshing Shopify Item #1#################');
        end;    
        // update any changes to titles etc
        Item[1].Reset;
        If Itemfilt <> '' then
            Item[1].Setrange("No.",ItemFilt);
        Item[1].Setrange("Key Info Changed Flag",true);
        Item[1].Setrange("Shopify Item",Item[1]."Shopify Item"::Shopify);
        Item[1].SetFilter("Shopify Product ID",'>0');
        If Item[1].findset then
        repeat
            if GuiAllowed Then Wind.Update(1,Item[1]."No.");
            Clear(Jsobj);
            Clear(Jsobj1);
            JsObj.Add('id',Item[1]."Shopify Product ID");
            JsObj.Add('title',Item[1]."Shopify Title");
            jsObj1.Add('product',JsObj);
            JsObj1.WriteTo(PayLoad);
            If Shopify_Data(Paction::PUT,
                       ShopifyBase + 'products/'+ Format(Item[1]."Shopify Product ID") + '.json'
                            ,Parms,Payload,Data) then
            begin                
                Clear(Item[1]."Key Info Changed Flag");
                Item[1].Modify(False);
            end
            else
                Update_Error_Log(StrSubstNo('Failed to Refresh Key Info for Parent Item %1 Using Product ID %2'
                                                                    ,Item[1]."No.",Item[1]."Shopify Product ID"));                      
        until Item[1].Next = 0;
        If GuiAllowed then Wind.Close;
        Log.reset;
        Log.Setfilter("Error Date/Time",'>=%1',CreateDateTime(Today,0T));
        Exit(Log.Count = 0);   
    end;     
     procedure Check_Product_ID(Item:record Item;var Cnt:integer):Text
    Var 
        Data:JsonObject;
        PayLoad:text;
        Parms:Dictionary of [text,text];
        JsArry:jsonArray;
        JsToken:array[2] of JsonToken;
        i:Integer;
        RetVal:Text;
        CRLF:text[2];
    Begin
        Clear(cnt);
        CRLF[1] := 13;
        CRLF[2] := 10;
        Clear(RetVal);
        Clear(Parms);
        Clear(PayLoad);
        Parms.add('fields','variants');
        If Shopify_Data(Paction::GET,ShopifyBase + 'products/'+ Format(Item."Shopify Product ID") + '.json'
                            ,Parms,Payload,Data) then 
        begin
            if Data.Get('product',JsToken[1]) then
                if JsToken[1].SelectToken('variants',jstoken[2]) then
                begin
                    JsArry := JsToken[2].AsArray();
                    for i := 0 to JsArry.Count - 1 do
                    begin
                        Cnt+=1;
                        JsArry.get(i,JsToken[1]);
                        jstoken[1].SelectToken('sku',JsToken[2]);
                        RetVal += 'SKU -> ' + JsToken[2].AsValue().AsCode();
                        JsToken[1].SelectToken('id',JsToken[2]);
                        RetVal += ' ID  -> ' + Format(JsToken[2].AsValue().AsBigInteger()) + CRLF;
                    end
                end
        end        
        else
             RetVal := 'Product ID not Found'; 
        exit(RetVal);                          
    End;
    procedure Update_Shopify_Child(var Item:Record Item;Act:option Delete,Create):Boolean
    var
        Flg:Boolean;
        Data:JsonObject;
        PayLoad:text;
        Parms:Dictionary of [text,text];
        Rel:Array[2] of Record "HL Shopify Item Relations";
        JsObj:jsonObject;
        JsObj1:jsonObject;
        JsArry:JsonArray;
        JsToken:array[2] of JsonToken;
        price:Decimal;
        Item2:record Item;
        ItemUnit:record "Item Unit of Measure";
        i:integer;
    begin
        Clear(flg);
        If Item."CRM Shopify Product ID" > 0 then
        begin
            Item2.reset;
            Item2.Setrange("Shopify Product ID",Item."CRM Shopify Product ID");
            If Item2.Findset then
            begin
                Rel[1].Reset;
                Rel[1].Setrange("Parent Item No.",Item2."No.");
                If (Act = Act::Delete) then 
                    Rel[1].Setrange("Un Publish Child",False)
                else
                    Rel[1].Setrange("Un Publish Child",True);
                If Rel[1].findset then
                begin
                    Clear(Parms);
                    Clear(Data);
                    Clear(PayLoad);
                    If (Act = Act::Delete) And (Item."Shopify Product Variant ID" > 0) 
                    And (Rel[1].Count > 1) then
                    begin
                        Parms.Add('fields','variants');
                        if Not Shopify_Data(Paction::GET,ShopifyBase + 'products/' + Format(Item."CRM Shopify Product ID") + '.json'
                                    ,Parms,PayLoad,Data) then
                            error(strsubstno('Failed to retrieve Item %1 with product ID %2 from shopify',Item."No.",Item."CRM Shopify Product ID"));            
                        Data.Get('product',JsToken[1]);
                        JsToken[1].SelectToken('variants',jstoken[2]);
                        JsArry := JsToken[2].AsArray();
                        for i := 0 to JsArry.Count - 1 do
                        begin
                            JsArry.get(i,JsToken[1]);
                            jstoken[1].SelectToken('sku',JsToken[2]);
                            if JsToken[2].AsValue().AsCode() = Item."No." then
                            begin
                                Clear(Parms);
                                JsToken[1].SelectToken('id',JsToken[2]);
                                If Not Shopify_Data(Paction::DELETE,ShopifyBase + 'products/'+ Format(Item."CRM Shopify Product ID") 
                                                        + '/variants/' + Format(jstoken[2].AsValue().AsBigInteger()) + '.json'
                                                        ,Parms,Payload,Data) Then
                                    error(StrSubstNo('Failed to delete Item %1 using product Id %2 variant %3 from shopify',Item."No."
                                                                                                                ,Item."CRM Shopify Product ID"
                                                                                                                ,jstoken[2].AsValue().AsBigInteger()))
                                else                                                                                                    
                                    break;
                            end;
                        end;
                        Clear(Item."Shopify Product Variant ID");
                        Clear(Item."Is In Shopify Flag");
                        Item."Shopify Transfer Flag" := true;
                        Item.Modify(False);
                        Rel[2].Reset;
                        Rel[2].Setrange("Parent Item No.",Rel[1]."Parent Item No.");
                        Rel[2].Setrange("Child Item no.",Item."No.");
                        if Rel[2].Findset then
                        begin
                            Rel[2]."Un Publish Child" := True;
                            Rel[2].Modify(false);
                        end;
                        flg := true;
                    End 
                    else If (Act = Act::Create) And (Item."Shopify Product Variant ID" = 0) Then 
                    begin
                        Clear(Jsobj);
                        Clear(Jsobj1);
                        JsObj.Add('sku',Item."No.");
                        JsObj.Add('option1',Item."Shopify Selling Option 1");
                        If Item."Shopify Selling Option 2" <> '' Then    
                            JsObj.Add('option2',Item."Shopify Selling Option 2");
                        price := Item.Get_Price();
                        JsObj.Add('price',format(price,0,'<Precision,2><Standard Format,1>'));
                        if (Price < Item."Unit Price")  then
                            JsObj.Add('compare_at_price',format(Item."Unit Price",0,'<Precision,2><Standard Format,1>'))
                        else
                            JsObj.Add('compare_at_price','');
                        JsObj.Add('inventory_management','shopify');
                        If ItemUnit.Get(Item."No.",Item."Base Unit of Measure") then
                        begin
                            JsObj.Add('weight',Format(ItemUnit.Weight,0,'<Precision,3><Standard Format,1>'));
                            JsObj.Add('weight_unit','kg');
                        end;     
                        jsObj1.Add('variant',JsObj);
                        Clear(PayLoad);
                        JsObj1.WriteTo(PayLoad);
                        If Shopify_Data(Paction::POST,
                                ShopifyBase + 'products/'+ Format(Item."CRM Shopify Product ID") +'/variants.json'
                                ,Parms,Payload,Data) then
                        begin             
                            Data.Get('variant',JsToken[1]);
                            Jstoken[1].SelectToken('id',JsToken[2]);
                            Item."Shopify Product Variant ID" := JsToken[2].AsValue().AsBigInteger();
                            Jstoken[1].SelectToken('inventory_item_id',JsToken[2]);
                            Item."Shopify Product Inventory ID" := JsToken[2].AsValue().AsBigInteger();
                            Item."Shopify Transfer Flag" := true;  // flag the creation of a new Item
                            Item."Is In Shopify Flag" := True;
                            Item."Is Child Flag" := True;
                            Item.modify(false);
                            Rel[2].Reset;
                            Rel[2].Setrange("Parent Item No.",Rel[1]."Parent Item No.");
                            Rel[2].Setrange("Child Item no.",Item."No.");
                            if Rel[2].Findset then
                            begin
                                Rel[2]."Un Publish Child" := False;
                                Rel[2].Modify(false);
                            end;    
                            Flg := True;
                        end
                        else
                            error('Failed to create Item %1 as a variant in shopify using product ID %1',Item."no.",Item."CRM Shopify Product ID");    
                    end;
                end;
            end;
        end;    
        exit(Flg);
    end;
    // Routine to move SKU from one parenet to another
    procedure Move_Shopify_SKU(var MRel:record "HL Shopify Item Relations" temporary):Boolean
    var
        Flg:Boolean;
        Data:JsonObject;
        PayLoad:text;
        Parms:Dictionary of [text,text];
        Rel:Record "HL Shopify Item Relations";
        JsObj:jsonObject;
        JsObj1:jsonObject;
        JsToken:array[2] of JsonToken;
        JsArry:JsonArray;
        price:Decimal;
        Item:array[2] of record Item;
        ItemUnit:record "Item Unit of Measure";
        i:Integer;
        Pos:Integer;
    begin
        Clear(Flg);
        If Mrel."Move To Parent" <> '' then
        begin
            Item[1].Get(Mrel."Move To Parent");
            If Item[1]."Shopify Product ID" > 0 then
            begin    
                // see if source parent has enough children after the strip
                Rel.Reset;
                Rel.Setrange("Parent Item No.",MRel."Parent Item No.");
                Rel.Findset();
                If Rel.Count - 1 > 0 then
                begin
                    Item[2].Get(Mrel."Child Item No.");
                    // see if the option we are about to move is already in the target
                    Clear(Parms); 
                    Parms.Add('fields','variants');
                    if not Shopify_Data(Paction::GET,ShopifyBase + 'products/' + Format(Item[1]."CRM Shopify Product ID") + '.json'
                                ,Parms,PayLoad,Data) then
                        error(strsubstno('Failed to retrieve Item %1 using product ID %2 from shopify',Item[1]."No.",Item[1]."CRM Shopify Product ID"));
                    Data.Get('product',JsToken[1]);
                    JsToken[1].SelectToken('variants',jstoken[2]);
                    JsArry := JsToken[2].AsArray();
                    for i := 0 to JsArry.Count - 1 do
                    begin
                        JsArry.get(i,JsToken[1]);
                        jstoken[1].SelectToken('option1',JsToken[2]);
                        If JsToken[2].AsValue().AsText() = Item[2]."Shopify Title" Then
                        begin
                            iF GuiAllowed then Message('Destination Parent already has a Variant with Option = %1 .. Move is invalid',Item[2]."Shopify Title");
                            exit(false);
                        end; 
                    end;
                    // now see if this is unpublished already ie we don't need to remove from 
                    // existing parent
                    If Not MRel."Un Publish Child" AND (Item[2]."CRM Shopify Product ID" > 0) then 
                    begin
                        if Not Shopify_Data(Paction::GET,ShopifyBase + 'products/' + Format(Item[2]."CRM Shopify Product ID") + '.json'
                                    ,Parms,PayLoad,Data) then
                            error(strsubstno('Failed to retrieve Item %1 using product ID %2 from shopify',Item[2]."No.",Item[2]."CRM Shopify Product ID"));
                        Data.Get('product',JsToken[1]);
                        JsToken[1].SelectToken('variants',jstoken[2]);
                        JsArry := JsToken[2].AsArray();
                        for i := 0 to JsArry.Count - 1 do
                        begin
                            JsArry.get(i,JsToken[1]);
                            jstoken[1].SelectToken('sku',JsToken[2]);
                            if JsToken[2].AsValue().AsCode() = Item[2]."No." then
                            begin
                                Clear(Parms);
                                JsToken[1].SelectToken('id',JsToken[2]);
                                Flg := Shopify_Data(Paction::DELETE,ShopifyBase + 'products/'+ Format(Item[2]."CRM Shopify Product ID") 
                                                        + '/variants/' + Format(jstoken[2].AsValue().AsBigInteger()) + '.json'
                                                        ,Parms,Payload,Data);
                                break;
                            end;    
                        end;
                    end
                    else
                        Flg := True;
                    If Flg then
                    begin
                        // now we are ready to move to new parent            
                        Clear(Jsobj);
                        Clear(Jsobj1);
                        JsObj.Add('sku',Item[2]."No.");
                        JsObj.Add('option1',Item[2]."Shopify Selling Option 1");
                        If Item[2]."Shopify Selling Option 2" <> '' Then    
                            JsObj.Add('option2',Item[2]."Shopify Selling Option 2");
                        price := Item[2].Get_Price();
                        JsObj.Add('price',format(price,0,'<Precision,2><Standard Format,1>'));
                        if (Price < Item[2]."Unit Price")  then
                            JsObj.Add('compare_at_price',format(Item[2]."Unit Price",0,'<Precision,2><Standard Format,1>'))
                        else
                            JsObj.Add('compare_at_price','');
                        JsObj.Add('inventory_management','shopify');    
                        If ItemUnit.Get(Item[2]."No.",Item[2]."Base Unit of Measure") then
                        begin
                            JsObj.Add('weight',Format(ItemUnit.Weight,0,'<Precision,3><Standard Format,1>'));
                            JsObj.Add('weight_unit','kg');
                        end;     
                        jsObj1.Add('variant',JsObj);
                        Clear(PayLoad);
                        JsObj1.WriteTo(PayLoad);
                        Flg := Shopify_Data(Paction::POST,
                                    ShopifyBase + 'products/'+ Format(Item[1]."Shopify Product ID") +'/variants.json'
                                    ,Parms,Payload,Data);
                        if Flg then            
                        begin
                            // save to remove from old parent relation
                            Rel.Get(Mrel."Parent Item No.",Mrel."Child Item No.");
                            POS := Rel."Child Position";
                            Rel.Delete();
                            Data.Get('variant',JsToken[1]);
                            Jstoken[1].SelectToken('id',JsToken[2]);
                            Item[2]."Shopify Product Variant ID" := JsToken[2].AsValue().AsBigInteger();
                            Jstoken[1].SelectToken('inventory_item_id',JsToken[2]);
                            Item[2]."Shopify Product Inventory ID" := JsToken[2].AsValue().AsBigInteger();
                            Item[2]."Shopify Transfer Flag" := true;  // flag the creation of a new Item
                            Item[2]."Is In Shopify Flag" := True;
                            Item[2]."Is Child Flag" := True;
                            Item[2]."CRM Shopify Product ID" := Item[1]."Shopify Product ID";
                            Item[2].modify(false);
                            // build new parent relation
                            Rel.init;
                            Rel."Parent Item No." := Item[1]."No.";
                            Rel."Child Item No." := Item[2]."No.";
                            Rel."Child Position" := POS;
                            Rel.Insert(True);
                            Commit;
                        end
                        else
                        begin 
                            // here if something went wrong we reasign back to original parent
                            Item[1].Get(MRel."Parent Item No.");
                            If Shopify_Data(Paction::POST,
                                    ShopifyBase + 'products/'+ Format(Item[1]."Shopify Product ID") +'/variants.json'
                                    ,Parms,Payload,Data) then
                            begin        
                                Data.Get('variant',JsToken[1]);
                                Jstoken[1].SelectToken('id',JsToken[2]);
                                Item[2]."Shopify Product Variant ID" := JsToken[2].AsValue().AsBigInteger();
                                Jstoken[1].SelectToken('inventory_item_id',JsToken[2]);
                                Item[2]."Shopify Product Inventory ID" := JsToken[2].AsValue().AsBigInteger();
                                Item[2]."Shopify Transfer Flag" := true;  // flag the creation of a new Item
                                Item[2]."Is In Shopify Flag" := True;
                                Item[2]."Is Child Flag" := True;
                                Item[2]."CRM Shopify Product ID" := Item[1]."Shopify Product ID";
                                Item[2].modify(false);
                            end;
                        end;
                    end;
                end;
            end;            
        end;
        exit(flg);
    end;   
    // Simple routine to test Shopify Connection is working 
    procedure Shopify_Test_Connection():Boolean
    var
        Data:JsonObject;
        PayLoad:text;
        Parms:Dictionary of [text,text];
    begin
        Clear(Parms);
        exit(Shopify_Data(Paction::GET,
                        ShopifyBase + 'products/count.json'
                        ,Parms,Payload,Data));
    end;
    //Simple routine to set all the items flags in a clear state
    local procedure Clear_Flags(var Item:Record Item)
    begin
        Clear(Item."Shopify Product ID");
        Clear(Item."Shopify Product Variant ID");
        Clear(Item."Shopify Product Inventory ID");
        Clear(Item."Shopify Location Inventory ID");
        Item."Shopify Transfer Flag" := True;
        If Item.Type = Item.type::"Non-Inventory" then 
        begin
            Clear(Item."CRM Shopify Product ID");
            Item."Shopify Item" := Item."Shopify Item"::internal;
        end;    
        Clear(Item."Shopify Publish Flag");
        Clear(Item."Is In Shopify Flag");
        Item."Shopify Update Flag" := true;
        Item.Modify(false);
    end;
    //routine to remove items from shopify
    procedure Delete_Items(ItemFilt:Code[20]):Boolean
    var
        Item:array[2] of Record Item;
        Data:JsonObject;
        PayLoad:text;
        Parms:Dictionary of [text,text];
        rel:record "HL Shopify Item Relations";
    begin
        Item[1].Reset;
        Item[1].Setrange("No.",ItemFilt);
        Item[1].Setfilter("Shopify Product ID",'>0');
        If Item[1].Findset then
        begin
            Clear(Data);
            Clear(PayLoad);
            Clear(Parms);
            if Shopify_Data(Paction::DELETE,ShopifyBase + 'products/' 
                        + Format(Item[1]."Shopify Product ID") + '.json'
                         ,Parms,PayLoad,Data) then
            begin
                Clear_Flags(Item[1]);
                // see if we have some children
                Rel.Reset;
                rel.Setrange("Parent Item No.",Item[1]."No.");
                If Rel.findset then
                repeat
                    if Item[2].Get(Rel."Child Item No.") then Clear_Flags(Item[2]);
                until rel.next = 0;
            end;
            Check_Delete_By_Title(Item[1]);
            Clear_Flags(Item[1]);
            Commit;    
            exit(true);
        end;    
        exit(true);
    end;
    //extra precautionary delete mechanism to ensure removal of product from shopify
    local procedure Check_Delete_By_Title(var Item:record Item)
    var
        Data:JsonObject;
        JsToken:array[2] of JsonToken;
        JsArry:jsonArray;
        PayLoad:text;
        Parms:Dictionary of [text,text];
        Item2:Record Item;
        rel:record "HL Shopify Item Relations";
        Flg:Boolean;
        i:integer;
    begin
        If Strlen(Item."Shopify Title") > 0 then
        begin
            Clear(Flg);
            Clear(Parms);
            Clear(Data);
            Clear(PayLoad);
            Parms.Add('fields','id');
            Parms.Add('title',Item."Shopify Title".Replace('&','%26'));
            if Shopify_Data(Paction::GET,ShopifyBase + 'products.json'
                         ,Parms,PayLoad,Data) then
            begin
                Data.Get('products',JsToken[1]);
                JsArry := JsToken[1].AsArray();
                for i := 0 to JsArry.Count - 1 do
                begin
                    Clear(Parms);
                    JsArry.get(i,JsToken[1]);
                    jstoken[1].SelectToken('id',JsToken[2]);
                    If Shopify_Data(Paction::DELETE,ShopifyBase + 'products/' 
                                    + JsToken[2].AsValue().AsText() + '.json'
                                    ,Parms,PayLoad,Data) then
                    Begin              
                        Clear_Flags(Item);
                        Rel.Reset;
                        rel.Setrange("Parent Item No.",Item."No.");
                        If Rel.findset then
                        repeat
                            Item2.Get(Rel."Child Item No.");
                            Clear_Flags(Item2);
                        until rel.next = 0;
                    end;    
                end;
            end;    
            Commit;
        end;        
    end;
    // routine to compare BC product ID's with Shopify ID's 
    // and remove any shopify products that BC does not know about
    Procedure Remove_Shopify_Duplicates()
    var
        Data:JsonObject;
        JsToken:array[2] of JsonToken;
        JsArry:jsonArray;
        PayLoad:text;
        Parms:Dictionary of [text,text];
        i:integer;
        Cnt:Integer;
        remCnt:integer;
        Item:record Item;
        win:dialog;
        indx:BigInteger;
    begin
        If GuiAllowed then win.Open('Removing Product ID #1################\'
                                   +'Removal Count #2######');
        Clear(Parms);
        Clear(Data);
        Clear(PayLoad);
        Clear(remCnt);
        Clear(indx);
        if Shopify_Data(Paction::GET,ShopifyBase + 'products/count.json'
                     ,Parms,PayLoad,Data) then
        begin
            Data.Get('count',JsToken[1]);
            Cnt := JsToken[1].AsValue().AsInteger();
            repeat
                Cnt -= 250;
                Clear(Parms);
                Parms.Add('limit','250');   
                Parms.Add('fields','id');
                Parms.Add('since_id',Format(indx));
                Sleep(20);
                if Shopify_Data(Paction::GET,ShopifyBase + 'products.json'
                         ,Parms,PayLoad,Data) then
                begin
                    Clear(Parms);
                    Data.Get('products',JsToken[1]);
                    JsArry := JsToken[1].AsArray();
                    for i := 0 to JsArry.Count - 1 do
                    begin
                        JsArry.get(i,JsToken[1]);
                        jstoken[1].SelectToken('id',JsToken[2]);
                        Item.Reset;
                        Item.Setrange("Shopify Product ID",JsToken[2].AsValue().AsBigInteger());
                        If Not Item.Findset then  
                        Begin
                            if Shopify_Data(Paction::DELETE,ShopifyBase + 'products/' 
                                        + JsToken[2].AsValue().AsText() + '.json'
                                        ,Parms,PayLoad,Data) then
                            begin 
                                RemCnt +=1;
                                if GuiAllowed then 
                                begin
                                    win.Update(1,JsToken[2].AsValue().AsText());
                                    Win.update(2,remCnt);
                                end;    
                            end;                    
                        end;
                    end;
                    indx := JsToken[2].AsValue().AsBigInteger();
                end;    
            until Cnt <= 0;
            if GuiAllowed then
            begin
                win.close;
                Message('%1 Duplicates have been removed from Shopify',Remcnt);
            end;    
        end;
    end;     
    //routine to purge all data from shopify 
    procedure Clean_Shopify()
    var
        Data:JsonObject;
        JsToken:array[2] of JsonToken;
        JsArry:jsonArray;
        PayLoad:text;
        Parms:Dictionary of [text,text];
        i:integer;
        Cnt:Integer;
        remCnt:integer;
        Item:record Item;
        win:dialog;
        indx:BigInteger;
    begin
        if GuiAllowed then win.Open('Removing Product ID #1################\'
                                   +'Removal Count #2######');
        Clear(Parms);
        Clear(Data);
        Clear(PayLoad);
        Clear(remCnt);
        Clear(indx);
        if Shopify_Data(Paction::GET,ShopifyBase + 'products/count.json'
                     ,Parms,PayLoad,Data) then
        begin
            Data.Get('count',JsToken[1]);
            Cnt := JsToken[1].AsValue().AsInteger();
            If Cnt > 0 then
            begin
                repeat
                    Cnt -= 250;
                    Clear(Parms);
                    Parms.Add('limit','250');   
                    Parms.Add('fields','id');
                    Parms.Add('since_id',Format(indx));
                    Sleep(20);
                    if Shopify_Data(Paction::GET,ShopifyBase + 'products.json'
                            ,Parms,PayLoad,Data) then
                    begin
                        Clear(Parms);
                        Data.Get('products',JsToken[1]);
                        JsArry := JsToken[1].AsArray();
                        for i := 0 to JsArry.Count - 1 do
                        begin
                            JsArry.get(i,JsToken[1]);
                            jstoken[1].SelectToken('id',JsToken[2]);
                            if Shopify_Data(Paction::DELETE,ShopifyBase + 'products/' 
                                            + JsToken[2].AsValue().AsText() + '.json'
                                            ,Parms,PayLoad,Data) then
                            begin
                                RemCnt +=1;
                                if GuiAllowed then
                                begin
                                    win.Update(1,JsToken[2].AsValue().AsText());
                                    Win.update(2,remCnt);
                                end;    
                            end;                    
                        end;
                    end;
                    Indx := JsToken[2].AsValue().AsBigInteger();
                until Cnt <= 0;
            end;    
            if GuiAllowed then win.close;
            Item.Reset;
            Item.Setrange("Shopify Item",Item."Shopify Item"::Shopify);
            Item.findset;
            repeat
                Clear_Flags(Item);
            until Item.next = 0;    
        end;            
    end;     
    // simple routine to access the corect price for SKU's in Shopify
    [TryFunction]
    procedure Update_Order_Locations(OrdId:BigInteger)
    var
        //Loc:record Location;
        OrdHdr:record "HL Shopify Order Header";
        OrdLine:array[2] of Record "HL Shopify Order Lines";
        BatchLine:Record "HL Sales Batch No";
        XmlDoc:XmlDocument;
        CurrNode:Array[3] of XmlNode;
        CuXML:Codeunit "XML DOM Management";
        xmlNodeLst:array[2] of XmlNodeList;
        Batchs:list of [text];
        BatchList:Dictionary of [text,text];
        BatInfo:array[2] of Text;
        lineID:BigInteger;
        i:integer;
        j:integer;
        Sku:Code[20];
        Item:record Item;
        Qty:Decimal;
        Excp:Record "HL Shopify Order Exceptions";
        Bom:record "BOM Component";
        Flg:Boolean;
        ErrFlg:Boolean;
        CU:Codeunit "HL NPF Routines";
        DisTot:Decimal;
        OrdTot:Decimal;
        HasOther:Boolean;
        win:dialog;
        RecCnt:integer;
    begin
        if GuiAllowed then Win.Open('Processing Order No #1############');
        Ordhdr.Reset;
        OrdHdr.SetRange("Order Status",Ordhdr."Order Status"::Open);
        If OrdId <> 0 then OrdHdr.Setrange(ID,OrdId);
        OrdHdr.Setrange("Order Type",OrdHdr."Order Type"::CreditMemo);
        If OrdHdr.Findset then
        repeat
            Excp.Reset;
            Excp.Setrange(ShopifyID,OrdHdr.ID);
            If Excp.Findset then Excp.Deleteall();
            if GuiAllowed then Win.Update(1,OrdHdr."Shopify Order No.");
            OrdLine[1].Reset;
            Ordline[1].SetRange("ShopifyID",OrdHdr.ID);
            Ordline[1].Setfilter("Item No.",'<>%1','');
            OrdLine[1].Setfilter("order Qty",'>0');
            If Ordline[1].FindSet() then
            repeat
                Item.get(OrdLine[1]."Item No.");
                // here we expand the Bom Components
                If Item.HasBOM() and Not Item."Sold As Finished Item" then
                begin
                    i := -1;
                    Bom.Reset;
                    Bom.Setrange("Parent Item No.",Item."No.");
                    Bom.Setrange(Type,Bom.Type::Item);
                    If Bom.Findset then
                    repeat
                        i += 1;
                        If i = 0 then
                        begin
                            OrdTot := OrdLine[1]."Base Amount";
                            DisTot := OrdLine[1]."Discount Amount";
                            Ordline[1]."Bundle Item No." := Item."No.";
                            Ordline[1]."Bundle Order Qty" := Ordline[1]."Order Qty";
                            Ordline[1]."Bundle Unit Price" := Ordline[1]."Unit Price";
                            Ordline[1]."BOM Qty" := Bom."Quantity per";
                            Ordline[1]."Item No." := Bom."No.";
                            Ordline[1]."Order Qty" := Ordline[1]."Bundle Order Qty" * Ordline[1]."BOM Qty";
                            Ordline[1]."Unit Price" := Ordline[1]."Bundle Unit Price"/Ordline[1]."BOM Qty";
                            Ordline[1]."Unit Price" := (Ordline[1]."Unit Price" * Bom."Bundle Price Value %")/100;
                            OrdLine[1]."Location Code" := 'QC';
                            OrdLine[1]."Unit Of Measure" := Bom."Unit of Measure Code";
                            OrdLine[1]."NPF Shipment Qty" := OrdLine[1]."Order Qty";
                            OrdLine[1]."Discount Amount" :=  (DisTot * Bom."Bundle Price Value %")/100;
                            OrdLine[1]."Base Amount" := (OrdTot * Bom."Bundle Price Value %")/100;
                            Ordline[1].Modify(false);
                            OrdLine[2].Copy(Ordline[1]);    
                        end
                        else
                        begin
                            Clear(OrdLine[2].ID);
                            Ordline[2]."BOM Qty" := Bom."Quantity per";
                            Ordline[2]."Item No." := Bom."No.";
                            Ordline[2]."Order Qty" := Ordline[2]."Bundle Order Qty" * Ordline[2]."BOM Qty";
                            Ordline[2]."Unit Price" := Ordline[2]."Bundle Unit Price"/Ordline[2]."BOM Qty";
                            Ordline[2]."Unit Price" := (Ordline[2]."Unit Price" * Bom."Bundle Price Value %")/100;
                            OrdLine[2]."Unit Of Measure" := Bom."Unit of Measure Code";
                            OrdLine[2]."Order Line No" += i;
                            OrdLine[2]."NPF Shipment Qty" := OrdLine[2]."Order Qty";
                            OrdLine[2]."Discount Amount" :=  (DisTot * Bom."Bundle Price Value %")/100;
                            OrdLine[2]."Base Amount" := (OrdTot * Bom."Bundle Price Value %")/100;
                            OrdLine[2].Insert();
                        end;          
                    until Bom.Next = 0;
                end
                else
                begin
                    OrdLine[1]."Location Code" := 'QC';
                    OrdLine[1]."Unit Of Measure" := Item."Base Unit of Measure";
                    OrdLine[1]."NPF Shipment Qty" := OrdLine[1]."Order Qty";
                end; 
                Ordline[1].Modify(false);
            until OrdLine[1].next = 0;
            OrdHdr."NPF Shipment Status" := OrdHdr."NPF Shipment Status"::Complete;
            OrdHdr.modify;
        until OrdHdr.next = 0;
        Clear(RecCnt);
        Ordhdr.Reset;
        OrdHdr.SetRange("Order Status",Ordhdr."Order Status"::Open);
        OrdHdr.Setrange("Order Type",OrdHdr."Order Type"::Invoice);
        OrdHdr.Setrange("NPF Shipment Status",OrdHdr."NPF Shipment Status"::InComplete);
        If OrdId <> 0 then OrdHdr.Setrange(ID,OrdID);
        OrdHdr.Setfilter("Shopify Order Status",'<>NULL');
        If OrdHdr.Findset then
        repeat
            RecCnt += 1;
            if GuiAllowed then Win.Update(1,OrdHdr."Shopify Order No.");
            OrdLine[1].Reset;
            Ordline[1].SetRange("ShopifyID",OrdHdr.ID);
            Ordline[1].Setfilter("Item No.",'<>%1','');
            OrdLine[1].Setfilter("order Qty",'>0');
            OrdLine[1].Setrange("Is NPF Item",True);
            If Ordline[1].FindSet() then
            repeat
                Item.get(OrdLine[1]."Item No.");
                // here we expand the Bom Components
                If Item.HasBOM() and Not Item."Sold As Finished Item" then
                begin
                    i:= -1;
                    Bom.Reset;
                    Bom.Setrange("Parent Item No.",Item."No.");
                    Bom.Setrange(Type,Bom.Type::Item);
                    If Bom.Findset then
                    repeat
                        i += 1;
                        If i = 0 then
                        begin
                            OrdTot := OrdLine[1]."Base Amount";
                            DisTot := OrdLine[1]."Discount Amount";
                            Ordline[1]."Bundle Item No." := Item."No.";
                            Ordline[1]."Bundle Order Qty" := Ordline[1]."Order Qty";
                            Ordline[1]."Bundle Unit Price" := Ordline[1]."Unit Price";
                            Ordline[1]."BOM Qty" := Bom."Quantity per";
                            Ordline[1]."Item No." := Bom."No.";
                            Ordline[1]."Order Qty" := Ordline[1]."Bundle Order Qty" * Ordline[1]."BOM Qty";
                            Ordline[1]."Unit Price" := Ordline[1]."Bundle Unit Price"/Ordline[1]."BOM Qty";
                            Ordline[1]."Unit Price" := (Ordline[1]."Unit Price" * Bom."Bundle Price Value %")/100;
                            OrdLine[1]."Unit Of Measure" := Bom."Unit of Measure Code";
                            OrdLine[1]."Discount Amount" :=  (DisTot * Bom."Bundle Price Value %")/100;
                            OrdLine[1]."Base Amount" := (OrdTot * Bom."Bundle Price Value %")/100;
                            Ordline[1].Modify(false);
                            OrdLine[2].Copy(Ordline[1]);    
                        end
                        else
                        begin
                            Clear(OrdLine[2].ID);
                            Ordline[2]."BOM Qty" := Bom."Quantity per";
                            Ordline[2]."Item No." := Bom."No.";
                            Ordline[2]."Order Qty" := Ordline[2]."Bundle Order Qty" * Ordline[2]."BOM Qty";
                            Ordline[2]."Unit Price" := Ordline[2]."Bundle Unit Price"/Ordline[2]."BOM Qty";
                            Ordline[2]."Unit Price" := (Ordline[2]."Unit Price" * Bom."Bundle Price Value %")/100;
                            OrdLine[2]."Unit Of Measure" := Bom."Unit of Measure Code";
                            OrdLine[2]."Discount Amount" :=  (DisTot * Bom."Bundle Price Value %")/100;
                            OrdLine[2]."Base Amount" := (OrdTot * Bom."Bundle Price Value %")/100;
                            OrdLine[2]."Order Line No" += i;
                            OrdLine[2].Insert();
                        end;          
                    until Bom.Next = 0;
                end;
                If Item.Type = Item.Type::"Non-Inventory" then
                begin
                    OrdLine[1]."Location Code" := 'NSW';
                    OrdLine[1]."Unit Of Measure" := Item."Base Unit of Measure";
                    OrdLine[1]."NPF Shipment Qty" := OrdLine[1]."Order Qty";
                    OrdLine[1].modify;
                end;
            Until OrdLine[1].next = 0;            
            // clear the exception log
            Excp.Reset;
            Excp.Setrange(ShopifyID,OrdHdr.ID);
            If Excp.Findset then Excp.Deleteall();
            Clear(HasOther);
            Clear(DisTot);
            // fix all the non NPF Types
            OrdLine[1].Reset;
            Ordline[1].SetRange("ShopifyID",OrdHdr.ID);
            Ordline[1].Setfilter("Item No.",'<>%1','');
            OrdLine[1].Setrange("Is NPF Item",False);
            OrdLine[1].Setfilter("order Qty",'>0');
            If OrdLine[1].Findset then
            begin
                HasOther := True;
                Ordline[1].CalcSums("Order Qty","Base Amount","Discount Amount");
                DisTot := OrdLine[1]."Discount Amount";
                OrdHdr."Order Total" := OrdLine[1]."Base Amount" - DisTot;
                repeat
                    OrdLine[1]."NPF Shipment Qty" := OrdLine[1]."Order Qty";
                    OrdLine[1]."Location Code" := 'NSW';
                    Item.Get(Ordline[1]."Item No.");
                    Ordline[1]."Unit Of Measure" := Item."Base Unit of Measure";    
                    OrdLine[1].Modify(False);
                until OrdLine[1].next = 0;
            end;              
            // now do all the NPF types
            OrdLine[1].Reset;
            Ordline[1].SetRange(ShopifyID,OrdHdr.ID);
            OrdLine[1].SetFilter("Location Code",'=%1','');
            Ordline[1].Setfilter("Item No.",'<>%1','');
            OrdLine[1].Setrange("Is NPF Item",True);
            OrdLine[1].Setfilter("order Qty",'>0');
            if OrdLine[1].findset then
            begin
                If CU.Get_Order_Shipment(Format(OrdHdr."Shopify Order ID"),XmlDoc) then
                begin
                    CurrNode[1] := XmlDoc.AsXmlNode();
                    if CuXML.FindNode(CurrNode[1],'//OrderList/Order/ShipmentDetails/Shipment/Products',CurrNode[2]) then 
                    begin
                        CurrNode[2].AsXmlElement().SelectNodes('Product',xmlNodeLst[1]);
                        For i := 1 to XMLNodeLst[1].Count do
                        begin
                            Clear(ErrFlg);
                            Clear(SKU);
                            Clear(Qty);
                            XmlNodeLst[1].Get(i,CurrNode[1]);
                            if CUXml.FindNode(CurrNode[1],'Code',CurrNode[2]) then
                                SKU := CurrNode[2].AsXmlElement().InnerText
                            else
                                ErrFlg := true;
                            if Not ErrFlg then        
                                if CUXml.FindNode(CurrNode[1],'Quantity',CurrNode[2]) then
                                    If Not Evaluate(Qty,CurrNode[2].AsXmlElement().InnerText) then
                                        ErrFlg := True;
                            If Not ErrFlg then            
                                if CUXml.FindNode(CurrNode[1],'SourceOrderItemUniqueIdentifier',CurrNode[2]) then
                                    If Not evaluate(lineID,CurrNode[2].AsXmlElement().InnerText) then
                                    begin
                                        OrdLine[1].Reset;
                                        Ordline[1].SetRange(ShopifyID,OrdHdr.ID);
                                        Ordline[1].Setrange("Item No.",SKU);
                                        OrdLine[1].SetFilter("Bundle Item No.",'<>%1','');
                                        If OrdLine[1].findset then
                                            lineID := OrdLine[1]."Order Line ID"
                                        else
                                            ErrFlg := True;
                                    end;
                            if not ErrFlg then                        
                                if CUXml.FindNode(CurrNode[1],'BatchAndExpiryList',CurrNode[2]) and Not Errflg then
                                    if CurrNode[2].AsXmlElement().SelectNodes('BatchAndExpiry',xmlNodeLst[2]) then
                                    begin
                                        Clear(BatchList);
                                        For j := 1 to XMLNodeLst[2].Count do
                                        begin
                                            Clear(BatInfo);
                                            XmlNodeLst[2].Get(j,CurrNode[1]);
                                            If CUXml.FindNode(CurrNode[1],'BatchNumber',CurrNode[2]) then
                                                If Strlen(CurrNode[2].AsXmlElement().InnerText) > 0 then
                                                begin
                                                    Batinfo[1] := CurrNode[2].AsXmlElement().InnerText + ',';
                                                    if CUXml.FindNode(CurrNode[1],'ExpiryDate',CurrNode[2]) then
                                                        Batinfo[1] += CurrNode[2].AsXmlElement().InnerText + ',';
                                                    If BatchList.ContainsKey(SKU) then
                                                    begin
                                                        BatchList.get(SKU,BatInfo[2]);
                                                        BatchList.Set(SKU,BatInfo[1] + BatInfo[2]);    
                                                    end
                                                    else
                                                        BatchList.Add(SKU,BatInfo[1]);
                                                    If BatchList.get(SKU,BatInfo[1]) then BatchList.Set(SKU,BatInfo[1].Remove(BatInfo[1].LastIndexOf(','),1));
                                                end;        
                                        end;
                                    end;
                            If Not ErrFlg and (Qty > 0) then
                            begin
                                Clear(flg); 
                                OrdLine[1].Reset;
                                Ordline[1].SetRange(ShopifyID,OrdHdr.ID);
                                Ordline[1].Setrange("Item No.",SKU);
                                OrdLine[1].Setrange("Order Line ID",lineID);
                                Ordline[1].Setfilter("Order Qty",'>0');
                                OrdLine[1].Setrange("Is NPF Item",True);
                                Ordline[1].Setrange("NPF Shipment Qty",0);
                                if Ordline[1].FindSet then
                                repeat
                                    If Qty >= OrdLine[1]."Order Qty" then
                                    begin
                                        Flg := True; // flag that we have some qty resolved
                                        Ordline[1]."NPF Shipment Qty" := OrdLine[1]."Order Qty";
                                        Qty -= OrdLine[1]."Order Qty"; 
                                    end;
                                    If Flg then
                                    begin
                                        OrdLine[1]."Location Code" := 'NSW';
                                        Item.Get(Ordline[1]."Item No.");
                                        Ordline[1]."Unit Of Measure" := Item."Base Unit of Measure";    
                                    end;
                                    If BatchList.get(Item."No.",BatInfo[1]) then
                                    begin
                                        Batchs := BatInfo[1].Split(',');             
                                        For j := 1 to Batchs.Count do
                                        begin
                                            If j Mod 2 = 1 then
                                            begin
                                                BatchLine.init;
                                                Clear(BatchLine.ID);
                                                BatchLine.insert;
                                                BatchLine."Order Line ID" := OrdLine[1].ID;
                                                BatchLine."Batch No" := CopyStr(batchs.get(j),1,30);      
                                            end
                                            else
                                            begin
                                                If Not Evaluate(BatchLine."Expiry Date",Batchs.get(j)) then
                                                    Clear(BatchLine."Expiry Date");
                                                BatchLine.modify;               
                                            end;
                                        end;            
                                    end;
                                    OrdLine[1].Modify;
                                    Commit;      
                                until OrdLine[1].next = 0;
                            end;
                        end;
                         //check to make sure some lines are processed
                        OrdLine[1].Reset;
                        Ordline[1].SetRange(ShopifyID,OrdHdr.ID);
                        Ordline[1].Setfilter("Item No.",'<>%1','');
                        OrdLine[1].Setrange("Is NPF Item",True);
                        OrdLine[1].Setfilter("order Qty",'>0');
                        If OrdLine[1].Findset then
                        begin
                            Ordline[1].CalcSums("Order Qty","NPF Shipment Qty","Base Amount","Discount Amount");
                            //see if order total has other lines then we add to this amount;
                            If HasOther then
                                OrdHdr."Order Total" += OrdLine[1]."Base Amount" - OrdLine[1]."Discount Amount" + OrdHdr."Freight Total"
                            else
                                OrdHdr."Order Total" := OrdLine[1]."Base Amount" - OrdLine[1]."Discount Amount" + OrdHdr."Freight Total";
                            If Ordline[1]."Order Qty" <> Ordline[1]."NPF Shipment Qty" then
                            begin
                                // see if we have more than one line order
                                If OrdLine[1].Count > 1 then
                                begin
                                    // makes sure all the discounts relate to the order lines and
                                    //not to the order as well
                                    Ordline[1].CalcSums("Discount Amount");
                                    If OrdHdr."Discount Total" = OrdLine[1]."Discount Amount" + DisTot then
                                    begin
                                        OrdLine[1].SetRange("NPF Shipment Qty",0);
                                        If OrdLine[1].FindSet() then
                                        begin
                                            Ordline[1].CalcSums("Base Amount","Discount Amount");
                                            OrdHdr."Order Total" -= OrdLine[1]."Base Amount" - OrdLine[1]."Discount Amount";
                                            OrdHdr."Discount Total" -= OrdLine[1]."Discount Amount";
                                            OrdHdr.modify();
                                            OrdLine[1].ModifyAll("Not Supplied",True);     
                                        end;                                                                    
                                    end    
                                    else
                                    begin
                                        Excp.init;
                                        Clear(Excp.ID);
                                        Excp.insert;
                                        Excp.ShopifyID := OrdHdr.ID;
                                        Excp.Exception := StrsubStno('Unable to Correct Order as an Order discount also applies'); 
                                        excp.Modify();
                                    end;
                                end
                                else
                                begin
                                    Excp.init;
                                    Clear(Excp.ID);
                                    Excp.insert;
                                    Excp.ShopifyID := OrdHdr.ID;
                                    Excp.Exception := StrsubStno('NPF -> Unable to Correct Order as there is only one line and it''s missing.'); 
                                    excp.Modify();
                                end;
                            end;
                        end;    
                    end
                    else
                    begin
                        Excp.init;
                        Clear(Excp.ID);
                        Excp.insert;
                        Excp.ShopifyID := OrdHdr.ID;
                        Excp.Exception := 'NPF -> Failed to retrieve Product List For Order';
                        excp.Modify();
                    end;
                end
                else
                begin
                    Excp.init;
                    Clear(Excp.ID);
                    Excp.insert;
                    Excp.ShopifyID := OrdHdr.ID;
                    Excp.Exception := 'Failed to retrieve Shopify Order ID ' + Format(OrdHdr."Shopify Order ID") +' via NPF Shipments API';
                    excp.Modify();
                end;
            end;    
            If RecCnt > 50 then
            begin
                Clear(RecCnt);
                Commit;
            end;
        until OrdHdr.next = 0;
        Commit;
        if GuiAllowed then
        begin 
            Win.Close;
            Win.Open('Updating NPF Shipment Status For Order #1###########');
        end;    
        Ordhdr.Reset;
        OrdHdr.SetRange("Order Status",Ordhdr."Order Status"::Open);
        OrdHdr.Setrange("Order Type",OrdHdr."Order Type"::Invoice);
        OrdHdr.Setrange("NPF Shipment Status",OrdHdr."NPF Shipment Status"::InComplete);
        If OrdId <> 0 then OrdHdr.Setrange(ID,OrdID);
        OrdHdr.Setfilter("Shopify Order Status",'<>NULL');
        If OrdHdr.Findset then
        repeat
            if GuiAllowed then Win.Update(1,OrdHdr."Shopify Order No.");
            OrdLine[1].Reset;
            Ordline[1].SetRange("ShopifyID",OrdHdr.ID);
            Ordline[1].SetRange("Not Supplied",False);
            Ordline[1].Setfilter("Item No.",'<>%1','');
            OrdLine[1].Setfilter("order Qty",'>0');
            If Ordline[1].Findset then
            begin
                Ordline[1].CalcSums("Order Qty","NPF Shipment Qty");
                If Ordline[1]."Order Qty" = Ordline[1]."NPF Shipment Qty" then 
                begin                   
                    OrdHdr."NPF Shipment Status" := OrdHdr."NPF Shipment Status"::Complete;       
                    OrdHdr.Modify();
                end
                else
                begin
                    Excp.init;
                    Clear(Excp.ID);
                    Excp.insert;
                    Excp.ShopifyID := OrdHdr.ID;
                    Excp.Exception := StrsubStno('NPF -> Order Total Qty = %1,NPF Shipped Total Qty = %2.',Ordline[1]."Order Qty", Ordline[1]."NPF Shipment Qty"); 
                    excp.Modify();
                    repeat
                        If Ordline[1]."NPF Shipment Qty" = 0 then
                        begin
                            Excp.init;
                            Clear(Excp.ID);
                            Excp.insert;
                            Excp.ShopifyID := OrdHdr.ID;
                            if OrdLine[1]."Bundle Item No." <> '' then
                                Excp.Exception := StrsubStno('NPF -> Bundle Item %1 possibly changed directly in NPF',OrdLine[1]."Bundle Item No.")
                            else
                                Excp.Exception := StrsubStno('NPF -> Item %1 possibly changed directly in NPF',OrdLine[1]."Item No.");
                            excp.Modify();
                        end;
                    until OrdLine[1].next = 0;        
                end;
            end;
            Update_Order_Application(OrdHdr);
        until OrdHdr.next = 0;
        if GuiAllowed then Win.Close;
        Commit;
    end;
    //routine to update the Order applications    
    local Procedure Update_Order_Application(var OrdHdr:Record "HL Shopify Order Header")
    var
        OrdLine:Record "HL Shopify Order Lines";
        OrdApp:Record "HL Shopfiy Order Applications";
        DiscApp:Record "HL Shopify Disc Apps";
    Begin
        OrdLine.Reset;
        Ordline.SetRange(ShopifyID,OrdHdr.ID);
        If Ordline.findset then
        repeat
            Clear(Ordline."Shopify Application ID");
            OrdApp.Reset;
            OrdApp.Setrange("Shopify Order ID",OrdHdr."Shopify Order ID");
            OrdApp.Setrange("Shopify Disc App Index",OrdLine."Shopify Application Index");
            If OrdApp.findset then
                If DiscApp.Get(OrdApp."Shopify Application Type",OrdApp."Shopify Disc App Code",OrdApp."Shopify Disc App Value") then
                    Ordline."Shopify Application ID" := DiscApp."Shopify App ID";
            Ordline.Modify();
        until Ordline.next = 0;    
    End;
    local procedure Check_For_Gift_Card(PJstoken:JsonToken;ID:BigInteger):Boolean
    var
        JsArry:JsonArray;
        JsToken:Array[2] of JsonToken;
        i:Integer;
        Dat:date;
        HasGiftCard:Boolean;
        exflg:Boolean;
        Setup:record "Sales & Receivables Setup";
    Begin 
        Setup.Get;
        exflg := True;
        Clear(HasGiftCard);
        if PJstoken.SelectToken('processed_at',Jstoken[1]) then
            If Not JsToken[1].AsValue().IsNull then
                If Evaluate(Dat,Copystr(JsToken[1].AsValue().AsText(),9,2) + '/' 
                        + Copystr(JsToken[1].AsValue().AsText(),6,2) + '/' + Copystr(JsToken[1].AsValue().AsText(),1,4)) then
        begin                   
            If PJstoken.SelectToken('line_items',Jstoken[1]) then
            begin
                JsArry := JsToken[1].AsArray();
                For i := 0 to JsArry.Count - 1 do
                begin
                    JsArry.get(i,JsToken[1]);
                    If JsToken[1].SelectToken('gift_card',JsToken[2]) then
                        if not Jstoken[2].AsValue().IsNull then
                            HasGiftcard := JsToken[2].AsValue().AsBoolean();
                    If HasGiftCard then break;                 
                end;
            end;
            // we have a gift card now see if we have waited long enough to process it now
            If HasGiftCard then 
                if Dat >= CalcDate('-4D',Today) then
                begin
                    Clear(exflg);
                    If Setup."Gift Card Order Index" = 0 Then
                        Setup."Gift Card Order Index" := ID
                    else if ID < Setup."Gift Card Order Index" then
                        Setup."Gift Card Order Index" := ID;
                    Setup.Modify(False);    
                end;
        end;
        exit(Exflg)
    End;
     // Routine To Call Shopify and fetch the orders
    procedure Get_Shopify_Orders(StartIndex:BigInteger):Boolean
    var
        OrdHdr:record "HL Shopify Order Header";
        OrdApp:record "HL Shopfiy Order Applications";
        OrdLine:record "HL Shopify Order Lines";
        indx:BigInteger;
        Parms:Dictionary of [text,text];
        Data:JsonObject;
        PayLoad:text;
        JsArry:Array[3] of JsonArray;
        JsToken:array[2] of JsonToken;
        cnt: integer;
        i,j,k,RecCnt:integer;
        dat,TstVal:Text;
        flg,ExFlg:boolean;
        win:dialog ;
        Setup:record "Sales & Receivables Setup";
        Status:text;
        OrdhdrEX:Record "HL Shopify Order Header";
        Item:record Item;
        ItemUnit:record "Item Unit of Measure";
        DimVal:record "Dimension Value";
        Startdate:date;
    begin
        if Not Item.Get('GIFT_CARD') then
        begin
            Item.init;
            Item.validate("No.",'GIFT_CARD');
            Item.Insert();
            Item.Description := 'Gift Card';
            Item.Type := Item.Type::"Non-Inventory";
            Item."Shopify Item" := Item."Shopify Item"::internal;
            Item.validate("Gen. Prod. Posting Group",'VOUCHER');
            Item.validate("VAT Prod. Posting Group",'NO GST');
            Item."SKU Part Source" := Item."SKU Part Source"::Other;
            If Not ItemUnit.get('GIFT_CARD','EA') then
            begin
                Itemunit.init;
                ItemUnit."Item No." := 'GIFT_CARD';
                ItemUnit.Code := 'EA';
                ItemUnit."Qty. per Unit of Measure" := 1;
                ItemUnit.Insert;
                Commit;
            end; 
            Item.Validate("Base Unit of Measure",'EA');
            Item.modify();
        end;
        if GuiAllowed then win.Open('Retrieving Order No    #1###########\'
                                   +'Processing Order No    #2###########\'
                                   +'Order Type             #3###########');
        Setup.Get;
        Clear(indx);
        Clear(Cnt);
        OrdHdr.Reset;
        OrdHdr.SetCurrentKey("Shopify Order No.");
        if OrdHdr.findlast then Startdate := OrdHdr."Shopify Order Date";
        OrdHdr.Reset;
        OrdHdr.SetCurrentKey("Shopify Order No.");
        Case Date2DWY(today,1) of
            2,4: OrdHdr.Setfilter("Shopify Order Date",'<=%1',CalcDate('-5D',Startdate));
            6: OrdHdr.Setfilter("Shopify Order Date",'<=%1',CalcDate('-3W',Startdate));
        end;    
        if OrdHdr.findlast then Indx := OrdHdr."Shopify Order No."; 
        OrdHdr.Reset;
        OrdHdr.SetFilter("Shopify Order No.",'>=%1',Indx);
        If OrdHdr.FindFirst() then 
            Indx := OrdHdr."Shopify Order ID"
        else
            Clear(Indx);        
        If StartIndex <> 0 then indx := StartIndex;
        If Setup."Gift Card Order Index" > 0 then
            If Indx > Setup."Gift Card Order Index" then
                indx := Setup."Gift Card Order Index";
        Clear(Setup."Gift Card Order Index");
        Setup.modify(false);        
        Clear(PayLoad);
        Clear(Parms);
        Clear(RecCnt);
        Parms.Add('since_id',Format(indx));
        Parms.add('status','any');
        Parms.Add('limit','250');
        Parms.Add('fields','id,cancelled_at,fulfillment_status,order_number,discount_applications,line_items,processed_at'
                +',currency,total_discounts,total_shipping_price_set,financial_status,total_price,total_tax');
        if Not Shopify_Data(Paction::GET,ShopifyBase + 'orders/count.json'
                                        ,Parms,PayLoad,Data) then Exit(false);
        Data.Get('count',JsToken[1]);
        Cnt := JsToken[1].AsValue().AsInteger();
        repeat
            Cnt -= 250;
            Sleep(10);
            Shopify_Data(Paction::GET,ShopifyBase + 'orders.json'
                ,Parms,PayLoad,Data);
            if Data.Get('orders',JsToken[1]) then
            begin
                JsArry[1] := JsToken[1].AsArray();
                for i := 0 to JsArry[1].Count - 1 do
                begin
                    JsArry[1].get(i,Jstoken[1]);
                    if Jstoken[1].SelectToken('order_number',Jstoken[2]) then
                        If Not JsToken[2].asvalue.IsNull then
                            if GuiAllowed then Win.Update(1,Jstoken[2].AsValue().AsBigInteger());
                    Clear(Indx);
                    Flg := Jstoken[1].SelectToken('id',Jstoken[2]);
                    If Flg Then Flg := Not Jstoken[2].AsValue().IsNull;
                    If Flg then 
                    begin
                        Indx := Jstoken[2].AsValue().AsBigInteger();
                        OrdHdr.Reset;
                        OrdHdr.Setrange("Shopify Order ID",indx);
                        Ordhdr.Setrange("Order Type",OrdHdr."Order Type"::Invoice);
                        Flg := Not OrdHdr.findset;
                    end;    
                    If Flg then Flg := Jstoken[1].SelectToken('cancelled_at',Jstoken[2]);
                    if Flg then Flg := Jstoken[2].AsValue().IsNull;
                    if Flg Then Flg := Jstoken[1].SelectToken('financial_status',Jstoken[2]);
                    if Flg Then Flg := Not Jstoken[2].AsValue().IsNull;
                    If Flg then Flg := Jstoken[2].AsValue().AsText().ToUpper() in ['PAID','REFUNDED','PARTIALLY_REFUNDED'];
                    If Flg then Flg := Jstoken[1].SelectToken('fulfillment_status',Jstoken[2]);
                    if Flg Then Flg := Check_For_Gift_Card(jstoken[1],indx);
                    If Flg then
                    begin
                        OrdhdrEX.Init;
                        OrdHdrEX."Order Type" := OrdHdrEx."Order Type"::Invoice;
                        OrdHdrEX."Shopify Order ID" := indx;
                        Get_Order_Transactions(OrdHdrEX);
                        //credit note is allowed with null fulfillment status invoies no
                        If (OrdHdrEx."Order Type" = OrdHdrEx."Order Type"::Invoice) 
                            AND JsToken[2].AsValue().Isnull() then 
                                Clear(Flg);    
                    end;
                    If Flg then 
                    begin
                        OrdHdr.Reset;
                        OrdHdr.Setrange("Shopify Order ID",indx);
                        OrdHdr.Setrange("Order Type",OrdHdrEx."Order Type");
                        If not OrdHdr.Findset then
                        begin
                            OrdHdr.init;
                            Clear(OrdHdr.ID);
                            OrdHdr.insert(True);
                            OrdHdr."Shopify Order Status" := Status;
                            OrdHdr."Order Type" := OrdHdrEX."Order Type";
                            OrdHdr."Shopify Order ID" := indx;
                            OrdHdr."Payment Gate Way" := OrdHdrEX."Payment Gate Way";
                            OrdHdr."Processed Date" := OrdhdrEX."Processed Date";
                            OrdHdr."Processed Time" := OrdHdrEx."Processed Time";
                            OrdHdr."Proc Time" := OrdHdrEx."Proc Time";
                            OrdHdr."Reference No" := OrdHdrEx."Reference No";
                            OrdHdr."Gift Card Total" := OrdhdrEX."Gift Card Total";
                            if GuiAllowed then Win.Update(3,Format(OrdHdr."Order Type"));
                            Jstoken[1].SelectToken('financial_status',Jstoken[2]);
                            OrdHdr."Shopify Financial Status" := Jstoken[2].AsValue().Astext().ToUpper();
                            Jstoken[1].SelectToken('fulfillment_status',Jstoken[2]);
                            Ordhdr."Shopify Order Status" := 'FULFILLED';
                            If Not Jstoken[2].AsValue().IsNull then
                                If Jstoken[2].AsValue().Astext().ToUpper() = 'PARTIAL' then
                                    OrdHdr."Shopify Order Status" := 'PARTIAL';
                            if Jstoken[1].SelectToken('order_number',Jstoken[2]) then
                                If Not JsToken[2].asvalue.IsNull then
                                begin
                                    OrdHdr."Shopify Order No." := Jstoken[2].AsValue().AsBigInteger();
                                    if GuiAllowed then Win.Update(2,Jstoken[2].AsValue().AsBigInteger());
                                end;    
                            if Jstoken[1].SelectToken('processed_at',Jstoken[2]) then
                                If Not JsToken[2].AsValue().IsNull then
                                begin
                                    Dat:= Copystr(Jstoken[2].AsValue().astext,1,10);
                                    if Evaluate(OrdHdr."Shopify Order Date",Copystr(Dat,9,2) + '/' + Copystr(Dat,6,2) + '/' + Copystr(Dat,1,4)) then;
                                end;    
                            if Jstoken[1].SelectToken('currency',Jstoken[2]) then
                                If Not JsToken[2].AsValue().IsNull then
                                    OrdHdr."Shopify Order Currency" := CopyStr(Jstoken[2].AsValue().AsCode(),1,10);
                            If Jstoken[1].SelectToken('total_discounts',Jstoken[2]) then
                                If Not JsToken[2].AsValue().IsNull then
                                    OrdHdr."Discount Total" := JsToken[2].AsValue().AsDecimal();
                            if Jstoken[1].SelectToken('total_price',Jstoken[2]) then
                                If Not JsToken[2].AsValue().IsNull then
                                    OrdHdr."Order Total" := JsToken[2].AsValue().AsDecimal();
                            If Jstoken[1].SelectToken('total_shipping_price_set',Jstoken[2]) then
                                If Jstoken[2].AsObject().SelectToken('shop_money',JsToken[1]) then
                                    If Jstoken[1].Asobject().SelectToken('amount',Jstoken[2]) then
                                        If Not JsToken[2].AsValue().IsNull then
                                            OrdHdr."Freight Total" := JsToken[2].AsValue().AsDecimal();
                            if Jstoken[1].SelectToken('total_tax',Jstoken[2]) then
                                if not Jstoken[2].AsValue().IsNull then
                                    OrdHdr."Tax Total" := JsToken[2].AsValue().AsDecimal();
                            Ordhdr.Modify();
                            RecCnt += 1;
                            if JsArry[1].get(i,Jstoken[1]) Then
                            begin
                                If Jstoken[1].SelectToken('discount_applications',Jstoken[2]) then
                                    If JsToken[2].AsArray().Count > 0 then
                                    begin
                                        JsArry[2] := JsToken[2].AsArray();
                                        for j := 0 to JsArry[2].Count - 1 do
                                        begin
                                            JsArry[2].get(j,Jstoken[1]);
                                            OrdApp.init;
                                            Clear(OrdApp.ID);
                                            OrdApp.Insert;
                                            OrdApp.ShopifyID := OrdHdr.ID;
                                            OrdApp."Shopify Order ID" := OrdHdr."Shopify Order ID";
                                            if JsToken[1].Selecttoken('type',JsToken[2]) then
                                                if not Jstoken[2].AsValue().IsNull then
                                                    OrdApp.validate("Shopify App Type",JsToken[2].AsValue().AsText());
                                            if JSToken[1].SelectToken('code',jsToken[2]) then
                                                if not Jstoken[2].AsValue().IsNull then
                                                    OrdApp."Shopify Disc App Code" := CopyStr(Jstoken[2].AsValue().AsCode(),1,100);
                                            if JSToken[1].SelectToken('description',jsToken[2]) then
                                                if not Jstoken[2].AsValue().IsNull then
                                                    OrdApp."Shopify Disc App Description" := CopyStr(Jstoken[2].AsValue().AsCode(),1,100)
                                            else if JSToken[1].SelectToken('title',jsToken[2]) then
                                                if not Jstoken[2].AsValue().IsNull then
                                                    OrdApp."Shopify Disc App Description" := CopyStr(Jstoken[2].AsValue().AsCode(),1,100);
                                            if JSToken[1].SelectToken('value',jsToken[2]) then
                                                if not Jstoken[2].AsValue().IsNull then
                                                    OrdApp."Shopify Disc App value" := jsToken[2].AsValue().AsDecimal();
                                            if JSToken[1].SelectToken('value_type',jsToken[2]) then
                                                if not Jstoken[2].AsValue().IsNull then
                                                    OrdApp."Shopify Disc App value Type" := jsToken[2].AsValue().Astext;
                                            OrdApp."Shopify Disc App Index" := j;
                                            OrdApp.modify(true);
                                        end;
                                    end;
                                JsArry[1].get(i,Jstoken[1]);
                                If Jstoken[1].SelectToken('line_items',Jstoken[2]) then
                                    If jsToken[2].AsArray().Count > 0 then
                                    begin
                                        JsArry[2] := JsToken[2].AsArray();
                                        for j := 0 to JsArry[2].Count - 1 do
                                        begin
                                            JsArry[2].get(j,JsToken[1]);
                                            OrdLine.init;
                                            Clear(OrdLine.ID);
                                            Ordline.insert;
                                            Ordline."Shopify Order ID" := OrdHdr."Shopify Order ID";
                                            Ordline.ShopifyID := OrdHdr.ID;
                                            OrdLine."Is NPF Item" := True;
                                            Ordline."Order Line No" := (j + 1) * 10;
                                            if JsToken[1].SelectToken('id',JsToken[2]) Then
                                            begin
                                                if not Jstoken[2].AsValue().IsNull then
                                                Begin    
                                                    OrdLine."Order Line ID" := JsToken[2].AsValue().AsBigInteger();
                                                    If JsToken[1].SelectToken('sku',JsToken[2]) then
                                                    begin
                                                        If Not JsToken[2].AsValue().IsNull then
                                                            Ordline."Item No.":= CopyStr(jstoken[2].AsValue().AsCode(),1,20)
                                                        else
                                                        begin
                                                            If JsToken[1].SelectToken('name',JsToken[2]) then
                                                                If Not JsToken[2].AsValue().IsNull then
                                                                begin
                                                                    If JsToken[2].AsValue().Astext.ToUpper().Contains('SUPER') then
                                                                        Ordline."Item No." := 'SUPERPHARMACY'
                                                                    else If JsToken[2].AsValue().Astext.ToUpper().Contains('B2B') then
                                                                        Ordline."Item No." := 'B2B ITEM';
                                                                end;     
                                                        end;
                                                        If Item.Get(OrdLine."Item No.") then
                                                        begin
                                                            OrdLine."Is NPF Item" := Item."SKU Part Source" = Item."SKU Part Source"::NPF;
                                                            If Item.Type = Item.type::"Non-Inventory" then Clear(OrdLine."Is NPF Item");
                                                            If JsToken[1].SelectToken('gift_card',JsToken[2]) then
                                                                if not Jstoken[2].AsValue().IsNull then
                                                                    if JsToken[2].AsValue().AsBoolean() then
                                                                    Begin
                                                                        Ordline."Item No." := 'GIFT_CARD';
                                                                        Clear(OrdLine."Is NPF Item");
                                                                    end;    
                                                            if JsToken[1].SelectToken('quantity',JsToken[2]) then
                                                                if not Jstoken[2].AsValue().IsNull then
                                                                begin
                                                                    Ordline."Order Qty" :=  jstoken[2].AsValue().AsDecimal();
                                                                    If Not OrdLine."Is NPF Item" then
                                                                    begin
                                                                        OrdLine."Location Code" := 'NSW';
                                                                        OrdLine."NPF Shipment Qty" := Ordline."Order Qty";
                                                                    end;
                                                                end;    
                                                            if JsToken[1].SelectToken('price',JsToken[2]) then
                                                                if not Jstoken[2].AsValue().IsNull then
                                                                    Ordline."Unit Price" :=  jstoken[2].AsValue().AsDecimal();
                                                            if JsToken[1].SelectToken('total_discount',JsToken[2]) then
                                                                if not Jstoken[2].AsValue().IsNull then
                                                                    Ordline."Discount Amount" := jstoken[2].AsValue().AsDecimal();
                                                            Ordline."Shopify Application Index" := -1;
                                                            if JsToken[1].SelectToken('discount_allocations',JsToken[2]) then
                                                            begin
                                                                If JsToken[2].AsArray().Count > 0 then
                                                                begin
                                                                    Jstoken[2].AsArray().get(0,Jstoken[1]);
                                                                    if jstoken[1].SelectToken('discount_application_index',JsToken[2]) then
                                                                        if not Jstoken[2].AsValue().IsNull then
                                                                            Ordline."Shopify Application Index" := JsToken[2].AsValue().AsInteger();
                                                                    if jstoken[1].SelectToken('amount',JsToken[2]) then
                                                                        if not Jstoken[2].AsValue().IsNull then
                                                                            Ordline."Discount Amount" := jstoken[2].AsValue().AsDecimal(); 
                                                                end;    
                                                            end;
                                                            Ordline."Tax Amount" := 0;
                                                            JsArry[2].get(j,JsToken[1]);
                                                            if JsToken[1].SelectToken('tax_lines',JsToken[2]) then
                                                            begin
                                                                If JsToken[2].AsArray().Count > 0 then
                                                                begin
                                                                    Jstoken[2].AsArray().get(0,Jstoken[1]);
                                                                    if jstoken[1].SelectToken('price',JsToken[2]) then
                                                                        if not Jstoken[2].AsValue().IsNull then
                                                                            Ordline."Tax Amount" := jstoken[2].AsValue().AsDecimal();
                                                                end;    
                                                            end;
                                                            Clear(OrdLine."Auto Delivered");
                                                            Ordline."Base Amount" := Ordline."Order Qty" * Ordline."Unit Price";
                                                            OrdLine.Modify(false);
                                                        end    
                                                        else
                                                            OrdLine.delete();
                                                    end    
                                                    else
                                                         OrdLine.delete();
                                                end    
                                                else
                                                    OrdLine.delete();
                                            end
                                            else
                                                OrdLine.delete();
                                        end;  
                                    end; 
                            end
                            else if GuiAllowed then
                            begin 
                                Win.Update(2,'');
                                Win.update(3,'');
                            end;
                            OrdLine.reset;
                            OrdLine.Setrange(ShopifyID,OrdHdr.ID);
                            If Not OrdLine.FindSet() then
                            begin
                                OrdHdr.Delete(True);
                                RecCnt -=1;
                            end;    
                        end    
                        Else if GuiAllowed then
                        begin 
                            Win.Update(2,'');
                            Win.update(3,'');
                        end;    
                    end
                    else if GuiAllowed then
                    begin 
                        Win.Update(2,'');
                        Win.update(3,'');
                    end;    
                end;
            end;
            Parms.Remove('since_id');
            Parms.Add('since_id',Format(indx));
            If recCnt > 50 then
            begin
                Clear(RecCnt);
                Commit;
            end;
        until cnt <=0; 
        Commit;
        //do every 7 days 
        If Date2DWY(today,1) = 7 then Process_Refunds();    
        if GuiAllowed then win.Close;
        exit(true);
    end;

    procedure Process_Refunds()
    var
        OrdHdr:array[2] of record "HL Shopify Order Header";
        OrdLine:record "HL Shopify Order Lines";
        indx:BigInteger;
        Parms:Dictionary of [text,text];
        Data:JsonObject;
        PayLoad:text;
        JsArry:array[2] of JsonArray;
        JsToken:array[3] of JsonToken;
        i,j:integer;
        dat:Text;
        win:Dialog;
        RecCnt:integer;
        TransAmount:Decimal;
        Item:record Item;
        Itemunit:record "Item Unit of Measure";
        OrdExist:Boolean;
        RefQty:Decimal;
        OrigQty:Decimal;
    begin
        if Not Item.Get('NON_REFUND_ITEM') then
        begin
            Item.init;
            Item.validate("No.",'NON_REFUND_ITEM');
            Item.Insert();
            Item.Description := 'Anonymous Refund Item';
            Item.Type := Item.Type::"Non-Inventory";
            Item."Shopify Item" := Item."Shopify Item"::internal;
            Item.validate("Gen. Prod. Posting Group",'VOUCHER');
            Item.validate("VAT Prod. Posting Group",'NO GST');
            If Not ItemUnit.get('NON_REFUND_ITEM','EA') then
            begin
                Itemunit.init;
                ItemUnit."Item No." := 'NON_REFUND_ITEM';
                ItemUnit.Code := 'EA';
                ItemUnit."Qty. per Unit of Measure" := 1;
                ItemUnit.Insert;
                Commit;
            end; 
            Item.Validate("Base Unit of Measure",'EA');
            Item.modify();
        end;
        if GuiAllowed then win.Open('Retrieving Order No    #1###########\'
                                   +'Processing Order No    #2###########');
        Clear(PayLoad);
        Clear(Parms);
        Clear(RecCnt);
        Parms.Add('fields','refunds');
        OrdHdr[1].Reset;
        OrdHdr[1].SetCurrentKey("Shopify Order No.");
        OrdHdr[1].Setrange("Order Status",OrdHdr[1]."Order Status"::Closed);
        OrdHdr[1].SetFilter("BC Reference No.",'<>%1','');
        OrdHdr[1].Setrange("Order Type",OrdHdr[1]."Order Type"::Invoice);
        OrdHdr[1].Setrange("Refunds Checked",False);
        OrdHdr[1].SetFilter("Shopify Order Date",'<=%1',CalcDate('-1W',Today));    
        If OrdHdr[1].Findset then
        repeat
            if GuiAllowed then 
            begin 
                Win.Update(1,OrdHdr[1]."Shopify Order No.");
                Win.Update(2,'');
            end;    
            if Shopify_Data(Paction::GET,ShopifyBase + 'orders/' + Format(OrdHdr[1]."Shopify Order ID") + '.json'
                                            ,Parms,PayLoad,Data) then
            Begin
                Clear(OrdExist);
                Data.Get('order',JsToken[1]);
                If JsToken[1].SelectToken('refunds',JsToken[2]) then
                Begin
                    JsArry[1] := JsToken[2].AsArray();
                    For i := 0 to JsArry[1].Count - 1 do
                    begin
                        JsArry[1].get(i,JsToken[1]);
                        Clear(TransAmount);
                        JsToken[1].SelectToken('transactions',JsToken[2]);
                        JsArry[2] := JsToken[2].AsArray();
                        if JsArry[2].Count > 0  then
                        begin
                            JsArry[2].get(0,JsToken[1]);
                            if JsToken[1].SelectToken('amount',Jstoken[2]) then
                                If not Jstoken[2].AsValue().IsNull then
                                    TransAmount := Jstoken[2].AsValue().AsDecimal();
                        end;
                        JsArry[1].get(i,JsToken[1]);
                        If i = 0 then
                        begin
                            if JsToken[1].SelectToken('order_id',JsToken[2]) then
                                if not JsToken[2].AsValue().IsNull then
                                    indx := JsToken[2].AsValue().AsBigInteger();
                            OrdHdr[2].Reset;
                            OrdHdr[2].Setrange("Order Type",OrdHdr[2]."Order Type"::CreditMemo);
                            OrdHdr[2].Setrange("Shopify Order ID",indx);
                            OrdExist := Not OrdHdr[2].Findset;
                            If OrdExist then
                            begin
                                if GuiAllowed then Win.Update(2,OrdHdr[1]."Shopify Order No.");
                                OrdHdr[2].init;
                                Clear(OrdHdr[2].ID);
                                OrdHdr[2].insert(True);
                                OrdHdr[2]."Shopify Order Status" := 'FULFILLED';
                                OrdHdr[2]."Order Type" := OrdHdr[2]."Order Type"::CreditMemo;
                                OrdHdr[2]."Shopify Order ID" := indx;
                                OrdHdr[2]."Shopify Order No." := OrdHdr[1]."Shopify Order No.";
                                OrdHdr[2]."Transaction Type" := 'refund';
                                OrdHdr[2]."Shopify Financial Status" := 'REFUNDED';
                                if Jstoken[1].SelectToken('processed_at',Jstoken[2]) then
                                begin
                                    Dat:= Copystr(Jstoken[2].AsValue().astext,1,10);
                                    If Evaluate(OrdHdr[2]."Shopify Order Date",Copystr(Dat,9,2) + '/' + Copystr(Dat,6,2) + '/' + Copystr(Dat,1,4)) then;
                                end;
                                OrdHdr[2]."Shopify Order Currency" := OrdHdr[1]."Shopify Order Currency";
                                JsToken[1].SelectToken('transactions',JsToken[2]);
                                JsArry[2] := JsToken[2].AsArray();
                                If JsArry[2].Count > 0  then
                                begin
                                    JsArry[2].get(0,JsToken[1]);
                                    if JsToken[1].SelectToken('gateway',Jstoken[2]) then
                                        If not Jstoken[2].AsValue().IsNull then
                                            OrdHdr[2]."Payment Gate Way" := CopyStr(JsToken[2].AsValue().AsText(),1,25);
                                    if JsToken[1].SelectToken('processed_at',JsToken[2]) then
                                        If not Jstoken[2].AsValue().IsNull then
                                            If Evaluate(OrdHdr[2]."Processed Date",CopyStr(JsToken[2].AsValue().AsText(),9,2) + '/' + 
                                                                CopyStr(JsToken[2].AsValue().AsText(),6,2) + '/' +
                                                                CopyStr(JsToken[2].AsValue().AsText(),1,4) + '/' ) then
                                            begin                
                                                OrdHdr[2]."Processed Time" := CopyStr(JsToken[2].AsValue().AsText(),12,8);
                                                if not Evaluate(OrdHdr[2]."Proc Time",OrdHdr[2]."Processed Time") then
                                                    OrdHdr[2]."Proc Time" := 0T;
                                            end; 
                                    if JsToken[1].SelectToken('receipt',JsToken[2]) then
                                    begin
                                        If JsToken[2].SelectToken('transaction_id',JsToken[3]) then
                                        begin
                                            If not Jstoken[3].AsValue().IsNull then
                                                OrdHdr[2]."Reference No" := CopyStr(JsToken[3].AsValue().AsText(),1,25)
                                        end        
                                        else if JsToken[2].SelectToken('payment_id',JsToken[3]) then
                                        begin
                                            If not Jstoken[3].AsValue().IsNull then
                                                OrdHdr[2]."Reference No" := CopyStr(JsToken[3].AsValue().AsText(),1,25)
                                        end        
                                        else if JsToken[2].SelectToken('x_reference',JsToken[3]) then
                                        begin
                                            If not Jstoken[3].AsValue().IsNull then
                                                OrdHdr[2]."Reference No" := CopyStr(JsToken[3].AsValue().AsText(),1,25)
                                        end
                                        else if JsToken[2].SelectToken('token',JsToken[3]) then
                                        begin
                                            If not Jstoken[3].AsValue().IsNull then
                                                OrdHdr[2]."Reference No" := CopyStr(JsToken[3].AsValue().AsText(),1,25)
                                        end
                                        else if JsToken[2].SelectToken('gift_card_id',JsToken[3]) then
                                        begin
                                            If not Jstoken[3].AsValue().IsNull then
                                            begin
                                                OrdHdr[2]."Reference No" := CopyStr(JsToken[3].AsValue().AsText(),1,25);
                                                If JsToken[1].SelectToken('amount',JsToken[3]) then
                                                    If not Jstoken[3].AsValue().IsNull then
                                                        Ordhdr[2]."Gift Card Total" := JsToken[3].AsValue().AsDecimal();
                                            end;
                                        end;
                                    end;                    
                                    If (OrdHdr[2]."Payment Gate Way" <> '') AND (OrdHdr[2]."Reference No" = '') then
                                        if JsToken[1].SelectToken('source_name',JsToken[2]) then
                                            If not Jstoken[2].AsValue().IsNull then
                                                OrdHdr[2]."Reference No" := CopyStr(JsToken[2].AsValue().AsText(),1,25);    
                                end;
                                If OrdHdr[2]."Reference No" = '' then
                                begin
                                    Clear(Data);
                                    Clear(Parms);
                                    Parms.Add('fields','note,source_name');
                                    if Shopify_Data(Paction::GET,ShopifyBase + 'orders/' + Format(OrdHdr[2]."Shopify Order ID") + '.json'
                                                            ,Parms,PayLoad,Data) then
                                    begin
                                        If Data.Get('order',JsToken[1]) then
                                        begin
                                            If JsToken[1].SelectToken('source_name',JsToken[2]) then
                                                If not Jstoken[2].AsValue().IsNull then
                                                    If JsToken[2].AsValue().AsText().ToUpper().Contains('MARKET') then
                                                    begin
                                                        If JsToken[1].SelectToken('note',JsToken[2]) then
                                                            If not Jstoken[2].AsValue().IsNull then
                                                            begin
                                                                OrdHdr[2]."Reference No" := CopyStr(Extract_MarketPlace_Invoice_Number(JsToken[2].AsValue().AsText()),1,25);
                                                                OrdHdr[2]."Payment Gate Way" := 'market_place';
                                                            end;
                                                    end 
                                                    else
                                                        OrdHdr[2]."Reference No" := CopyStr(JsToken[2].AsValue().AsText(),1,25);            
                                        end;
                                    end; 
                                end;
                                RecCnt += 1;
                                Ordhdr[2].Modify(False);
                            end;
                        end;
                        If OrdExist then
                        begin        
                            JsArry[1].Get(i,JsToken[2]);
                            JsToken[2].SelectToken('refund_line_items',JsToken[1]);
                            Jsarry[2] := JsToken[1].AsArray();
                            If JsArry[2].Count > 0 then Clear(TransAmount);
                            For j := 0 to JsArry[2].Count - 1 do
                            begin
                                JsArry[2].get(j,JsToken[2]);
                                Clear(RefQty);
                                if JsToken[2].Asobject.AsToken.SelectToken('quantity',JsToken[1]) then
                                    if not Jstoken[1].AsValue().IsNull then
                                        RefQty :=  jstoken[1].AsValue().AsDecimal();
                                If JsToken[2].SelectToken('line_item',Jstoken[1]) then
                                begin
                                    OrdLine.init;
                                    Clear(OrdLine.ID);
                                    Ordline.insert;
                                    Ordline."Shopify Order ID" := OrdHdr[2]."Shopify Order ID";
                                    OrdLine.ShopifyID := Ordhdr[2].ID;
                                    Ordline."Order Line No" := (j + 1) * 10;
                                    if JsToken[1].Asobject.AsToken.SelectToken('id',JsToken[2]) Then
                                    begin
                                        if not Jstoken[2].AsValue().IsNull then
                                        Begin    
                                            OrdLine."Order Line ID" := JsToken[2].AsValue().AsBigInteger();
                                            If JsToken[1].Asobject.AsToken.SelectToken('sku',JsToken[2]) then
                                            begin
                                                If Not JsToken[2].AsValue().IsNull then
                                                begin
                                                    Ordline."Item No." := jstoken[2].AsValue().AsCode();
                                                    OrdLine."Order Qty" := RefQty;
                                                    If JsToken[1].Asobject.AsToken.SelectToken('gift_card',JsToken[2]) then
                                                        if not Jstoken[2].AsValue().IsNull then
                                                            if JsToken[2].AsValue().AsBoolean() then
                                                                Ordline."Item No." := 'GIFT_CARD';
                                                    OrdLine."Location Code" := 'QC';
                                                    OrdLine."NPF Shipment Qty" := OrdLine."Order Qty";
                                                    Clear(OrigQty);            
                                                    if JsToken[1].Asobject.AsToken.SelectToken('quantity',JsToken[2]) then
                                                        if not Jstoken[2].AsValue().IsNull then
                                                            OrigQty := jstoken[2].AsValue().AsDecimal();
                                                    if JsToken[1].Asobject.AsToken.SelectToken('price',JsToken[2]) then
                                                        if not Jstoken[2].AsValue().IsNull then
                                                            Ordline."Unit Price" :=  jstoken[2].AsValue().AsDecimal();
                                                    if JsToken[1].Asobject.AsToken.SelectToken('total_discount',JsToken[2]) then
                                                        if not Jstoken[2].AsValue().IsNull then
                                                            Ordline."Discount Amount" := jstoken[2].AsValue().AsDecimal();
                                                    Ordline."Shopify Application Index" := -1;
                                                    if JsToken[1].Asobject.AsToken.SelectToken('discount_allocations',JsToken[2]) then
                                                    begin
                                                        If JsToken[2].AsArray().Count > 0 then
                                                        begin
                                                            Jstoken[2].AsArray().get(0,Jstoken[3]);
                                                            if jstoken[3].SelectToken('discount_application_index',JsToken[2]) then
                                                                if not Jstoken[2].AsValue().IsNull then
                                                                    Ordline."Shopify Application Index" := JsToken[2].AsValue().AsInteger();
                                                            if jstoken[3].SelectToken('amount',JsToken[2]) then
                                                                if not Jstoken[2].AsValue().IsNull then
                                                                    Ordline."Discount Amount" := jstoken[2].AsValue().AsDecimal(); 
                                                        end;    
                                                    end;
                                                    If OrigQty > 0 then
                                                    begin
                                                        If Ordline."Discount Amount" > 0 then
                                                            Ordline."Discount Amount" := (Ordline."Discount Amount" * OrdLine."Order Qty")/OrigQty;  
                                                        Clear(Ordline."Tax Amount");
                                                        If JsToken[1].Asobject.AsToken.SelectToken('tax_lines',JsToken[2]) then
                                                        begin
                                                            If JsToken[2].AsArray().Count > 0 then
                                                            begin
                                                                Jstoken[2].AsArray().get(0,Jstoken[3]);
                                                                if jstoken[3].SelectToken('price',JsToken[2]) then
                                                                    if not Jstoken[2].AsValue().IsNull then
                                                                        Ordline."Tax Amount" := jstoken[2].AsValue().AsDecimal();
                                                            end;    
                                                        end;
                                                        If Ordline."Tax Amount" > 0 then
                                                            Ordline."Tax Amount" := (Ordline."Tax Amount" * OrdLine."Order Qty")/OrigQty;  
                                                        Ordline."Base Amount" := Ordline."Order Qty" * Ordline."Unit Price";
                                                        If Item.Get(Ordline."Item No.") then
                                                        Begin
                                                            OrdLine."Unit Of Measure" := Item."Base Unit of Measure";
                                                            Ordline.modify(False);
                                                        end    
                                                        else
                                                            OrdLine.Delete();
                                                    end
                                                    else
                                                        OrdLine.Delete();            
                                                end
                                                else
                                                    OrdLine.Delete();
                                            end
                                            else
                                                OrdLine.Delete();
                                        end
                                        else
                                            OrdLine.Delete();
                                    end
                                    else
                                        OrdLine.Delete();
                                end;
                            end;
                            //see if this is a refund with no items involved
                            If TransAmount > 0 then
                            begin
                                OrdLine.reset;
                                OrdLine.Setrange(ShopifyID,OrdHdr[2].ID);
                                j:= 10;
                                If OrdLine.findlast then j += OrdLine."Order Line No"; 
                                OrdLine.init;
                                Clear(OrdLine.ID);
                                Ordline.insert;
                                Ordline."Shopify Order ID" := OrdHdr[2]."Shopify Order ID";
                                OrdLine.ShopifyID := Ordhdr[2].ID;
                                Ordline."Order Line No" := j;
                                Ordline."Item No." := 'NON_REFUND_ITEM';
                                OrdLine."Location Code" := 'QC';
                                Item.Get(Ordline."Item No.");
                                OrdLine."Unit Of Measure" := Item."Base Unit of Measure";
                                OrdLine."Order Qty" := 1;
                                OrdLine."Unit Price" := TransAmount;
                                Ordline."NPF Shipment Qty" := 1;
                                Ordline."Shopify Application Index" := -1;
                                OrdLine."Discount Amount" := 0;
                                OrdLine."Tax Amount" := 0;
                                Ordline."Base Amount" := Ordline."Order Qty" * Ordline."Unit Price";
                                OrdLine.modify(false);
                            end;    
                            Commit;
                        end;
                    end;
                    if OrdExist then
                    begin        
                        OrdLine.reset;
                        OrdLine.Setrange(ShopifyID,OrdHdr[2].ID);
                        If OrdLine.findset then
                        begin
                            OrdLine.CalcSums("Base Amount","Discount Amount","Tax Amount");
                            OrdHdr[2]."Tax Total" := OrdLine."Tax Amount";
                            OrdHdr[2]."Discount Total" := OrdLine."Discount Amount";
                            OrdHdr[2]."Order Total" := OrdLine."Base Amount" - OrdLine."Discount Amount";
                            OrdHdr[2].Modify(False);
                        end
                        else
                        begin
                            OrdHdr[2].Delete(True);
                            RecCnt -=1;
                        end;
                    end;
                end;
            end;    
            OrdHdr[1]."Refunds Checked" := True;
            OrdHdr[1].Modify(false);
            If RecCnt > 50 then
            begin
                Clear(RecCnt);
                Commit;
            end;          
        until OrdHdr[1].next = 0;
        if GuiAllowed then Win.Close;
        Commit;
    end;        

        local Procedure Extract_MarketPlace_Invoice_Number(Val:text):text
    var
        Retval:text;
        i:integer; 
    Begin
        Clear(retval);
        For i:= 1 to StrLen(val) do
            if (Val[i] >= '0') and (Val[i] <= '9') then
                retval += Val[i];
        exit(retval);
    End;
    local procedure Get_Order_Transactions(var Ordhdr:record "HL Shopify Order Header")
    var
        Parms:Dictionary of [text,text];
        Data:JsonObject;
        PayLoad:text;
        JsArry:JsonArray;
        JsToken:array[3] of JsonToken;
        i:integer;
    Begin
        Clear(Parms);
        Ordhdr."Transaction Date" := Today;
        Ordhdr."Transaction Type" := 'sale';
        if Shopify_Data(Paction::GET,ShopifyBase + 'orders/' + Format(OrdHdr."Shopify Order ID") + '/transactions.json'
                                     ,Parms,PayLoad,Data) then
        begin                             
            If Data.Get('transactions',JsToken[1]) then
            begin
                JsArry := JsToken[1].AsArray();
                If JsArry.Count = 0 then OrdHdr."Transaction Type" := 'promotion'
                else
                begin
                    For i := 0 to Jsarry.Count - 1 do
                    Begin     
                        JsArry.get(i,JsToken[1]);
                        if Jstoken[1].SelectToken('status',JsToken[2]) then
                            If not JsToken[2].AsValue().IsNull then
                                If (JsToken[2].AsValue().AsText().ToUpper() = 'SUCCESS')then
                                begin
                                    If i = 0 then
                                    Begin
                                        if JsToken[1].SelectToken('kind',JsToken[2]) then
                                            If not JsToken[2].AsValue().IsNull then
                                            begin
                                                OrdHdr."Transaction Type" := Copystr(JsToken[2].AsValue().AsText(),1,25);
                                                If JsToken[2].AsValue().AsText().ToUpper() = 'REFUND' then 
                                                    Ordhdr."Order Type" := Ordhdr."Order Type"::CreditMemo;
                                            end;        
                                        If JsToken[1].SelectToken('gateway',JsToken[2]) then
                                            If not Jstoken[2].AsValue().IsNull then
                                                OrdHdr."Payment Gate Way" := CopyStr(JsToken[2].AsValue().AsText(),1,25);
                                        if JsToken[1].SelectToken('processed_at',JsToken[2]) then
                                            If not Jstoken[2].AsValue().IsNull then
                                                If Evaluate(OrdHdr."Processed Date",CopyStr(JsToken[2].AsValue().AsText(),9,2) + '/' + 
                                                                CopyStr(JsToken[2].AsValue().AsText(),6,2) + '/' +
                                                                CopyStr(JsToken[2].AsValue().AsText(),1,4) + '/' ) then
                                                begin                
                                                    OrdHdr."Processed Time" := CopyStr(JsToken[2].AsValue().AsText(),12,8);
                                                    if not Evaluate(OrdHdr."Proc Time",OrdHdr."Processed Time") then
                                                        OrdHdr."Proc Time" := 0T;
                                                end; 
                                        if JsToken[1].SelectToken('receipt',JsToken[2]) then
                                        begin
                                            If JsToken[2].SelectToken('transaction_id',JsToken[3]) then
                                            begin
                                                If not Jstoken[3].AsValue().IsNull then
                                                    OrdHdr."Reference No" := CopyStr(JsToken[3].AsValue().AsText(),1,25)
                                            end        
                                            else if JsToken[2].SelectToken('payment_id',JsToken[3]) then
                                            begin
                                                If not Jstoken[3].AsValue().IsNull then
                                                    OrdHdr."Reference No" := CopyStr(JsToken[3].AsValue().AsText(),1,25)
                                            end        
                                            else if JsToken[2].SelectToken('x_reference',JsToken[3]) then
                                            begin
                                                If not Jstoken[3].AsValue().IsNull then
                                                    OrdHdr."Reference No" := CopyStr(JsToken[3].AsValue().AsText(),1,25)
                                            end        
                                            else if JsToken[2].SelectToken('token',JsToken[3]) then
                                            begin
                                                If not Jstoken[3].AsValue().IsNull then
                                                    OrdHdr."Reference No" := CopyStr(JsToken[3].AsValue().AsText(),1,25)
                                            end        
                                            else if JsToken[2].SelectToken('gift_card_id',JsToken[3]) then
                                            Begin
                                                If not Jstoken[3].AsValue().IsNull then
                                                begin
                                                    OrdHdr."Reference No" := CopyStr(JsToken[3].AsValue().AsText(),1,25);
                                                    If JsToken[1].SelectToken('amount',JsToken[3]) then
                                                        If not Jstoken[3].AsValue().IsNull then
                                                            Ordhdr."Gift Card Total" := JsToken[3].AsValue().AsDecimal();
                                                end; 
                                            end;               
                                        end;
                                        If (OrdHdr."Payment Gate Way" <> '') AND (OrdHdr."Reference No" = '') then
                                            if JsToken[1].SelectToken('source_name',JsToken[2]) then
                                                If not Jstoken[2].AsValue().IsNull then
                                                    OrdHdr."Reference No" := CopyStr(JsToken[2].AsValue().AsText(),1,25);    
                                    end
                                    else If Ordhdr."Gift Card Total" = 0 then
                                            if JsToken[1].SelectToken('receipt',JsToken[2]) then
                                                if JsToken[2].SelectToken('gift_card_id',JsToken[3]) then
                                                    If not Jstoken[3].AsValue().IsNull then
                                                        If JsToken[1].SelectToken('amount',JsToken[3]) then
                                                            If not Jstoken[3].AsValue().IsNull then
                                                                Ordhdr."Gift Card Total" := JsToken[3].AsValue().AsDecimal();
                                end;
                    end;
                end;  
            end;          
            If OrdHdr."Reference No" = '' then
            begin
                Clear(Data);
                Clear(Parms);
                Parms.Add('fields','note,source_name');
                if Shopify_Data(Paction::GET,ShopifyBase + 'orders/' + Format(OrdHdr."Shopify Order ID") + '.json'
                                        ,Parms,PayLoad,Data) then
                begin
                    If Data.Get('order',JsToken[1]) then
                    begin
                        If JsToken[1].SelectToken('source_name',JsToken[2]) then
                            If not Jstoken[2].AsValue().IsNull then
                                If JsToken[2].AsValue().AsText().ToUpper().Contains('MARKET') then
                                begin
                                    If JsToken[1].SelectToken('note',JsToken[2]) then
                                        If not Jstoken[2].AsValue().IsNull then
                                        begin
                                            OrdHdr."Reference No" := CopyStr(Extract_MarketPlace_Invoice_Number(JsToken[2].AsValue().AsText()),1,25);
                                            OrdHdr."Payment Gate Way" := 'market_place';
                                        end;
                                end 
                                else
                                    OrdHdr."Reference No" := CopyStr(JsToken[2].AsValue().AsText(),1,25);            
                                             
                    end;
                end;
            end;
        end;                            
    end;
    procedure Send_Email_Msg(Subject:text;Body:text;ExRecip:Text):Boolean;
    var
        EM:Codeunit "Email Message";
        Emailer:Codeunit Email;    
        Setup:Record "Sales & Receivables Setup";
        Recip:Text;
    begin
        Setup.get;
        Clear(Recip);
        If ExRecip <> '' then 
            Recip := ExRecip
        else
            Recip := Setup."Exception Email Address"; 
        If Recip.Contains('@') then
        begin
            EM.Create(Recip,Subject,Body);
            Exit(Emailer.Send(EM,Enum::"Email Scenario"::Default));
        end;
        exit(false);
    end;
    procedure Get_Dim_Set_Id(OrdType:Code[20];Item:record Item):Integer
    var
        DimSet:record "Dimension Set Entry" temporary;
        DimVal:record "Dimension Value";
        Defdim:record "Default Dimension";
        DimMgt:Codeunit DimensionManagement;
        PS:Code[20];
    begin
        if DefDim.Get(DataBase::Item,Item."No.",'DEPARTMENT') then
        begin
            DimSet.init;
            DimSet.Validate("Dimension Code",'DEPARTMENT');
            DimSet.validate("Dimension Value Code",Defdim."Dimension Value Code");
            DimSet.insert;
        end;
        if DefDim.Get(DataBase::Item,Item."No.",'CATEGORY') then
        begin
            DimSet.init;
            DimSet.Validate("Dimension Code",'CATEGORY');
            DimSet.validate("Dimension Value Code",Defdim."Dimension Value Code");
            DimSet.insert;
        end;
        if DefDim.Get(DataBase::Item,Item."No.",'SUB-CATEGORY') then
        begin
            DimSet.init;
            DimSet.Validate("Dimension Code",'SUB-CATEGORY');
            DimSet.validate("Dimension Value Code",Defdim."Dimension Value Code");
            DimSet.insert;
        end;
        if DefDim.Get(DataBase::Item,Item."No.",'BRAND') then
        begin
            DimSet.init;
            DimSet.Validate("Dimension Code",'BRAND');
            DimSet.validate("Dimension Value Code",Defdim."Dimension Value Code");
            DimSet.insert;
        end;
        Case Item."SKU Part Source" of
            Item."SKU Part Source"::NPF:PS:= 'NPF';
            Item."SKU Part Source"::"PG":PS := 'PG';
            else
                PS:= 'OTHER';
        end;      
        If DimVal.Get('ITEM SOURCE',PS) then
        begin
            DimSet.init;
            DimSet.Validate("Dimension Code",'ITEM SOURCE');
            DimSet.validate("Dimension Value Code",PS);
            DimSet.insert;
        end;    
        If DimVal.Get('ORDER TYPE',OrdType) then
        begin
            DimSet.init;
            DimSet.Validate("Dimension Code",'ORDER TYPE');
            DimSet.validate("Dimension Value Code",OrdType);
            Dimset.insert;
            Exit(DimMgt.GetDimensionSetID(DimSet));
        end;
        Exit(0);
    end;
    local procedure Clear_QC_Stock()
    var
        Item:Record Item;
        Cu:Codeunit "HL NPF Routines";
    begin
        Item.Reset;
        Item.Setrange(Type,Item.Type::Inventory);
        Item.Setrange("Location Filter",'QC');
        If Item.findSet then
        repeat
            Item.CalcFields(Inventory);
            If Item.Inventory > 0 then Cu.Adjust_Inventory(Item,'QC',-Item.Inventory);
        until Item.next = 0;
    end;
    procedure Credit_Correction(ID:BigInteger)
    var
        SinvLine:Record "Sales Invoice Line";
        SalesHdr:Record "Sales Header";
        SalesLine:record "Sales Line";
        Cu:Codeunit "Sales-Post";
        PCHdr:Record "HL Shopify Order Header";
        lineNo:Integer;
        CuRel:Codeunit "Release Sales Document";
    begin
        SinvLine.reset;
        SinvLine.Setrange("Shopify Order ID",ID);
        If SinvLine.Findset then
        begin
            Clear(lineNo);
            SalesHdr.Init();
            SalesHdr.validate("Document Type",SalesHdr."Document Type"::"Credit Memo");
            SalesHdr.Validate("Sell-to Customer No.",'HEALTHY LIFE');
            SalesHdr.validate("Prices Including VAT",True);
            SalesHdr."Your Reference" := 'SHOPIFY CORRECTION';
            //SalesHdr."External Document No." := Buff."BC Reference No.";
            SalesHdr."Reason Code" := 'CUSTRETURN';
            SalesHdr.Insert(true);
            repeat
                lineNo += 10;
                Clear(SalesLine);
                SalesLine.init;
                SalesLine.Validate("Document Type",SalesHdr."Document Type");
                SalesLine.Validate("Document No.",SalesHdr."No.");
                SalesLine."Line No." := lineNo;
                SalesLine.insert(true);
                SalesLine.Validate(Type,SalesLine.Type::Item);
                SalesLine.validate("No.",SinvLine."No.");
                SalesLine.Validate("Location Code",Sinvline."Location Code");
                SalesLine.Validate("VAT Prod. Posting Group",SinvLine."VAT Prod. Posting Group");
                SalesLine.Validate("Unit of Measure Code",Sinvline."Unit of measure code");
                SalesLine.Validate(Quantity,SinvLine.Quantity);
                Salesline.Validate("Unit Price",SinvLine."Unit Price");
                Salesline.Validate("Line Discount Amount",SinvLine."Line Discount Amount");
                Salesline."Shopify Order ID" := ID;
                SalesLine.Modify(true);
                // here we establish the 
            until SinvLine.next = 0;
            Commit;
            if CuRel.Run(SalesHdr) then 
                If CU.Run(SalesHdr) then
                begin
                    PCHdr.Reset();
                    PCHdr.Setrange("Shopify Order ID",ID);
                    If PCHdr.findset then
                    begin
                        Clear(PCHdr."BC Reference No.");
                        Clear(PCHdr."Order Status");
                        PCHdr.modify(false);
                        Process_Orders(true,ID);
                        Commit;
                        PchDr.FindSet();
                        Message('Order No %1 has been corrected',PCHdr."BC Reference No.");
                    end;
                 end;
            end;     
    end;
    
    // Here is where we process all received orders
    procedure Process_Orders(Bypass:Boolean;OrdNoID:Biginteger):Boolean
    var
        SalesHdr:record "Sales Header";
        SalesLine:Record "Sales Line";
        SalesInvHdr:record "Sales Invoice Header";
        SalesCrdHdr:Record "Sales Cr.Memo Header";
        OrdNo:Code[20];
        Cu:Codeunit "Sales-Post";
        CuRel:Codeunit "Release Sales Document";
        HLOrdHdr:Array[2] of record "HL Shopify Order Header";
        HLOrdLin:record "HL Shopify Order Lines";
        Cust:Record Customer;
        LineNo:Integer;
        Item:Record Item;
        loop:Integer;
        ExFlg:Boolean;
        Res:Record "Reason Code";
        SaleDocType:Record "Sales Header";
        Loc:Record Location;
        ItemUnit:Record "Item Unit of Measure";
        unit:record "Unit of Measure";
        Result:Boolean;
        i:Decimal;
        win:dialog;
        Excp:Record "HL Shopify Order Exceptions";
        Dim:record Dimension;
        Dimval:Record "Dimension Value";
        OrdType:Code[20];
        OrderCnt:Integer;
        GLSetup:record "General Ledger Setup";
        PstDate:date;
        Disc:Decimal;
        ProcCnt:Integer;
        SalesSetup:record "Sales & Receivables Setup";
    begin
        Result := True;
        If Not Res.get('CUSTRETURN') then
        begin
            Res.Init;
            Res.Code := 'CUSTRETURN';
            Res.Description := 'Customer Return';
            Res.Insert();
        end;
        If Not Unit.get('EA') then
        begin
            Unit.init;
            unit.Code := 'EA';
            Unit.Description := 'Each';
            Unit.insert;
        end;
        if Not Item.Get('SHIPPING') then
        begin
            Item.init;
            Item.validate("No.",'SHIPPING');
            Item.Insert();
            Item.Description := 'Shipping';
            Item.Type := Item.Type::"Non-Inventory";
            Item."Shopify Item" := Item."Shopify Item"::internal;
            Item.validate("Gen. Prod. Posting Group",'FREIGHTOUT');
            Item.validate("VAT Prod. Posting Group",'GST10');
            Item."SKU Part Source" := Item."SKU Part Source"::Other;
            If Not ItemUnit.get('SHIPPING','EA') then
            begin
                Itemunit.init;
                ItemUnit."Item No." := 'SHIPPING';
                ItemUnit.Code := 'EA';
                ItemUnit."Qty. per Unit of Measure" := 1;
                ItemUnit.Insert;
                Commit;
            end; 
            Item.Validate("Base Unit of Measure",'EA');
            Item.modify();
        end;    
        if Not Item.Get('GIFT_CARD_REDEEM') then
        begin
            Item.init;
            Item.validate("No.",'GIFT_CARD_REDEEM');
            Item.Insert();
            Item.Description := 'Gift Card Redeem';
            Item.Type := Item.Type::"Non-Inventory";
            Item."Shopify Item" := Item."Shopify Item"::internal;
            Item.validate("Gen. Prod. Posting Group",'VOUCHER');
            Item.validate("VAT Prod. Posting Group",'NO GST');
            Item."SKU Part Source" := Item."SKU Part Source"::Other;
            If Not ItemUnit.get('GIFT_CARD_REDEEM','EA') then
            begin
                Itemunit.init;
                ItemUnit."Item No." := 'GIFT_CARD_REDEEM';
                ItemUnit.Code := 'EA';
                ItemUnit."Qty. per Unit of Measure" := 1;
                ItemUnit.Insert;
                Commit;
            end; 
            Item.Validate("Base Unit of Measure",'EA');
            Item.modify();
        end;
        if Not Item.Get('DISCOUNTS') then
        begin
            Item.init;
            Item.validate("No.",'DISCOUNTS');
            Item.Insert();
            Item.Description := 'Discounts';
            Item.Type := Item.Type::"Non-Inventory";
            Item."Shopify Item" := Item."Shopify Item"::internal;
            Item.validate("Gen. Prod. Posting Group",'FREIGHTOUT');
            Item.validate("VAT Prod. Posting Group",'NO GST');
            Item."SKU Part Source" := Item."SKU Part Source"::Other;
            If Not ItemUnit.get('DISCOUNTS','EA') then
            begin
                Itemunit.init;
                ItemUnit."Item No." := 'DISCOUNTS';
                ItemUnit.Code := 'EA';
                ItemUnit."Qty. per Unit of Measure" := 1;
                ItemUnit.Insert;
                Commit;
            end; 
            Item.Validate("Base Unit of Measure",'EA');
            Item.modify();
        end;    
        // Location for return Orders    
        If not Loc.Get('QC') then
        begin
            loc.init;
            Loc.Code := 'QC';
            Loc."Use As In-Transit" := false;
            loc.insert;
        end;
        If Not Dim.Get('CUSTOMER TYPE') then
        begin
            Dim.Init();
            Dim.validate(Code,'CUSTOMER TYPE');
            Dim.Name := 'Customer Types';
            Dim."Code Caption" := 'Customer Types';
            Dim.insert;      
        end;
        If Not Dimval.get(Dim.Code,'GUEST') then
        begin
            Dimval.Init();
            Dimval.validate("Dimension Code",Dim.Code);
            Dimval.validate(Code,'GUEST');
            Dimval.Name := 'Guest Member';
            Dimval."Dimension Value Type" := Dimval."Dimension Value Type"::Standard;             
            DimVal.Insert;
        end;    
        If Not Dimval.get(Dim.Code,'PLATINUM') then
        begin
            Dimval.Init();
            Dimval.validate("Dimension Code",Dim.Code);
            Dimval.validate(Code,'PLATINUM');
            Dimval.Name := 'Platimun Member';
            Dimval."Dimension Value Type" := Dimval."Dimension Value Type"::Standard;             
            DimVal.Insert;
        end;    
        If Not Dimval.get(Dim.Code,'GOLD') then
        begin
            Dimval.Init();
            Dimval.validate("Dimension Code",Dim.Code);
            Dimval.validate(Code,'GOLD');
            Dimval.Name := 'Gold Member';
            Dimval."Dimension Value Type" := Dimval."Dimension Value Type"::Standard;             
            DimVal.Insert;
        end;    
        If Not Dimval.get(Dim.Code,'SILVER') then
        begin
            Dimval.Init();
            Dimval.validate("Dimension Code",Dim.Code);
            Dimval.validate(Code,'SILVER');
            Dimval.Name := 'Silver Member';
            Dimval."Dimension Value Type" := Dimval."Dimension Value Type"::Standard;             
            DimVal.Insert;
        end;    
        If Not Dimval.get(Dim.Code,'BRONZE') then
        begin
            Dimval.Init();
            Dimval.validate("Dimension Code",Dim.Code);
            Dimval.validate(Code,'BRONZE');
            Dimval.Name := 'Bronze Member';
            Dimval."Dimension Value Type" := Dimval."Dimension Value Type"::Standard;             
            DimVal.Insert;
        end;    
        If Not Dim.Get('ORDER TYPE') then
        begin
            Dim.Init();
            Dim.validate(Code,'ORDER TYPE');
            Dim.Name := 'Order Types';
            Dim."Code Caption" := 'Order Types';
            Dim.insert;      
        end;
        If Not Dimval.get(Dim.Code,'STANDARD') then
        begin
            Dimval.Init();
            Dimval.validate("Dimension Code",Dim.Code);
            Dimval.validate(Code,'STANDARD');
            Dimval.Name := 'Standard Order';
            Dimval."Dimension Value Type" := Dimval."Dimension Value Type"::Standard;             
            DimVal.Insert;
        end;    
        If Not Dimval.get(Dim.Code,'AUTO ORDER') then
        begin
            Dimval.Init();
            Dimval.validate("Dimension Code",Dim.Code);
            Dimval.validate(Code,'AUTO ORDER');
            Dimval.Name := 'Auto Order';
            Dimval."Dimension Value Type" := Dimval."Dimension Value Type"::Standard;             
            DimVal.Insert;
        end;
        If Not Dim.Get('ITEM SOURCE') then
        begin
            Dim.Init();
            Dim.validate(Code,'ITEM SOURCE');
            Dim.Name := 'Item Source' ;
            Dim."Code Caption" := 'Item Source';
            Dim.insert;      
        end;
        If Not Dimval.get(Dim.Code,'NPF') then
        begin
            Dimval.Init();
            Dimval.validate("Dimension Code",Dim.Code);
            Dimval.validate(Code,'NPF');
            Dimval.Name := 'NPF Item source';
            Dimval."Dimension Value Type" := Dimval."Dimension Value Type"::Standard;             
            DimVal.Insert;
        end;
        If Not Dimval.get(Dim.Code,'PG') then
        begin
            Dimval.Init();
            Dimval.validate("Dimension Code",Dim.Code);
            Dimval.validate(Code,'PG');
            Dimval.Name := 'Pharmacy goods';
            Dimval."Dimension Value Type" := Dimval."Dimension Value Type"::Standard;             
            DimVal.Insert;
        end;
        If Not Dimval.get(Dim.Code,'OTHER') then
        begin
            Dimval.Init();
            Dimval.validate("Dimension Code",Dim.Code);
            Dimval.validate(Code,'OTHER');
            Dimval.Name := 'Other goods';
            Dimval."Dimension Value Type" := Dimval."Dimension Value Type"::Standard;             
            DimVal.Insert;
        end;
        Item.Reset;
        Item.Setrange(Blocked,true);
        If Item.Findset Then Item.ModifyAll(Blocked,false,false);
        Item.Reset;
        Item.Setrange("Sales Blocked",true);
        If Item.Findset Then Item.ModifyAll("Sales Blocked",false,false);
        Clear(PstDate);
        GLSetup.get;
        If (GLSetup."Allow Posting To" <> 0D) AND (GLSetup."Allow Posting To" < Today) then 
        begin
            PstDate := GLSetup."Allow Posting To";
            Clear(GLSetup."Allow Posting To");
            GLSetup.MOdify(false);       
        end;
        If Not Bypass Then 
            if not update_Order_Locations(OrdNoID) And GuiAllowed then
                Message('%1,%2,%3',GetLastErrorCode,GetLastErrorCallStack,GetLastErrorText());
        Result := Cust.Get('HEALTHY LIFE');
        if Result then
        begin
            If OrdNoID <> 0 then
            begin
                Excp.Reset();
                Excp.Setrange(ShopifyID,OrdNoID);
                If Excp.findset then Exit; 
                HLOrdHdr[1].reset;
                HLOrdHdr[1].Setrange(ID,OrdNoID);
                If HLOrdHdr[1].findset then
                begin
                    HLOrdLin.Reset;
                    HLOrdLin.SetRange(ShopifyID,HLOrdHdr[1].ID);
                    HLOrdLin.Setrange("Not Supplied",false);
                    HLOrdLin.Setfilter("Item No.",'<>%1','');
                    HLOrdLin.Setrange("Is NPF Item",True);
                    HLOrdLin.Setfilter("order Qty",'>0');
                    If HLOrdLin.Findset then
                    begin
                        HLOrdLin.CalcSums("Order Qty","NPF Shipment Qty");
                        If HLOrdLin."Order Qty" = HLOrdLin."NPF Shipment Qty" then 
                        begin                   
                            HLOrdHdr[1]."NPF Shipment Status" := HLOrdHdr[1]."NPF Shipment Status"::Complete;       
                            HLOrdHdr[1].Modify();
                        end
                        else
                        begin
                            Excp.init;
                            Clear(Excp.ID);
                            Excp.insert;
                            Excp.ShopifyID := HLOrdHdr[1].ID;
                            Excp.Exception := StrsubStno('NPF -> Order Total Qty = %1,Shipped Total Qty = %2',HLOrdLin."Order Qty", HLOrdLin."NPF Shipment Qty"); 
                            excp.Modify();
                            Result := False;
                        end;    
                    end;    
                end;
            end;
            If Result then
            begin
                SalesSetup.get;
                If SalesSetup."Order Process Count" = 0 then
                begin
                    SalesSetup."Order Process Count" := 300;
                    SalesSetup.Modify(False);
                end;    
                if GuiAllowed Then Win.Open('Processing Orders #1####### of #2#########');
                For Loop := 1 to 2  do
                begin
                    Clear(OrderCnt);
                    HLOrdHdr[1].reset;
                    HLOrdHdr[1].Setrange("Order Status",HLOrdHdr[1]."Order Status"::Open);
                    HLOrdHdr[1].Setrange("BC Reference No.",'');
                    If OrdNoID <> 0 then HLOrdHdr[1].Setrange(ID,OrdNoID);
                    if Loop = 1 then
                    begin
                        HLOrdHdr[1].Setrange("NPF Shipment Status",HLOrdHdr[1]."NPF Shipment Status"::Complete);
                        HLOrdHdr[1].Setrange("Order Type",HLOrdHdr[1]."Order Type"::Invoice);
                    end    
                    else
                        HLOrdHdr[1].Setrange("Order Type",HLOrdHdr[1]."Order Type"::CreditMemo);
                    Clear(ProcCnt);    
                    Clear(i);
                    If HLOrdHdr[1].findset then
                    begin
                        if GuiAllowed then win.update(2,HLOrdHdr[1].Count);
                        repeat
                            OrderCnt += 1;
                            If ProcCnt = 0 then
                            begin
                                Clear(LineNo);
                                Clear(SalesHdr);
                                SalesHdr.init;
                                if Loop = 1 then
                                    SalesHdr.validate("Document Type",SalesHdr."Document Type"::Invoice)
                                else
                                    SalesHdr.validate("Document Type",SalesHdr."Document Type"::"Credit Memo");
                                SaleDocType."Document Type" := SalesHdr."Document Type";    
                                SalesHdr.Validate("Sell-to Customer No.",Cust."No.");
                                SalesHdr.validate("Prices Including VAT",True);
                                SalesHdr."Your Reference" := 'SHOPIFY ORDERS';
                                SalesHdr.Insert(true);
                                OrdNo := SalesHdr."No.";
                            end;
                            ProcCnt += 1;    
                            if GuiAllowed Then Win.Update(1,OrderCnt);
                            Clear(ExFlg);
                            HLOrdLin.Reset();
                            HLOrdLin.Setrange(ShopifyID,HLOrdHdr[1].ID);
                            HLOrdLin.Setrange("Not Supplied",False);
                            HLOrdLin.Setfilter("Item No.",'<>%1','');
                            HLOrdLin.Setfilter("order Qty",'>0');
                            If HLOrdLin.FindSet then
                            repeat
                                exFlg := Item.Get(HLOrdLin."Item No.");
                                if exflg Then exflg := Not Item.Blocked;
                                if exFlg then exflg := Item."Gen. Prod. Posting Group" <> '';
                                If exflg then exflg := Item."VAT Prod. Posting Group" <> '';
                                If Exflg then exflg := HLOrdLin."Unit Of Measure" <> '';
                                If Exflg then exflg := HLOrdLin."Location Code" <> '';
                                If Exflg then exflg := Not Item."Sales Blocked";
                                If exflg then 
                                begin
                                    LineNo += 10;
                                    Clear(SalesLine);
                                    SalesLine.init;
                                    SalesLine.Validate("Document Type",SalesHdr."Document Type");
                                    SalesLine.Validate("Document No.",SalesHdr."No.");
                                    SalesLine."Line No." := LineNo;
                                    // here we establish the 
                                    Salesline.insert(true);
                                    SalesLine.Validate(Type,SalesLine.Type::Item);
                                    SalesLine.validate("No.",Item."No.");
                                    If Item.Type = Item.Type::Inventory then
                                        SalesLine.Validate("Location Code",HLOrdLin."Location Code");
                                    Salesline."Bundle Item No." :=  HLOrdLin."Bundle Item No.";
                                    Salesline."Bundle Order Qty" := HLOrdLin."Bundle Order Qty";
                                    Salesline."Bundle Unit Price" := HLOrdLin."Bundle Unit Price";
                                    If HLOrdHdr[1]."Shopify Order Currency" <> 'AUD' then
                                        SalesLine.validate("Currency Code",HLOrdHdr[1]."Shopify Order Currency");
                                    If (HLOrdLin."Tax Amount" = 0) and (SalesLine."VAT %" > 0) then
                                        SalesLine.Validate("VAT Prod. Posting Group",'NO GST')
                                    else If (HLOrdLin."Tax Amount" > 0) and (SalesLine."VAT %" = 0) then
                                        SalesLine.Validate("VAT Prod. Posting Group",'GST10');
                                    SalesLine.Validate("Unit of Measure Code",HLOrdLin."Unit Of Measure");
                                    SalesLine.Validate(Quantity,HLOrdLin."Order Qty");
                                    Salesline.Validate("Unit Price",HLOrdLin."Unit Price");
                                    Salesline.Validate("Line Discount Amount",HLOrdLin."Discount Amount");
                                    Salesline."Shopify Order ID" := HLOrdHdr[1]."Shopify Order ID";
                                    SalesLine."Shopify Application ID" := HLOrdLin."Shopify Application ID";
                                    SalesLine."Rebate Supplier No." := Item."Vendor No.";
                                    SalesLine."Rebate Brand" := Item.Brand;
                                    OrdType := 'STANDARD';
                                    If HLOrdLin."Auto Delivered" then OrdType := 'AUTO ORDER';
                                    Salesline."Dimension Set ID" := Get_Dim_Set_Id(OrdType,Item);
                                    SalesLine."Auto Delivered" := HLOrdLin."Auto Delivered";        
                                    SalesLine.Modify(true);
                                end;
                            Until (HLOrdLin.next = 0) Or Not exFlg;
                            // check to make sure all the shopify order lines were resolved ie BC Item exists
                            If Not exflg then
                            begin
                            // that are not complete ie missing an item ref in BC
                                SalesLine.Reset();
                                salesLine.Setrange("Document Type",SalesHdr."Document Type");
                                SalesLine.SetRange("Document No.",SalesHdr."No.");
                                SalesLine.Setrange("Shopify Order ID",HLOrdHdr[1]."Shopify Order ID");
                                If salesLine.Findset then
                                begin 
                                    SalesLine.deleteall(true);
                                    if GuiAllowed then Message(strsubstno('Shopify Order No %1 skipped due to invalid item lines being detected.'
                                                                ,HLOrdHdr[1]."Shopify Order No."));
                                    Excp.init;
                                    Clear(Excp.ID);
                                    Excp.insert;
                                    Excp.ShopifyID := HLOrdHdr[1].ID;
                                    Excp.Exception := StrsubStno('Order Process -> Order Item %1 is missing critical setup information',Item."No."); 
                                    excp.Modify();
                                end
                                else
                                begin
                                    Excp.init;
                                    Clear(Excp.ID);
                                    Excp.insert;
                                    Excp.ShopifyID := HLOrdHdr[1].ID;
                                    Excp.Exception := 'Order Process -> Order contains no items with order qty > 0 '; 
                                    excp.Modify();
                                end;    
                            end
                            else
                            Begin
                                // Now see if any shipping is defined against this Shopify Order
                                If HLOrdHdr[1]."Freight Total" > 0 then
                                begin
                                    LineNo += 10;
                                    Clear(SalesLine);
                                    SalesLine.init;
                                    SalesLine.Validate("Document Type",SalesHdr."Document Type");
                                    SalesLine.Validate("Document No.",SalesHdr."No.");
                                    SalesLine."Line No." := LineNo;
                                    Salesline.insert(true);
                                    SalesLine.Validate(Type,SalesLine.TYpe::Item);
                                    SalesLine.validate("No.",'SHIPPING');
                                    SalesLine.Validate("VAT Prod. Posting Group",'GST10');
                                    If HLOrdHdr[1]."Shopify Order Currency" <> 'AUD' then
                                        SalesLine.validate("Currency Code",HLOrdHdr[1]."Shopify Order Currency");
                                    SalesLine.Validate("Unit of Measure Code",'EA');    
                                    SalesLine.Validate(Quantity,1);
                                    Clear(Salesline."Auto Delivered");
                                    Salesline.Validate("Unit Price",HLOrdHdr[1]."Freight Total");
                                    Salesline."Shopify Order ID" := HLOrdHdr[1]."Shopify Order ID";
                                    SalesLine.Modify(true);
                                end;
                                If HLOrdHdr[1]."Gift Card Total" > 0 then
                                begin
                                    LineNo += 10000;
                                    Clear(SalesLine);
                                    SalesLine.init;
                                    SalesLine.Validate("Document Type",SalesHdr."Document Type");
                                    SalesLine.Validate("Document No.",SalesHdr."No.");
                                    SalesLine."Line No." := LineNo;
                                    Salesline.insert(true);
                                    SalesLine.Validate(Type,SalesLine.TYpe::Item);
                                    SalesLine.validate("No.",'GIFT_CARD_REDEEM');
                                    SalesLine.Validate("VAT Prod. Posting Group",'NO GST');
                                    If HLOrdHdr[1]."Shopify Order Currency" <> 'AUD' then
                                        SalesLine.validate("Currency Code",HLOrdHdr[1]."Shopify Order Currency");
                                    SalesLine.Validate("Unit of Measure Code",'EA');    
                                    SalesLine.Validate(Quantity,1);
                                    Salesline.Validate("Unit Price",-HLOrdHdr[1]."Gift Card Total");
                                    Salesline."Shopify Order ID" := HLOrdHdr[1]."Shopify Order ID";
                                    Clear(Salesline."Auto Delivered");
                                    SalesLine.Modify(true);
                                end;
                                /*
                                Salesline.Reset;
                                SalesLine.Setrange("Shopify Order ID",HLOrdHdr[1]."Shopify Order ID");
                                If SalesLine.Findset then
                                begin
                                    SalesLine.Calcsums("Line Discount Amount");
                                    Disc := SalesLine."Line Discount Amount" - HLOrdHdr[1]."Discount Total";
                                    If Disc <> 0 then
                                    begin
                                        LineNo += 10;
                                        Clear(SalesLine);
                                        SalesLine.init;
                                        SalesLine.Validate("Document Type",SalesHdr."Document Type");
                                        SalesLine.Validate("Document No.",SalesHdr."No.");
                                        SalesLine."Line No." := LineNo;
                                        Salesline.insert(true);
                                        SalesLine.Validate(Type,SalesLine.TYpe::Item);
                                        SalesLine.validate("No.",'DISCOUNTS');
                                        SalesLine.Validate("VAT Prod. Posting Group",'NO GST');
                                        If HLOrdHdr[1]."Shopify Order Currency" <> 'AUD' then
                                            SalesLine.validate("Currency Code",HLOrdHdr[1]."Shopify Order Currency");
                                        SalesLine.Validate("Unit of Measure Code",'EA');    
                                        SalesLine.Validate(Quantity,1);
                                        Clear(Salesline."Auto Delivered");
                                        Salesline."Shopify Order ID" := HLOrdHdr[1]."Shopify Order ID";
                                        Salesline.Validate("Unit Price",Disc);
                                        SalesLine.Modify(true);
                                    end;
                                end;
                                */    
                                    // flag this shopify order as closed now
                                // and save the BC order no
                                HLOrdHdr[1]."BC Reference No." := OrdNo;
                                HLOrdHdr[1].Modify();
                            end;
                            If ProcCnt >= SalesSetup."Order Process Count" then
                            begin
                                Clear(ProcCnt);
                                If Loop = 2 then SalesHdr."Reason Code" := 'CUSTRETURN'; 
                                SalesHdr.Modify(true);
                                Commit;
                                // now release the sales order and attempt to post it now 
                                if CuRel.Run(SalesHdr) then
                                    if Cu.Run(SalesHdr) then
                                    begin
                                        HLOrdHdr[2].Reset;
                                        HLOrdHdr[2].Setrange("Order Status",HLOrdHdr[2]."Order Status"::Open);
                                        HLOrdHdr[2].Setrange("BC Reference No.",OrdNo);
                                        if HLOrdHdr[2].Findset then
                                        begin
                                            HLOrdHdr[2].ModifyAll("Order Status",HLOrdHdr[2]."Order Status"::Closed);
                                            Commit;
                                            If Loop = 1 then
                                            begin
                                                SalesInvHdr.Reset;
                                                SalesInvHdr.Setrange("Pre-Assigned No.",OrdNo);
                                                if SalesInvHdr.findset then
                                                begin
                                                    HLOrdHdr[2].Reset;
                                                    HLOrdHdr[2].Setrange("Order Status",HLOrdHdr[2]."Order Status"::Closed);
                                                    HLOrdHdr[2].Setrange("BC Reference No.",OrdNo);
                                                    if HLOrdHdr[2].Findset then
                                                        HLOrdHdr[2].Modifyall("BC Reference No.",SalesInvHdr."No.");
                                                end; 
                                            end 
                                            else
                                            begin
                                                SalesCrdHdr.Reset;
                                                SalesCrdHdr.Setrange("Pre-Assigned No.",OrdNo);
                                                if SalesCrdHdr.findset then
                                                begin
                                                    HLOrdHdr[2].Reset;
                                                    HLOrdHdr[2].Setrange("Order Status",HLOrdHdr[2]."Order Status"::Closed);
                                                    HLOrdHdr[2].Setrange("BC Reference No.",OrdNo);
                                                    if HLOrdHdr[2].Findset then
                                                        HLOrdHdr[2].Modifyall("BC Reference No.",SalesCrdHdr."No.");
                                                end; 
                                            end;
                                        end;
                                    end;
                                    Commit;
                            end;    
                        Until HLOrdHdr[1].next = 0;
                    end;    
                    If ProcCnt > 0 then
                    begin
                        // check and ensure some sales lines were created now
                        SalesLine.reset;
                        SalesLine.Setrange("Document Type",SalesHdr."Document Type");
                        SalesLine.SetRange("Document No.",OrdNo);
                        If SalesLine.Findset then
                        begin
                     // we have some lines now
                            If Loop = 2 then SalesHdr."Reason Code" := 'CUSTRETURN'; 
                            SalesHdr.Modify(true);
                            Commit;
                            // now release the sales order and attempt to post it now 
                            if CuRel.Run(SalesHdr) then
                                if Cu.Run(SalesHdr) then
                                begin
                                    HLOrdHdr[2].Reset;
                                    HLOrdHdr[2].Setrange("Order Status",HLOrdHdr[2]."Order Status"::Open);
                                    HLOrdHdr[2].Setrange("BC Reference No.",OrdNo);
                                    if HLOrdHdr[2].Findset then
                                    begin
                                        HLOrdHdr[2].ModifyAll("Order Status",HLOrdHdr[2]."Order Status"::Closed);
                                        Commit;
                                        If Loop = 1 then
                                        begin
                                            SalesInvHdr.Reset;
                                            SalesInvHdr.Setrange("Pre-Assigned No.",OrdNo);
                                            if SalesInvHdr.findset then
                                            begin
                                                HLOrdHdr[2].Reset;
                                                HLOrdHdr[2].Setrange("Order Status",HLOrdHdr[2]."Order Status"::Closed);
                                                HLOrdHdr[2].Setrange("BC Reference No.",OrdNo);
                                                if HLOrdHdr[2].Findset then
                                                    HLOrdHdr[2].Modifyall("BC Reference No.",SalesInvHdr."No.");
                                            end; 
                                        end 
                                        else
                                        begin
                                            SalesCrdHdr.Reset;
                                            SalesCrdHdr.Setrange("Pre-Assigned No.",OrdNo);
                                            if SalesCrdHdr.findset then
                                            begin
                                                HLOrdHdr[2].Reset;
                                                HLOrdHdr[2].Setrange("Order Status",HLOrdHdr[2]."Order Status"::Closed);
                                                HLOrdHdr[2].Setrange("BC Reference No.",OrdNo);
                                                if HLOrdHdr[2].Findset then
                                                    HLOrdHdr[2].Modifyall("BC Reference No.",SalesCrdHdr."No.");
                                            end; 
                                        end;
                                    end; 
                                end;        
                        end
                        else
                        begin
                            SalesHdr.SetHideValidationDialog(true);
                            SalesHdr.Delete(True);
                        end;   
                        Commit;
                    end;
                end;    
                if GuiAllowed Then Win.Close;
            end;
        end;
        If Excp.count > 1 then Send_Email_Msg('Order Exceptions','Check Shopify Sales Orders .. Exceptions exist requiring manual intervention.','');
        If PstDate <> 0D then
        begin
            GLsetup."Allow Posting To" := PstDate;
            GLSetup.Modify(false);
        end;
        Clear_QC_Stock();    
        exit(result); 
    end;
    procedure Correct_Sales_Prices(SkuFilt:Code[20])
    var
    Sprice:Array[3] of record "HL Shopfiy Pricing";
    Sku:Code[20];
    StartDate:date;
    begin
        Clear(SKU);
        Sprice[1].Reset;
        If SkuFilt <> '' then
            Sprice[1].Setrange("Item No.",SkuFilt);
        Sprice[1].Setrange("Ending Date",0D);
        If Sprice[1].Findset then
        repeat
            If SKU <> Sprice[1]."Item No." then
            begin
                SKU :=  Sprice[1]."Item No.";
                Sprice[2].Reset;
                Sprice[2].Setrange("Ending Date",0D);
                Sprice[2].Setrange("Item No.",SKU);
                If Sprice[2].Count > 1 then
                begin
                    Sprice[2].Findset;
                    StartDate := CalcDate('-1Y',Sprice[2]."Starting Date");
                    repeat
                        If Sprice[2]."Starting Date" > StartDate then
                            StartDate := Sprice[2]."Starting Date";
                    until Sprice[2].next = 0;
                    Sprice[2].SetFilter("Starting Date",'<>%1',StartDate);
                    If Sprice[2].Findset then Sprice[2].ModifyAll("Ending Date",StartDate,false);
                    Sprice[2].SetFilter("Starting Date",'<=%1',Today);
                    Sprice[2].SetRange("Ending Date",StartDate);
                    If Sprice[2].Count > 1 then
                    begin
                        Sprice[2].Findset;
                        StartDate := Sprice[2]."Starting Date";
                        repeat
                            If Sprice[2]."Starting Date" > StartDate then
                            Begin
                                Sprice[3].Copyfilters(Sprice[2]);
                                Sprice[3].Setrange("Starting Date",StartDate);
                                If Sprice[3].findset then
                                Begin
                                    Sprice[3]."Ending Date" := StartDate;
                                    Sprice[3].Modify();
                                end;     
                                StartDate := Sprice[2]."Starting Date";
                            end;            
                        until Sprice[2].next = 0;
                    end;
                end;
            end;                
        until Sprice[1].next = 0;
        Sprice[1].Reset;
        If SkuFilt <> '' then
            Sprice[1].Setrange("Item No.",SkuFilt);
        Sprice[1].Setfilter("Ending Date",'<>%1&<=%2',0D,Today);
        If Sprice[1].Findset then Sprice[1].DeleteAll(False);
    end;
    procedure Correct_Purchase_Costs(SkuFilt:Code[20])
    var
    PCost:Array[3] of record "HL Purchase Pricing";
    Sku:Code[20];
    StartDate:date;
    begin
        Clear(SKU);
        PCost[1].Reset;
        If SkuFilt <> '' then
            Pcost[1].Setrange("Item No.",SkuFilt);
        PCost[1].Setrange("End Date",0D);
        If PCost[1].Findset then
        repeat
            If SKU <> Pcost[1]."Item No." then
            begin
                SKU :=  Pcost[1]."Item No.";
                Pcost[2].Reset;
                Pcost[2].Setrange("End Date",0D);
                Pcost[2].Setrange("Item No.",SKU);
                If Pcost[2].Count > 1 then
                begin
                    Pcost[2].Findset;
                    StartDate := CalcDate('-1Y',Pcost[2]."Start Date");
                    repeat
                        If Pcost[2]."Start Date" > StartDate then
                            StartDate := Pcost[2]."Start Date";
                    until Pcost[2].next = 0;
                    Pcost[2].SetFilter("Start Date",'<>%1',StartDate);
                    If Pcost[2].Findset then Pcost[2].ModifyAll("End Date",StartDate,false);
                    Pcost[2].SetFilter("Start Date",'<=%1',Today);
                    Pcost[2].SetRange("End Date",StartDate);
                    If Pcost[2].Count > 1 then
                    begin
                        Pcost[2].Findset;
                        StartDate := Pcost[2]."Start Date";
                        repeat
                            If Pcost[2]."Start Date" > StartDate then
                            Begin
                                Pcost[3].Copyfilters(Pcost[2]);
                                Pcost[3].Setrange("Start Date",StartDate);
                                If Pcost[3].findset then
                                Begin
                                    Pcost[3]."End Date" := StartDate;
                                    Pcost[3].Modify();
                                end;     
                                StartDate := Pcost[2]."Start Date";
                            end;            
                        until Pcost[2].next = 0;
                    end;
                end;
            end;                
        until Pcost[1].next = 0;
        Pcost[1].Reset;
        If SkuFilt <> '' then
            Pcost[1].Setrange("Item No.",SkuFilt);
        Pcost[1].Setfilter("End Date",'<>%1&<%2',0D,Today);
        If Pcost[1].Findset then Pcost[1].DeleteAll(False);
    end;
    procedure Build_Cash_Receipts(var Ordhdr:record "HL Shopify Order Header")
    var
        GenJrnlBatch:record "Gen. Journal Batch";
        GenJrnl:Record "Gen. Journal Line";
        GenTemplate:Record "Gen. Journal Template";
        NoSeriesMgt:Codeunit NoSeriesManagement;
        DummyCode:Code[10];
        GLSetup:Record "General Ledger Setup"; 
        Lineno:Integer;
        Sinv:Record "Sales Invoice Header";
        Scrd:record "Sales Cr.Memo Header";
        Doc:Code[20];
        InvTot:Decimal;
        CrdTot:decimal;
        GenJtrnTemp:Record "Gen. Journal Template";
        Cu:Codeunit "Gen. Jnl.-Post";
        PstDate:date; 
        TmpBuff:record "HL Shopify Order Header" temporary;
    begin
        TmpBuff.Reset();
        If Tmpbuff.Findset then TmpBuff.DeleteAll();
        GLSetup.get;
        If GLSetup."Reconcillation Bank Acc" = '' then
        begin
            Message('Reconciliation Bank acc not defined in General Ledger Setup');
            exit;
        end;    
        If GLSetup."Reconcillation Clearing Acc" = '' then
        begin
            Message('Reconciliation Clearing acc not defined in General Ledger Setup');
            exit;
        end; 
        If Not GenJtrnTemp.Get('CASH RECE') then
        begin
            GenJtrnTemp.Init();
            GenJtrnTemp.Validate(Name,'CASH RECE');
            GenJtrnTemp.insert;
            GenJtrnTemp.Description := 'Cash Receipts journal';
            GenJtrnTemp.validate(Type,GenJtrnTemp.type::"Cash Receipts");
            GenJtrnTemp.Validate("Bal. Account Type",GenJtrnTemp."Bal. Account Type"::"G/L Account");
            GenJtrnTemp.Validate("Source Code",'CASHRECJNL');
            GenJtrnTemp.Validate("Force Doc. Balance",true);
            GenJtrnTemp.Validate("Copy VAT Setup to Jnl. Lines",true);
            GenJtrnTemp.validate("Copy to Posted Jnl. Lines",true);
            GenJtrnTemp.Modify();
        end;
        If Not GenJrnlBatch.Get('CASH RECE','DEFAULT') then
        begin
            GenJrnlBatch.init;
            GenJrnlBatch.validate("Journal Template Name",'CASH RECE');
            GenJrnlBatch.Validate(Name,'DEFAULT');
            GenJrnlBatch.Insert();
            GenJrnlBatch.Validate("Bal. Account Type",GenJrnlBatch."Bal. Account Type"::"G/L Account");
            GenJrnlBatch.Validate("No. Series",'GJNL-RCPT');
            GenJrnlBatch.modify();
        end;
        Clear(PstDate);
        If (GLSetup."Allow Posting To" <> 0D) AND (GLSetup."Allow Posting To" < Today) then 
        begin
            PstDate := GLSetup."Allow Posting To";
            Clear(GLSetup."Allow Posting To");
            GLSetup.MOdify(false);       
        end;
        Clear(InvTot);
        Clear(CrdTot);
        Clear(Lineno);
        GenJrnl.reset;
        GenJrnl.Setrange("Journal Template Name",'CASH RECE');
        GenJrnl.Setrange("Journal Batch Name",'DEFAULT');
        If GenJrnl.findset then GenJrnl.DeleteAll();
        Ordhdr.Setrange("Cash Receipt Status",Ordhdr."Cash Receipt Status"::UnApplied);
        Ordhdr.Setfilter("Order Total",'>0');
        If Ordhdr.findset then
        repeat
            If Ordhdr."Order Type" = Ordhdr."Order Type"::Invoice then
                InvTot += Ordhdr."Order Total"
            else
                CrdTot -= Ordhdr."Order Total";
        until Ordhdr.next = 0;
        if InvTot > 0 then
        begin
            GenJrnl.INIT;
            GenJrnl.VALIDATE("Journal Template Name",'CASH RECE');
            GenJrnl.VALIDATE("Journal Batch Name",'DEFAULT');
            GenJrnl."Source Code" := 'CASHRECJNL';
            LineNo += 10;
            GenJrnl."Line No." := LineNo;
            GenJrnl.INSERT(true);
            GenJrnl.FILTERGROUP(2);
            GenJrnl.VALIDATE("Posting Date",TODAY);
            NoSeriesMgt.InitSeries('GJNL-RCPT','',GenJrnl."Posting Date",GenJrnl."Document No.",DummyCode);
            Doc := GenJrnl."Document No.";
            GenJrnl.Validate("Account Type",GenJrnl."Account Type"::"Bank Account");
            GenJrnl.Validate("Account No.",GLSetup."Reconcillation Bank Acc");
            GenJrnl.Description := StrSubstNo('%1 Payments For %2',Ordhdr."Payment Gate Way",Today);
            GenJrnl.Validate("Document Type",GenJrnl."Document Type"::Payment);
            GenJrnl.Validate(Amount,InvTot);
            GenJrnl.Modify();
            Ordhdr.Setrange("Order Type",Ordhdr."Order Type"::Invoice);
            If Ordhdr.findset then
            repeat
                GenJrnl.INIT;
                GenJrnl.VALIDATE("Journal Template Name",'CASH RECE');
                GenJrnl.VALIDATE("Journal Batch Name",'DEFAULT');
                GenJrnl."Source Code" := 'CASHRECJNL';
                LineNo += 10;
                GenJrnl."Line No." := LineNo;
                GenJrnl.INSERT(true);
                GenJrnl.FILTERGROUP(2);
                GenJrnl.VALIDATE("Posting Date",TODAY);
                GenJrnl."Document No." := Doc;
                GenJrnl.Validate("Account Type",GenJrnl."Account Type"::"G/L Account");
                GenJrnl.Validate("Account No.",GLsetup."Reconcillation Clearing Acc");
                GenJrnl.Description := StrSubstNo('Shopify Order No %1 for Order Date %2 - ' + Ordhdr."Payment Gate Way",Ordhdr."Shopify Order No.",Ordhdr."Shopify Order Date");
                GenJrnl.Validate("Document Type",GenJrnl."Document Type"::Payment);
                GenJrnl.Validate(Amount,-Ordhdr."Order Total");
                GenJrnl.Modify();
                Ordhdr."Cash Receipt Status" := Ordhdr."Cash Receipt Status"::Applied;
                Ordhdr.Modify();
                TmpBuff.Copy(Ordhdr);
                TmpBuff.insert;
            until Ordhdr.next = 0;
            Commit;
        end;
        if CrdTot < 0 then
        begin
            GenJrnl.INIT;
            GenJrnl.VALIDATE("Journal Template Name",'CASH RECE');
            GenJrnl.VALIDATE("Journal Batch Name",'DEFAULT');
            GenJrnl."Source Code" := 'CASHRECJNL';
            LineNo += 10;
            GenJrnl."Line No." := LineNo;
            GenJrnl.INSERT(true);
            GenJrnl.FILTERGROUP(2);
            GenJrnl.VALIDATE("Posting Date",TODAY);
            NoSeriesMgt.InitSeries('GJNL-RCPT','',GenJrnl."Posting Date",GenJrnl."Document No.",DummyCode);
            Doc := GenJrnl."Document No.";
            GenJrnl.Validate("Account Type",GenJrnl."Account Type"::"Bank Account");
            GenJrnl.Validate("Account No.",GLSetup."Reconcillation Bank Acc");
            GenJrnl.Description := StrSubstNo('%1 Refunds For %2',Ordhdr."Payment Gate Way",Today);
            GenJrnl.Validate("Document Type",GenJrnl."Document Type"::Refund);
            GenJrnl.Validate(Amount,CrdTot);
            GenJrnl.Modify();
            Ordhdr.Setrange("Order Type",Ordhdr."Order Type"::CreditMemo);
            If Ordhdr.findset then
            repeat
                GenJrnl.INIT;
                GenJrnl.VALIDATE("Journal Template Name",'CASH RECE');
                GenJrnl.VALIDATE("Journal Batch Name",'DEFAULT');
                GenJrnl."Source Code" := 'CASHRECJNL';
                LineNo += 10;
                GenJrnl."Line No." := LineNo;
                GenJrnl.INSERT(true);
                GenJrnl.FILTERGROUP(2);
                GenJrnl.VALIDATE("Posting Date",TODAY);
                GenJrnl."Document No." := Doc;
                GenJrnl.Validate("Account Type",GenJrnl."Account Type"::"G/L Account");
                GenJrnl.Validate("Account No.",GLsetup."Reconcillation Clearing Acc");
                GenJrnl.Description := StrSubstNo('Shopify Order No %1 for Order Date %2 - ' + Ordhdr."Payment Gate Way", Ordhdr."Shopify Order No.",Ordhdr."Shopify Order Date");
                GenJrnl.Validate("Document Type",GenJrnl."Document Type"::Refund);
                GenJrnl.Validate(Amount,Ordhdr."Order Total");
                GenJrnl.Modify();
                Ordhdr."Cash Receipt Status" := Ordhdr."Cash Receipt Status"::Applied;
                Ordhdr.Modify();
                TmpBuff.Copy(Ordhdr);
                TmpBuff.insert;
            until Ordhdr.next = 0;
            Commit;
        end;
        Clear(Doc);
        Ordhdr.Setrange("Order Type");
        Ordhdr.Setrange("Cash Receipt Status",Ordhdr."Cash Receipt Status"::Applied);
        Ordhdr.Setrange("Invoice Applied Status",Ordhdr."Invoice Applied Status"::UnApplied);
        Ordhdr.Setfilter("BC Reference No.",'<>%1&<>%2','','N/A');
        Ordhdr.Setfilter("Order Total",'>0');
        If Ordhdr.findset then
        repeat
            Clear(Doc);
            If Sinv.get(Ordhdr."BC Reference No.") AND (Ordhdr."Order Type" = Ordhdr."Order Type"::Invoice) then
                Doc := Sinv."No."
            else If Scrd.Get(Ordhdr."BC Reference No.") and (Ordhdr."Order Type" = Ordhdr."Order Type"::CreditMemo) then
                Doc := Scrd."No.";
            If doc <> '' then
            begin
                GenJrnl.INIT;
                GenJrnl.VALIDATE("Journal Template Name",'CASH RECE');
                GenJrnl.VALIDATE("Journal Batch Name",'DEFAULT');
                GenJrnl."Source Code" := 'CASHRECJNL';
                LineNo += 10;
                GenJrnl."Line No." := LineNo;
                GenJrnl.INSERT(true);
                GenJrnl.FILTERGROUP(2);
                GenJrnl.VALIDATE("Posting Date",TODAY);
                NoSeriesMgt.InitSeries('GJNL-RCPT','',GenJrnl."Posting Date",GenJrnl."Document No.",DummyCode);
                GenJrnl.VALIDATE("Account Type",GenJrnl."Account Type"::Customer);
                GenJrnl.VALIDATE("Account No.",'HEALTHY LIFE');
                GenJrnl.Validate("Bal. Account Type",GenJrnl."Bal. Account Type"::"G/L Account");
                GenJrnl.Validate("Bal. Account No.",GLSetup."Reconcillation Clearing Acc");
                GenJrnl.Description := StrSubstNo('Shopify Order No %1 for Order Date %2',Ordhdr."Shopify Order No.",Ordhdr."Shopify Order Date");
                If Ordhdr."Order Type" = Ordhdr."Order Type"::Invoice then
                begin
                    GenJrnl.Validate("Document Type",GenJrnl."Document Type"::Payment);
                    GenJrnl.Validate(Amount,-Ordhdr."Order Total");
                    GenJrnl."Applies-to Doc. Type" := GenJrnl."Applies-to Doc. Type"::Invoice;
                end    
                else
                begin
                    GenJrnl.Validate("Document Type",GenJrnl."Document Type"::Refund);
                    GenJrnl.Validate(Amount,Ordhdr."Order Total");
                    GenJrnl."Applies-to Doc. Type" := GenJrnl."Applies-to Doc. Type"::"Credit Memo";
                end;
                GenJrnl."Applies-to Doc. No." := Doc;
                GenJrnl.Modify();
                Ordhdr."Invoice Applied Status" := Ordhdr."Invoice Applied Status"::Applied;
                Ordhdr.Modify();
                TmpBuff.Copy(Ordhdr);
                If TmpBuff.Get(Ordhdr.ID) then
                    TmpBuff.modify
                else
                    Tmpbuff.Insert();    
            end;
        until Ordhdr.next = 0;
        Commit; 
        if Not GenJrnl.IsEmpty then 
        Begin
            if not Cu.Run(GenJrnl) then
            begin
                TmpBuff.Reset;
                TmpBuff.Findset;
                repeat
                    Ordhdr.Get(TmpBuff.ID);
                    Ordhdr."Cash Receipt Status" := Ordhdr."Cash Receipt Status"::UnApplied;
                    Ordhdr."Invoice Applied Status" := Ordhdr."Invoice Applied Status"::UnApplied;
                    Ordhdr.Modify();
                until TmpBuff.next = 0;    
            end;
        end;        
        If PstDate <> 0D then
        begin
            GLSetup."Allow Posting To" := PstDate;
            GLSetup.Modify(false);
        end;
    end;   
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post", 'OnBeforeCode', '', true, true)]
    local procedure "Gen. Jnl.-Post_OnBeforeCode"
    (
        var GenJournalLine: Record "Gen. Journal Line";
		var HideDialog: Boolean
    )
    begin
        HideDialog := True;
    end;
    
}