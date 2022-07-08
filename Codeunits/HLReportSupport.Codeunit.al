codeunit 80200 HLReportSupport
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::ReportManagement, 'OnAfterSubstituteReport', '', false, false)]
    local procedure OnSubstituteReport(ReportId: Integer;var NewReportId: Integer)
    begin
        Case ReportID of // Sales Invoice
        206: NewReportId:=80204;
        // Remittance Advice
        399: NewReportId:=80200;
        //Purchase Order
        405: NewReportId:=80201;
        //Purchase Credit Note
        407: NewReportId:=80203;
        //Purchase Return Order
        6641: NewReportId:=80202;
        //Remittance advise Ledger Entries
        400: NewReportId:=80205;
        end;
    end;
}
