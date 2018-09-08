<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:fo="http://www.w3.org/1999/XSL/Format" xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:fox="http://xmlgraphics.apache.org/fop/extensions"
    xmlns:ead3="http://ead3.archivists.org/schema/" exclude-result-prefixes="xs ead3 fox"
    version="2.0">

    <!-- this file is imported by "ead3-to-pdf-ua.xsl" -->

    <!--========== Cover Page ========-->
    <xsl:template match="ead3:control">
        <fo:page-sequence master-reference="cover" xsl:use-attribute-sets="center-text">
            <fo:static-content flow-name="xsl-region-before">
                <fo:block id="cover-page">
                    <xsl:choose>
                        <xsl:when test="$repository-code = ('ypm', 'ycba')">
                            <xsl:text>Yale University</xsl:text>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:text>Yale University Library</xsl:text>
                        </xsl:otherwise>
                    </xsl:choose>
                </fo:block>
                <fo:block xsl:use-attribute-sets="margin-after-large">
                    <xsl:apply-templates select="$holding-repository"/>
                </fo:block>
            </fo:static-content>
            <fo:static-content flow-name="xsl-region-after">
                <!-- use something with rightsdeclaration once we're on EAD3 1.1.0
                in the meantime, i should also add the creative commons license to our PDFs, right? -->
                <fo:block>
                    <xsl:apply-templates select="ead3:maintenancehistory[1]/ead3:maintenanceevent[1]/ead3:eventdatetime[1]" mode="titlepage.pdf.creation.date"/>
                </fo:block>
            </fo:static-content>
            <fo:flow flow-name="xsl-region-body">
                <xsl:if test="$unpublished-draft eq true()">
                    <fo:block xsl:use-attribute-sets="unpublished">
                        <xsl:text>*** UNPUBLISHED DRAFT ***</xsl:text> 
                    </fo:block>
                </xsl:if>
                <fo:block xsl:use-attribute-sets="h1">
                    <xsl:apply-templates select="$finding-aid-title"/>
                </fo:block>
                <fo:block xsl:use-attribute-sets="h2 margin-after-large">
                    <xsl:apply-templates select="$collection-identifier"/>
                </fo:block>
                <xsl:call-template name="coverpage.image"/>
                <fo:block xsl:use-attribute-sets="margin-after-small">
                    <xsl:apply-templates select="$finding-aid-author"/>
                </fo:block>
                <fo:block xsl:use-attribute-sets="margin-after-small">
                    <xsl:apply-templates select="ead3:filedesc/ead3:publicationstmt[1]/ead3:date[1]"/>
                </fo:block>
                <fo:block>
                    <xsl:apply-templates select="ead3:filedesc/ead3:publicationstmt[1]/ead3:address[1]"/>
                </fo:block>
            </fo:flow>
        </fo:page-sequence>
    </xsl:template>
    <!--========== End: Cover Page ======== -->

    <xsl:template name="coverpage.image">
        <fo:block xsl:use-attribute-sets="margin-after-small">
            <xsl:choose>
                <xsl:when test="$repository-code='divinity'">
                    <fo:external-graphic src="url('logos/divshield.jpg')"
                        content-width="scale-to-fit"
                        scaling="uniform"
                        fox:alt-text="Divinity school shield logo"/>
                </xsl:when>
                <xsl:when test="$repository-code='med'">
                    <fo:external-graphic src="url('logos/medshield.jpg')"
                        content-width="scale-to-fit"
                        scaling="uniform"
                        fox:alt-text="Medical school shield logo"/>
                </xsl:when>
                <xsl:when test="$repository-code='beinecke'">
                    <fo:external-graphic src="url('logos/brbl_bldg.jpg')"
                        content-width="scale-to-fit"
                        scaling="uniform"
                        fox:alt-text="A drawing of an exterior view of the Beinecke Library"/>
                </xsl:when>
                <xsl:when test="$repository-code='ypm'">
                    <fo:external-graphic src="url('logos/peabody.jpg')"
                        content-width="scale-to-fit"
                        scaling="uniform"
                        fox:alt-text="A view from outside the Peabody Museum, with a statue of a triceratops horridus in the foreground"/>
                </xsl:when>
                <xsl:when test="$repository-code='lwl'">
                    <fo:external-graphic src="url('logos/walpole-summer.jpg')"
                        content-width="scale-to-fit"
                        scaling="uniform"
                        fox:alt-text="A view of the Lewis Walpole Library, during summertime"/>
                </xsl:when>
                <xsl:when test="$repository-code='ycba'">
                    <fo:external-graphic src="url('logos/ycba.png')"
                        content-width="scale-to-fit"
                        scaling="uniform"
                        fox:alt-text="A view inside the Yale Center for British Art Library. Photograph by Richard Caspole, 2016"/>
                </xsl:when>
                <xsl:otherwise>
                    <fo:external-graphic src="url('logos/Yale_University_Shield_1.svg')"
                        width="70%"
                        content-height="70%"
                        content-width="scale-to-fit"
                        scaling="uniform"
                        fox:alt-text="Yale University logo, with the Lux et Veritas motto"/>
                </xsl:otherwise>
            </xsl:choose>
        </fo:block>
    </xsl:template>

    <xsl:template match="ead3:addressline">
        <fo:block>
            <xsl:apply-templates/>
        </fo:block>
    </xsl:template>

    <xsl:template match="ead3:eventdatetime" mode="titlepage.pdf.creation.date">
        <fo:block font-size="9pt">
            <xsl:text>Last modified at </xsl:text>
            <xsl:value-of select="format-dateTime(xs:dateTime(.), '[h]:[m01] [Pn] on [FNn], [MNn] [D1o], [Y0001]')"/>
        </fo:block>
    </xsl:template>



</xsl:stylesheet>
