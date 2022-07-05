pageextension 80009 "HL Purchase Order List Ext" extends "Purchase Order List"
{
    PromotedActionCategoriesML = ENU = 'New,Process,Report,Request Approval,Print/Send,Order,Release,Posting,Navigate,Healthy Life',
                                 ENA = 'New,Process,Report,Request Approval,Print/Send,Order,Release,Posting,Navigate,Healthy Life';

    layout
    {
        addafter("Buy-from Vendor Name")
        {
            field("Order Type"; rec."Order Type")
            {
                ApplicationArea = All;
            }
            field("NPF ASN Status"; rec."NPF ASN Status")
            {
                ApplicationArea = All;
            }
         }
    }
    actions
    {
        addafter("P&osting")
        {
            Group("Healthy Life")
            {
                Action(Msg1)
                {
                    ApplicationArea = all;
                    Caption = 'Import Purchase Order';
                    Image = Change;
                    Promoted = true;
                    PromotedCategory = Category10;
                    ToolTip = 'Imports/Build Purchase Orders';
                    trigger OnAction()
                    var
                        Instrm:InStream;
                        FileName:Text;
                        SkipCnt:integer;
                        data:Text;
                        PurchHdr:record "Purchase Header";
                        Disc:Decimal;
                        LineNo:integer;
                        Pg:Page "Purchase Order";
                        win:dialog;
                        CU:Codeunit "HL Import Export Routines";
                    begin
                        if Confirm('Import/Build Purchase Order Now?',True) then
                        begin
                            Clear(SkipCnt);
                            Clear(lineNo);
                            Clear(PurchHdr);
                            if File.UploadIntoStream('Purchase Order Import','','',FileName,Instrm) then
                            Begin
                                Win.Open('Importing SKU #1###########');
                                While Not Instrm.EOS  do
                                begin
                                    SkipCnt +=1;
                                    Instrm.ReadText(Data);
                                    If SkipCnt = 2 then Cu.Build_Import_PO_Header(PurchHdr,DATA,Disc);
                                    If SkipCnt > 3 then Cu.Build_Import_PO_Lines(PurchHdr,DATA,Disc,LineNo,Win);
                                end;
                                win.close;
                                Commit;
                                If PurchHdr."No." <> '' then
                                begin 
                                    Pg.SetRecord(PurchHdr);
                                    Pg.RunModal();
                                end;    
                            end;
                        end;
                    end;            
                } 
/*                Action(Msg2)
                {
                    ApplicationArea = all;
                    Caption = 'Supplier Rebates';
                    Image = Change;
                    Promoted = true;
                    PromotedCategory = Category10;
                    ToolTip = 'Supplier Brand Rebate Maintenance';
                    trigger OnAction()
                    var
                        Pg:Page "HL Supplier Brand Rebates";
                    begin
                        Pg.Set_Page_Mode(0,'');
                        Pg.RunModal();     
                    end;  
                }    
                Action(MsgA)
                {
                    ApplicationArea = all;
                    Caption = 'PO Line Disc %';
                    Image = Change;
                    Promoted = true;
                    PromotedCategory = Category10;
                    ToolTip = 'PO Line Disc % Maintenance';
                    trigger OnAction()
                    var
                        Pg:Page "HL Supplier Brand Rebates";
                    begin
                        Pg.Set_Page_Mode(3,'');
                        Pg.RunModal();     
                    end;  
                }    
                Action(MsgB)
                {
                    ApplicationArea = all;
                    Caption = 'Cost Analysis';
                    Image = Change;
                    Promoted = true;
                    PromotedCategory = Category7;
                    ToolTip = 'Product Cost Analysis';
                    RunObject = PAGE "HL Cost Analysis";
                }*/    
                action(Msg3)
                {
                    ApplicationArea = all;
                    Caption = 'Manage NPF ASN';
                    Image = Change;
                    Promoted = true;
                    PromotedCategory = Category10;
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
                                        If Confirm(StrSubstNo('Update NPF ASN For Location %1 Now?',rec."Location Code"),True) then
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
                Action(Msg4)
                {
                    ApplicationArea = all;
                    Caption = 'Purchase Order Exceptions';
                    Image = Change;
                    Promoted = true;
                    PromotedCategory = Category10;
                    ToolTip = 'Purchase Order Exceptions';
                    RunObject = Page "HL Purch. Order Exceptions";
                }
            }    
        }
    }
}    