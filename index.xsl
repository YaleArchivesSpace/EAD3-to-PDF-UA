<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:fo="http://www.w3.org/1999/XSL/Format" xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:fox="http://xmlgraphics.apache.org/fop/extensions"
    xmlns:ead3="http://ead3.archivists.org/schema/" exclude-result-prefixes="xs ead3 fox"
    version="2.0">

    <!-- this file is imported by "ead3-to-pdf-ua.xsl" -->
    <xsl:template match="ead3:archdesc/ead3:index[1]">
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
                    <xsl:apply-templates select="ead3:head"/>
                </fo:block>
                <xsl:apply-templates select="* except ead3:head"/>
                
                <xsl:apply-templates select="* except (ead3:indexentry, ead3:head)"/>
                <!-- need to check and see if EAD3 enforces -->
                <xsl:if test="ead3:indexentry">
                    <fo:list-block start-indent="5mm" provisional-distance-between-starts="35mm">
                        <xsl:apply-templates select="ead3:indexentry"/>
                    </fo:list-block>
                </xsl:if>
                
                <xsl:apply-templates select="../ead3:index[position() gt 1]"/>
                
                <!-- adding this to grab the last page number-->
                <xsl:if test="$last-page eq 'index'">
                    <fo:wrapper id="last-page"/>
                </xsl:if>
            </fo:flow>
        </fo:page-sequence>
    </xsl:template>
    
    <xsl:template match="ead3:archdesc/ead3:index[position() gt 1]">
        <xsl:call-template name="section-start"/>
        <xsl:variable name="id-for-link" select="if (@id) then @id else generate-id(.)"/> 
        <fo:block xsl:use-attribute-sets="h3" id="{@id-for-link}">
            <xsl:apply-templates select="ead3:head"/>
        </fo:block>
        <xsl:apply-templates select="* except (ead3:indexentry, ead3:head)"/>
        <!-- need to check and see if EAD3 enforces -->
        <xsl:if test="ead3:indexentry">
            <fo:list-block start-indent="5mm" provisional-distance-between-starts="35mm">
                <xsl:apply-templates select="ead3:indexentry"/>
            </fo:list-block>
        </xsl:if>
    </xsl:template>
    
    <xsl:template match="ead3:indexentry">
        <!-- gotta update this once i'm online again, with a copy of the schema -->
        <fo:list-item space-after="1em">
            <fo:list-item-label>
                <fo:block>
                    <xsl:apply-templates select="ead3:name"/>
                </fo:block>
            </fo:list-item-label>
            <fo:list-item-body start-indent="body-start()" end-indent="5mm">
                <fo:block>
                    <xsl:apply-templates select="ead3:ref"/>
                </fo:block>
            </fo:list-item-body>
        </fo:list-item>
    </xsl:template>

</xsl:stylesheet>
