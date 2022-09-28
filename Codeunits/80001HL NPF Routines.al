codeunit 80001 "HL NPF Routines"
{   var
        Paction:Option GET,POST,DELETE,PATCH,PUT;
    local procedure CallRESTWebService(var RestRec : Record "HL RESTWebServiceArguments";Parms:Dictionary of [text,text];Payload:text) : Boolean
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
        if RestRec.Accept <> '' then Headers.Add('Accept', RestRec."Accept");
        If Strlen(Payload) > 0 then
        begin
            // get the payload data now
            Content.WriteFrom(Payload);
            if Not Content.GetHeaders(Headers) Then Exit(false);
            Headers.Clear();
            Headers.Add('Content-Type','application/xml');
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
    local procedure NPF_Data(Method:option;Request:text;Parms:Dictionary of [text,text];Payload:Text;var Data:XmlDocument): boolean
    var
        Setup:Record "Sales & Receivables Setup";
        Ws:Record "HL RestWebServiceArguments";
    begin
        Setup.get;
        Ws.init;
        If Setup."Use NPF Dev Access" then
            Ws.URL := Setup."Dev NPF Connnect Url"
        else    
            Ws.URL := Setup."NPF Connnect Url";
        Ws.Url += Request;
        ws.Accept := 'text/xml';
        Ws.RestMethod := Method;
        if CallRESTWebService(ws,Parms,Payload) then
            exit(ws.GetXmlData(Data))
        else
            exit(false);
    end; 
    local procedure Build_XML_Request(RootName:text):XmlDocument
    var
        XmlDoc:XmlDocument;
        CurrNode:Array[2] of XmlNode;
        CuXML:Codeunit "XML DOM Management";
        Setup:Record "Sales & Receivables Setup";
        Logins:Array[3] of text;
    begin
        Setup.get;
        If Setup."Use NPF Dev Access" then
        begin
            Logins[1] := Setup."Dev NPF UserName";
            Logins[2] := setup."Dev NPF Password";
            logins[3] := Setup."Dev NPF Client Code";
        end
        else
        begin
            Logins[1] := Setup."NPF UserName";
            Logins[2] := setup."NPF Password";
            logins[3] := Setup."NPF Client Code";
        end;
        XmlDoc := XmlDocument.Create();
        CuXML.AddRootElement(XmlDoc,RootName,CurrNode[2]);
        CuXML.AddElement(CurrNode[2],'Login','','',CurrNode[1]);
        CuXML.AddElement(CurrNode[1],'Username',Logins[1],'',CurrNode[2]);
        CuXML.AddElement(CurrNode[1],'Password',Logins[2],'',CurrNode[2]);
        CuXML.AddElement(CurrNode[1],'ClientCode',logins[3],'',CurrNode[2]);
        Exit(XmlDoc);    
    end;    
    Procedure Get_Order_Shipment(OrderNo:Text;var Resp:XmlDocument):Boolean
    var
        CurrNode:Array[2] of XmlNode;
        CuXML:Codeunit "XML DOM Management";
        Payload:text;
        Req: Label '/npforderstatus.asmx/importorderstatus';
        Parms:Dictionary of [text,text];
    begin
        clear(Resp);
        Clear(Parms);
        Resp := Build_XML_Request('orderlist');
        CurrNode[1] := Resp.AsXmlNode();
        if CuXML.FindNode(CurrNode[1],'//orderlist',CurrNode[2]) then
        begin
            CuXML.AddElement(CurrNode[2],'order','','',CurrNode[1]);
            CuXML.AddElement(CurrNode[1],'SalesOrderNo',OrderNo,'',CurrNode[2]);
            Resp.WriteTo(Payload);
            Payload := Payload.Replace('utf-16','utf-8');
            exit(NPF_Data(Paction::POST,Req,Parms,Payload,Resp));
        end;
        Exit(False);    
    end; 
    Procedure Get_SOH(ReqType:Option SOH,AVSOH;ProductCode:Code[20];var Resp:XmlDocument):Boolean
    var
        CurrNode:Array[2] of XmlNode;
        CuXML:Codeunit "XML DOM Management";
        Payload:text;
        Req1: Label '/FMSohAPI.asmx/StockOnHand';
        Req2: Label '/FMSohAPI.asmx/StockAvailable';
        Req:Text;
        Parms:Dictionary of [text,text];
    begin
        Clear(Resp);
        Clear(Parms);
        Resp := Build_XML_Request('ProductList');
        CurrNode[1] := Resp.AsXmlNode();
        if CuXML.FindNode(CurrNode[1],'//ProductList',CurrNode[2]) then
        begin
            CuXML.AddElement(CurrNode[2],'Product','','',CurrNode[1]);
            CuXML.AddElement(CurrNode[1],'ProductCode',ProductCode,'',CurrNode[2]);
            Resp.WriteTo(Payload);
            Payload := Payload.Replace('utf-16','utf-8');
            If ReqType = ReqType::SOH then
                Req := Req1
            else
                req := Req2;
            exit(NPF_Data(Paction::POST,Req,Parms,Payload,Resp));
        end;
        exit(false);    
    end;
    Procedure Get_Inventory_Transactions(PageNo:Integer;TransactionID:integer;var Resp:XmlDocument):Boolean
    var
        CurrNode:Array[2] of XmlNode;
        CuXML:Codeunit "XML DOM Management";
        Payload:text;
        Req: Label '/FMSOHAPI.asmx/Inventory_Transaction';
        Parms:Dictionary of [text,text];
    begin
        Clear(Resp);
        Clear(Parms);
        Resp := Build_XML_Request('Transactions');
        CurrNode[1] := Resp.AsXmlNode();
        if CuXML.FindNode(CurrNode[1],'//Transactions',CurrNode[2]) then
        Begin
            CuXML.AddElement(CurrNode[2],'Transaction','','',CurrNode[1]);
            CuXML.AddElement(CurrNode[1],'PageNo',Format(PageNo),'',CurrNode[2]);
            CuXML.AddElement(CurrNode[1],'TransactionId',Format(TransactionID),'',CurrNode[2]);
            Resp.WriteTo(Payload);
            Payload := Payload.Replace('utf-16','utf-8');
            exit(NPF_Data(Paction::POST,Req,Parms,Payload,Resp));
        end;
        exit(false);    
    end;

    Local Procedure Get_ASN_Status(PONo:Code[20];var Resp:XmlDocument):Boolean
    var
        CurrNode:Array[2] of XmlNode;
        CuXML:Codeunit "XML DOM Management";
        Payload:text;
        Req: Label '/FMInboundAPI.asmx/InboundStatus';
        Parms:Dictionary of [text,text];
    begin
        Clear(Resp);
        Resp := Build_XML_Request('InboundReceiptList');
        CurrNode[1] := Resp.AsXmlNode();
        if CuXML.FindNode(CurrNode[1],'//InboundReceiptList',CurrNode[2]) then
        begin
            CuXML.AddElement(CurrNode[2],'InboundReceipt','','',CurrNode[1]);
            CuXML.AddElement(CurrNode[1],'PONo',PONo,'',CurrNode[2]);
            Resp.WriteTo(Payload);
            Payload := Payload.Replace('utf-16','utf-8');
            Clear(Parms);
            exit(NPF_Data(Paction::POST,Req,Parms,Payload,Resp));
        end;
        exit(false);    
    end;     
     // Create NPF ASN for passed PO information
    local procedure Return_Numeric(tstval:text):text
    var
        i:integer;
        ValTxt:Text;
    begin
        Clear(ValTxt);
        For i := 1 to StrLen(TstVal) do
            If (TsTval[i] >= '0') AND (Tstval[i] <= '9') then
                ValTxt += Tstval[i];

        exit(ValTxt);
    end;
    local procedure Ascii_Parser(val:text):Text
    var
        i:integer;
        j:integer;
        RetVal:text;
    begin
        Clear(retVal);    
        for i:= 1 to strlen(val) do
        begin
            For j:= 32 to 127 do
                if Val[i] = j then
                    RetVal += Val[i]
        end;
        exit(retval);
    end;        
    procedure Create_Update_ASN(var PurchHdr:Record "Purchase Header"):Boolean
    var
        PurchLine:Array[2] of record "Purchase Line";
        PayLoad:text;
        Parms:Dictionary of [text,text];
        Loc:record Location;
        Flg:Boolean;
        ItemUnit:Record "Item Unit of Measure";
        Setup:Record "Sales & Receivables Setup";
        Logins:Array[3] of text;
        XmlDoc:XmlDocument;
        CurrNode:Array[3] of XmlNode;
        CuXML:Codeunit "XML DOM Management";
        Ven:record Vendor;
        item:record Item;
        Iteunit:Record "Item Unit of Measure";
        Req:Label '/FMInboundAPI_V2.asmx/Import_Inbound_V2';
        testDate:date;
        i:Integer;
    begin
        Clear(Parms);
        Flg := false;
        if Not Loc.get(PurchHdr."Location Code") then
        begin
            If GuiAllowed Then Message('Location code is not defined');
            Exit(flg);
        end;
        If Loc."NPF Warehouse ID" = 0 then
        begin
            If GuiAllowed Then Message('NPF Warehouse ID is invalid correct and retry');
            Exit(flg);
        end;
        PurchLine[1].reset;
        PurchLine[1].SetCurrentKey("Line No.");
        PurchLine[1].Setrange("Document Type",PurchLine[1]."Document Type"::Order);
        PurchLine[1].Setrange("Document No.",PurchHdr."No.");
        PurchLine[1].Setrange(Type,PurchLine[1].Type::Item);
        If Not Purchline[1].Findset then
        begin
            If GuiAllowed Then Message('Purchase order containes no item lines');
            exit(flg);
        end;
        Purchline[2].CopyFilters(Purchline[1]);
        repeat
            Purchline[2].Setrange("No.",Purchline[1]."No.");
            If Purchline[2].Count > 1 then
            begin
                If GuiAllowed Then message('%1 is repeated on PO\Only Unique SKU No. are allowed',Purchline[1]."No.");
                exit(flg);
            end;    
        until PurchLine[1].next = 0;
        If (PurchHdr."Requested Receipt Date" = 0D)
            AND (PurchHdr."Promised Receipt Date" = 0D) then
        begin
            If GuiAllowed Then Message('Requested And Or Promised Receipt Dates Are Missing');
            exit(flg);
        end;
        Setup.get;
        If Setup."Use NPF Dev Access" then
        begin
            Logins[1] := Setup."Dev NPF UserName";
            Logins[2] := setup."Dev NPF Password";
            logins[3] := Setup."Dev NPF Client Code";
        end
        else
        begin
            Logins[1] := Setup."NPF UserName";
            Logins[2] := setup."NPF Password";
            logins[3] := Setup."NPF Client Code";
        end;
        XmlDoc := XmlDocument.Create();
        CuXML.AddRootElement(XmlDoc,'Inbound',CurrNode[2]);
        CuXML.AddElement(CurrNode[2],'Login','','',CurrNode[1]);
        CuXML.AddElement(CurrNode[1],'Username',Ascii_Parser(Logins[1]),'',CurrNode[2]);
        CuXML.AddElement(CurrNode[1],'Password',Ascii_Parser(Logins[2]),'',CurrNode[2]);
        if CuXML.FindNode(CurrNode[1],'//Inbound',CurrNode[2]) then
        begin
            CuXML.AddElement(CurrNode[2],'InboundDetail','','',CurrNode[1]);
            CuXML.AddElement(CurrNode[1],'ClientCode',Ascii_Parser(Logins[3]),'',CurrNode[2]);
            CuXML.AddElement(CurrNode[1],'PONo',PurchHdr."No.",'',CurrNode[2]);
            CuXML.AddElement(CurrNode[1],'BookedDate',Format(Today,0,'<year4>-<Month,2>-<Day,2>'),'',CurrNode[2]);
        end
        else
            Exit(flg);    
        // we ensure that the delivery date conforms to NPF requirements of 48 Hr of booking date and
        // not on week ends
        TestDate := PurchHdr."Requested Receipt Date";
        If TestDate >= CalcDate('+2D',Today) then
        begin
            If Date2DWY(TestDate,1) > 5 then
            begin
                if Date2DWY(TestDate,1) = 6 then 
                    TestDate := CalcDate('+2D',testDate)
                else    
                    TestDate := Calcdate('+1D',Testdate);
            end;
        end 
        else
        begin
            TestDate :=  CalcDate('+2D',Today);
            If Date2DWY(TestDate,1) > 5 then
            begin
                if Date2DWY(TestDate,1) = 6 then 
                    TestDate := CalcDate('+2D',testDate)
                else    
                    TestDate := Calcdate('+1D',Testdate);
            end;
        end;    
        PurchHdr."Requested Receipt Date" := TestDate;
        PurchHdr.modify(false);
        CuXML.AddElement(CurrNode[1],'DeliveryDate',Format(PurchHdr."Requested Receipt Date",0,'<year4>-<Month,2>-<Day,2>'),'',CurrNode[2]);
        CuXML.AddElement(CurrNode[1],'DeliveryType','2','',CurrNode[2]);
        CuXML.AddElement(CurrNode[1],'PalletType','','',CurrNode[2]);
        CuXML.AddElement(CurrNode[1],'NoofPallets','','',CurrNode[2]);
        CuXML.AddElement(CurrNode[1],'VesselNumber','','',CurrNode[2]);
        if CuXML.FindNode(CurrNode[1],'//Inbound/InboundDetail',CurrNode[2]) then
        begin
            CuXML.AddElement(CurrNode[2],'Supplier','','',CurrNode[1]);
            ven.get(PurchHdr."Buy-from Vendor No.");
            CuXML.AddElement(CurrNode[1],'Name',Ascii_Parser(Ven.name) + ' ' + Ascii_Parser(Ven."Name 2"),'',CurrNode[2]);
            CuXML.AddElement(CurrNode[1],'Email',Ascii_Parser(ven."E-Mail"),'',CurrNode[2]);
            CuXML.AddElement(CurrNode[1],'Phone',Return_Numeric(Ven."Phone No."),'',CurrNode[2]);
            CuXML.AddElement(CurrNode[1],'Country',Ascii_Parser(Ven."Country/Region Code"),'',CurrNode[2]);
            CuXML.AddElement(CurrNode[1],'State',Ascii_Parser(Ven.County),'',CurrNode[2]);
            CuXML.AddElement(CurrNode[1],'City',Ascii_Parser(ven.City),'',CurrNode[2]);
            CuXML.AddElement(CurrNode[1],'AdditionalInfo','','',CurrNode[2]);
            CuXML.FindNode(CurrNode[1],'//Inbound/InboundDetail',CurrNode[2]);
            CuXML.AddElement(CurrNode[2],'Items','','',CurrNode[1]);
            If Purchline[1].Findset then
            repeat
                If Item.get(PurchLine[1]."No.") then
                begin
                    CuXML.AddElement(CurrNode[1],'Item','','',CurrNode[2]);
                    CuXML.AddElement(CurrNode[2],'Code',Item."No.",'',CurrNode[3]);
                    CuXML.AddElement(CurrNode[2],'Description',Ascii_Parser(PurchLine[1].Description),'',CurrNode[3]);
                    CuXML.AddElement(CurrNode[2],'Quantity',Format(PurchLine[1]."Quantity (base)",0,'<Precision,2><Standard Format,1>'),'',CurrNode[3]);
                    If ItemUnit.get(Item."No.",Item."Base Unit of Measure") then
                    begin
                        CuXML.AddElement(CurrNode[2],'Weight',Format(ItemUnit.weight,0,'<Precision,2><Standard Format,1>'),'',CurrNode[3]);
                        CuXML.AddElement(CurrNode[2],'Length',Format(ItemUnit.Length,0,'<Precision,2><Standard Format,1>'),'',CurrNode[3]);
                        CuXML.AddElement(CurrNode[2],'Width',Format(ItemUnit.Width,0,'<Precision,2><Standard Format,1>'),'',CurrNode[3]);
                        CuXML.AddElement(CurrNode[2],'Height',Format(ItemUnit.Height,0,'<Precision,2><Standard Format,1>'),'',CurrNode[3]);
                    end
                    else
                    begin
                        CuXML.AddElement(CurrNode[2],'Weight','0','',CurrNode[3]);
                        CuXML.AddElement(CurrNode[2],'Length','0','',CurrNode[3]);
                        CuXML.AddElement(CurrNode[2],'Width','0','',CurrNode[3]);
                        CuXML.AddElement(CurrNode[2],'Height','0','',CurrNode[3]);
                    end;
                    CuXML.AddElement(CurrNode[2],'Price','0','',CurrNode[3]);
                    CuXML.AddElement(CurrNode[2],'QtyperInner','0','',CurrNode[3]);
                    CuXML.AddElement(CurrNode[2],'QtyperCase','0','',CurrNode[3]);
                    CuXML.AddElement(CurrNode[2],'Additioninfo1','','',CurrNode[3]);
                    CuXML.AddElement(CurrNode[2],'Additioninfo2','','',CurrNode[3]);
                    CuXML.AddElement(CurrNode[2],'Barcode',Item.GTIN,'',CurrNode[3]);
                    CuXML.AddElement(CurrNode[2],'Shelf_Life_Days',Format(Item."Shelf Life Months" * 30),'',CurrNode[3]);
                    i := Item."Storage Method Type";
                    CuXML.AddElement(CurrNode[2],'Storage_Method_Id',Format(i),'',CurrNode[3]);
                    CuXML.AddElement(CurrNode[2],'Storage_Temperature_Nominal_In_Celsius'
                                        ,Format(Item."Storage Nominal Temperature",0,'<Precision,2><Standard Format,1>'),'',CurrNode[3]);
                    CuXML.AddElement(CurrNode[2],'Storage_Temperature_Tolerance'
                                        ,Format(Item."Storage Nominal Temperature",0,'<Precision,2><Standard Format,1>'),'',CurrNode[3]);
                    CuXML.AddElement(CurrNode[2],'HS_Code',Item."HS Code",'',CurrNode[3]);
                    i := Item."Picking Sequence";
                    CuXML.AddElement(CurrNode[2],'Picking_Sequence',Format(i),'',CurrNode[3]);
                end;    
            until PurchLine[1].next = 0;
        end 
        else
            exit(flg);    
        XmlDoc.WriteTo(PayLoad);
        Payload := Payload.Replace('utf-16','utf-8');
        If NPF_Data(Paction::POST,Req,Parms,Payload,XmlDoc) then
        begin
            CurrNode[1] := XmlDoc.AsXmlNode();    
            If CuXML.FindNode(CurrNode[1],'//Request/Status',CurrNode[2]) then
                If CurrNode[2].AsXmlElement().InnerText.ToUpper() = 'VALID' then
                begin
                    CuXML.FindNode(CurrNode[1],'//Request/Response/BookingReferenceNo',CurrNode[2]);
                    PurchHdr."NPF Booking Ref No" := CurrNode[2].AsXmlElement().InnerText();
                    PurchHdr."NPF ASN Status" := PurchHdr."NPF ASN Status"::PENDING;
                    PurchHdr.Modify(false);
                    flg := true;
                end
                else If CuXML.FindNode(CurrNode[1],'//Request/Response/Errors/Error/ErrorDetail',CurrNode[2]) then
                    If GuiAllowed then Message('NPF Error - > %1',CurrNode[2].AsXmlElement().InnerText);
        end;
        exit(flg); 
    end;   
    procedure Get_ASN_Receipts(var PurchHdr:Record "Purchase Header";UseDisplay:boolean):Boolean
    var
        PayLoad:text;
        Parms:Dictionary of [text,text];
        XmlDoc:XmlDocument;
        CurrNode:Array[3] of XmlNode;
        CuXML:Codeunit "XML DOM Management";
        Corr:Record "HL Purchase Corrections";
        i:Integer;
        Sku:text;
        qty:array[2] of Decimal;
        flg:Boolean;
        runFlg:Boolean;
        PurchLine:record "Purchase Line";
        POEx:Record "HL Purch Exceptions";
        Excnt:integer;
        NoOrd:Integer;
        InvOrd:Integer;
        SKUKeys:list of [text];
        SKUList:Dictionary of [text,Decimal];
        LineNo:Integer;
        Item:record Item;
        IsRel:Boolean;
        XMLNodeLst:XmlNodeList;
    Begin
        flg := False;
        If Get_ASN_Status(PurchHdr."No.",XmlDoc) then
        begin
            CurrNode[1] := XmlDoc.AsXmlNode();
            if CuXML.FindNode(CurrNode[1],'//InboundReceiptList/InboundReceipt/ReceiptStatus',CurrNode[2]) then
            begin
                Case CurrNode[2].AsXmlElement().InnerText().ToUpper() of
                    'NOT RECEIVED':PurchHdr."NPF ASN Status" := PurchHdr."NPF ASN Status"::"NOT RECEIVED";
                    'RECEIVED':PurchHdr."NPF ASN Status" := PurchHdr."NPF ASN Status"::RECEIVED;
                    'RECEIVED WITH DISCREPANCIES':PurchHdr."NPF ASN Status" := PurchHdr."NPF ASN Status"::"RECEIVED WITH DISCREPANCIES";
                    'RECEIPT IN PROGRESS':PurchHdr."NPF ASN Status" := PurchHdr."NPF ASN Status"::"RECEIPT IN PROGRESS"; 
                    'QUARANTINE':PurchHdr."NPF ASN Status" := PurchHdr."NPF ASN Status"::QUARANTINE;
                end;
                PurchHdr.Modify(False);
                If PurchHdr."NPF ASN Status" in [PurchHdr."NPF ASN Status"::RECEIVED,PurchHdr."NPF ASN Status"::"RECEIVED WITH DISCREPANCIES"] then
                begin
                    IsRel := PurchHdr.Status = PurchHdr.Status::Released;
                    PurchHdr.Status := PurchHdr.Status::Open;
                    PurchHdr.Modify(False);    
                    Clear(LineNo);
                    Purchline.Reset;
                    PurchLine.Setrange("Document No.",PurchHdr."No.");
                    PurchLine.Setrange("Document Type",PurchHdr."Document Type");
                    If Purchline.findlast then LineNo := Purchline."Line No.";
                    Corr.Reset();
                    Corr.Setrange(User,UserId);
                    If Corr.findset then Corr.DeleteAll();
                    Clear(Excnt);
                    Clear(NoOrd);
                    Clear(InvOrd);
                    if CuXML.FindNode(CurrNode[1],'//InboundReceiptList/InboundReceipt/Items',CurrNode[2]) then 
                    begin
                        CurrNode[2].AsXmlElement().SelectNodes('Item',XmlNodeLst);    
                        For i := 1 to XMLNodeLst.Count do
                        begin
                            XmlNodeLst.Get(i,CurrNode[1]);
                            runFlg := True;
                            If CUXml.FindNode(CurrNode[1],'ItemCode',CurrNode[2]) then
                                sku := CurrNode[2].AsXmlElement().InnerText
                            else
                                Clear(runFlg);    
                            if CUXml.FindNode(CurrNode[1],'ReceivedQuantity',CurrNode[2]) Then
                                RunFlg := Evaluate(Qty[1],CurrNode[2].AsXmlElement().InnerText)
                            else
                               Clear(runFlg);
                            if RunFlg then       
                                If SKUList.ContainsKey(Sku) then
                                begin
                                    SKuList.get(SKU,qty[2]);
                                    SkuList.Set(SKU,qty[1] + Qty[2]);    
                                end
                                else
                                    SkuList.Add(SKU,qty[1]);    
                        end;
                        SKUKeys := SKUList.Keys;    
                       // here we loop and check the received NPF qty to the ordered qty    
                        For i := 1 to SKUKeys.count do
                        begin
                            Skulist.Get(SkuKeys.Get(i),Qty[1]);
                            Purchline.Reset;
                            PurchLine.Setrange("Document No.",PurchHdr."No.");
                            PurchLine.Setrange("Document Type",PurchHdr."Document Type");
                            Purchline.Setrange(type,PurchLine.type::Item);
                            Purchline.Setrange("No.",SkuKeys.Get(i));
                            If Purchline.Findset then
                            begin
                                If UseDisplay then
                                begin
                                    Corr.init;
                                    Clear(Corr.ID);
                                    Corr.Insert();
                                    Corr.User := UserId;
                                    Corr.PO := PurchHdr."No.";
                                    Corr.SKU := Purchline."No.";
                                    Corr.description := PurchLine.Description;
                                    Corr."Original Order Qty" := PurchLine."Quantity (base)";
                                    Corr."NPF Corrected Qty" := qty[1];
                                    if Qty[1] <> PurchLine."Quantity (base)" then Corr."Correction Status" := Corr."Correction Status"::Corrected;
                                    Corr.Modify();
                                end;
                                if Qty[1] <> PurchLine."Quantity (base)" then Excnt += 1;
                                Purchline."NPF Recvd Qty" := Qty[1];
                                Purchline.Modify(False);
                            end
                            else
                            begin
                                If Item.Get(SkuKeys.Get(i)) then
                                Begin               
                                    LineNo += 10000;
                                    Purchline.Init;
                                    PurchLine.Validate("Document No.",PurchHdr."No.");
                                    PurchLine.Validate("Document Type",PurchHdr."Document Type");
                                    Purchline.Validate("Line No.",LineNo);
                                    Purchline.insert;
                                    Purchline.validate(type,PurchLine.type::Item);
                                    Purchline.validate("No.",SkuKeys.Get(i));
                                    Purchline.Validate("Unit of Measure Code",Item."Base Unit of Measure");
                                    Purchline.Validate(Quantity,Qty[1]);
                                    Purchline."NPF Recvd Qty" := Qty[1];
                                    Clear(Purchline."Original Order Qty");
                                    Clear(Purchline."Original Order Qty(base)");
                                    Clear(Purchline."Original Order UOM");
                                    Purchline.Modify();
                                    If UseDisplay then
                                    begin
                                        Corr.init;
                                        Clear(Corr.ID);
                                        Corr.Insert();
                                        Corr.User := UserId;
                                        Corr.PO := PurchHdr."No.";
                                        Corr.SKU := Purchline."No.";
                                        Corr.description := PurchLine.Description;
                                        Corr."Original Order Qty" := 0;
                                        Corr."NPF Corrected Qty" := qty[1];
                                        Corr."Correction Status" := Corr."Correction Status"::"Not Ordered";
                                        Corr.Modify();
                                    end;
                                    NoOrd += 1;
                                end
                                else If UseDisplay then
                                begin
                                    Corr.init;
                                    Clear(Corr.ID);
                                    Corr.Insert();
                                    Corr.User := UserId;
                                    Corr.PO := PurchHdr."No.";
                                    Corr.SKU := SkuKeys.Get(i);
                                    Corr.description := 'Unknown SKU Error';
                                    Corr."Original Order Qty" := 0;
                                    Corr."NPF Corrected Qty" := qty[1];
                                    Corr."Correction Status" := Corr."Correction Status"::"Unknown SKU";
                                    Corr.Modify();
                                end;
                                InvOrd += 1;
                            end;
                        end;
                        Purchline.Reset;
                        PurchLine.Setrange("Document No.",PurchHdr."No.");
                        PurchLine.Setrange("Document Type",PurchLine."Document Type"::Order);
                        Purchline.Setrange(type,PurchLine.type::Item);
                        PurchLine.Setrange("NPF Recvd Qty",-1);
                        If Purchline.Findset then
                        repeat
                            Excnt += 1;
                            Purchline."NPF Recvd Qty" := 0;
                            Purchline.Modify(False);
                            If UseDisplay then
                            begin
                                Corr.init;
                                Clear(Corr.ID);
                                Corr.Insert();
                                Corr.User := UserId;
                                Corr.PO := PurchHdr."No.";
                                Corr.SKU := PurchLine."No.";
                                Corr.description := PurchLine.Description;
                                Corr."Original Order Qty" := PurchLine."Quantity (base)";
                                Corr."NPF Corrected Qty" := 0;
                                if 0 <> PurchLine."Quantity (base)" then Corr."Correction Status" := Corr."Correction Status"::Corrected;
                                Corr.Modify();
                            end;
                        Until PurchLine.Next = 0;
                        If (Excnt > 0) Or (NoOrd > 0) Or (InvOrd > 0) then
                        begin
                            If POEx.Get(PurchHdr."No.") then
                            begin
                                POEx."Exception Count" := Excnt;
                                POEx."Not On Order Exception Count" := NoOrd;
                                POEx."Unknown SKU Exception Count" := InvOrd;
                                POEx.modify;
                            end
                        end    
                        else
                        begin
                            POEx.init;
                            POEx."Purchase Order No." := PurchHdr."No.";
                            POEx."Exception Date" := Today;
                            POEx."Exception Count" := Excnt;
                            POEx."Not On Order Exception Count" := NoOrd;
                            POEx."Unknown SKU Exception Count" := InvOrd;
                            POEx.insert;
                        end;
                    end;
                    If IsRel then
                    begin 
                        PurchHdr.Status := PurchHdr.Status::Released;
                        PurchHdr.Modify(false);
                    end;
                    flg := true;    
                end
                else
                    flg := true;
            end;
        end
        else
            If GuiAllowed Then Message('Failed Communications to NPF for stock receipts/ASN Status');            
        commit;
        exit(Flg);
    end;
    Procedure Build_NPF_Inventory_Levels(Prod:Code[20])
    var
        XmlDoc:XmlDocument;
        XmlNodeLst:array[2] of XmlNodeList;
        CurrNode:array[2] of XmlNode;
        CuXML:Codeunit "XML DOM Management";
        i:Integer;
        j:Integer;
        win:Dialog;
        Item:record Item;
        loc:Record Location;
        qty:Decimal;
        Hinv:Record "HL NPF Inventory";
        HBatch:array[2] of record "HL NPF SOH Batches";
    Begin
        if GuiAllowed then win.Open('Retrieving SOH From NPF .. Please Wait');
        If Get_SOH(0,Prod,XmlDoc) then
        begin
            if GuiAllowed then
            begin 
                Win.Close;
                win.Open('SKU -> #1##############');
            end;
            CurrNode[1] := XMlDoc.AsXmlNode();
            if CuXML.findnode(CurrNode[1],'ProductList',CurrNode[2]) then
            begin
                Hinv.reset;
                If Hinv.FindSet() then Hinv.ModifyAll("Update Flag",False,False);
                CurrNode[2].AsXmlElement().SelectNodes('Product',xmlNodeLst[1]);
                For i := 1 to XmlNodeLst[1].count do
                begin
                    XmlNodeLst[1].get(i,CurrNode[1]);
                    CuXML.findnode(CurrNode[1],'ProductCode',CurrNode[2]);    
                    If Item.Get(CurrNode[2].AsXmlElement().InnerText.ToUpper()) then
                    begin
                        if GuiAllowed then Win.Update(1,Item."No.");
                        CuXML.findnode(CurrNode[1],'StockonHand',CurrNode[2]);
                        if Not Evaluate(Qty,Currnode[2].AsXmlElement().InnerText) then
                            Qty := 0;    
                        Loc.reset;
    //                   Loc.Setrange("NPF Warehouse ID",JsToken[1].AsValue().AsInteger());
                        Loc.Setrange(Code,'NSW');
                        If Loc.findset then 
                        Begin
                            If Not Hinv.get(Item."No.",Loc.Code) then
                            begin
                                Hinv.SKU := Item."No.";
                                Hinv."Location Code" := Loc.Code;
                                Hinv.Insert;
                            end;
                            Hinv.Qty := qty;
                            Hinv."Update Flag" := True;
                            Hinv.Modify();        
                        end;
                        HBatch[1].Reset;
                        HBatch[1].Setrange(SKU,Item."No.");
                        If HBatch[1].findset Then Hbatch[1].Deleteall;
                        CuXML.findnode(CurrNode[1],'StockOnHand_BatchAndExpiryList',CurrNode[2]);
                        CurrNode[2].AsXmlElement().SelectNodes('BatchAndExpiry',xmlNodeLst[2]);
                        For j := 1 to XmlNodeLst[2].Count do
                        begin
                            XmlNodeLst[2].get(j,CurrNode[1]);
                            HBatch[1].init;
                            HBatch[1].SKU := Item."no.";
                            HBatch[1]."Location Code" := Loc.Code;
                            CuXML.findnode(CurrNode[1],'BatchNumber',CurrNode[2]);
                            HBatch[1]."Batch No." := CurrNode[2].AsXmlElement().InnerText;
                            If HBatch[2].Get(HBatch[1].SkU,HBatch[1]."Batch No.") then
                            begin     
                                CuXML.findnode(CurrNode[1],'ReceivedQty',CurrNode[2]);
                                If Not Evaluate(HBatch[2]."Batch Qty",CurrNode[2].AsXmlElement().InnerText) then
                                    Clear(HBatch[2]."Batch Qty");
                                CuXML.findnode(CurrNode[1],'ExpiryDate',CurrNode[2]);
                                If Not Evaluate(HBatch[2]."Expiry Date",CurrNode[2].AsXmlElement().InnerText) then
                                    Clear(HBatch[2]."Expiry Date");
                                HBatch[2].Modify;
                            end 
                            else
                            begin
                                CuXML.findnode(CurrNode[1],'ReceivedQty',CurrNode[2]);
                                If Not Evaluate(HBatch[1]."Batch Qty",CurrNode[2].AsXmlElement().InnerText) then
                                    Clear(HBatch[1]."Batch Qty");
                                CuXML.findnode(CurrNode[1],'ExpiryDate',CurrNode[2]);
                                If Not Evaluate(HBatch[1]."Expiry Date",CurrNode[2].AsXmlElement().InnerText) then
                                    Clear(HBatch[1]."Expiry Date");
                                HBatch[1].Insert;
                            end;        
                        end;
                    end;
                end;
                Hinv.reset;
                Hinv.Setrange("Update Flag",False);
                If Hinv.findset Then Hinv.DeleteAll(True);
            end
            else if CuXML.findnode(CurrNode[1],'//Request/Response/Errors/Error/ErrorDetail',CurrNode[2]) then
                If Guiallowed then Message('%1',CurrNode[2].AsXmlElement().InnerText)
            else If Guiallowed then Message('Network data retrival errors have resulted suggest a retry');    
        end
        else
            Error('Failed Communications to NPF for inventory levels');
        if GuiAllowed then win.Close;
    end;
    Procedure Build_NPF_Inventory_Transaction()
    var
        PageCnt,i,j:Integer;
        Trans:record "HL NPF Inventory Transactions";
        Index:integer;
        StartIndx:Integer;
        XmlDoc:XmlDocument;
        XmlNodeLst:XmlNodeList;
        CurrNode:array[3] of XmlNode;
        CuXML:Codeunit "XML DOM Management";
        Win:dialog;
    begin
        if GuiAllowed then Win.Open('Retrieving NPF Inventory Transactions');  
        Clear(Startindx);
        Trans.Reset;
        If Trans.FindLast() then StartIndx := Trans."Transaction ID"; 
        if Get_Inventory_Transactions(1,StartIndx,xmldoc) then
        begin
            CurrNode[1] := XMlDoc.AsXmlNode();
            CuXML.findnode(CurrNode[1],'InventoryTransaction',CurrNode[2]);
            CuXML.findnode(CurrNode[2],'Status',CurrNode[1]);
            If CurrNode[1].AsXmlElement().InnerText.ToUpper() = 'SUCCESS' then
            begin
                If GuiAllowed then
                begin
                    Win.close;
                    Win.Open('SKU #1############');
                end;
                CuXML.findnode(CurrNode[2],'TotalPages',CurrNode[1]);
                Evaluate(PageCnt,CurrNode[1].AsXmlElement().InnerText);
                for i := 1 to PageCnt do
                begin
                    If Get_Inventory_Transactions(i,StartIndx,xmldoc) then
                    begin
                        CurrNode[1] := XMlDoc.AsXmlNode();
                        CuXML.findnode(CurrNode[1],'InventoryTransaction',CurrNode[2]);
                        CuXML.findnode(CurrNode[2],'Status',CurrNode[3]);
                        If CurrNode[3].AsXmlElement().InnerText.ToUpper() = 'SUCCESS' then
                        begin
                            CuXML.findnode(CurrNode[2],'Transactions',CurrNode[3]);
                            CurrNode[3].SelectNodes('Transaction',XmlNodeLst);
                            for j:= 1 to XmlNodeLst.Count do
                            begin
                                XmlNodeLst.get(j,CurrNode[1]);
                                CuXML.findnode(CurrNode[1],'TransactionId',CurrNode[2]);
                                evaluate(index,CurrNode[2].AsXmlElement().InnerText);
                                If not Trans.Get(index) then
                                begin
                                    Trans.init;
                                    Trans."Transaction ID" := index;
                                    Trans.Insert();
                                end;    
                                CuXML.findnode(CurrNode[1],'PostingDateTime',CurrNode[2]);
                                Evaluate(Trans.PostingDateTime,CurrNode[2].AsXmlElement().InnerText);
                                CuXML.findnode(CurrNode[1],'Product',CurrNode[2]);
                                CuXML.findnode(CurrNode[2],'ProductId',CurrNode[3]);
                                Trans.Sku := CurrNode[3].AsXmlElement().InnerText;
                                if Guiallowed then win.update(1,Trans.SKU);
                                CuXML.findnode(CurrNode[2],'Quantity',CurrNode[3]);
                                evaluate(trans.Qty,CurrNode[3].AsXmlElement().InnerText);
                                CuXML.findnode(CurrNode[2],'UOM',CurrNode[3]);
                                Trans.UOM := Copystr(CurrNode[3].AsXmlElement().InnerText,1,10);
                                CuXML.findnode(CurrNode[2],'TransactionType',CurrNode[3]);
                                Trans."Transaction Type" := CopyStr(CurrNode[3].AsXmlElement().InnerText,1,50);
                                CuXML.findnode(CurrNode[2],'TransactionName',CurrNode[3]);
                                Trans."Transaction Name" := CopyStr(CurrNode[3].AsXmlElement().InnerText,1,50);
                                CuXML.findnode(CurrNode[2],'ReasonDescription',CurrNode[3]);
                                Trans."Reason Description" := CopyStr(CurrNode[3].AsXmlElement().InnerText,1,80);
                                CuXML.findnode(CurrNode[2],'LotDetails',CurrNode[3]);
                                CuXML.findnode(CurrNode[3],'LotId',CurrNode[2]);
                                Trans."Batch No" := CurrNode[2].AsXmlElement().InnerText;
                                CuXML.findnode(CurrNode[3],'ExpiryDate',CurrNode[2]);
                                Evaluate(Trans."Expiry Date",CurrNode[2].AsXmlElement().InnerText);
                                trans.Modify();
                            end;
                        end;
                    end;    
                end;
            end;
        end;
        if Guiallowed Then win.close;
    end;
    procedure Adjust_Inventory(var Item:record Item;Loc:Code[10];Qty:Decimal):Boolean;
    var
        ItemJrnLine:Record	"Item Journal Line";	
        CuItemJrnl:Codeunit	"Item Jnl.-Post Line";	
        ItemJrnBatch:Record	"Item Journal Batch";	
        Reason:Record	"Reason Code";
        GLSetup:record "General Ledger Setup";
        PSTDate:date;
        Flg:Boolean;
    begin
        Clear(PSTDate);
        GLSetup.Get;
        If (GLSetup."Allow Posting To" <> 0D) AND (GLSetup."Allow Posting To" < Today) then
        begin
            PSTDate := GLSetup."Allow Posting To";
            Clear(GLSetup."Allow Posting To");
            GLSetup.modify(false);
        end;
        IF NOT Reason.GET('NPFADJST') THEN
        BEGIN
            Reason.Code := 'NPFADJST';
            Reason.Description := 'NPF Adjustments';
            Reason.INSERT;
        END;
        IF NOT ItemJrnBatch.GET('ITEM','NPFADJST') THEN
        BEGIN
            ItemJrnBatch."Journal Template Name" := 'ITEM';
            ItemJrnBatch.Name := 'NPFADJST';
            ItemJrnBatch.Description := 'NPF Adjustments';
            ItemJrnBatch."Reason Code" := Reason.Code;
            ItemJrnBatch."Template Type" := ItemJrnBatch."Template Type"::Item;
            ItemJrnBatch.INSERT;
        END;
        CLEAR(ItemJrnLine);
        ItemJrnLine.INIT;
        ItemJrnLine."Journal Template Name" := ItemJrnBatch."Journal Template Name";
        ItemJrnLine."Journal Batch Name" := ItemJrnBatch.Name;
        ItemJrnLine."Document No." := STRSUBSTNO('NPF - %1',FORMAT(WORKDATE,0,'<Day,2>/<Month,2>/<Year4>'));
        ItemJrnLine."Line No." := 10000;
        ItemJrnLine."Posting Date" := TODAY;
        If Qty < 0 then
            ItemJrnLine."Entry Type" := ItemJrnLine."Entry Type"::"Negative Adjmt."
        else
            ItemJrnLine."Entry Type" := ItemJrnLine."Entry Type"::"Positive Adjmt.";
        ItemJrnLine.Description := 'NPF Balance Adjustment';
        ItemJrnLine.VALIDATE("Item No.",Item."No.");
        ItemJrnLine.VALIDATE("Unit Cost",Item."Unit Cost");
        ItemJrnLine.VALIDATE("Location Code",Loc);
        ItemJrnLine.VALIDATE("Unit of Measure Code",Item."Base Unit of Measure");
        ItemJrnLine.VALIDATE(Quantity,ABS(qty));
        ItemJrnLine."Reason Code" := ItemJrnBatch."Reason Code";
        ItemJrnLine."Return Reason Code" := ItemJrnBatch."Reason Code";
        Commit;
        Flg := CuItemJrnl.RUN(ItemJrnLine);
        If PSTDate <> 0D then
        begin
            GLSetup."Allow Posting To" := PSTDate;
            GLSetup.Modify(False);
        end;
        Exit(Flg);
    end;
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Release Purchase Document", 'OnBeforeManualReleasePurchaseDoc', '', true, true)]
    local procedure "Release Purchase Document_OnBeforeManualReleasePurchaseDoc"
    (
        var PurchaseHeader: Record "Purchase Header";
		PreviewMode: Boolean
    )
    begin
        If PurchaseHeader."Order Type" = PurchaseHeader."Order Type"::NPF then
            If (PurchaseHeader."Requested Receipt Date" = 0D) then
                Error('Requested Receipt Date must be defined');
    end;
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post", 'OnBeforePostPurchaseDoc', '', true, true)]
    local procedure "Purch.-Post_OnBeforePostPurchaseDoc"
    (
        var PurchaseHeader: Record "Purchase Header";
		PreviewMode: Boolean;
		CommitIsSupressed: Boolean;
		var HideProgressWindow: Boolean
    )
    var
        Flg:boolean;
        PurchLine:record "Purchase Line";
        Excp:record "HL Purch Exceptions";
    begin
        Flg := True;
        if PurchaseHeader."Order Type" = PurchaseHeader."Order Type"::NPF then
        begin
            If PurchaseHeader."NPF ASN Status" in[PurchaseHeader."NPF ASN Status"::RECEIVED
              ,PurchaseHeader."NPF ASN Status"::"RECEIVED WITH DISCREPANCIES"]   then
            begin
                PurchLine.Reset;
                Purchline.Setrange("Document Type",PurchaseHeader."Document Type");
                Purchline.Setrange("Document No.",PurchaseHeader."No.");
                Purchline.Setrange(Type,PurchLine.type::Item);
                If Purchline.findset then
                repeat
                    Flg := Purchline."Quantity (Base)" <> PurcHline."NPF Recvd Qty";
                until (Purchline.Next = 0) or Flg;
                If Flg Then Error('Purchase Order Still Contains NPF Exception Qtys .. Correct And Retry');
                // remove the exception record now
                if Excp.Get(PurchaseHeader."No.") then Excp.Delete;
            end   
            else If Not Confirm('This NPF PO Order does not have a ASN RECEIVED Status type ... Continue on regardless',false) then
                error('');
        end;          
    end;
 // rountine to include rebate information as required on purchase lines
    Procedure Purch_Rebates(var Purchline:record "Purchase Line")
    var
        GenSetup:Record "General Ledger Setup";
        SupBrand:Record "HL Supplier Brand Rebates";
        PurchHdr:record "Purchase Header";    
        Item:Record Item;
        Ven:Record Vendor;
    begin
        PurchHdr.Get(Purchline."Document Type",Purchline."Document No.");
        If (Purchline.Type = Purchline.Type::Item) AND (PurchHdr."Order Type" = Purchhdr."Order Type"::NPF) then
        begin
            GenSetup.Get;
            Item.Get(Purchline."No.");
            If Item.Type = Item.Type::Inventory then
            begin
                SupBrand.reset;
                SupBrand.Setrange("Supplier No.",Purchline."Buy-from Vendor No.");
                SupBrand.Setrange(Brand,Item.Brand);
                SupBrand.Setrange("Rebate Status",SupBrand."Rebate Status"::Open);
                SupBrand.Setfilter("Rebate Start Date Period",'<=%',Today);
                If SupBrand.Findset then
                begin
                    Purchline."Line Rebate %" := SupBrand."Volume Rebate %";
                    Purchline."Line Rebate %" += SupBrand."Marketing Rebate %";
                end;
                Purchline.validate("Indirect Cost %",-Purchline."Line Rebate %");    
            end;    
        end;    
    end; 
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post", 'OnAfterPostItemLine', '', true, true)]
    local procedure "Update Accural Rebates"
    (
        PurchaseLine: Record "Purchase Line";
        CommitIsSupressed: Boolean;
        PurchaseHeader: Record "Purchase Header";
        RemQtyToBeInvoiced: Decimal;
        RemQtyToBeInvoicedBase: Decimal
    )
    var
        Reb:Record "HL Purchase Rebates";
        SupBrand:Record "HL Supplier Brand Rebates";
        Item:Record Item;
        i:Integer;    
        Amt:Decimal;
    begin
        If (PurchaseHeader."Order Type" = PurchaseHeader."Order Type"::NPF) 
            And (Purchaseline."Document type" = PurchaseLine."Document Type"::order)
            And (Purchaseline.Type = PurchaseLine.Type::Item)
            And (PurchaseLine."Indirect Cost %" < 0) then
        begin
            Amt := ABS(Purchaseline.Amount * (PurchaseLine."Indirect Cost %"/100));  
            Item.Get(Purchaseline."No.");
            SupBrand.reset;
            SupBrand.Setrange("Supplier No.",PurchaseHeader."Buy-from Vendor No.");
            SupBrand.Setrange(Brand,Item.Brand);
            SupBrand.Setrange("Rebate Status",SupBrand."Rebate Status"::Open);
            SupBrand.Setfilter("Rebate Start Date Period",'<=%',Today);
            If SupBrand.Findset then
                For i:= 1 to 2 do
                begin
                    Reb.init;
                    Clear(Reb.ID);
                    Reb.Insert();
                    Reb."Document No." := PurchaseHeader."Posting No.";
                    Reb."Rebate Date" := PurchaseHeader."Posting Date";
                    Reb."Supplier No." := PurchaseHeader."Buy-from Vendor No.";
                    Reb."Item No." := PurchaseLine."No.";
                    Reb."Document Line No." := PurchaseLine."Line No.";
                    Reb.Brand := SupBrand.Brand;
                    Case i of
                        1:
                        begin
                            Reb."Rebate Type" := Reb."Rebate Type"::PartnerShip;
                            Reb."Rebate Value" := amt * ABS(SupBrand."Volume Rebate %"/PurchaseLine."Indirect Cost %");
                            Reb."Rebate %" := SupBrand."Volume Rebate %";  
                        end;
                        2:
                        begin
                            Reb."Rebate Type" := Reb."Rebate Type"::Marketing;
                            Reb."Rebate Value" := amt * ABS(SupBrand."Marketing Rebate %"/PurchaseLine."Indirect Cost %");
                            Reb."Rebate %" := SupBrand."Marketing Rebate %";  
                        end;
                    end;
                    Reb.Modify();
                end;
        end;               
    end;
}