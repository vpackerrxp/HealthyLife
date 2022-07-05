codeunit 80003 "PC EDI Routines"
{
/*    Var
        Paction:Option GET,POST,DELETE,PATCH,PUT;
        errText:text;

    local procedure CallRESTWebService(var RestRec : Record "PC RESTWebServiceArguments";Parms:Dictionary of [text,text];Data:text) : Boolean
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
        RequestMessage.GetHeaders(Headers);
        If Restrec."Sps Access Token 1" <> '' then Headers.Add('Authorization', 'Bearer ' + RestRec."SPS Access Token 1" +  RestRec."SPS Access Token 2");
        If Restrec.RestMethod  in [RestRec.RestMethod::POST
                                  ,RestRec.RestMethod::PUT,RestRec.RestMethod::PATCH] then
        begin
            // get the payload data now
            Content.WriteFrom(Data);
            if Not Content.GetHeaders(Headers) Then Exit(false);
            Headers.Clear();
            If RestRec."Token Type" = RestRec."Token Type"::SpsData then
                Headers.Add('Content-Type','application/text')
            else
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
    local procedure EDI_Data(Method:option;Request:text;Parms:Dictionary of [text,text];Payload:Text;var Data:jsonobject;DataFlg:boolean): boolean
    var
        Ws:Record "PC RestWebServiceArguments";
        Setup:record "Sales & Receivables Setup";
    begin
        Setup.Get();
        Ws.init;
        Ws.Url := Request;
        If DataFlg then
            Ws."Token Type" := Ws."Token Type"::SpsData
        else
            Ws."Token Type" := Ws."Token Type"::SpsAuth;
        ws."SPS Access Token 1" := Setup."SPS Access Token 1"; 
        ws."SPS Access Token 2" := Setup."SPS Access Token 2"; 
        Ws.RestMethod := Method;
        Clear(errText);
        if CallRESTWebService(ws,Parms,Payload) then
           exit(Data.ReadFrom(ws.GetResponseContentAsText()))
        else
        begin
            errText := ws.GetResponseContentAsText();      
            exit(false);
        end;    
    end; 
    local procedure EDI_Data_AsArray(Method:option;Request:text;Parms:Dictionary of [text,text];Payload:Text;var Data:JsonArray): boolean
    var
        Ws:Record "PC RestWebServiceArguments";
        Setup:record "Sales & Receivables Setup";
    begin
        Setup.Get();
        Ws.init;
        Ws.Url := Request;
        Ws."Token Type":= Ws."Token Type"::SpsData;
        ws."SPS Access Token 1" := Setup."SPS Access Token 1"; 
        ws."SPS Access Token 2" := Setup."SPS Access Token 2"; 
        Ws.RestMethod := Method;
        Clear(errText);
        if CallRESTWebService(ws,Parms,Payload) then
           exit(Data.ReadFrom(ws.GetResponseContentAsText()))
        else
        begin
            errText := ws.GetResponseContentAsText();      
            exit(false);
        end;    
    end; 

    local procedure EDI_XML_Data(Method:option;Request:text;Parms:Dictionary of [text,text];Payload:Text;var Data:XmlDocument;DataFlg:boolean): boolean
    var
        Ws:Record "PC RestWebServiceArguments";
        Setup:record "Sales & Receivables Setup";
    begin
        Setup.Get();
        Ws.init;
        Ws.Url := Request;
        If DataFlg then
            Ws."Token Type" := Ws."Token Type"::SpsData
        else
            Ws."Token Type" := Ws."Token Type"::SpsAuth;
        ws."SPS Access Token 1" := Setup."SPS Access Token 1"; 
        ws."SPS Access Token 2" := Setup."SPS Access Token 2"; 
        Ws.RestMethod := Method;
        Clear(errText);
        if CallRESTWebService(ws,Parms,Payload) then
           exit(XmlDocument.ReadFrom(ws.GetResponseContentAsText(),Data))
        else
        begin
            errText := ws.GetResponseContentAsText();      
            exit(false);
        end;    
    end; 
    procedure Get_EDI_Access_Token():Boolean
    var
        Setup:Record "Sales & Receivables Setup";
        Jsobj:JsonObject;
        Parms:Dictionary of [text,text];
        Payload:Text;
        Jstoken:JsonToken;
        request:Label 'https://auth.spscommerce.com/oauth/token';
    begin
        Setup.Get;
        If Setup."SPS Token Date" < TODAY then
        begin         
            Clear(Setup."SPS Access Token 1");
            Clear(Setup."SPS Access Token 2");
            Setup.Modify(false);
            Commit();
        end;    
        If Setup."SPS Access Token 1" = '' then
        begin    
            Clear(Parms);
            Clear(Jsobj);
            Clear(Payload);
            Jsobj.add('grant_type','client_credentials');
            jsobj.add('client_id',Setup."SPS Client ID");
            jsobj.add('client_secret',Setup."SPS Secret Key");
            Jsobj.add('audience','api://api.spscommerce.com/');
            Jsobj.WriteTo(Payload);
            clear(Jsobj);
            If EDI_Data(Paction::POST,request,Parms,Payload,Jsobj,false) then
            begin
                Jsobj.get('access_token',JStoken);
                Setup."SPS Access Token 1" := CopyStr(Jstoken.AsValue().AsText(),1,1000);
                Setup."SPS Access Token 2" := CopyStr(Jstoken.AsValue().AsText(),1001,200);
                Setup."SPS Token Date" := Today;
                Setup.modify(false);
                Commit;     
            end
            else
                Message(errText);
        end;
        exit(Setup."SPS Access Token 1" <> '');        
    end;
    
    Procedure Build_EDI_Purchase_Order(var PurchHdr:record "Purchase Header";FuncCode:Code[10]):Boolean;
    var
        PurchLine:record "Purchase Line";
        XmlDoc:XmlDocument;
        CurrNode:Array[4] of XmlNode;
        CuXML:Codeunit "XML DOM Management";
        LineNo:Integer;
        Ven:Record Vendor;
        Loc:Record Location;
        Item:record Item;
        Comm:Record "Purch. Comment Line";
        Comments:text;
        Jsobj:JsonObject;
        Parms:Dictionary of [text,text];
        Payload:Text;
        request:Label 'https://api.spscommerce.com/transactions/v2/';
        CompInfo:record "Company Information";
        Ret:Boolean;
    Begin
        //Get_Transaction_Documents();
        //Exit;
        Ret := Get_EDI_Access_Token();
        if Ret then
        begin
            CompInfo.get;
            XmlDocument.ReadFrom('<PurchaseOrder/>',XmlDoc);
            CurrNode[1] := XmlDoc.AsXmlNode();
            CuXML.FindNode(CurrNode[1],'//PurchaseOrder',CurrNode[2]);
            CuXML.AddElement(CurrNode[2],'Header','','',CurrNode[1]);
            CuXML.AddElement(CurrNode[1],'PurchaseOrderNumber',PurchHdr."No.",'',CurrNode[2]);
            CuXML.AddElement(CurrNode[1],'MessageFunctionCode',FuncCode,'',CurrNode[2]);
            CuXML.AddElement(CurrNode[1],'PurchaseOrderDate',Format(PurchHdr."Order Date",0,'<Day,2>-<Month,2>-<Year4>'),'',CurrNode[2]);
            CuXML.AddElement(CurrNode[1],'RequestedDeliveryDate',Format(PurchHdr."Requested Receipt Date",0,'<Day,2>-<Month,2>-<year4>'),'',CurrNode[2]);
            CuXML.AddElement(CurrNode[1],'RequestedDeliveryTime',Format(PurchHdr."Requested Receipt Time",0,'<Hours24,2>:<Minutes,2>:<Seconds,2>'),'',CurrNode[2]);
            If PurchHdr."Fulfilo Order ID" > 0 then
                CuXML.AddElement(CurrNode[1],'BookingReferenceNumber',Format(PurchHdr."Fulfilo Order ID"),'',CurrNode[2])
            else
                CuXML.AddElement(CurrNode[1],'BookingReferenceNumber','','',CurrNode[2]);
            Clear(Comments);
            Comm.reset;
            Comm.Setrange("Document Type",PurchHdr."Document Type");
            Comm.Setrange("No.",PurchHdr."No.");
            If Comm.findset then  
            repeat
                Comments += Comm.Comment + ' ';
            until Comm.Next = 0;                
            CuXML.AddElement(CurrNode[1],'Notes',Comments,'',CurrNode[2]);
            CuXML.AddElement(CurrNode[1],'NameAddressParty','','',CurrNode[2]);
            CuXML.AddElement(CurrNode[2],'PartyCodeQualifier','BUYER','',CurrNode[1]);
            CuXML.AddElement(CurrNode[2],'PartyIdentifier','PETCULTURE','',CurrNode[1]);
            If Compinfo."Name 2" <> '' then
                CuXML.AddElement(CurrNode[2],'PartyName',CompInfo.Name + ' ' + Compinfo."Name 2",'',CurrNode[1])
            else
                CuXML.AddElement(CurrNode[2],'PartyName',CompInfo.Name,'',CurrNode[1]);
            If CompInfo."Address 2" <> '' then     
                CuXML.AddElement(CurrNode[2],'Address',CompInfo.Address + ' ' + CompInfo."Address 2",'',CurrNode[1])
            else
                CuXML.AddElement(CurrNode[2],'Address',CompInfo.Address,'',CurrNode[1]);
            CuXML.AddElement(CurrNode[2],'City',CompInfo.City,'',CurrNode[1]);
            CuXML.AddElement(CurrNode[2],'State',compinfo.County,'',CurrNode[1]);
            CuXML.AddElement(CurrNode[2],'Postcode',compinfo."Post Code",'',CurrNode[1]);
            If CompInfo."Country/Region Code" = '' then
                CuXML.AddElement(CurrNode[2],'Country','AU','',CurrNode[1])
            else
                CuXML.AddElement(CurrNode[2],'Country',CompInfo."Country/Region Code",'',CurrNode[1]);
            CuXML.AddElement(CurrNode[2],'ContactName',CompInfo."Contact Person",'',CurrNode[1]);
            CuXML.AddElement(CurrNode[2],'Phone',Compinfo."Phone No.",'',CurrNode[1]);
            CuXML.AddElement(CurrNode[2],'Email',Compinfo."E-Mail",'',CurrNode[1]);
            CuXML.FindNode(CurrNode[2],'//PurchaseOrder/Header',CurrNode[1]);
            CuXML.AddElement(CurrNode[1],'NameAddressParty','','',CurrNode[2]);
            CuXML.AddElement(CurrNode[2],'PartyCodeQualifier','SUPPLIER','',CurrNode[1]);
            CuXML.AddElement(CurrNode[2],'PartyIdentifier',PurchHdr."Buy-from Vendor No.",'',CurrNode[1]);
            If PurchHdr."Buy-from Vendor Name 2" <> '' then
                CuXML.AddElement(CurrNode[2],'PartyName',PurchHdr."Buy-from Vendor Name" + ' ' + PurchHdr."Buy-from Vendor Name 2",'',CurrNode[1])
            else
                 CuXML.AddElement(CurrNode[2],'PartyName',PurchHdr."Buy-from Vendor Name",'',CurrNode[1]);
            if  PurchHdr."Buy-from Address 2" <> '' then   
                CuXML.AddElement(CurrNode[2],'Address',PurchHdr."Buy-from Address" + ' ' + PurchHdr."Buy-from Address 2",'',CurrNode[1])
            else
                CuXML.AddElement(CurrNode[2],'Address',PurchHdr."Buy-from Address",'',CurrNode[1]);
            CuXML.AddElement(CurrNode[2],'City',PurchHdr."Buy-from City",'',CurrNode[1]);
            CuXML.AddElement(CurrNode[2],'State',PurchHdr."Buy-from County",'',CurrNode[1]);
            CuXML.AddElement(CurrNode[2],'Postcode',PurchHdr."Buy-from Post Code",'',CurrNode[1]);
            if PurchHdr."Buy-from Country/Region Code" = '' then
                CuXML.AddElement(CurrNode[2],'Country','AU','',CurrNode[1])
            else
                CuXML.AddElement(CurrNode[2],'Country',PurchHdr."Buy-from Country/Region Code",'',CurrNode[1]);
            CuXML.AddElement(CurrNode[2],'ContactName',PurchHdr."Buy-from Contact",'',CurrNode[1]);
            Ven.Get(PurchHdr."Buy-from Vendor No.");
            CuXML.AddElement(CurrNode[2],'Phone',Ven."Phone No.",'',CurrNode[1]);
            CuXML.AddElement(CurrNode[2],'Email',Ven."E-Mail",'',CurrNode[1]);
            CuXML.FindNode(CurrNode[2],'//PurchaseOrder/Header',CurrNode[1]);
            CuXML.AddElement(CurrNode[1],'NameAddressParty','','',CurrNode[2]);
            CuXML.AddElement(CurrNode[2],'PartyCodeQualifier','SHIPTO','',CurrNode[1]);
            Loc.Get(PurchHdr."Location Code");
            CuXML.AddElement(CurrNode[2],'PartyIdentifier','DC'+ Loc.Code,'',CurrNode[1]);
            If Loc."Name 2" <> '' then
                CuXML.AddElement(CurrNode[2],'PartyName',Loc.Name + ' ' + Loc."Name 2",'',CurrNode[1])
            else
                CuXML.AddElement(CurrNode[2],'PartyName',Loc.Name,'',CurrNode[1]);
            if Loc."Address 2" <> '' then    
                CuXML.AddElement(CurrNode[2],'Address',Loc.Address + ' ' + Loc."Address 2",'',CurrNode[1])
            else
                CuXML.AddElement(CurrNode[2],'Address',Loc.Address,'',CurrNode[1]);
            CuXML.AddElement(CurrNode[2],'City',Loc.City,'',CurrNode[1]);
            CuXML.AddElement(CurrNode[2],'State',Loc.County,'',CurrNode[1]);
            CuXML.AddElement(CurrNode[2],'Postcode',Loc."Post Code",'',CurrNode[1]);
            If Loc."Country/Region Code" = '' then
                CuXML.AddElement(CurrNode[2],'Country','AU','',CurrNode[1])
            else
            CuXML.AddElement(CurrNode[2],'Country',Loc."Country/Region Code",'',CurrNode[1]);
            CuXML.AddElement(CurrNode[2],'ContactName',loc.Contact,'',CurrNode[1]);
            CuXML.AddElement(CurrNode[2],'Phone',Loc."Phone No.",'',CurrNode[1]);
            CuXML.AddElement(CurrNode[2],'Email',Loc."E-Mail",'',CurrNode[1]);
            CuXML.FindNode(CurrNode[2],'//PurchaseOrder/Header',CurrNode[1]);
            If PurchHdr."Currency Code" = '' then
                CuXML.AddElement(CurrNode[1],'Currency','AUD','',CurrNode[2])
            else
                CuXML.AddElement(CurrNode[1],'Currency',PurchHdr."Currency Code",'',CurrNode[2]);
            PurchHdr.CalcFields(Amount,"Amount Including VAT","Invoice Discount Amount");    
            If PurchHdr."Invoice Discount Amount" > 0 then
            begin
                CuXML.FindNode(CurrNode[2],'//PurchaseOrder/Header',CurrNode[1]);
                CuXML.AddElement(CurrNode[1],'AllowancesOrCharges','','',CurrNode[2]);
                CuXML.AddElement(CurrNode[2],'AllowancesOrCharge','ALLOWANCE','',CurrNode[1]);
                CuXML.AddElement(CurrNode[2],'AllowanceOrChargeIdentifier','ORDDISC','',CurrNode[1]);
                CuXML.AddElement(CurrNode[2],'AllowanceOrChargeDescription','Order Discount','',CurrNode[1]);
                CuXML.AddElement(CurrNode[2],'AllowanceOrChargeAmount',Format(PurchHdr."Invoice Discount Amount",0,'<Precision,2><Standard Format,1>'),'',CurrNode[1]);
                CuXML.AddElement(CurrNode[2],'AllowanceOrChargePercentage',Format(PurchHdr."Invoice Discount Amount" * 100/(PurchHdr."Amount" + PurchHdr."Invoice Discount Amount"),0,'<Precision,2><Standard Format,1>'),'',CurrNode[1]);
                //See if tax applies or not   
                If PurchHdr."Amount" <> PurchHdr."Amount Including VAT" then
                begin
                CuXML.AddElement(CurrNode[2],'AllowanceOrChargeTaxRate',Format(PurchHdr."Amount"/(PurchHdr."Amount Including VAT" - PurchHdr."Amount"),0,'<Precision,2><Standard Format,1>'),'',CurrNode[1]);
                CuXML.AddElement(CurrNode[2],'AllowanceOrChargeTaxAmount',Format(PurchHdr."Invoice Discount Amount"/100 * (PurchHdr."Amount"/(PurchHdr."Amount Including VAT" - PurchHdr."Amount")),0,'<Precision,2><Standard Format,1>'),'',CurrNode[1]);
                end
                else
                begin    
                    CuXML.AddElement(CurrNode[2],'AllowanceOrChargeTaxRate','0','',CurrNode[1]);
                    CuXML.AddElement(CurrNode[2],'AllowanceOrChargeTaxAmount','0','',CurrNode[1]);
                end;    
            end;
            PurchLine.Reset;
            PurchLine.Setrange("Document Type",PurchHdr."Document Type");
            PurchLine.setrange("Document No.",PurchHdr."No.");
            Purchline.Setrange(Type,PurchLine.type::Item);
            PurchLine.Setrange("No.",'FREIGHT');
            If Purchline.Findset then
            begin
                CuXML.FindNode(CurrNode[2],'//PurchaseOrder/Header',CurrNode[1]);
                CuXML.AddElement(CurrNode[1],'AllowancesOrCharges','','',CurrNode[2]);
                CuXML.AddElement(CurrNode[2],'AllowancesOrCharge','CHARGE','',CurrNode[1]);
                CuXML.AddElement(CurrNode[2],'AllowanceOrChargeIdentifier','FC','',CurrNode[1]);
                CuXML.AddElement(CurrNode[2],'AllowanceOrChargeDescription','Freight Cost','',CurrNode[1]);
                CuXML.AddElement(CurrNode[2],'AllowanceOrChargeAmount',Format(PurchLine."Amount Including VAT",0,'<Precision,2><Standard Format,1>'),'',CurrNode[1]);
                CuXML.AddElement(CurrNode[2],'AllowanceOrChargePercentage','0','',CurrNode[1]);
                If PurchHdr."Amount" <> PurchHdr."Amount Including VAT" then
                begin
                CuXML.AddElement(CurrNode[2],'AllowanceOrChargeTaxRate',Format(PurchHdr."Amount"/(PurchHdr."Amount Including VAT" - PurchHdr."Amount"),0,'<Precision,2><Standard Format,1>'),'',CurrNode[1]);
                CuXML.AddElement(CurrNode[2],'AllowanceOrChargeTaxAmount',Format(PurchLine."Amount Including VAT" - PurchLine."Line Amount",0,'<Precision,2><Standard Format,1>'),'',CurrNode[3]);
                end
                else
                begin    
                    CuXML.AddElement(CurrNode[2],'AllowanceOrChargeTaxRate','0','',CurrNode[1]);
                    CuXML.AddElement(CurrNode[2],'AllowanceOrChargeTaxAmount','0','',CurrNode[1]);
                end; 
            end;
            Clear(LineNo);    
            CuXML.FindNode(CurrNode[1],'//PurchaseOrder',CurrNode[2]);
            CuXML.AddElement(CurrNode[2],'LineItems','','',CurrNode[1]);
            Purchline.SetFilter("No.",'<>FREIGHT');
            If PurchLine.findset then
            repeat
                LineNo += 1;
                CuXML.AddElement(CurrNode[1],'LineItem','','',CurrNode[2]);
                CuXML.AddElement(CurrNode[2],'LineNumber',Format(PurchLine."Line No."),'',CurrNode[3]);
                Item.Get(PurchLine."No.");
                CuXML.AddElement(CurrNode[2],'GTIN',Item.GTIN,'',CurrNode[3]);
                CuXML.AddElement(CurrNode[2],'BuyerPartNumber',PurchLine."No.",'',CurrNode[3]);
                CuXML.AddElement(CurrNode[2],'VendorPartNumber',Purchline."Vendor Item No.",'',CurrNode[3]);
                If PurchLine."Description 2" <> '' then
                    CuXML.AddElement(CurrNode[2],'ProductDescription',PurchLine.Description + ' ' + PurchLine."Description 2",'',CurrNode[3])
                else
                    CuXML.AddElement(CurrNode[2],'ProductDescription',PurchLine.Description,'',CurrNode[3]);
                CuXML.AddElement(CurrNode[2],'OrderQty',Format(PurchLine.Quantity,0,'<Precision,2><Standard Format,0>'),'',CurrNode[3]);
                CuXML.AddElement(CurrNode[2],'OrderQtyUOM',PurchLine."Unit of Measure Code",'',CurrNode[3]);
                CuXML.AddElement(CurrNode[2],'PackSize',Format(PurchLine."Qty. per Unit of Measure",0,'<Precision,2><Standard Format,1>'),'',CurrNode[3]);
                CuXML.AddElement(CurrNode[2],'UnitPrice',Format(PurchLine."Direct Unit Cost",0,'<Precision,2><Standard Format,1>'),'',CurrNode[3]);
                CuXML.AddElement(CurrNode[2],'TaxRate',Format(PurchLine."VAT %",0,'<Precision,2><Standard Format,1>'),'',CurrNode[3]);
                If PurchLine."Line Discount %" > 0 then 
                begin
                    CuXML.AddElement(CurrNode[2],'AllowancesOrCharges','','',CurrNode[3]);
                    CuXML.AddElement(CurrNode[3],'AllowancesOrCharge','ALLOWANCE','',CurrNode[4]);
                    CuXML.AddElement(CurrNode[3],'AllowanceOrChargePercentage',Format(PurchLine."Line Discount %",0,'<Precision,2><Standard Format,1>'),'',CurrNode[4]);
                    CuXML.AddElement(CurrNode[3],'AllowanceOrChargeAmount',Format(PurchLine."Line Discount Amount"/Purchline.Quantity,0,'<Precision,2><Standard Format,1>'),'',CurrNode[4]);
                end;    
                CuXML.AddElement(CurrNode[2],'LineAmountExcGST',Format(PurchLine."Line Amount",0,'<Precision,2><Standard Format,1>'),'',CurrNode[3]);
                CuXML.AddElement(CurrNode[2],'LineAmountGST',Format(PurchLine."Amount Including VAT" - PurchLine."Line Amount",0,'<Precision,2><Standard Format,1>'),'',CurrNode[3]);
                CuXML.AddElement(CurrNode[2],'LineAmountIncGST',Format(PurchLine."Amount Including VAT",0,'<Precision,2><Standard Format,1>'),'',CurrNode[3]);
            until PurchLine.next = 0;
            CuXML.FindNode(CurrNode[2],'//PurchaseOrder',CurrNode[1]);
            CuXML.AddElement(CurrNode[1],'Summary','','',CurrNode[2]);
            CuXML.AddElement(CurrNode[2],'NumberOfLines',Format(LineNo),'',CurrNode[1]);
            CuXML.AddElement(CurrNode[2],'OrderAmountExcGST',Format(PurchHdr.Amount,0,'<Precision,2><Standard Format,1>'),'',CurrNode[1]);
            CuXML.AddElement(CurrNode[2],'OrderAmountGST',Format(PurchHdr."Amount Including VAT" - PurchHdr.Amount,0,'<Precision,2><Standard Format,1>'),'',CurrNode[1]);
            CuXML.AddElement(CurrNode[2],'OrderAmountIncGST',Format(PurchHdr."Amount Including VAT",0,'<Precision,2><Standard Format,1>'),'',CurrNode[1]);
            XmlDoc.WriteTo(Payload);
            Clear(Jsobj);
            Clear(parms);
            Ret := EDI_Data(Paction::POST,request + PurchHdr."No." + '.dat',Parms,Payload,Jsobj,true);
        end;
        exit(Ret);
    End;
    
    local procedure Get_Transaction_Documents()
    var
        request:Label 'https://api.spscommerce.com/transactions/v2/';
        Parms:Dictionary of [text,text];
        Payload:Text;
        JsToken:array[2] of JsonToken;
        JSArray:JsonArray;
        FileLst:List of [Text];
        i:Integer;
        XmlDoc:XmlDocument;
        CurrNode:Array[4] of XmlNode;
        CuXML:Codeunit "XML DOM Management";
        EDIHdrBuff:record "PC EDI Header Buffer";
        EDILineBuff:record "PC EDI Line Buffer";
    begin
        If Get_EDI_Access_Token() then
        begin
            Clear(Parms);
            Clear(Payload);
            Clear(JSArray);
            Clear(Filelst);
            If EDI_Data_AsArray(Paction::Get,request + 'PO*',Parms,Payload,JSArray) then
            begin
                for i := 0 to JSArray.Count -1 do
                begin
                    JSArray.get(i,JsToken[1]);
                    JsToken[1].SelectToken('key',JsToken[2]);
                    FileLst.Add(JsToken[2].AsValue().AsText());
                end;
                for i := 1 to FileLst.Count do
                begin
                    Clear(Parms);
                    Clear(Payload);
                    If EDI_XML_Data(Paction::Get,request + FileLst.Get(i),Parms,Payload,XmlDoc,true) then
                    begin
                        EDIHdrBuff.init;
                        Clear(EDIHdrBuff.ID);
                        EDIHdrBuff.Insert;
                        CurrNode[1] := XmlDoc.AsXmlNode();
                        If CuXML.FindNode(CurrNode[1],'//PurchaseOrderResponse',CurrNode[2]) then
                            EDIHdrBuff."Response Type" := EDIHdrBuff."Response Type"::Response
                        else If CuXML.FindNode(CurrNode[1],'//DespatchAdvice',CurrNode[2]) then
                            EDIHdrBuff."Response Type" := EDIHdrBuff."Response Type"::Dispatch
                        else If CuXML.FindNode(CurrNode[1],'//Invoice',CurrNode[2]) then
                            EDIHdrBuff."Response Type" := EDIHdrBuff."Response Type"::Invoice;
                        If EDIHdrBuff."Response Type" > 0 then
                        begin

                        end;            
                    end;
               end;
            end;
        end;     
    end;
    Procedure Build_EDI_Purchase_Order_Resp(var PurchHdr:record "Purchase Header";FuncCode:Code[10]):Boolean;
    var
        PurchLine:record "Purchase Line";
        XmlDoc:XmlDocument;
        CurrNode:Array[4] of XmlNode;
        CuXML:Codeunit "XML DOM Management";
        LineNo:Integer;
        Ven:Record Vendor;
        Loc:Record Location;
        Item:record Item;
        Comm:Record "Purch. Comment Line";
        Comments:text;
        Jsobj:JsonObject;
        Parms:Dictionary of [text,text];
        Payload:Text;
        request:Label 'https://api.spscommerce.com/transactions/v2/';
        CompInfo:record "Company Information";
        Ret:Boolean;
        BlobTmp:COdeunit "Temp Blob";
        Outstrm:OutStream;
        inStrm:InStream;
        Filename:text;
    Begin
        //Get_Transaction_Documents();
        //Exit;
        Ret := Get_EDI_Access_Token();
        if Ret then
        begin
            CompInfo.get;
            XmlDocument.ReadFrom('<PurchaseOrderResponse/>',XmlDoc);
            CurrNode[1] := XmlDoc.AsXmlNode();
            CuXML.FindNode(CurrNode[1],'//PurchaseOrderResponse',CurrNode[2]);
            CuXML.AddElement(CurrNode[2],'Header','','',CurrNode[1]);
            CuXML.AddElement(CurrNode[1],'PurchaseOrderResponseNumber',PurchHdr."No.",'',CurrNode[2]);
            CuXML.AddElement(CurrNode[1],'MessageFunctionCode',FuncCode,'',CurrNode[2]);
            CuXML.AddElement(CurrNode[1],'PurchaseOrderResponseDate',Format(PurchHdr."Order Date",0,'<Day,2>-<Month,2>-<Year4>'),'',CurrNode[2]);
            CuXML.AddElement(CurrNode[1],'RequestedDeliveryDate',Format(PurchHdr."Requested Receipt Date",0,'<Day,2>-<Month,2>-<year4>'),'',CurrNode[2]);
            CuXML.AddElement(CurrNode[1],'RequestedDeliveryTime',Format(PurchHdr."Requested Receipt Time",0,'<Hours24,2>:<Minutes,2>:<Seconds,2>'),'',CurrNode[2]);
            CuXML.AddElement(CurrNode[1],'PurchaseOrderNumber',PurchHdr."No.",'',CurrNode[2]);
            Clear(Comments);
            Comm.reset;
            Comm.Setrange("Document Type",PurchHdr."Document Type");
            Comm.Setrange("No.",PurchHdr."No.");
            If Comm.findset then  
            repeat
                Comments += Comm.Comment + ' ';
            until Comm.Next = 0;                
            CuXML.AddElement(CurrNode[1],'Notes',Comments,'',CurrNode[2]);
            CuXML.AddElement(CurrNode[1],'NameAddressParty','','',CurrNode[2]);
            CuXML.AddElement(CurrNode[2],'PartyCodeQualifier','BUYER','',CurrNode[1]);
            CuXML.AddElement(CurrNode[2],'PartyIdentifier','PETCULTURE','',CurrNode[1]);
            If Compinfo."Name 2" <> '' then
                CuXML.AddElement(CurrNode[2],'PartyName',CompInfo.Name + ' ' + Compinfo."Name 2",'',CurrNode[1])
            else
                CuXML.AddElement(CurrNode[2],'PartyName',CompInfo.Name,'',CurrNode[1]);
            If CompInfo."Address 2" <> '' then     
                CuXML.AddElement(CurrNode[2],'Address',CompInfo.Address + ' ' + CompInfo."Address 2",'',CurrNode[1])
            else
                CuXML.AddElement(CurrNode[2],'Address',CompInfo.Address,'',CurrNode[1]);
            CuXML.AddElement(CurrNode[2],'City',CompInfo.City,'',CurrNode[1]);
            CuXML.AddElement(CurrNode[2],'State',compinfo.County,'',CurrNode[1]);
            CuXML.AddElement(CurrNode[2],'Postcode',compinfo."Post Code",'',CurrNode[1]);
            If CompInfo."Country/Region Code" = '' then
                CuXML.AddElement(CurrNode[2],'Country','AU','',CurrNode[1])
            else
                CuXML.AddElement(CurrNode[2],'Country',CompInfo."Country/Region Code",'',CurrNode[1]);
            CuXML.AddElement(CurrNode[2],'ContactName',CompInfo."Contact Person",'',CurrNode[1]);
            CuXML.AddElement(CurrNode[2],'Phone',Compinfo."Phone No.",'',CurrNode[1]);
            CuXML.AddElement(CurrNode[2],'Email',Compinfo."E-Mail",'',CurrNode[1]);
            CuXML.FindNode(CurrNode[2],'//PurchaseOrderResponse/Header',CurrNode[1]);
            CuXML.AddElement(CurrNode[1],'NameAddressParty','','',CurrNode[2]);
            CuXML.AddElement(CurrNode[2],'PartyCodeQualifier','SUPPLIER','',CurrNode[1]);
            CuXML.AddElement(CurrNode[2],'PartyIdentifier',PurchHdr."Buy-from Vendor No.",'',CurrNode[1]);
            If PurchHdr."Buy-from Vendor Name 2" <> '' then
                CuXML.AddElement(CurrNode[2],'PartyName',PurchHdr."Buy-from Vendor Name" + ' ' + PurchHdr."Buy-from Vendor Name 2",'',CurrNode[1])
            else
                 CuXML.AddElement(CurrNode[2],'PartyName',PurchHdr."Buy-from Vendor Name",'',CurrNode[1]);
            if  PurchHdr."Buy-from Address 2" <> '' then   
                CuXML.AddElement(CurrNode[2],'Address',PurchHdr."Buy-from Address" + ' ' + PurchHdr."Buy-from Address 2",'',CurrNode[1])
            else
                CuXML.AddElement(CurrNode[2],'Address',PurchHdr."Buy-from Address",'',CurrNode[1]);
            CuXML.AddElement(CurrNode[2],'City',PurchHdr."Buy-from City",'',CurrNode[1]);
            CuXML.AddElement(CurrNode[2],'State',PurchHdr."Buy-from County",'',CurrNode[1]);
            CuXML.AddElement(CurrNode[2],'Postcode',PurchHdr."Buy-from Post Code",'',CurrNode[1]);
            if PurchHdr."Buy-from Country/Region Code" = '' then
                CuXML.AddElement(CurrNode[2],'Country','AU','',CurrNode[1])
            else
                CuXML.AddElement(CurrNode[2],'Country',PurchHdr."Buy-from Country/Region Code",'',CurrNode[1]);
            CuXML.AddElement(CurrNode[2],'ContactName',PurchHdr."Buy-from Contact",'',CurrNode[1]);
            Ven.Get(PurchHdr."Buy-from Vendor No.");
            CuXML.AddElement(CurrNode[2],'Phone',Ven."Phone No.",'',CurrNode[1]);
            CuXML.AddElement(CurrNode[2],'Email',Ven."E-Mail",'',CurrNode[1]);
            CuXML.FindNode(CurrNode[2],'//PurchaseOrderResponse/Header',CurrNode[1]);
            CuXML.AddElement(CurrNode[1],'NameAddressParty','','',CurrNode[2]);
            CuXML.AddElement(CurrNode[2],'PartyCodeQualifier','SHIPTO','',CurrNode[1]);
            Loc.Get(PurchHdr."Location Code");
            CuXML.AddElement(CurrNode[2],'PartyIdentifier','DC'+ Loc.Code,'',CurrNode[1]);
            If Loc."Name 2" <> '' then
                CuXML.AddElement(CurrNode[2],'PartyName',Loc.Name + ' ' + Loc."Name 2",'',CurrNode[1])
            else
                CuXML.AddElement(CurrNode[2],'PartyName',Loc.Name,'',CurrNode[1]);
            if Loc."Address 2" <> '' then    
                CuXML.AddElement(CurrNode[2],'Address',Loc.Address + ' ' + Loc."Address 2",'',CurrNode[1])
            else
                CuXML.AddElement(CurrNode[2],'Address',Loc.Address,'',CurrNode[1]);
            CuXML.AddElement(CurrNode[2],'City',Loc.City,'',CurrNode[1]);
            CuXML.AddElement(CurrNode[2],'State',Loc.County,'',CurrNode[1]);
            CuXML.AddElement(CurrNode[2],'Postcode',Loc."Post Code",'',CurrNode[1]);
            If Loc."Country/Region Code" = '' then
                CuXML.AddElement(CurrNode[2],'Country','AU','',CurrNode[1])
            else
            CuXML.AddElement(CurrNode[2],'Country',Loc."Country/Region Code",'',CurrNode[1]);
            CuXML.AddElement(CurrNode[2],'ContactName',loc.Contact,'',CurrNode[1]);
            CuXML.AddElement(CurrNode[2],'Phone',Loc."Phone No.",'',CurrNode[1]);
            CuXML.AddElement(CurrNode[2],'Email',Loc."E-Mail",'',CurrNode[1]);
            CuXML.FindNode(CurrNode[2],'//PurchaseOrderResponse/Header',CurrNode[1]);
            If PurchHdr."Currency Code" = '' then
                CuXML.AddElement(CurrNode[1],'Currency','AUD','',CurrNode[2])
            else
                CuXML.AddElement(CurrNode[1],'Currency',PurchHdr."Currency Code",'',CurrNode[2]);
            PurchHdr.CalcFields(Amount,"Amount Including VAT","Invoice Discount Amount");    
            If PurchHdr."Invoice Discount Amount" > 0 then
            begin
                CuXML.FindNode(CurrNode[2],'//PurchaseOrderResponse/Header',CurrNode[1]);
                CuXML.AddElement(CurrNode[1],'AllowancesOrCharges','','',CurrNode[2]);
                CuXML.AddElement(CurrNode[2],'AllowancesOrCharge','ALLOWANCE','',CurrNode[1]);
                CuXML.AddElement(CurrNode[2],'AllowanceOrChargeIdentifier','ORDDISC','',CurrNode[1]);
                CuXML.AddElement(CurrNode[2],'AllowanceOrChargeDescription','Order Discount','',CurrNode[1]);
                CuXML.AddElement(CurrNode[2],'AllowanceOrChargeAmount',Format(PurchHdr."Invoice Discount Amount",0,'<Precision,2><Standard Format,1>'),'',CurrNode[1]);
                CuXML.AddElement(CurrNode[2],'AllowanceOrChargePercentage',Format(PurchHdr."Invoice Discount Amount" * 100/(PurchHdr."Amount" + PurchHdr."Invoice Discount Amount"),0,'<Precision,2><Standard Format,1>'),'',CurrNode[1]);
                //See if tax applies or not   
                If PurchHdr."Amount" <> PurchHdr."Amount Including VAT" then
                begin
                CuXML.AddElement(CurrNode[2],'AllowanceOrChargeTaxRate',Format(PurchHdr."Amount"/(PurchHdr."Amount Including VAT" - PurchHdr."Amount"),0,'<Precision,2><Standard Format,1>'),'',CurrNode[1]);
                CuXML.AddElement(CurrNode[2],'AllowanceOrChargeTaxAmount',Format(PurchHdr."Invoice Discount Amount"/100 * (PurchHdr."Amount"/(PurchHdr."Amount Including VAT" - PurchHdr."Amount")),0,'<Precision,2><Standard Format,1>'),'',CurrNode[1]);
                end
                else
                begin    
                    CuXML.AddElement(CurrNode[2],'AllowanceOrChargeTaxRate','0','',CurrNode[1]);
                    CuXML.AddElement(CurrNode[2],'AllowanceOrChargeTaxAmount','0','',CurrNode[1]);
                end;    
            end;
            PurchLine.Reset;
            PurchLine.Setrange("Document Type",PurchHdr."Document Type");
            PurchLine.setrange("Document No.",PurchHdr."No.");
            Purchline.Setrange(Type,PurchLine.type::Item);
            PurchLine.Setrange("No.",'FREIGHT');
            If Purchline.Findset then
            begin
                CuXML.FindNode(CurrNode[2],'//PurchaseOrderResponse/Header',CurrNode[1]);
                CuXML.AddElement(CurrNode[1],'AllowancesOrCharges','','',CurrNode[2]);
                CuXML.AddElement(CurrNode[2],'AllowancesOrCharge','CHARGE','',CurrNode[1]);
                CuXML.AddElement(CurrNode[2],'AllowanceOrChargeIdentifier','FC','',CurrNode[1]);
                CuXML.AddElement(CurrNode[2],'AllowanceOrChargeDescription','Freight Cost','',CurrNode[1]);
                CuXML.AddElement(CurrNode[2],'AllowanceOrChargeAmount',Format(PurchLine."Amount Including VAT",0,'<Precision,2><Standard Format,1>'),'',CurrNode[1]);
                CuXML.AddElement(CurrNode[2],'AllowanceOrChargePercentage','0','',CurrNode[1]);
                If PurchHdr."Amount" <> PurchHdr."Amount Including VAT" then
                begin
                CuXML.AddElement(CurrNode[2],'AllowanceOrChargeTaxRate',Format(PurchHdr."Amount"/(PurchHdr."Amount Including VAT" - PurchHdr."Amount"),0,'<Precision,2><Standard Format,1>'),'',CurrNode[1]);
                CuXML.AddElement(CurrNode[2],'AllowanceOrChargeTaxAmount',Format(PurchLine."Amount Including VAT" - PurchLine."Line Amount",0,'<Precision,2><Standard Format,1>'),'',CurrNode[3]);
                end
                else
                begin    
                    CuXML.AddElement(CurrNode[2],'AllowanceOrChargeTaxRate','0','',CurrNode[1]);
                    CuXML.AddElement(CurrNode[2],'AllowanceOrChargeTaxAmount','0','',CurrNode[1]);
                end; 
            end;
            Clear(LineNo);    
            CuXML.FindNode(CurrNode[1],'//PurchaseOrderResponse',CurrNode[2]);
            CuXML.AddElement(CurrNode[2],'LineItems','','',CurrNode[1]);
            Purchline.SetFilter("No.",'<>FREIGHT');
            If PurchLine.findset then
            repeat
                LineNo += 1;
                CuXML.AddElement(CurrNode[1],'LineItem','','',CurrNode[2]);
                CuXML.AddElement(CurrNode[2],'LineNumber',Format(PurchLine."Line No."),'',CurrNode[3]);
                Item.Get(PurchLine."No.");
                CuXML.AddElement(CurrNode[2],'GTIN',Item.GTIN,'',CurrNode[3]);
                CuXML.AddElement(CurrNode[2],'BuyerPartNumber',PurchLine."No.",'',CurrNode[3]);
                CuXML.AddElement(CurrNode[2],'VendorPartNumber',Purchline."Vendor Item No.",'',CurrNode[3]);
                If PurchLine."Description 2" <> '' then
                    CuXML.AddElement(CurrNode[2],'ProductDescription',PurchLine.Description + ' ' + PurchLine."Description 2",'',CurrNode[3])
                else
                    CuXML.AddElement(CurrNode[2],'ProductDescription',PurchLine.Description,'',CurrNode[3]);
                CuXML.AddElement(CurrNode[2],'OrderQty',Format(PurchLine.Quantity,0,'<Precision,2><Standard Format,0>'),'',CurrNode[3]);
                CuXML.AddElement(CurrNode[2],'OrderQtyUOM',PurchLine."Unit of Measure Code",'',CurrNode[3]);
                CuXML.AddElement(CurrNode[2],'PackSize',Format(PurchLine."Qty. per Unit of Measure",0,'<Precision,2><Standard Format,1>'),'',CurrNode[3]);
                CuXML.AddElement(CurrNode[2],'UnitPrice',Format(PurchLine."Direct Unit Cost",0,'<Precision,2><Standard Format,1>'),'',CurrNode[3]);
                CuXML.AddElement(CurrNode[2],'TaxRate',Format(PurchLine."VAT %",0,'<Precision,2><Standard Format,1>'),'',CurrNode[3]);
                If PurchLine."Line Discount %" > 0 then 
                begin
                    CuXML.AddElement(CurrNode[2],'AllowancesOrCharges','','',CurrNode[3]);
                    CuXML.AddElement(CurrNode[3],'AllowancesOrCharge','ALLOWANCE','',CurrNode[4]);
                    CuXML.AddElement(CurrNode[3],'AllowanceOrChargePercentage',Format(PurchLine."Line Discount %",0,'<Precision,2><Standard Format,1>'),'',CurrNode[4]);
                    CuXML.AddElement(CurrNode[3],'AllowanceOrChargeAmount',Format(PurchLine."Line Discount Amount"/Purchline.Quantity,0,'<Precision,2><Standard Format,1>'),'',CurrNode[4]);
                end;    
                CuXML.AddElement(CurrNode[2],'LineAmountExcGST',Format(PurchLine."Line Amount",0,'<Precision,2><Standard Format,1>'),'',CurrNode[3]);
                CuXML.AddElement(CurrNode[2],'LineAmountGST',Format(PurchLine."Amount Including VAT" - PurchLine."Line Amount",0,'<Precision,2><Standard Format,1>'),'',CurrNode[3]);
                CuXML.AddElement(CurrNode[2],'LineAmountIncGST',Format(PurchLine."Amount Including VAT",0,'<Precision,2><Standard Format,1>'),'',CurrNode[3]);
            until PurchLine.next = 0;
            CuXML.FindNode(CurrNode[2],'//PurchaseOrderResponse',CurrNode[1]);
            CuXML.AddElement(CurrNode[1],'Summary','','',CurrNode[2]);
            CuXML.AddElement(CurrNode[2],'NumberOfLines',Format(LineNo),'',CurrNode[1]);
            CuXML.AddElement(CurrNode[2],'OrderAmountExcGST',Format(PurchHdr.Amount,0,'<Precision,2><Standard Format,1>'),'',CurrNode[1]);
            CuXML.AddElement(CurrNode[2],'OrderAmountGST',Format(PurchHdr."Amount Including VAT" - PurchHdr.Amount,0,'<Precision,2><Standard Format,1>'),'',CurrNode[1]);
            CuXML.AddElement(CurrNode[2],'OrderAmountIncGST',Format(PurchHdr."Amount Including VAT",0,'<Precision,2><Standard Format,1>'),'',CurrNode[1]);
            XmlDoc.WriteTo(Payload);
            BlobTmp.CreateOutStream(Outstrm);
            Outstrm.WriteText(Payload);
            BlobTmp.CreateInStream(InStrm);
            //inStrm.ReadText(Payload);
            FileName := PurchHdr."No." + '.Resp'; 
            DownloadFromStream(Instrm,'ItemExport','','',FileName);
            ret := true;
            //            Clear(Jsobj);
            //Clear(parms);
            //Ret := EDI_Data(Paction::POST,request + PurchHdr."No." + '.Resp',Parms,Payload,Jsobj,true);
        end;
        exit(Ret);
    End;
   Procedure Build_EDI_Purchase_Ship(var PurchHdr:record "Purchase Header";FuncCode:Code[10]):Boolean;
    var
        PurchLine:record "Purchase Line";
        XmlDoc:XmlDocument;
        CurrNode:Array[4] of XmlNode;
        CuXML:Codeunit "XML DOM Management";
        LineNo:Integer;
        Ven:Record Vendor;
        Loc:Record Location;
        Item:record Item;
        Comm:Record "Purch. Comment Line";
        Comments:text;
        Jsobj:JsonObject;
        Parms:Dictionary of [text,text];
        Payload:Text;
        request:Label 'https://api.spscommerce.com/transactions/v2/';
        CompInfo:record "Company Information";
        Ret:Boolean;
        BlobTmp:COdeunit "Temp Blob";
        Outstrm:OutStream;
        inStrm:InStream;
        Filename:text;
    Begin
        //Get_Transaction_Documents();
        //Exit;
        Ret := Get_EDI_Access_Token();
        if Ret then
        begin
            CompInfo.get;
            XmlDocument.ReadFrom('<DespatchAdvice/>',XmlDoc);
            CurrNode[1] := XmlDoc.AsXmlNode();
            CuXML.FindNode(CurrNode[1],'//DespatchAdvice',CurrNode[2]);
            CuXML.AddElement(CurrNode[2],'Header','','',CurrNode[1]);
            CuXML.AddElement(CurrNode[1],'DespatchAdviceNumber',PurchHdr."No.",'',CurrNode[2]);
            CuXML.AddElement(CurrNode[1],'DespatchAdviceDate',Format(PurchHdr."Order Date",0,'<Day,2>-<Month,2>-<Year4>'),'',CurrNode[2]);
            CuXML.AddElement(CurrNode[1],'ShipDate',Format(PurchHdr."Order Date",0,'<Day,2>-<Month,2>-<Year4>'),'',CurrNode[2]);
            CuXML.AddElement(CurrNode[1],'EstimatedDeliveryDate',Format(PurchHdr."Requested Receipt Date",0,'<Day,2>-<Month,2>-<year4>'),'',CurrNode[2]);
            CuXML.AddElement(CurrNode[1],'EstimatedDeliveryTime',Format(PurchHdr."Requested Receipt Time",0,'<Hours24,2>:<Minutes,2>:<Seconds,2>'),'',CurrNode[2]);
            CuXML.AddElement(CurrNode[1],'PurchaseOrderNumber',PurchHdr."No.",'',CurrNode[2]);
            CuXML.AddElement(CurrNode[1],'ConsignmentNoteNumber','ABCD','',CurrNode[2]);
            CuXML.AddElement(CurrNode[1],'BookingReferenceNumber','1234','',CurrNode[2]);
            CuXML.AddElement(CurrNode[1],'ShipmentTrackingNumber','QWER','',CurrNode[2]);
            CuXML.AddElement(CurrNode[1],'ShipmentTrackingNumber','','',CurrNode[2]);
            CuXML.AddElement(CurrNode[1],'ShipmentTrackingURL','','',CurrNode[2]);
            CuXML.AddElement(CurrNode[1],'CarrierName','','',CurrNode[2]);
            CuXML.AddElement(CurrNode[1],'SplitOrCompleteShipment','','',CurrNode[2]);
            CuXML.AddElement(CurrNode[1],'ShipmentPalletCount','','',CurrNode[2]);
            CuXML.AddElement(CurrNode[1],'ShipmentCartonCount','','',CurrNode[2]);
            CuXML.AddElement(CurrNode[1],'NameAddressParty','','',CurrNode[2]);
            CuXML.AddElement(CurrNode[2],'PartyCodeQualifier','BUYER','',CurrNode[1]);
            CuXML.AddElement(CurrNode[2],'PartyIdentifier','PETCULTURE','',CurrNode[1]);
            CuXML.FindNode(CurrNode[2],'//DespatchAdvice/Header',CurrNode[1]);
            CuXML.AddElement(CurrNode[1],'NameAddressParty','','',CurrNode[2]);
            CuXML.AddElement(CurrNode[2],'PartyCodeQualifier','SUPPLIER','',CurrNode[1]);
            CuXML.AddElement(CurrNode[2],'PartyIdentifier',PurchHdr."Buy-from Vendor No.",'',CurrNode[1]);
            CuXML.FindNode(CurrNode[2],'//DespatchAdvice/Header',CurrNode[1]);
            CuXML.AddElement(CurrNode[1],'NameAddressParty','','',CurrNode[2]);
            CuXML.AddElement(CurrNode[2],'PartyCodeQualifier','SHIPTO','',CurrNode[1]);
            Loc.Get(PurchHdr."Location Code");
            CuXML.AddElement(CurrNode[2],'PartyIdentifier','DC'+ Loc.Code,'',CurrNode[1]);
            CuXML.FindNode(CurrNode[2],'//DespatchAdvice/Header',CurrNode[1]);
            CuXML.AddElement(CurrNode[1],'Packages','','',CurrNode[2]);
            CuXML.AddElement(CurrNode[2],'Package','','',CurrNode[1]);
            CuXML.AddElement(CurrNode[1],'PackageLevelCode','PALLET','',CurrNode[2]);
            CuXML.AddElement(CurrNode[1],'CartonCount','10','',CurrNode[2]);
            CuXML.AddElement(CurrNode[1],'SSCC','','',CurrNode[2]);
            CuXML.AddElement(CurrNode[1],'NumberOfUnitsPerLayer','','',CurrNode[2]);
            CuXML.AddElement(CurrNode[1],'NumberOfLayersOnPallet','','',CurrNode[2]);
            CuXML.AddElement(CurrNode[1],'UnitNetWeight','','',CurrNode[2]);
            CuXML.FindNode(CurrNode[1],'//DespatchAdvice',CurrNode[2]);
            Clear(LineNo);    
            CuXML.AddElement(CurrNode[2],'LineItems','','',CurrNode[1]);
            PurchLine.Reset;
            PurchLine.Setrange("Document Type",PurchHdr."Document Type");
            PurchLine.setrange("Document No.",PurchHdr."No.");
            Purchline.Setrange(Type,PurchLine.type::Item);
            Purchline.SetFilter("No.",'<>FREIGHT');
            If PurchLine.findset then
            repeat
                LineNo += 1;
                CuXML.AddElement(CurrNode[1],'LineItem','','',CurrNode[2]);
                CuXML.AddElement(CurrNode[2],'LineNumber',Format(PurchLine."Line No."),'',CurrNode[3]);
                Item.Get(PurchLine."No.");
                CuXML.AddElement(CurrNode[2],'GTIN',Item.GTIN,'',CurrNode[3]);
                CuXML.AddElement(CurrNode[2],'BuyerPartNumber',PurchLine."No.",'',CurrNode[3]);
                CuXML.AddElement(CurrNode[2],'VendorPartNumber',Purchline."Vendor Item No.",'',CurrNode[3]);
                If PurchLine."Description 2" <> '' then
                    CuXML.AddElement(CurrNode[2],'ProductDescription',PurchLine.Description + ' ' + PurchLine."Description 2",'',CurrNode[3])
                else
                    CuXML.AddElement(CurrNode[2],'ProductDescription',PurchLine.Description,'',CurrNode[3]);
                CuXML.AddElement(CurrNode[2],'ShipQty',Format(PurchLine.Quantity,0,'<Precision,2><Standard Format,0>'),'',CurrNode[3]);
                CuXML.AddElement(CurrNode[2],'ShipQtyUOM',PurchLine."Unit of Measure Code",'',CurrNode[3]);
                CuXML.AddElement(CurrNode[2],'VarianceQty','0','',CurrNode[3]);
                CuXML.AddElement(CurrNode[2],'VarianceQtyCode','','',CurrNode[3]);
                CuXML.AddElement(CurrNode[2],'BatchNumber','','',CurrNode[3]);
                CuXML.AddElement(CurrNode[2],'SerialNumber','','',CurrNode[3]);
                CuXML.AddElement(CurrNode[2],'BestBeforeDate','','',CurrNode[3]);
                CuXML.AddElement(CurrNode[2],'ExpiryDate','','',CurrNode[3]);
            until PurchLine.next = 0;
            CuXML.FindNode(CurrNode[2],'//DespatchAdvice',CurrNode[1]);
            CuXML.AddElement(CurrNode[1],'NumberOfLines',Format(LineNo),'',CurrNode[2]);
             XmlDoc.WriteTo(Payload);
            BlobTmp.CreateOutStream(Outstrm);
            Outstrm.WriteText(Payload);
            BlobTmp.CreateInStream(InStrm);
            //inStrm.ReadText(Payload);
            FileName := PurchHdr."No." + '.Desp'; 
            DownloadFromStream(Instrm,'ItemExport','','',FileName);
            ret := true;
            //            Clear(Jsobj);
            //Clear(parms);
            //Ret := EDI_Data(Paction::POST,request + PurchHdr."No." + '.Resp',Parms,Payload,Jsobj,true);
        end;
        exit(Ret);
    End;
Procedure Build_EDI_Invoice(var PurchHdr:record "Purchase Header";FuncCode:Code[10]):Boolean;
    var
        PurchLine:record "Purchase Line";
        XmlDoc:XmlDocument;
        CurrNode:Array[4] of XmlNode;
        CuXML:Codeunit "XML DOM Management";
        LineNo:Integer;
        Ven:Record Vendor;
        Loc:Record Location;
        Item:record Item;
        Comm:Record "Purch. Comment Line";
        Comments:text;
        Jsobj:JsonObject;
        Parms:Dictionary of [text,text];
        Payload:Text;
        request:Label 'https://api.spscommerce.com/transactions/v2/';
        CompInfo:record "Company Information";
        Ret:Boolean;
        BlobTmp:COdeunit "Temp Blob";
        Outstrm:OutStream;
        inStrm:InStream;
        Filename:text;
    Begin
        //Get_Transaction_Documents();
        //Exit;
        Ret := Get_EDI_Access_Token();
        if Ret then
        begin
            CompInfo.get;
            XmlDocument.ReadFrom('<Invoice/>',XmlDoc);
            CurrNode[1] := XmlDoc.AsXmlNode();
            CuXML.FindNode(CurrNode[1],'//Invoice',CurrNode[2]);
            CuXML.AddElement(CurrNode[2],'Header','','',CurrNode[1]);
            CuXML.AddElement(CurrNode[1],'InvoiceNumber',PurchHdr."No.",'',CurrNode[2]);
            CuXML.AddElement(CurrNode[1],'InvoiceName',PurchHdr."No.",'',CurrNode[2]);
            CuXML.AddElement(CurrNode[1],'MessageFunctionCode',FuncCode,'',CurrNode[2]);
            CuXML.AddElement(CurrNode[1],'InvoiceDate',Format(PurchHdr."Order Date",0,'<Day,2>-<Month,2>-<Year4>'),'',CurrNode[2]);
            CuXML.AddElement(CurrNode[1],'PurchaseOrderNumber',PurchHdr."No.",'',CurrNode[2]);
            CuXML.AddElement(CurrNode[1],'DespatchAdviceNumber','','',CurrNode[2]);
            CuXML.AddElement(CurrNode[1],'ConsignmentNoteNumber','','',CurrNode[2]);
            CuXML.AddElement(CurrNode[1],'BookingReferenceNumber','','',CurrNode[2]);
            Clear(Comments);
            Comm.reset;
            Comm.Setrange("Document Type",PurchHdr."Document Type");
            Comm.Setrange("No.",PurchHdr."No.");
            If Comm.findset then  
            repeat
                Comments += Comm.Comment + ' ';
            until Comm.Next = 0;                
            CuXML.AddElement(CurrNode[1],'Notes',Comments,'',CurrNode[2]);
            CuXML.AddElement(CurrNode[1],'NameAddressParty','','',CurrNode[2]);
            CuXML.AddElement(CurrNode[2],'PartyCodeQualifier','BUYER','',CurrNode[1]);
            CuXML.AddElement(CurrNode[2],'PartyIdentifier','PETCULTURE','',CurrNode[1]);
            If Compinfo."Name 2" <> '' then
                CuXML.AddElement(CurrNode[2],'PartyName',CompInfo.Name + ' ' + Compinfo."Name 2",'',CurrNode[1])
            else
                CuXML.AddElement(CurrNode[2],'PartyName',CompInfo.Name,'',CurrNode[1]);
            If CompInfo."Address 2" <> '' then     
                CuXML.AddElement(CurrNode[2],'Address',CompInfo.Address + ' ' + CompInfo."Address 2",'',CurrNode[1])
            else
                CuXML.AddElement(CurrNode[2],'Address',CompInfo.Address,'',CurrNode[1]);
            CuXML.AddElement(CurrNode[2],'City',CompInfo.City,'',CurrNode[1]);
            CuXML.AddElement(CurrNode[2],'State',compinfo.County,'',CurrNode[1]);
            CuXML.AddElement(CurrNode[2],'Postcode',compinfo."Post Code",'',CurrNode[1]);
            If CompInfo."Country/Region Code" = '' then
                CuXML.AddElement(CurrNode[2],'Country','AU','',CurrNode[1])
            else
                CuXML.AddElement(CurrNode[2],'Country',CompInfo."Country/Region Code",'',CurrNode[1]);
            CuXML.AddElement(CurrNode[2],'GSTNumber',CompInfo."Contact Person",'',CurrNode[1]);
            CuXML.AddElement(CurrNode[2],'ContactName',CompInfo."Contact Person",'',CurrNode[1]);
            CuXML.AddElement(CurrNode[2],'Phone',Compinfo."Phone No.",'',CurrNode[1]);
            CuXML.AddElement(CurrNode[2],'Email',Compinfo."E-Mail",'',CurrNode[1]);
            CuXML.FindNode(CurrNode[2],'//Invoice/Header',CurrNode[1]);
            CuXML.AddElement(CurrNode[1],'NameAddressParty','','',CurrNode[2]);
            CuXML.AddElement(CurrNode[2],'PartyCodeQualifier','SUPPLIER','',CurrNode[1]);
            CuXML.AddElement(CurrNode[2],'PartyIdentifier',PurchHdr."Buy-from Vendor No.",'',CurrNode[1]);
            If PurchHdr."Buy-from Vendor Name 2" <> '' then
                CuXML.AddElement(CurrNode[2],'PartyName',PurchHdr."Buy-from Vendor Name" + ' ' + PurchHdr."Buy-from Vendor Name 2",'',CurrNode[1])
            else
                 CuXML.AddElement(CurrNode[2],'PartyName',PurchHdr."Buy-from Vendor Name",'',CurrNode[1]);
            if  PurchHdr."Buy-from Address 2" <> '' then   
                CuXML.AddElement(CurrNode[2],'Address',PurchHdr."Buy-from Address" + ' ' + PurchHdr."Buy-from Address 2",'',CurrNode[1])
            else
                CuXML.AddElement(CurrNode[2],'Address',PurchHdr."Buy-from Address",'',CurrNode[1]);
            CuXML.AddElement(CurrNode[2],'City',PurchHdr."Buy-from City",'',CurrNode[1]);
            CuXML.AddElement(CurrNode[2],'State',PurchHdr."Buy-from County",'',CurrNode[1]);
            CuXML.AddElement(CurrNode[2],'Postcode',PurchHdr."Buy-from Post Code",'',CurrNode[1]);
            if PurchHdr."Buy-from Country/Region Code" = '' then
                CuXML.AddElement(CurrNode[2],'Country','AU','',CurrNode[1])
            else
                CuXML.AddElement(CurrNode[2],'Country',PurchHdr."Buy-from Country/Region Code",'',CurrNode[1]);
            CuXML.AddElement(CurrNode[2],'GSTNumber',CompInfo."Contact Person",'',CurrNode[1]);
            CuXML.AddElement(CurrNode[2],'ContactName',PurchHdr."Buy-from Contact",'',CurrNode[1]);
            Ven.Get(PurchHdr."Buy-from Vendor No.");
            CuXML.AddElement(CurrNode[2],'Phone',Ven."Phone No.",'',CurrNode[1]);
            CuXML.AddElement(CurrNode[2],'Email',Ven."E-Mail",'',CurrNode[1]);
            CuXML.FindNode(CurrNode[2],'//Invoice/Header',CurrNode[1]);
            CuXML.AddElement(CurrNode[1],'NameAddressParty','','',CurrNode[2]);
            CuXML.AddElement(CurrNode[2],'PartyCodeQualifier','SHIPTO','',CurrNode[1]);
            Loc.Get(PurchHdr."Location Code");
            CuXML.AddElement(CurrNode[2],'PartyIdentifier','DC'+ Loc.Code,'',CurrNode[1]);
            If Loc."Name 2" <> '' then
                CuXML.AddElement(CurrNode[2],'PartyName',Loc.Name + ' ' + Loc."Name 2",'',CurrNode[1])
            else
                CuXML.AddElement(CurrNode[2],'PartyName',Loc.Name,'',CurrNode[1]);
            if Loc."Address 2" <> '' then    
                CuXML.AddElement(CurrNode[2],'Address',Loc.Address + ' ' + Loc."Address 2",'',CurrNode[1])
            else
                CuXML.AddElement(CurrNode[2],'Address',Loc.Address,'',CurrNode[1]);
            CuXML.AddElement(CurrNode[2],'City',Loc.City,'',CurrNode[1]);
            CuXML.AddElement(CurrNode[2],'State',Loc.County,'',CurrNode[1]);
            CuXML.AddElement(CurrNode[2],'Postcode',Loc."Post Code",'',CurrNode[1]);
            If Loc."Country/Region Code" = '' then
                CuXML.AddElement(CurrNode[2],'Country','AU','',CurrNode[1])
            else
            CuXML.AddElement(CurrNode[2],'Country',Loc."Country/Region Code",'',CurrNode[1]);
            CuXML.AddElement(CurrNode[2],'GSTNumber',CompInfo."Contact Person",'',CurrNode[1]);
            CuXML.AddElement(CurrNode[2],'ContactName',loc.Contact,'',CurrNode[1]);
            CuXML.AddElement(CurrNode[2],'Phone',Loc."Phone No.",'',CurrNode[1]);
            CuXML.AddElement(CurrNode[2],'Email',Loc."E-Mail",'',CurrNode[1]);
            CuXML.FindNode(CurrNode[1],'//Invoice/Header',CurrNode[2]);
            If PurchHdr."Currency Code" = '' then
                CuXML.AddElement(CurrNode[2],'Currency','AUD','',CurrNode[1])
            else
                CuXML.AddElement(CurrNode[2],'Currency',PurchHdr."Currency Code",'',CurrNode[1]);
            CuXML.FindNode(CurrNode[2],'//Invoice/Header',CurrNode[1]);
            CuXML.AddElement(CurrNode[1],'PaymentTerms','','',CurrNode[2]);
            CuXML.AddElement(CurrNode[2],'TermsDescription','','',CurrNode[1]);
            CuXML.AddElement(CurrNode[2],'TermsDueDate','','',CurrNode[1]);
            CuXML.AddElement(CurrNode[2],'TermsDiscountPercentage','','',CurrNode[1]);
            CuXML.AddElement(CurrNode[2],'TermsDiscountAmount','','',CurrNode[1]);
            PurchHdr.CalcFields(Amount,"Amount Including VAT","Invoice Discount Amount");    
            If PurchHdr."Invoice Discount Amount" > 0 then
            begin
                CuXML.FindNode(CurrNode[2],'//Invoice/Header',CurrNode[1]);
                CuXML.AddElement(CurrNode[1],'AllowancesOrCharges','','',CurrNode[2]);
                CuXML.AddElement(CurrNode[2],'AllowancesOrCharge','ALLOWANCE','',CurrNode[1]);
                CuXML.AddElement(CurrNode[2],'AllowanceOrChargeIdentifier','ORDDISC','',CurrNode[1]);
                CuXML.AddElement(CurrNode[2],'AllowanceOrChargeDescription','Order Discount','',CurrNode[1]);
                CuXML.AddElement(CurrNode[2],'AllowanceOrChargeAmount',Format(PurchHdr."Invoice Discount Amount",0,'<Precision,2><Standard Format,1>'),'',CurrNode[1]);
                CuXML.AddElement(CurrNode[2],'AllowanceOrChargePercentage',Format(PurchHdr."Invoice Discount Amount" * 100/(PurchHdr."Amount" + PurchHdr."Invoice Discount Amount"),0,'<Precision,2><Standard Format,1>'),'',CurrNode[1]);
                //See if tax applies or not   
                If PurchHdr."Amount" <> PurchHdr."Amount Including VAT" then
                begin
                CuXML.AddElement(CurrNode[2],'AllowanceOrChargeTaxRate',Format(PurchHdr."Amount"/(PurchHdr."Amount Including VAT" - PurchHdr."Amount"),0,'<Precision,2><Standard Format,1>'),'',CurrNode[1]);
                CuXML.AddElement(CurrNode[2],'AllowanceOrChargeTaxAmount',Format(PurchHdr."Invoice Discount Amount"/100 * (PurchHdr."Amount"/(PurchHdr."Amount Including VAT" - PurchHdr."Amount")),0,'<Precision,2><Standard Format,1>'),'',CurrNode[1]);
                end
                else
                begin    
                    CuXML.AddElement(CurrNode[2],'AllowanceOrChargeTaxRate','0','',CurrNode[1]);
                    CuXML.AddElement(CurrNode[2],'AllowanceOrChargeTaxAmount','0','',CurrNode[1]);
                end;    
            end;
            PurchLine.Reset;
            PurchLine.Setrange("Document Type",PurchHdr."Document Type");
            PurchLine.setrange("Document No.",PurchHdr."No.");
            Purchline.Setrange(Type,PurchLine.type::Item);
            PurchLine.Setrange("No.",'FREIGHT');
            If Purchline.Findset then
            begin
                CuXML.FindNode(CurrNode[2],'//Invoice/Header',CurrNode[1]);
                CuXML.AddElement(CurrNode[1],'AllowancesOrCharges','','',CurrNode[2]);
                CuXML.AddElement(CurrNode[2],'AllowancesOrCharge','CHARGE','',CurrNode[1]);
                CuXML.AddElement(CurrNode[2],'AllowanceOrChargeIdentifier','FC','',CurrNode[1]);
                CuXML.AddElement(CurrNode[2],'AllowanceOrChargeDescription','Freight Cost','',CurrNode[1]);
                CuXML.AddElement(CurrNode[2],'AllowanceOrChargeAmount',Format(PurchLine."Amount Including VAT",0,'<Precision,2><Standard Format,1>'),'',CurrNode[1]);
                CuXML.AddElement(CurrNode[2],'AllowanceOrChargePercentage','0','',CurrNode[1]);
                If PurchHdr."Amount" <> PurchHdr."Amount Including VAT" then
                begin
                CuXML.AddElement(CurrNode[2],'AllowanceOrChargeTaxRate',Format(PurchHdr."Amount"/(PurchHdr."Amount Including VAT" - PurchHdr."Amount"),0,'<Precision,2><Standard Format,1>'),'',CurrNode[1]);
                CuXML.AddElement(CurrNode[2],'AllowanceOrChargeTaxAmount',Format(PurchLine."Amount Including VAT" - PurchLine."Line Amount",0,'<Precision,2><Standard Format,1>'),'',CurrNode[3]);
                end
                else
                begin    
                    CuXML.AddElement(CurrNode[2],'AllowanceOrChargeTaxRate','0','',CurrNode[1]);
                    CuXML.AddElement(CurrNode[2],'AllowanceOrChargeTaxAmount','0','',CurrNode[1]);
                end; 
            end;
            Clear(LineNo);    
            CuXML.FindNode(CurrNode[1],'//Invoice',CurrNode[2]);
            CuXML.AddElement(CurrNode[2],'LineItems','','',CurrNode[1]);
            Purchline.SetFilter("No.",'<>FREIGHT');
            If PurchLine.findset then
            repeat
                LineNo += 1;
                CuXML.AddElement(CurrNode[1],'LineItem','','',CurrNode[2]);
                CuXML.AddElement(CurrNode[2],'LineNumber',Format(PurchLine."Line No."),'',CurrNode[3]);
                Item.Get(PurchLine."No.");
                CuXML.AddElement(CurrNode[2],'GTIN',Item.GTIN,'',CurrNode[3]);
                CuXML.AddElement(CurrNode[2],'BuyerPartNumber',PurchLine."No.",'',CurrNode[3]);
                CuXML.AddElement(CurrNode[2],'VendorPartNumber',Purchline."Vendor Item No.",'',CurrNode[3]);
                If PurchLine."Description 2" <> '' then
                    CuXML.AddElement(CurrNode[2],'ProductDescription',PurchLine.Description + ' ' + PurchLine."Description 2",'',CurrNode[3])
                else
                    CuXML.AddElement(CurrNode[2],'ProductDescription',PurchLine.Description,'',CurrNode[3]);
                CuXML.AddElement(CurrNode[2],'InvoiceQty',Format(PurchLine.Quantity,0,'<Precision,2><Standard Format,0>'),'',CurrNode[3]);
                CuXML.AddElement(CurrNode[2],'InvoiceQtyUOM',PurchLine."Unit of Measure Code",'',CurrNode[3]);
                CuXML.AddElement(CurrNode[2],'PackSize',Format(PurchLine."Qty. per Unit of Measure",0,'<Precision,2><Standard Format,1>'),'',CurrNode[3]);
                CuXML.AddElement(CurrNode[2],'UnitPrice',Format(PurchLine."Direct Unit Cost",0,'<Precision,2><Standard Format,1>'),'',CurrNode[3]);
                CuXML.AddElement(CurrNode[2],'TaxRate',Format(PurchLine."VAT %",0,'<Precision,2><Standard Format,1>'),'',CurrNode[3]);
                If PurchLine."Line Discount %" > 0 then 
                begin
                    CuXML.AddElement(CurrNode[2],'AllowancesOrCharges','','',CurrNode[3]);
                    CuXML.AddElement(CurrNode[3],'AllowancesOrCharge','ALLOWANCE','',CurrNode[4]);
                    CuXML.AddElement(CurrNode[3],'AllowanceOrChargePercentage',Format(PurchLine."Line Discount %",0,'<Precision,2><Standard Format,1>'),'',CurrNode[4]);
                    CuXML.AddElement(CurrNode[3],'AllowanceOrChargeAmount',Format(PurchLine."Line Discount Amount"/Purchline.Quantity,0,'<Precision,2><Standard Format,1>'),'',CurrNode[4]);
                end;    
                CuXML.AddElement(CurrNode[2],'LineAmountExcGST',Format(PurchLine."Line Amount",0,'<Precision,2><Standard Format,1>'),'',CurrNode[3]);
                CuXML.AddElement(CurrNode[2],'LineAmountGST',Format(PurchLine."Amount Including VAT" - PurchLine."Line Amount",0,'<Precision,2><Standard Format,1>'),'',CurrNode[3]);
                CuXML.AddElement(CurrNode[2],'LineAmountIncGST',Format(PurchLine."Amount Including VAT",0,'<Precision,2><Standard Format,1>'),'',CurrNode[3]);
            until PurchLine.next = 0;
            CuXML.FindNode(CurrNode[2],'//PurchaseOrderResponse',CurrNode[1]);
            CuXML.AddElement(CurrNode[1],'Summary','','',CurrNode[2]);
            CuXML.AddElement(CurrNode[2],'NumberOfLines',Format(LineNo),'',CurrNode[1]);
            CuXML.AddElement(CurrNode[2],'InvoiceAmountExcGST',Format(PurchHdr.Amount,0,'<Precision,2><Standard Format,1>'),'',CurrNode[1]);
            CuXML.AddElement(CurrNode[2],'InvoiceAmountGST',Format(PurchHdr."Amount Including VAT" - PurchHdr.Amount,0,'<Precision,2><Standard Format,1>'),'',CurrNode[1]);
            CuXML.AddElement(CurrNode[2],'InvoiceAmountIncGST',Format(PurchHdr."Amount Including VAT",0,'<Precision,2><Standard Format,1>'),'',CurrNode[1]);
            XmlDoc.WriteTo(Payload);
            BlobTmp.CreateOutStream(Outstrm);
            Outstrm.WriteText(Payload);
            BlobTmp.CreateInStream(InStrm);
            //inStrm.ReadText(Payload);
            FileName := PurchHdr."No." + '.Inv'; 
            DownloadFromStream(Instrm,'ItemExport','','',FileName);
            ret := true;
            //            Clear(Jsobj);
            //Clear(parms);
            //Ret := EDI_Data(Paction::POST,request + PurchHdr."No." + '.Resp',Parms,Payload,Jsobj,true);
        end;
        exit(Ret);
    End;
    procedure get_files()
    var
        BlobTmp:COdeunit "Temp Blob";
        Outstrm:OutStream;
        inStrm:InStream;
        Filename:text;
        XmlDoc:XmlDocument;
        request:Label 'https://api.spscommerce.com/transactions/v2/';
        Jsobj:JsonObject;
        Parms:Dictionary of [text,text];
        Payload:Text;
    begin
        If Get_EDI_Access_Token() then
        begin
            if File.UploadIntoStream('Item Import','','',FileName,Instrm) then
            Begin
                inStrm.Read(Payload);
                //XmlDoc.WriteTo(Payload);
                EDI_Data(Paction::POST,request + Filename,Parms,Payload,Jsobj,true);
            end;                  
        end;
    end;
*/



}