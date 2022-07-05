codeunit 80005 Test 
 {
     Permissions = TableData "Sales Invoice Line" = rm;


var
        Paction:Option GET,POST,DELETE,PATCH,PUT;
        WsError:text;
        ShopifyBase:Label '/admin/api/2021-10/';

    procedure Testrun()
    var
        OrdApp:Record "HL Shopfiy Order Applications";
        DiscApps:record "HL Shopify Disc Apps";
        CU:Codeunit "HL Shopify Routines";
        Parms:Dictionary of [text,text];
        Data:JsonObject;
        PayLoad:text;
        JsArry:JsonArray;
        JsToken:array[2] of JsonToken;
        Sinv:Record "Sales Invoice Line";
        win:dialog;
        i:integer;
        Item:record Item;
    begin
        Item.reset;
        Item.Setrange(Type,Item.Type::Inventory);
        IF Item.findset then
        repeat
            Item."Price Includes VAT" := Item."VAT Prod. Posting Group" = 'GST10';
            Item.Modify(False);
            Item.Update_Parent();
        until Item.Next = 0;    
        exit;
        






        Win.Open('Record Count #1####### of #2#######');    
        Clear(Parms);
        Parms.Add('fields','discount_applications');
        //DiscApps.reset;
        //If DiscApps.findset then DiscApps.DeleteAll(False);
        Sinv.Reset;
        Sinv.Setfilter("Shopify Application ID",'>0');
        If Sinv.Findset then Sinv.ModifyAll("Shopify Application ID",0,False);
        OrdApp.Reset();
        //OrdApp.Setfilter("Shopify Disc App Code",'=%1','');
        If OrdApp.FindSet() then
        begin
            Clear(i);
            Win.update(2,OrdApp.Count);
            repeat
                Clear(PayLoad);
                if CU.Shopify_Data(Paction::GET,ShopifyBase + 'orders/' + Format(OrdApp."Shopify Order ID") + '.json'
                                        ,Parms,PayLoad,Data) then
                    If Data.Get('order',JsToken[1]) then
                        If JsToken[1].SelectToken('discount_applications',JsToken[2]) then
                            If JsToken[2].AsArray().Count > 0 then
                            begin
                                JsToken[2].AsArray().get(0,Jstoken[1]);  
                                if JSToken[1].SelectToken('code',jsToken[2]) then
                                    if not Jstoken[2].AsValue().IsNull then
                                    begin
                                        i+=1;
                                        Win.update(1,i);
                                        OrdApp."Shopify Disc App Code" := CopyStr(Jstoken[2].AsValue().AsCode(),1,100);
                                        OrdApp.modify(true);
                                   end;
                            end;
                        Sinv.Reset;
                        Sinv.Setrange("Shopify Order ID",OrdApp."Shopify Order ID");
                        If Sinv.Findset then
                            if DiscApps.Get(OrdApp."Shopify Application Type",OrdApp."Shopify Disc App Code",OrdApp."Shopify Disc App Value") then        
                                Sinv.modifyall("Shopify Application ID",DiscApps."Shopify App ID",false);
                        If i Mod 10 = 0 then Commit;
            until OrdApp.next = 0;
            Commit;
        end;
        win.close;                        
    end;                        
    
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
        CU:Codeunit "HL Shopify Routines";
    begin
        Clear(PayLoad);
        Clear(Parms);
        Clear(RecCnt);
        Parms.Add('fields','id,cancelled_at,fulfillment_status,order_number,discount_applications,line_items,processed_at'
                +',currency,total_discounts,total_shipping_price_set,financial_status,total_price,total_tax');
        CU.Shopify_Data(Paction::GET,ShopifyBase + 'orders/' + Format(StartIndex) + '.json'
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
                If Flg then Indx := Jstoken[2].AsValue().AsBigInteger();
                If Flg then Flg := Jstoken[1].SelectToken('cancelled_at',Jstoken[2]);
                if Flg then Flg := Jstoken[2].AsValue().IsNull;
                if Flg Then Flg := Jstoken[1].SelectToken('financial_status',Jstoken[2]);
                if Flg Then Flg := Not Jstoken[2].AsValue().IsNull;
                If Flg then Flg := Jstoken[2].AsValue().AsText().ToUpper() in ['PAID','REFUNDED','PARTIALLY_REFUNDED'];
                If Flg then Flg := Jstoken[1].SelectToken('fulfillment_status',Jstoken[2]);
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
                                        if JSToken[1].SelectToken('description',jsToken[2]) then
                                            if not Jstoken[2].AsValue().IsNull then
                                                OrdApp."Shopify Disc App Description" := CopyStr(Jstoken[2].AsValue().AsCode(),1,100)
                                        else if JSToken[1].SelectToken('code',jsToken[2]) then
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
                                        OrdLine."Order Qty" := OrdHdr."Order Type";
                                        Clear(OrdLine."Is NPF Item");
                                        ORdline."Order Line No" := (j + 1) * 10;
                                        if JsToken[1].SelectToken('id',JsToken[2]) Then
                                        begin
                                            if not Jstoken[2].AsValue().IsNull then
                                            Begin    
                                                OrdLine."Order Line ID" := JsToken[2].AsValue().AsBigInteger();
                                                If JsToken[1].SelectToken('sku',JsToken[2]) then
                                                    If Not JsToken[2].AsValue().IsNull then
                                                    begin
                                                        If JsToken[2].AsValue().AsCode() <> '' then
                                                        begin
                                                            Ordline."Item No." := jstoken[2].AsValue().AsCode();
                                                            If Item.Get(OrdLine."Item No.") then
                                                                OrdLine."Is NPF Item" := Item."SKU Part Source" = Item."SKU Part Source"::NPF;
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
                                                        end;
                                                    end;        
                                                    Ordline."Base Amount" := Ordline."Order Qty" * Ordline."Unit Price";
                                                    Ordline.modify(false);
                                            end    
                                            else
                                                OrdLine.delete;
                                        end
                                        else
                                            OrdLine.delete;
                                    end;  
                                end; 
                        end
                        else
                            if GuiAllowed then
                            begin 
                                Win.Update(2,'');
                                Win.update(3,'');
                            end;    
                    end    
                    Else
                        if GuiAllowed then
                        begin 
                            Win.Update(2,'');
                            Win.update(3,'');
                        end;    
                end
                else
                    if GuiAllowed then
                    begin 
                        Win.Update(2,'');
                        Win.update(3,'');
                    end;    
            end;
        end;
        Commit;
        if GuiAllowed then win.Close;
        exit(true);
    end;

    Procedure Fix_Refunds()
    var
        OrdHdr1:record "HL Shopify Order Header";
        OrdHdr2:record "HL Shopify Order Header";
        Cu:codeunit "HL Shopify Routines";
    begin
        OrdHdr1.reset;
        OrdHdr1.SetRange("Shopify Order Date",Calcdate('-9D',today()),Today());
        OrdHdr1.Setrange("Order Type",OrdHdr1."Order Type"::Invoice);
        If OrdHdr1.findset then
            OrdHdr1.ModifyAll("Refunds Checked",False); 
         



        
 /*       repeat
            OrdHdr2.reset;
            OrdHdr2.Setrange("Shopify Order Id",OrdHdr1."Shopify Order ID");
            OrdHdr2.Setrange("Order Type",OrdHdr2."Order Type"::Invoice);
            If OrdHdr2.findset then
                OrdHdr2.ModifyAll("Refunds Checked",False); 
            OrdHdr1.Delete(True);                   
        until OrdHdr1.next = 0;*/
        Commit;
        CU.Process_Refunds();
    end;

    local procedure Get_Order_Transactions(var Ordhdr:record "HL Shopify Order Header")
    var
        Parms:Dictionary of [text,text];
        Data:JsonObject;
        PayLoad:text;
        JsArry:JsonArray;
        JsToken:array[3] of JsonToken;
        i:integer;
        CU:codeunit "HL Shopify Routines";
    Begin
        Clear(Parms);
        Ordhdr."Transaction Date" := Today;
        Ordhdr."Transaction Type" := 'sale';
        if CU.Shopify_Data(Paction::GET,ShopifyBase + 'orders/' + Format(OrdHdr."Shopify Order ID") + '/transactions.json'
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
        end;                            
    end;
}