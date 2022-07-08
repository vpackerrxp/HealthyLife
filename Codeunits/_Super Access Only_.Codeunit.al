codeunit 80202 "Super Access Only"
{
    EventSubscriberInstance = StaticAutomatic;

    [EventSubscriber(ObjectType::Table, database::"Bank Account Ledger Entry", 'OnAfterInsertEvent', '', true, true)]
    procedure checksuperaccess()var AcccessControl: Record "Access Control";
    begin
        AcccessControl.setrange("User Security ID", UserSecurityId);
        AcccessControl.setrange("Role ID", 'SUPER');
        if not AcccessControl.FindFirst()then error('You do not have permission to create a bank transaction, Super Permission is required')end;
}
