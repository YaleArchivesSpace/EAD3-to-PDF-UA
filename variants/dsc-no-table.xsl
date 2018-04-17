<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:fo="http://www.w3.org/1999/XSL/Format" xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:fox="http://xmlgraphics.apache.org/fop/extensions"
    xmlns:ead3="http://ead3.archivists.org/schema/" exclude-result-prefixes="xs ead3 fox"
    version="2.0">

    <!-- this file is imported by "ead3-to-pdf-ua.xsl" -->
    
    <!-- to do:
        change so that the only thing in tables are files/items with containers ?
        
        everything else can be handled in blocks.
        
     -->
    
    <!-- not worrying about multiple DSC sections.  ASpace can only export 1 DSC -->
    <xsl:template match="ead3:dsc">
        <fo:page-sequence master-reference="contents">
            <!-- Page header -->
            <fo:static-content flow-name="xsl-region-before">
                <fo:block/>
            </fo:static-content>
            <!-- Page footer-->
            <fo:static-content flow-name="xsl-region-after" role="artifact">
                <fo:block xsl:use-attribute-sets="page-number">
                    <xsl:text>Page </xsl:text>
                    <fo:page-number/>
                    <xsl:text> of </xsl:text>
                    <fo:page-number-citation ref-id="last-page"/>
                </fo:block>
            </fo:static-content>
            <!-- Content of page -->
            <fo:flow flow-name="xsl-region-body">
                <xsl:call-template name="section-start"/>
                <fo:block xsl:use-attribute-sets="h3" id="dsc-contents"><xsl:value-of select="$dsc-title"/></fo:block>
                
                <xsl:apply-templates select="ead3:*[matches(local-name(), '^c0|^c1')] | ead3:c"/>


                <!-- adding this to grab the last page number
                i don't think this is the preferred method of doing that, so review when needed.  if i use this method, then we'll need to move this to the real last page!
                which could be an index, a control access section, or the container list. -->
                <fo:wrapper id="last-page"/>
            </fo:flow>
        </fo:page-sequence>
    </xsl:template>
    
    <xsl:template match="ead3:*[matches(local-name(), '^c0|^c1')] | ead3:c">
        <xsl:variable name="indent-constant" select="count(ancestor::*) - 3"/> <!-- e.g. c01 = 0, c02 = 1, etc. -->
        <xsl:variable name="indent" select="concat(xs:string($indent-constant * 8), 'pt')"/> <!-- e.g. 0, 8pt for c02, 16pt for c03, etc.-->
        <fo:block start-indent="{$indent}">
            <!-- i should adjust percentage if there are no containers -->
            <fo:inline-container vertical-align="top" inline-progression-dimension="79.9%">
                <fo:block>
                    <xsl:apply-templates select="if (ead3:did/ead3:unittitle) then ead3:did/ead3:unittitle else ead3:did/ead3:unitdate"/>
                </fo:block>
            </fo:inline-container>
            <fo:inline-container vertical-align="top" inline-progression-dimension="19.9%">
                <fo:block>
                    <xsl:apply-templates select="ead3:did/ead3:container"/>
                </fo:block>
            </fo:inline-container>

            <!-- not great either.
            <fo:block text-align-last="justify"> 
                <fo:inline>
                    <xsl:apply-templates select="if (ead3:did/ead3:unittitle) then ead3:did/ead3:unittitle else ead3:did/ead3:unitdate"/>
                </fo:inline>
                <fo:leader leader-pattern="space"/>    
                <fo:inline>
                    <xsl:apply-templates select="ead3:did/ead3:container"/>
                </fo:inline>
            </fo:block>
            -->
            <!-- and this has even worse issues, so i'll probably keep everything in a table :(
            <fo:block>
                <fo:float float="right">
                    <fo:block end-indent="10pt">
                        <xsl:apply-templates select="ead3:did/ead3:container"/>
                    </fo:block>
                </fo:float> 
                <xsl:apply-templates select="if (ead3:did/ead3:unittitle) then ead3:did/ead3:unittitle else ead3:did/ead3:unitdate"/>
            </fo:block>
            <fo:block>
                <xsl:apply-templates select="ead3:did" mode="dsc"/>
                <xsl:apply-templates select="ead3:bioghist, ead3:scopecontent
                    , ead3:acqinfo, ead3:custodhist, ead3:accessrestrict, ead3:userestrict, ead3:prefercite
                    , ead3:processinfo, ead3:altformavail, ead3:relatedmaterial, ead3:separatedmaterial, ead3:accruals, ead3:appraisals
                    , ead3:originalsloc, ead3:otherfindingaid, ead3:phystech, ead3:fileplan, ead3:odd, ead3:bibliography, ead3:arrangement" mode="dsc"/>
            </fo:block>
            -->
        </fo:block>
         <xsl:apply-templates select="ead3:*[matches(local-name(), '^c0|^c1')] | ead3:c"/>
    </xsl:template>
      
    <xsl:template match="ead3:did" mode="dsc">
        <xsl:apply-templates select="ead3:abstract, ead3:physdesc, 
            ead3:physdestructured, ead3:physdescset, ead3:physloc, 
            ead3:langmaterial, ead3:materialspec, ead3:origination, ead3:repository" mode="#current"/>     
    </xsl:template>
    
    <xsl:template match="ead3:container">
        <xsl:value-of select="concat(@localtype, ' ', .)"/>
        <xsl:if test="position() ne last()">
            <xsl:text>, </xsl:text>
        </xsl:if>
    </xsl:template>

</xsl:stylesheet>