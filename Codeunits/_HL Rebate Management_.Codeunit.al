codeunit 80201 "HL Rebate Management"
{
    [EventSubscriber(ObjectType::Table, Database::"Purchase Line", 'OnAfterAssignItemValues', '', false, false)]
    local procedure OnAfterAssignItemValues(var PurchLine: Record "Purchase Line";
    Item: Record Item;
    CurrentFieldNo: Integer);
    begin
    // PurchLine."Indirect Cost %" := -10;
    end;
}
