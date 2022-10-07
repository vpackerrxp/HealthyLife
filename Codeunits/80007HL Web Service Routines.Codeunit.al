codeunit 80007 "HL WebService Routines"
{
    var
        Paction:Option GET,POST,DELETE,PATCH,PUT;
    trigger OnRun()
    var
        Log:Record "HL Execution Log";
    Begin
        Log.init;
        Clear(Log.ID);
        log.insert;
        Commit;
        Log."Execution Start Time" := CurrentDateTime;
        Log."Execution Type" := Log."Execution Type"::Webservice;
        Log."Operation" := 'Transfer_Items_To API';
        If Transfer_Items_To_API() then
            Log.Status := Log.Status::Pass
        else
            log."Error Message" := CopyStr(GetLastErrorText,1,250);
        Log."Execution Time" := CurrentDateTime;
        log.Modify();
        Commit;
    end;    
    [TryFunction]
    procedure Transfer_Items_To_API()
    Var
       JsObj:JsonObject;
       JsArry:JsonArray;
       jsToken:JsonToken;
       PayLoad:text;
       Item:array[2] of record Item;
       ItemRel:record "HL Shopify Item Relations";
       ItemUnit:record "Item Unit of Measure";
       DelTrack:record "HL Track Item Relation Deletes";
       CU:Codeunit "HL Shopify Routines";
       HasData:Boolean;
       Parms:Dictionary of [text,text];
       Err:Text;
    Begin
        Clear(HasData);
        Clear(JsArry);
        Item[1].Reset;
        Item[1].Setrange(Type,Item[1].Type::"Inventory");
        Item[1].Setrange("Web Service Update Flag",True);
        If Item[1].Findset then
        repeat
            Clear(JsObj);
            ItemRel.Reset;
            ItemRel.Setrange("Child Item No.",Item[1]."No.");
            If ItemRel.FindSet() then
            Begin
                Item[2].Get(ItemRel."Parent Item No.");
                JsObj.Add('parentSKU',Item[2]."No.");
                JsObj.Add('variantSKU',Item[1]."No.");
                JsObj.Add('parentId',Item[2]."Shopify Product ID");
                JsObj.Add('variantId',Item[1]."Shopify Product Variant ID");
                Jsobj.add('name',Item[2]."Shopify Title");
                Jsobj.add('variantname',Item[1]."Shopify Selling Option 1");
                JsObj.Add('price',Item[1]."Current Price");
                JsObj.Add('rrprice',Item[1]."Current RRP");
                If Item[1]."Gen. Prod. Posting Group" = 'NO GST' then
                    JsObj.Add('taxable',false)
                else
                    JsObj.Add('taxable',true);
                JsObj.Add('barcode',Item[1].GTIN);
                If ItemUnit.get(Item[1]."No.",Item[1]."Base Unit of Measure") then
                    JsObj.Add('weight',ItemUnit.Weight)
                else
                    JsObj.Add('weight',0);
                JsObj.Add('position',ItemRel."Child Position");    
                If ItemRel."Un Publish Child" then
                    JsObj.add('status',0) // unpublish
                else
                    JsObj.add('status',2); // update
                HasData := True;    
                JsArry.add(JsObj);    
            end;           
        until Item[1].next = 0;
        DelTrack.reset;
        If DelTrack.findset then
        repeat
            Clear(JsObj);
            JsObj.Add('parentSKU',DelTrack."Parent SKU");
            JsObj.Add('variantSKU',DelTrack."Child SKU");
            JsObj.Add('parentId',DelTrack."Parent ID");
            JsObj.Add('variantId',DelTrack."Child ID");
            Jsobj.add('name',DelTrack."Parent Name");
            Jsobj.add('variantname',DelTrack."Child Name");
            JsObj.Add('price',DelTrack.Price);
            Item[1].Get(DelTrack."Child SKU");
            JsObj.Add('rrprice',Item[1]."Current RRP");
            If Item[1]."Gen. Prod. Posting Group" = 'NO GST' then
                JsObj.Add('taxable',false)
            else
                JsObj.Add('taxable',true);
            JsObj.Add('barcode',Item[1].GTIN);
            If ItemUnit.get(Item[1]."No.",Item[1]."Base Unit of Measure") then
                JsObj.Add('weight',ItemUnit.Weight)
            else
                JsObj.Add('weight',0);
            JsObj.Add('position',DelTrack.Position);    
            JsObj.add('status',1); // Delete
            JsArry.add(JsObj);    
            HasData := True;    
        Until DelTrack.next = 0;
        Item[1].Reset;
        Item[1].Setrange("Web Service Update Flag",true);
        If Item[1].Findset then Item[1].ModifyAll("Web Service Update Flag",False,False);
        DelTrack.reset;
        If DelTrack.findset then DelTrack.DeleteAll(False);
        If HasData and CU.Set_WebService_Access_Token() then
        begin
            JsArry.WriteTo(PayLoad);
            Clear(JsObj);
            If not CU.Web_Sevice_Data(Paction::POST,Parms,PayLoad,JsObj,Err) then
                Error(Err)
            Else If JsObj.SelectToken('Error',jsToken) then
                Error(jsToken.AsValue().AsText());    
        end;    
    End;
}
