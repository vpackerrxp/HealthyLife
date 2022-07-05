pageextension 80008 "HL Purchase Header Ext" extends "Purchase Order"
{
    PromotedActionCategoriesML = ENU = 'New,Process,Report,Approve,Release,Posting,Prepare,Order,Request Approval,Print/Send,Navigate,Healthy Life',
                                 ENA = 'New,Process,Report,Approve,Release,Posting,Prepare,Order,Request Approval,Print/Send,Navigate,Healthy Life';

    layout
    {
        addafter(Status)
        {
            field("Order Type"; rec."Order Type")
            {
                ApplicationArea = All;
            }
            field("NPF ASN Status"; rec."NPF ASN Status")
            {
                ApplicationArea = All;
                Style = Strong;
                Editable = flg;
            }
        }
        
       /* addafter("Requested Receipt Date")
        {
            field("Requested Receipt Time";rec."Requested Receipt Time")
            {
                ApplicationArea = All;
            }
        }*/
        
     }
    actions
    {
        addafter(Invoices)
        {
            Group("Healthy Life")
            {
                action(Mg1)
                {
                    ApplicationArea = all;
                    Caption = 'Manage NPF ASN';
                    Image = Change;
                    Promoted = true;
                    PromotedCategory = Category12;
                    ToolTip = 'Manages NPF ASN Status';
                    trigger OnAction()
                    var
                        cu:Codeunit "HL NPF Routines";
                        Corr:Record "HL Purchase Corrections";
                        Pg:Page "HL Purchase Corrections";
                    begin
                        If (rec."Order Type" = rec."Order Type"::NPF) AND (rec.Status = rec.Status::Released) then
                        begin 
                            Case StrMenu('Create NPF ASN,Update NPF ASN,Check NPF ASN Status',1) of
                                1:
                                begin
                                    If rec."NPF ASN Status"  = rec."NPF ASN Status"::" " then
                                    begin
                                        If Confirm(StrSubstNo('Create NPF ASN For Location %1 Now?',rec."Location Code"),True) then
                                        Begin
                                            If Cu.Create_Update_ASN(Rec) then
                                                Message('NPF ASN Creation Successfull')
                                            else
                                                Message('NPF ASN Creation UnSuccessfull');
                                        End;
                                    end    
                                    else
                                        message('Invalid NPF ASN Status for ASN Creation');            
                                end;
                                2:
                                begin
                                    If rec."NPF ASN Status" = rec."NPF ASN Status"::PENDING then
                                    begin                            
                                        If Confirm(StrSubstNo('Update ASN For Location %1 Now?',rec."Location Code"),True) then
                                        Begin
                                            If Cu.Create_Update_ASN(rec) then
                                                Message('NPF ASN Update Successfull')
                                            else
                                                Message('NPF ASN Update UnSuccessfull');
                                        End;
                                    end    
                                    else
                                       message('NPF Update ASN is only valid for NPF ASN Status Pending');            
                                end;
                                3:
                                begin
                                    If rec."NPF ASN Status" <> rec."NPF ASN Status"::" " then
                                    begin                 
                                        If Confirm(StrSubstNo('Check NPF ASN Status For Location %1 Now?',rec."Location Code"),True) then
                                        Begin
                                            If Cu.Get_ASN_Receipts(Rec,True) then
                                            begin
                                                If rec."NPF ASN Status" in [rec."NPF ASN Status"::RECEIVED,rec."NPF ASN Status"::"RECEIVED WITH DISCREPANCIES"] then
                                                begin
                                                    Corr.reset;
                                                    Corr.Setrange(User,USERID);
                                                    If Corr.findset then
                                                    begin
                                                        Pg.SetTableView(Corr);
                                                        Pg.RunModal();
                                                    end;
                                                end    
                                                else      
                                                     Message('Check NPF ASN Status Successfull');
                                            end    
                                            else
                                                Message('Check NPF ASN UnSuccessfull');
                                        End;
                                    end    
                                    else
                                        message('NPF ASN Status Blank is Invalid for NPF Check ASN Status');            
                                end;
                            end
                        end    
                        else
                            message('Only Valid For Released Orders of Type NPF');
                    end;                
                }    
                 action(Msg2)
                {
                    ApplicationArea = All;
                    Caption = 'Access NPF ASN Status';
                    Image = Change;
                    Promoted = true;
                    PromotedCategory = Category12;
                    trigger OnAction()
                    begin
                        Case StrMenu('Enabled Access,Disable Access',1) of
                            1:Flg := true;
                            2:Clear(Flg);
                        end;
                        CurrPage.Update(false);
                    end;
                }
            }
        }
    }
    trigger OnOpenPage()
    begin
        Clear(flg);
    end;
    var
        flg:Boolean;
}