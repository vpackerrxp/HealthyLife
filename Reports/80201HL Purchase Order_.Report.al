report 80201 "HL Purchase Order"
{
    DefaultLayout = RDLC;
    RDLCLayout = 'Reports\Report\PurchaseOrder.rdl';
    Caption = 'Order';
    PreviewMode = PrintLayout;

    dataset
    {
        dataitem("Purchase Header";"Purchase Header")
        {
            DataItemTableView = SORTING("Document Type", "No.")WHERE("Document Type"=CONST(Order));
            RequestFilterFields = "No.", "Buy-from Vendor No.", "No. Printed";
            RequestFilterHeading = 'Purchase Order';

            column(OrderNo_Lbl; OrderNoCaptionLbl)
            {
            }
            column(OrderDate_PurchaseHeader; Format("Order Date", 0, 4))
            {
            }
            column(OrderDate_Lbl; OrderDateLbl)
            {
            }
            column(TotalAmountInclVAT; TotalAmountInclVAT)
            {
                AutoFormatExpression = "Purchase Header"."Currency Code";
                AutoFormatType = 1;
            }
            column(DocumentType_PurchHdr;"Document Type")
            {
            }
            column(No_PurchHdr;"No.")
            {
            }
            column(Requested_Receipt_Date;Format("Requested Receipt Date",0,'<day,2>/<month,2>/<year4>'))
            {
            }
            column(AmtCaption;AmtCaptionLbl)
            {
            }
            column(PaymentTermsCaption;PaymentTermsCaptionLbl)
            {
            }
            column(ShpMethodCaption;ShpMethodCaptionLbl)
            {
            }
            column(PrepmtPaymentTermsDescCaption;PrepmtPaymentTermsDescCaptionLbl)
            {
            }
            column(AllowInvDiscCaption;AllowInvDiscCaptionLbl)
            {
            }
            column(BuyFromContactPhoneNoLbl;BuyFromContactPhoneNoLbl)
            {
            }
            column(BuyFromContactMobilePhoneNoLbl;BuyFromContactMobilePhoneNoLbl)
            {
            }
            column(BuyFromContactEmailLbl;BuyFromContactEmailLbl)
            {
            }
            column(PayToContactPhoneNoLbl;PayToContactPhoneNoLbl)
            {
            }
            column(PayToContactMobilePhoneNoLbl;PayToContactMobilePhoneNoLbl)
            {
            }
            column(PayToContactEmailLbl;PayToContactEmailLbl)
            {
            }
            column(BuyFromContactPhoneNo;BuyFromContact."Phone No.")
            {
            }
            column(BuyFromContactMobilePhoneNo;BuyFromContact."Mobile Phone No.")
            {
            }
            column(BuyFromContactEmail;BuyFromContact."E-Mail")
            {
            }
            column(PayToContactPhoneNo;PayToContact."Phone No.")
            {
            }
            column(PayToContactMobilePhoneNo;PayToContact."Mobile Phone No.")
            {
            }
            column(PayToContactEmail;PayToContact."E-Mail")
            {
            }
            dataitem(CopyLoop;"Integer")
            {
                DataItemTableView = SORTING(Number);

                dataitem(PageLoop;"Integer")
                {
                    DataItemTableView = SORTING(Number)WHERE(Number=CONST(1));

                    column(OrderCopyText;StrSubstNo(Text004, CopyText))
                    {
                    }
                    column(CompanyAddr1;CompanyAddr[1])
                    {
                    }
                    column(CompanyAddr2;CompanyAddr[2])
                    {
                    }
                    column(CompanyAddr3;CompanyAddr[3])
                    {
                    }
                    column(CompanyAddr4;CompanyAddr[4])
                    {
                    }
                    column(CompanyInfoPhoneNo;CompanyInfo."Phone No.")
                    {
                    }
                    column(CompanyInfoVATRegNo;CompanyInfo."VAT Registration No.")
                    {
                    }
                    column(CompanyInfoHomePage;CompanyInfo."Home Page")
                    {
                    }
                    column(CompanyInfoEmail;CompanyInfo."E-Mail")
                    {
                    }
                    column(CompanyInfoGiroNo;CompanyInfo."Giro No.")
                    {
                    }
                    column(CompanyInfoBankName;CompanyInfo."Bank Name")
                    {
                    }
                    column(CompanyInfoBankAccNo;CompanyInfo."Bank Account No.")
                    {
                    }
                    column(CompanyAddr5;CompanyAddr[5])
                    {
                    }
                    column(CompanyAddr6;CompanyAddr[6])
                    {
                    }
                    column(BuyFromAddr1;BuyFromAddr[1])
                    {
                    }
                    column(BuyFromAddr2;BuyFromAddr[2])
                    {
                    }
                    column(BuyFromAddr3;BuyFromAddr[3])
                    {
                    }
                    column(BuyFromAddr4;BuyFromAddr[4])
                    {
                    }
                    column(BuyFromAddr5;BuyFromAddr[5])
                    {
                    }
                    column(BuyFromAddr6;BuyFromAddr[6])
                    {
                    }
                    column(BuyFromAddr7;BuyFromAddr[7])
                    {
                    }
                    column(BuyFromAddr8;BuyFromAddr[8])
                    {
                    }
                    column(Ship1;ShipToAddr[1])
                    {
                    }
                    column(Ship2;ShipToAddr[2])
                    {
                    }
                    column(Ship3;ShipToAddr[3])
                    {
                    }
                    column(Ship4;ShipToAddr[4])
                    {
                    }
                    column(Ship5;ShipToAddr[5])
                    {
                    }
                    column(OutputNo;OutputNo)
                    {
                    }
                    column(VATBaseDisc_PurchHdr;"Purchase Header"."VAT Base Discount %")
                    {
                    }
                    column(PricesInclVATtxt;PricesInclVATtxt)
                    {
                    }
                    column(ShowInternalInfo;ShowInternalInfo)
                    {
                    }
                    column(CompanyInfoABNDivPartNo;CompanyInfo."ABN Division Part No.")
                    {
                    }
                    column(CompanyInfoABN;CompanyInfo.ABN)
                    {
                    }
                    column(VATNoText;VATNoText)
                    {
                    }
                    column(VATRegNo_PurchHdr;"Purchase Header"."VAT Registration No.")
                    {
                    }
                    column(BuyfromVendorNo_PurchHdr;"Purchase Header"."Buy-from Vendor No.")
                    {
                    }
                    column(PurchaserText;PurchaserText)
                    {
                    }
                    column(SalesPurchPersonName;SalesPurchPerson.Name)
                    {
                    }
                    column(RefText;ReferenceText)
                    {
                    }
                    column(YourRef_PurchHdr;"Purchase Header"."Your Reference")
                    {
                    }
                    column(DocDate_PurchHdr;Format("Purchase Header"."Document Date", 0, 4))
                    {
                    }
                    column(PricesIncVAT_PurchHdr;"Purchase Header"."Prices Including VAT")
                    {
                    }
                    column(ABN_PurchHdr;"Purchase Header".ABN)
                    {
                    }
                    column(PaymentTermsDesc;PaymentTerms.Description)
                    {
                    }
                    column(ShipmentMethodDesc;ShipmentMethod.Description)
                    {
                    }
                    column(PrepmtPaymentTermsDesc;PrepmtPaymentTerms.Description)
                    {
                    }
                    column(ABNDivPartNo_PurchHdr;"Purchase Header"."ABN Division Part No.")
                    {
                    }
                    column(PhoneNoCaption;PhoneNoCaptionLbl)
                    {
                    }
                    column(VATRegNoCaption;VATRegNoCaptionLbl)
                    {
                    }
                    column(DimText;DimText)
                    {
                    }
                    column(GiroNoCaption;GiroNoCaptionLbl)
                    {
                    }
                    column(BankCaption;BankCaptionLbl)
                    {
                    }
                    column(BankAccNoCaption;BankAccNoCaptionLbl)
                    {
                    }
                    column(PageCaption;PageCaptionLbl)
                    {
                    }
                    column(ABNDivPartNoCaption;ABNDivPartNoCaptionLbl)
                    {
                    }
                    column(ABNCaption;ABNCaptionLbl)
                    {
                    }
                    column(OrderNoCaption;OrderNoCaptionLbl)
                    {
                    }
                    column(DocDateCaption;DocDateCaptionLbl)
                    {
                    }
                    column(HomePageCaption;HomePageCaptionLbl)
                    {
                    }
                    column(EmailCaption;EmailCaptionLbl)
                    {
                    }
                    column(BuyfromVendorNo_PurchHdrCaption;"Purchase Header".FieldCaption("Buy-from Vendor No."))
                    {
                    }
                    column(PricesIncVAT_PurchHdrCaption;"Purchase Header".FieldCaption("Prices Including VAT"))
                    {
                    }
                    dataitem(DimensionLoop1;"Integer")
                    {
                        DataItemLinkReference = "Purchase Header";
                        DataItemTableView = SORTING(Number)WHERE(Number=FILTER(1..));

                        column(HdrDimsCaption;HdrDimsCaptionLbl)
                        {
                        }
                        trigger OnAfterGetRecord()begin
                            if Number = 1 then begin
                                if not DimSetEntry1.FindSet then CurrReport.Break();
                            end
                            else if not Continue then CurrReport.Break();
                            Clear(DimText);
                            Continue:=false;
                            repeat OldDimText:=DimText;
                                if DimText = '' then DimText:=StrSubstNo('%1 %2', DimSetEntry1."Dimension Code", DimSetEntry1."Dimension Value Code")
                                else
                                    DimText:=StrSubstNo('%1, %2 %3', DimText, DimSetEntry1."Dimension Code", DimSetEntry1."Dimension Value Code");
                                if StrLen(DimText) > MaxStrLen(OldDimText)then begin
                                    DimText:=OldDimText;
                                    Continue:=true;
                                    exit;
                                end;
                            until DimSetEntry1.Next = 0;
                        end;
                        trigger OnPreDataItem()begin
                            if not ShowInternalInfo then CurrReport.Break();
                        end;
                    }
                    dataitem("Purchase Line";"Purchase Line")
                    {
                        DataItemLink = "Document Type"=FIELD("Document Type"), "Document No."=FIELD("No.");
                        DataItemLinkReference = "Purchase Header";
                        DataItemTableView = SORTING("Document Type", "Document No.", "Line No.");

                        trigger OnPreDataItem()begin
                            CurrReport.Break();
                        end;
                    }
                    dataitem(RoundLoop;"Integer")
                    {
                        DataItemTableView = SORTING(Number);

                        column(PurchLineLineAmt;PurchLine."Line Amount")
                        {
                        AutoFormatExpression = "Purchase Line"."Currency Code";
                        AutoFormatType = 1;
                        }
                        column(Desc_PurchLine;"Purchase Line".Description)
                        {
                        }
                        //Gerard 
                        /*
                        column(PurchLineCrossRef;"Purchase Line"."Cross-Reference No.")
                        {
                        }
                        column(PurchLineItemRef;"Purchase Line"."Cross-Reference No.")
                        {
                        }
                        */
                        column(PurchLineCrossRef;"Purchase Line"."Item Reference No.")
                        {
                        }
                        column(PurchLineItemRef;"Purchase Line"."Item Reference No.")
                        {
                        }
                       
                        column(LineNo_PurchLine;"Purchase Line"."Line No.")
                        {
                        }
                        column(AllowInvDisctxt;AllowInvDisctxt)
                        {
                        }
                        column(Type_PurchLine;Format("Purchase Line".Type, 0, 2))
                        {
                        }
                        column(No_PurchLine;"Purchase Line"."No.")
                        {
                        }
                        column(Quantity_PurchLine;"Purchase Line".Quantity)
                        {
                        }
                        column(UnitofMeasure_PurchLine;"Purchase Line"."Unit of Measure")
                        {
                        }
                        column(DirectUnitCost_PurchLine;"Purchase Line"."Direct Unit Cost")
                        {
                        AutoFormatExpression = "Purchase Header"."Currency Code";
                        AutoFormatType = 2;
                        }
                        column(LineDisc_PurchLine;"Purchase Line"."Line Discount %")
                        {
                        }
                        column(LineAmt_PurchLine;"Purchase Line"."Line Amount")
                        {
                        AutoFormatExpression = "Purchase Header"."Currency Code";
                        AutoFormatType = 1;
                        }
                        column(AllowInvoiceDisc_PurchLine;"Purchase Line"."Allow Invoice Disc.")
                        {
                        }
                        column(VATIdentifier_PurchLine;"Purchase Line"."VAT Identifier")
                        {
                        }
                        column(PurchLineInvDiscAmt;-PurchLine."Inv. Discount Amount")
                        {
                        AutoFormatExpression = "Purchase Line"."Currency Code";
                        AutoFormatType = 1;
                        }
                        column(TotalText;TotalText)
                        {
                        }
                        column(PurchLineLineAmtInvDiscAmt;PurchLine."Line Amount" - PurchLine."Inv. Discount Amount")
                        {
                        AutoFormatExpression = "Purchase Header"."Currency Code";
                        AutoFormatType = 1;
                        }
                        column(TotalInclVATText;TotalInclVATText)
                        {
                        }
                        column(VATAmtLineVATAmtText;VATAmountLine.VATAmountText)
                        {
                        }
                        column(VATAmt;VATAmount)
                        {
                        AutoFormatExpression = "Purchase Header"."Currency Code";
                        AutoFormatType = 1;
                        }
                        column(TotalExclVATText;TotalExclVATText)
                        {
                        }
                        column(VATDiscAmt;-VATDiscountAmount)
                        {
                        AutoFormatExpression = "Purchase Header"."Currency Code";
                        AutoFormatType = 1;
                        }
                        column(VATBaseAmt;VATBaseAmount)
                        {
                        AutoFormatExpression = "Purchase Header"."Currency Code";
                        AutoFormatType = 1;
                        }
                        column(TotalAmtInclVAT;TotalAmountInclVAT)
                        {
                        AutoFormatExpression = "Purchase Header"."Currency Code";
                        AutoFormatType = 1;
                        }
                        column(TotalSubTotal;TotalSubTotal)
                        {
                        AutoFormatExpression = "Purchase Header"."Currency Code";
                        AutoFormatType = 1;
                        }
                        column(TotalInvoiceDiscAmt;TotalInvoiceDiscountAmount)
                        {
                        AutoFormatExpression = "Purchase Header"."Currency Code";
                        AutoFormatType = 1;
                        }
                        column(TotalAmt;TotalAmount)
                        {
                        AutoFormatExpression = "Purchase Header"."Currency Code";
                        AutoFormatType = 1;
                        }
                        column(DirectUnitCostCaption;DirectUnitCostCaptionLbl)
                        {
                        }
                        column(DiscountPercentCaption;DiscountPercentCaptionLbl)
                        {
                        }
                        column(InvDiscAmtCaption;InvDiscAmtCaptionLbl)
                        {
                        }
                        column(SubtotalCaption;SubtotalCaptionLbl)
                        {
                        }
                        column(VATDiscAmtCaption;VATDiscAmtCaptionLbl)
                        {
                        }
                        column(Desc_PurchLineCaption;"Purchase Line".FieldCaption(Description))
                        {
                        }
                        column(No_PurchLineCaption;"Purchase Line".FieldCaption("No."))
                        {
                        }
                        column(Quantity_PurchLineCaption;"Purchase Line".FieldCaption(Quantity))
                        {
                        }
                        column(UnitofMeasure_PurchLineCaption;"Purchase Line".FieldCaption("Unit of Measure"))
                        {
                        }
                        column(AllowInvoiceDisc_PurchLineCaption;"Purchase Line".FieldCaption("Allow Invoice Disc."))
                        {
                        }
                        column(VATIdentifier_PurchLineCaption;"Purchase Line".FieldCaption("VAT Identifier"))
                        {
                        }
                        dataitem(DimensionLoop2;"Integer")
                        {
                            DataItemTableView = SORTING(Number)WHERE(Number=FILTER(1..));

                            column(LineDimsCaption;LineDimsCaptionLbl)
                            {
                            }
                            trigger OnAfterGetRecord()begin
                                if Number = 1 then begin
                                    if not DimSetEntry2.FindSet then CurrReport.Break();
                                end
                                else if not Continue then CurrReport.Break();
                                Clear(DimText);
                                Continue:=false;
                                repeat OldDimText:=DimText;
                                    if DimText = '' then DimText:=StrSubstNo('%1 %2', DimSetEntry2."Dimension Code", DimSetEntry2."Dimension Value Code")
                                    else
                                        DimText:=StrSubstNo('%1, %2 %3', DimText, DimSetEntry2."Dimension Code", DimSetEntry2."Dimension Value Code");
                                    if StrLen(DimText) > MaxStrLen(OldDimText)then begin
                                        DimText:=OldDimText;
                                        Continue:=true;
                                        exit;
                                    end;
                                until DimSetEntry2.Next = 0;
                            end;
                            trigger OnPreDataItem()begin
                                if not ShowInternalInfo then CurrReport.Break();
                                DimSetEntry2.SetRange("Dimension Set ID", "Purchase Line"."Dimension Set ID");
                            end;
                        }
                        trigger OnAfterGetRecord()begin
                            if Number = 1 then PurchLine.Find('-')
                            else
                                PurchLine.Next;
                            "Purchase Line":=PurchLine;
                            if not "Purchase Header"."Prices Including VAT" and (PurchLine."VAT Calculation Type" = PurchLine."VAT Calculation Type"::"Full VAT")then PurchLine."Line Amount":=0;
                            //if ("Purchase Line"."Cross-Reference No." <> '') and (not ShowInternalInfo) then
                            //    "Purchase Line"."No." := "Purchase Line"."Cross-Reference No.";
                            if(PurchLine.Type = PurchLine.Type::Item)then begin
                                if "Purchase Line"."No." <> '' then begin
                                    item.get("Purchase Line"."No.");
                                    if ItemVendor.get("Purchase Line"."Buy-from Vendor No.", "Purchase Line"."No.", "Purchase Line"."Variant Code")then if ItemVendor."Vendor Item No." <> '' then "Purchase Line"."Item Reference No.":=ItemVendor."Vendor Item No.";
                                    if("Purchase Line"."Item Reference No." = '') and (item."Vendor No." = "Purchase Line"."Buy-from Vendor No.")then "Purchase Line"."Item Reference No.":=item."Vendor Item No.";
                                end;
                            end;
                            if(PurchLine.Type = PurchLine.Type::"G/L Account") and (not ShowInternalInfo)then "Purchase Line"."No.":='';
                            AllowInvDisctxt:=Format("Purchase Line"."Allow Invoice Disc.");
                            TotalSubTotal+="Purchase Line"."Line Amount";
                            TotalInvoiceDiscountAmount-="Purchase Line"."Inv. Discount Amount";
                            TotalAmount+="Purchase Line".Amount;
                        end;
                        trigger OnPostDataItem()begin
                            PurchLine.DeleteAll();
                        end;
                        trigger OnPreDataItem()begin
                            MoreLines:=PurchLine.Find('+');
                            while MoreLines and (PurchLine.Description = '') and (PurchLine."Description 2" = '') and (PurchLine."No." = '') and (PurchLine.Quantity = 0) and (PurchLine.Amount = 0)do MoreLines:=PurchLine.Next(-1) <> 0;
                            if not MoreLines then CurrReport.Break();
                            PurchLine.SetRange("Line No.", 0, PurchLine."Line No.");
                            SetRange(Number, 1, PurchLine.Count);
                        end;
                    }
                    dataitem(VATCounter;"Integer")
                    {
                        DataItemTableView = SORTING(Number);

                        column(VATAmtLineVATBase;VATAmountLine."VAT Base")
                        {
                        AutoFormatExpression = "Purchase Header"."Currency Code";
                        AutoFormatType = 1;
                        }
                        column(VATAmtLineVATAmt;VATAmountLine."VAT Amount")
                        {
                        AutoFormatExpression = "Purchase Header"."Currency Code";
                        AutoFormatType = 1;
                        }
                        column(VATAmtLineLineAmt;VATAmountLine."Line Amount")
                        {
                        AutoFormatExpression = "Purchase Header"."Currency Code";
                        AutoFormatType = 1;
                        }
                        column(VATAmtLineInvDiscBaseAmt;VATAmountLine."Inv. Disc. Base Amount")
                        {
                        AutoFormatExpression = "Purchase Header"."Currency Code";
                        AutoFormatType = 1;
                        }
                        column(VATAmtLineInvoiceDiscAmt;VATAmountLine."Invoice Discount Amount")
                        {
                        AutoFormatExpression = "Purchase Header"."Currency Code";
                        AutoFormatType = 1;
                        }
                        column(VATAmtLineVAT;VATAmountLine."VAT %")
                        {
                        DecimalPlaces = 0: 5;
                        }
                        column(VATAmtLineVATIdentifier;VATAmountLine."VAT Identifier")
                        {
                        }
                        column(VATPercentCaption;VATPercentCaptionLbl)
                        {
                        }
                        column(VATBaseCaption;VATBaseCaptionLbl)
                        {
                        }
                        column(VATAmtCaption;VATAmtCaptionLbl)
                        {
                        }
                        column(VATAmtSpecCaption;VATAmtSpecCaptionLbl)
                        {
                        }
                        column(VATIdentCaption;VATIdentCaptionLbl)
                        {
                        }
                        column(InvDiscBaseAmtCaption;InvDiscBaseAmtCaptionLbl)
                        {
                        }
                        column(LineAmtCaption;LineAmtCaptionLbl)
                        {
                        }
                        column(InvDiscAmt1Caption;InvDiscAmt1CaptionLbl)
                        {
                        }
                        column(TotalCaption;TotalCaptionLbl)
                        {
                        }
                        trigger OnAfterGetRecord()begin
                            VATAmountLine.GetLine(Number);
                        end;
                        trigger OnPreDataItem()begin
                            if VATAmount = 0 then CurrReport.Break();
                            SetRange(Number, 1, VATAmountLine.Count);
                        end;
                    }
                    dataitem(VATCounterLCY;"Integer")
                    {
                        DataItemTableView = SORTING(Number);

                        column(VALExchRate;VALExchRate)
                        {
                        }
                        column(VALSpecLCYHeader;VALSpecLCYHeader)
                        {
                        }
                        column(VALVATAmtLCY;VALVATAmountLCY)
                        {
                        AutoFormatType = 1;
                        }
                        column(VALVATBaseLCY;VALVATBaseLCY)
                        {
                        AutoFormatType = 1;
                        }
                        column(VATAmtLineVAT1;VATAmountLine."VAT %")
                        {
                        DecimalPlaces = 0: 5;
                        }
                        column(VATAmtLineVATIdentifier1;VATAmountLine."VAT Identifier")
                        {
                        }
                        trigger OnAfterGetRecord()begin
                            VATAmountLine.GetLine(Number);
                            VALVATBaseLCY:=VATAmountLine.GetBaseLCY("Purchase Header"."Posting Date", "Purchase Header"."Currency Code", "Purchase Header"."Currency Factor");
                            VALVATAmountLCY:=VATAmountLine.GetAmountLCY("Purchase Header"."Posting Date", "Purchase Header"."Currency Code", "Purchase Header"."Currency Factor");
                        end;
                        trigger OnPreDataItem()begin
                            if(not GLSetup."Print VAT specification in LCY") or ("Purchase Header"."Currency Code" = '') or (VATAmountLine.GetTotalVATAmount = 0)then CurrReport.Break();
                            SetRange(Number, 1, VATAmountLine.Count);
                            Clear(VALVATBaseLCY);
                            Clear(VALVATAmountLCY);
                            if GLSetup."LCY Code" = '' then VALSpecLCYHeader:=Text007 + Text008
                            else
                                VALSpecLCYHeader:=Text007 + Format(GLSetup."LCY Code");
                            CurrExchRate.FindCurrency("Purchase Header"."Posting Date", "Purchase Header"."Currency Code", 1);
                            VALExchRate:=StrSubstNo(Text009, CurrExchRate."Relational Exch. Rate Amount", CurrExchRate."Exchange Rate Amount");
                        end;
                    }
                    dataitem(Total;"Integer")
                    {
                        DataItemTableView = SORTING(Number)WHERE(Number=CONST(1));
                    }
                    dataitem(Total2;"Integer")
                    {
                        DataItemTableView = SORTING(Number)WHERE(Number=CONST(1));

                        column(PaytoVendNo_PurchHdr;"Purchase Header"."Pay-to Vendor No.")
                        {
                        }
                        column(VendAddr8;VendAddr[8])
                        {
                        }
                        column(VendAddr7;VendAddr[7])
                        {
                        }
                        column(VendAddr6;VendAddr[6])
                        {
                        }
                        column(VendAddr5;VendAddr[5])
                        {
                        }
                        column(VendAddr4;VendAddr[4])
                        {
                        }
                        column(VendAddr3;VendAddr[3])
                        {
                        }
                        column(VendAddr2;VendAddr[2])
                        {
                        }
                        column(VendAddr1;VendAddr[1])
                        {
                        }
                        column(PaymentDetailsCaption;PaymentDetailsCaptionLbl)
                        {
                        }
                        column(VendNoCaption;VendNoCaptionLbl)
                        {
                        }
                        trigger OnPreDataItem()begin
                            if "Purchase Header"."Buy-from Vendor No." = "Purchase Header"."Pay-to Vendor No." then CurrReport.Break();
                        end;
                    }
                    dataitem(Total3;"Integer")
                    {
                        DataItemTableView = SORTING(Number)WHERE(Number=CONST(1));

                        column(SelltoCustNo_PurchHdr;"Purchase Header"."Sell-to Customer No.")
                        {
                        }
                        column(ShipToAddr1;ShipToAddr[1])
                        {
                        }
                        column(ShipToAddr2;ShipToAddr[2])
                        {
                        }
                        column(ShipToAddr3;ShipToAddr[3])
                        {
                        }
                        column(ShipToAddr4;ShipToAddr[4])
                        {
                        }
                        column(ShipToAddr5;ShipToAddr[5])
                        {
                        }
                        column(ShipToAddr6;ShipToAddr[6])
                        {
                        }
                        column(ShipToAddr7;ShipToAddr[7])
                        {
                        }
                        column(ShipToAddr8;ShipToAddr[8])
                        {
                        }
                        column(ShiptoAddCaption;ShiptoAddCaptionLbl)
                        {
                        }
                        column(SelltoCustNo_PurchHdrCaption;"Purchase Header".FieldCaption("Sell-to Customer No."))
                        {
                        }
                        trigger OnPreDataItem()begin
                            if("Purchase Header"."Sell-to Customer No." = '') and (ShipToAddr[1] = '')then CurrReport.Break();
                        end;
                    }
                    dataitem(PrepmtLoop;"Integer")
                    {
                        DataItemTableView = SORTING(Number)WHERE(Number=FILTER(1..));

                        column(PrepmtLineAmt;PrepmtLineAmount)
                        {
                        AutoFormatExpression = "Purchase Header"."Currency Code";
                        AutoFormatType = 1;
                        }
                        column(TotalPrepmtLineAmount;TotalPrepmtLineAmount)
                        {
                        }
                        column(PrepmtInvBufGLAccNo;PrepmtInvBuf."G/L Account No.")
                        {
                        }
                        column(PrepmtInvBufDesc;PrepmtInvBuf.Description)
                        {
                        }
                        column(TotalExclVATText1;TotalExclVATText)
                        {
                        }
                        column(PrepmtVATAmtLineVATAmtText;PrepmtVATAmountLine.VATAmountText)
                        {
                        }
                        column(PrepmtVATAmt;PrepmtVATAmount)
                        {
                        AutoFormatExpression = "Purchase Header"."Currency Code";
                        AutoFormatType = 1;
                        }
                        column(TotalInclVATText1;TotalInclVATText)
                        {
                        }
                        column(PrepmtInvBufAmtPrepmtVATAmt;PrepmtInvBuf.Amount + PrepmtVATAmount)
                        {
                        AutoFormatExpression = "Purchase Header"."Currency Code";
                        AutoFormatType = 1;
                        }
                        column(PrepmtTotalAmtInclVAT;PrepmtTotalAmountInclVAT)
                        {
                        AutoFormatExpression = "Purchase Header"."Currency Code";
                        AutoFormatType = 1;
                        }
                        column(Number_IntegerLine;Number)
                        {
                        }
                        column(DescCaption;DescCaptionLbl)
                        {
                        }
                        column(GLAccNoCaption;GLAccNoCaptionLbl)
                        {
                        }
                        column(PrepmtSpecCaption;PrepmtSpecCaptionLbl)
                        {
                        }
                        column(PrepmtLoopLineNo;PrepmtLoopLineNo)
                        {
                        }
                        dataitem(PrepmtDimLoop;"Integer")
                        {
                            DataItemTableView = SORTING(Number)WHERE(Number=FILTER(1..));

                            column(DummyColumn;0)
                            {
                            }
                            trigger OnAfterGetRecord()begin
                                if Number = 1 then begin
                                    if not PrepmtDimSetEntry.FindSet then CurrReport.Break();
                                end
                                else if not Continue then CurrReport.Break();
                                Clear(DimText);
                                Continue:=false;
                                repeat OldDimText:=DimText;
                                    if DimText = '' then DimText:=StrSubstNo('%1 %2', PrepmtDimSetEntry."Dimension Code", PrepmtDimSetEntry."Dimension Value Code")
                                    else
                                        DimText:=StrSubstNo('%1, %2 %3', DimText, PrepmtDimSetEntry."Dimension Code", PrepmtDimSetEntry."Dimension Value Code");
                                    if StrLen(DimText) > MaxStrLen(OldDimText)then begin
                                        DimText:=OldDimText;
                                        Continue:=true;
                                        exit;
                                    end;
                                until PrepmtDimSetEntry.Next = 0;
                            end;
                            trigger OnPreDataItem()begin
                                if not ShowInternalInfo then CurrReport.Break();
                                PrepmtDimSetEntry.SetRange("Dimension Set ID", PrepmtInvBuf."Dimension Set ID");
                            end;
                        }
                        trigger OnAfterGetRecord()begin
                            if Number = 1 then begin
                                if not PrepmtInvBuf.Find('-')then CurrReport.Break();
                            end
                            else if PrepmtInvBuf.Next = 0 then CurrReport.Break();
                            if "Purchase Header"."Prices Including VAT" then PrepmtLineAmount:=PrepmtInvBuf."Amount Incl. VAT"
                            else
                                PrepmtLineAmount:=PrepmtInvBuf.Amount;
                            PrepmtLoopLineNo+=1;
                            TotalPrepmtLineAmount+=PrepmtLineAmount;
                        end;
                        trigger OnPreDataItem()begin
                            PrepmtLoopLineNo:=0;
                            TotalPrepmtLineAmount:=0;
                        end;
                    }
                    dataitem(PrepmtVATCounter;"Integer")
                    {
                        DataItemTableView = SORTING(Number);

                        column(PrepmtVATAmtLineVATAmt;PrepmtVATAmountLine."VAT Amount")
                        {
                        AutoFormatExpression = "Purchase Header"."Currency Code";
                        AutoFormatType = 1;
                        }
                        column(PrepmtVATAmtLineVATBase;PrepmtVATAmountLine."VAT Base")
                        {
                        AutoFormatExpression = "Purchase Header"."Currency Code";
                        AutoFormatType = 1;
                        }
                        column(PrepmtVATAmtLineLineAmt;PrepmtVATAmountLine."Line Amount")
                        {
                        AutoFormatExpression = "Purchase Header"."Currency Code";
                        AutoFormatType = 1;
                        }
                        column(PrepmtVATAmtLineVAT;PrepmtVATAmountLine."VAT %")
                        {
                        DecimalPlaces = 0: 5;
                        }
                        column(PrepmtVATAmtLineVATIdentifier;PrepmtVATAmountLine."VAT Identifier")
                        {
                        }
                        column(PrepmtVATAmtSpecCaption;PrepmtVATAmtSpecCaptionLbl)
                        {
                        }
                        trigger OnAfterGetRecord()begin
                            PrepmtVATAmountLine.GetLine(Number);
                        end;
                        trigger OnPreDataItem()begin
                            SetRange(Number, 1, PrepmtVATAmountLine.Count);
                        end;
                    }
                    dataitem(PrepmtTotal;"Integer")
                    {
                        DataItemTableView = SORTING(Number)WHERE(Number=CONST(1));

                        trigger OnPreDataItem()begin
                            if not PrepmtInvBuf.Find('-')then CurrReport.Break();
                        end;
                    }
                }
                trigger OnAfterGetRecord()var PrepmtPurchLine: Record "Purchase Line" temporary;
                TempPurchLine: Record "Purchase Line" temporary;
                begin
                    Clear(PurchLine);
                    Clear(PurchPost);
                    PurchLine.DeleteAll();
                    VATAmountLine.DeleteAll();
                    PurchPost.GetPurchLines("Purchase Header", PurchLine, 0);
                    PurchLine.CalcVATAmountLines(0, "Purchase Header", PurchLine, VATAmountLine);
                    PurchLine.UpdateVATOnLines(0, "Purchase Header", PurchLine, VATAmountLine);
                    VATAmount:=VATAmountLine.GetTotalVATAmount;
                    VATBaseAmount:=VATAmountLine.GetTotalVATBase;
                    VATDiscountAmount:=VATAmountLine.GetTotalVATDiscount("Purchase Header"."Currency Code", "Purchase Header"."Prices Including VAT");
                    TotalAmountInclVAT:=VATAmountLine.GetTotalAmountInclVAT;
                    PrepmtInvBuf.DeleteAll();
                    PurchPostPrepmt.GetPurchLines("Purchase Header", 0, PrepmtPurchLine);
                    if not PrepmtPurchLine.IsEmpty then begin
                        PurchPostPrepmt.GetPurchLinesToDeduct("Purchase Header", TempPurchLine);
                        if not TempPurchLine.IsEmpty then PurchPostPrepmt.CalcVATAmountLines("Purchase Header", TempPurchLine, PrePmtVATAmountLineDeduct, 1);
                    end;
                    PurchPostPrepmt.CalcVATAmountLines("Purchase Header", PrepmtPurchLine, PrepmtVATAmountLine, 0);
                    PrepmtVATAmountLine.DeductVATAmountLine(PrePmtVATAmountLineDeduct);
                    PurchPostPrepmt.UpdateVATOnLines("Purchase Header", PrepmtPurchLine, PrepmtVATAmountLine, 0);
                    PurchPostPrepmt.BuildInvLineBuffer("Purchase Header", PrepmtPurchLine, 0, PrepmtInvBuf);
                    PrepmtVATAmount:=PrepmtVATAmountLine.GetTotalVATAmount;
                    PrepmtVATBaseAmount:=PrepmtVATAmountLine.GetTotalVATBase;
                    PrepmtTotalAmountInclVAT:=PrepmtVATAmountLine.GetTotalAmountInclVAT;
                    if Number > 1 then CopyText:=FormatDocument.GetCOPYText;
                    OutputNo:=OutputNo + 1;
                    TotalSubTotal:=0;
                    TotalAmount:=0;
                end;
                trigger OnPostDataItem()begin
                    if not IsReportInPreviewMode then CODEUNIT.Run(CODEUNIT::"Purch.Header-Printed", "Purchase Header");
                end;
                trigger OnPreDataItem()begin
                    NoOfLoops:=Abs(NoOfCopies) + 1;
                    CopyText:='';
                    SetRange(Number, 1, NoOfLoops);
                    OutputNo:=0;
                end;
            }
            trigger OnAfterGetRecord()begin
                CurrReport.Language:=Language.GetLanguageIdOrDefault("Language Code");
                FormatAddressFields("Purchase Header");
                FormatDocumentFields("Purchase Header");
                if BuyFromContact.Get("Buy-from Contact No.")then;
                if PayToContact.Get("Pay-to Contact No.")then;
                PricesInclVATtxt:=Format("Prices Including VAT");
                DimSetEntry1.SetRange("Dimension Set ID", "Dimension Set ID");
                if not IsReportInPreviewMode then if ArchiveDocument then ArchiveManagement.StorePurchDocument("Purchase Header", LogInteraction);
            end;
            trigger OnPostDataItem()begin
                OnAfterPostDataItem("Purchase Header");
            end;
        }
    }
    requestpage
    {
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';

                    field(NoofCopies;NoOfCopies)
                    {
                        ApplicationArea = Suite;
                        Caption = 'No. of Copies';
                        ToolTip = 'Specifies how many copies of the document to print.';
                    }
                    field(ShowInternalInformation;ShowInternalInfo)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Show Internal Information';
                        ToolTip = 'Specifies if you want the printed report to show information that is only for internal use.';
                    }
                    field(ArchiveDocument;ArchiveDocument)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Archive Document';
                        ToolTip = 'Specifies whether to archive the order.';

                        trigger OnValidate()begin
                            if not ArchiveDocument then LogInteraction:=false;
                        end;
                    }
                    field(LogInteraction;LogInteraction)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Log Interaction';
                        Enabled = LogInteractionEnable;
                        ToolTip = 'Specifies if you want the program to log this interaction.';

                        trigger OnValidate()begin
                            if LogInteraction then ArchiveDocument:=ArchiveDocumentEnable;
                        end;
                    }
                }
            }
        }
        actions
        {
        }
        trigger OnInit()begin
            LogInteractionEnable:=true;
            ArchiveDocument:=PurchSetup."Archive Orders";
        end;
        trigger OnOpenPage()begin
            InitLogInteraction;
            LogInteractionEnable:=LogInteraction;
        end;
    }
    labels
    {
    }
    trigger OnInitReport()
    var
        RLS:record "Report Layout Selection";
    begin
        GLSetup.Get();
        CompanyInfo.Get();
        PurchSetup.Get();
        //RLS.SetTempLayoutSelected();
        OnAfterInitReport;
    end;
    trigger OnPostReport()begin
        if LogInteraction and not IsReportInPreviewMode then if "Purchase Header".FindSet then repeat "Purchase Header".CalcFields("No. of Archived Versions");
                    SegManagement.LogDocument(13, "Purchase Header"."No.", "Purchase Header"."Doc. No. Occurrence", "Purchase Header"."No. of Archived Versions", DATABASE::Vendor, "Purchase Header"."Buy-from Vendor No.", "Purchase Header"."Purchaser Code", '', "Purchase Header"."Posting Description", '');
                until "Purchase Header".Next = 0;
    end;
    trigger OnPreReport()begin
        if not CurrReport.UseRequestPage then InitLogInteraction;
    end;
    var Text004: Label 'Order %1', Comment='%1 = Document No.';
    GLSetup: Record "General Ledger Setup";
    CompanyInfo: Record "Company Information";
    ShipmentMethod: Record "Shipment Method";
    PaymentTerms: Record "Payment Terms";
    PrepmtPaymentTerms: Record "Payment Terms";
    SalesPurchPerson: Record "Salesperson/Purchaser";
    VATAmountLine: Record "VAT Amount Line" temporary;
    PrepmtVATAmountLine: Record "VAT Amount Line" temporary;
    PrePmtVATAmountLineDeduct: Record "VAT Amount Line" temporary;
    PurchLine: Record "Purchase Line" temporary;
    DimSetEntry1: Record "Dimension Set Entry";
    DimSetEntry2: Record "Dimension Set Entry";
    PrepmtDimSetEntry: Record "Dimension Set Entry";
    PrepmtInvBuf: Record "Prepayment Inv. Line Buffer" temporary;
    RespCenter: Record "Responsibility Center";
    CurrExchRate: Record "Currency Exchange Rate";
    PurchSetup: Record "Purchases & Payables Setup";
    BuyFromContact: Record Contact;
    PayToContact: Record Contact;
    Item: Record Item;
    ItemVendor: Record "Item Vendor";
    Language: Codeunit Language;
    FormatAddr: Codeunit "Format Address";
    FormatDocument: Codeunit "Format Document";
    PurchPost: Codeunit "Purch.-Post";
    ArchiveManagement: Codeunit ArchiveManagement;
    SegManagement: Codeunit SegManagement;
    PurchPostPrepmt: Codeunit "Purchase-Post Prepayments";
    VendAddr: array[8]of Text[100];
    ShipToAddr: array[8]of Text[100];
    CompanyAddr: array[8]of Text[100];
    BuyFromAddr: array[8]of Text[100];
    PurchaserText: Text[30];
    VATNoText: Text[80];
    ReferenceText: Text[80];
    TotalText: Text[50];
    TotalInclVATText: Text[50];
    TotalExclVATText: Text[50];
    MoreLines: Boolean;
    NoOfCopies: Integer;
    NoOfLoops: Integer;
    CopyText: Text[30];
    OutputNo: Integer;
    DimText: Text[120];
    OldDimText: Text[75];
    ShowInternalInfo: Boolean;
    Continue: Boolean;
    ArchiveDocument: Boolean;
    LogInteraction: Boolean;
    VATAmount: Decimal;
    VATBaseAmount: Decimal;
    VATDiscountAmount: Decimal;
    TotalAmountInclVAT: Decimal;
    VALVATBaseLCY: Decimal;
    VALVATAmountLCY: Decimal;
    VALSpecLCYHeader: Text[80];
    VALExchRate: Text[50];
    Text007: Label 'VAT Amount Specification in ';
    Text008: Label 'Local Currency';
    Text009: Label 'Exchange rate: %1/%2';
    PrepmtVATAmount: Decimal;
    PrepmtVATBaseAmount: Decimal;
    PrepmtTotalAmountInclVAT: Decimal;
    PrepmtLineAmount: Decimal;
    PricesInclVATtxt: Text[30];
    AllowInvDisctxt: Text[30];
    [InDataSet]
    ArchiveDocumentEnable: Boolean;
    [InDataSet]
    LogInteractionEnable: Boolean;
    TotalSubTotal: Decimal;
    TotalAmount: Decimal;
    TotalInvoiceDiscountAmount: Decimal;
    OrderDateLbl: Label 'Order Date';
    PhoneNoCaptionLbl: Label 'Phone No.';
    VATRegNoCaptionLbl: Label 'VAT Registration No.';
    GiroNoCaptionLbl: Label 'Giro No.';
    BankCaptionLbl: Label 'Bank';
    BankAccNoCaptionLbl: Label 'Account No.';
    PageCaptionLbl: Label 'Page';
    ABNDivPartNoCaptionLbl: Label 'Division Part No.';
    ABNCaptionLbl: Label 'ABN';
    OrderNoCaptionLbl: Label 'Order No.';
    DocDateCaptionLbl: Label 'Document Date';
    HomePageCaptionLbl: Label 'Home Page';
    EmailCaptionLbl: Label 'Email';
    HdrDimsCaptionLbl: Label 'Header Dimensions';
    DirectUnitCostCaptionLbl: Label 'Direct Unit Cost';
    DiscountPercentCaptionLbl: Label 'Discount %';
    InvDiscAmtCaptionLbl: Label 'Invoice Discount Amount';
    SubtotalCaptionLbl: Label 'Subtotal';
    VATDiscAmtCaptionLbl: Label 'Payment Discount on VAT';
    LineDimsCaptionLbl: Label 'Line Dimensions';
    VATPercentCaptionLbl: Label 'VAT %';
    VATBaseCaptionLbl: Label 'VAT Base';
    VATAmtCaptionLbl: Label 'VAT Amount';
    VATAmtSpecCaptionLbl: Label 'VAT Amount Specification';
    VATIdentCaptionLbl: Label 'VAT Identifier';
    InvDiscBaseAmtCaptionLbl: Label 'Invoice Discount Base Amount';
    LineAmtCaptionLbl: Label 'Line Amount';
    InvDiscAmt1CaptionLbl: Label 'Invoice Discount Amount';
    TotalCaptionLbl: Label 'Total';
    PaymentDetailsCaptionLbl: Label 'Payment Details';
    VendNoCaptionLbl: Label 'Vendor No.';
    ShiptoAddCaptionLbl: Label 'Ship-to Address';
    DescCaptionLbl: Label 'Description';
    GLAccNoCaptionLbl: Label 'G/L Account No.';
    PrepmtSpecCaptionLbl: Label 'Prepayment Specification';
    PrepmtVATAmtSpecCaptionLbl: Label 'Prepayment VAT Amount Specification';
    AmtCaptionLbl: Label 'Amount';
    PaymentTermsCaptionLbl: Label 'Payment Terms';
    ShpMethodCaptionLbl: Label 'Shipment Method';
    PrepmtPaymentTermsDescCaptionLbl: Label 'Prepayment Payment Terms';
    AllowInvDiscCaptionLbl: Label 'Allow Invoice Discount';
    BuyFromContactPhoneNoLbl: Label 'Buy-from Contact Phone No.';
    BuyFromContactMobilePhoneNoLbl: Label 'Buy-from Contact Mobile Phone No.';
    BuyFromContactEmailLbl: Label 'Buy-from Contact E-Mail';
    PayToContactPhoneNoLbl: Label 'Pay-to Contact Phone No.';
    PayToContactMobilePhoneNoLbl: Label 'Pay-to Contact Mobile Phone No.';
    PayToContactEmailLbl: Label 'Pay-to Contact E-Mail';
    PrepmtLoopLineNo: Integer;
    TotalPrepmtLineAmount: Decimal;
    procedure InitializeRequest(NewNoOfCopies: Integer;
    NewShowInternalInfo: Boolean;
    NewArchiveDocument: Boolean;
    NewLogInteraction: Boolean)begin
        NoOfCopies:=NewNoOfCopies;
        ShowInternalInfo:=NewShowInternalInfo;
        ArchiveDocument:=NewArchiveDocument;
        LogInteraction:=NewLogInteraction;
    end;
    local procedure IsReportInPreviewMode(): Boolean var MailManagement: Codeunit "Mail Management";
    begin
        exit(CurrReport.Preview or MailManagement.IsHandlingGetEmailBody);
    end;
    local procedure InitLogInteraction()begin
        LogInteraction:=SegManagement.FindInteractTmplCode(13) <> '';
    end;
    local procedure FormatAddressFields(var PurchaseHeader: Record "Purchase Header")begin
        FormatAddr.GetCompanyAddr(PurchaseHeader."Responsibility Center", RespCenter, CompanyInfo, CompanyAddr);
        FormatAddr.PurchHeaderBuyFrom(BuyFromAddr, PurchaseHeader);
        if PurchaseHeader."Buy-from Vendor No." <> PurchaseHeader."Pay-to Vendor No." then FormatAddr.PurchHeaderPayTo(VendAddr, PurchaseHeader);
        FormatAddr.PurchHeaderShipTo(ShipToAddr, PurchaseHeader);
    end;
    local procedure FormatDocumentFields(PurchaseHeader: Record "Purchase Header")begin
        // with PurchaseHeader do begin GS 05/11/2020
        FormatDocument.SetTotalLabels(PurchaseHeader."Currency Code", TotalText, TotalInclVATText, TotalExclVATText);
        FormatDocument.SetPurchaser(SalesPurchPerson, PurchaseHeader."Purchaser Code", PurchaserText);
        FormatDocument.SetPaymentTerms(PaymentTerms, PurchaseHeader."Payment Terms Code", PurchaseHeader."Language Code");
        FormatDocument.SetPaymentTerms(PrepmtPaymentTerms, PurchaseHeader."Prepmt. Payment Terms Code", PurchaseHeader."Language Code");
        FormatDocument.SetShipmentMethod(ShipmentMethod, PurchaseHeader."Shipment Method Code", PurchaseHeader."Language Code");
        ReferenceText:=FormatDocument.SetText(PurchaseHeader."Your Reference" <> '', PurchaseHeader.FieldCaption("Your Reference"));
        VATNoText:=FormatDocument.SetText(PurchaseHeader."VAT Registration No." <> '', PurchaseHeader.FieldCaption("VAT Registration No."));
    //end;
    end;
    [IntegrationEvent(TRUE, false)]
    local procedure OnAfterInitReport()begin
    end;
    [IntegrationEvent(TRUE, false)]
    local procedure OnAfterPostDataItem(var PurchaseHeader: Record "Purchase Header")begin
    end;
}
