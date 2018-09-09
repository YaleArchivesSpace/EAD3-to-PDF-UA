<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:fo="http://www.w3.org/1999/XSL/Format" xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:fox="http://xmlgraphics.apache.org/fop/extensions"
    xmlns:ead3="http://ead3.archivists.org/schema/" exclude-result-prefixes="xs ead3 fox"
    version="2.0">

    <!-- this file is imported by "ead3-to-pdf-ua.xsl" -->
    <xsl:template match="ead3:archdesc/ead3:odd[matches(lower-case(normalize-space(ead3:head)), $odd-headings-to-add-at-end)][1]">
        <fo:page-sequence master-reference="index">
            <!-- Page header -->
            <fo:static-content flow-name="xsl-region-before" role="artifact">
                <xsl:call-template name="header-right"/>
            </fo:static-content>
            <!-- Page footer-->
            <fo:static-content flow-name="xsl-region-after" role="artifact">
                <xsl:call-template name="footer"/>
            </fo:static-content>
            <fo:flow flow-name="xsl-region-body">
                <xsl:call-template name="section-start"/>
                <xsl:variable name="id-for-link" select="if (@id) then @id else generate-id(.)"/>
                <fo:block xsl:use-attribute-sets="h3" id="{@id-for-link}">
                    <xsl:if test="@audience='internal' and $suppressInternalComponents eq false()">
                        <xsl:attribute name="border-style">solid</xsl:attribute>
                        <xsl:attribute name="border-width">2px</xsl:attribute>
                        <xsl:attribute name="border-color">red</xsl:attribute>
                    </xsl:if>
                    <xsl:apply-templates select="ead3:head"/>
                </fo:block>
                <xsl:apply-templates select="* except ead3:head"/>
                <xsl:apply-templates select="../ead3:odd[matches(lower-case(normalize-space(ead3:head)), $odd-headings-to-add-at-end)][position() gt 1]"/>
                <!-- adding this to grab the last page number-->
                <xsl:if test="$last-page eq 'odd-index'">
                    <fo:wrapper id="last-page"/>
                </xsl:if>
            </fo:flow>
        </fo:page-sequence>
    </xsl:template>

    <xsl:template match="ead3:archdesc/ead3:odd[matches(lower-case(normalize-space(ead3:head)), $odd-headings-to-add-at-end)][position() gt 1]">
        <xsl:call-template name="section-start"/>
        <xsl:variable name="id-for-link" select="if (@id) then @id else generate-id(.)"/>
        <fo:block xsl:use-attribute-sets="h3" id="{@id-for-link}">
            <xsl:if test="@audience='internal' and $suppressInternalComponents eq false()">
                <xsl:attribute name="border-style">solid</xsl:attribute>
                <xsl:attribute name="border-width">2px</xsl:attribute>
                <xsl:attribute name="border-color">red</xsl:attribute>
            </xsl:if>
            <xsl:apply-templates select="ead3:head"/>
        </fo:block>
        <xsl:apply-templates select="* except ead3:head"/>
    </xsl:template>

</xsl:stylesheet>
