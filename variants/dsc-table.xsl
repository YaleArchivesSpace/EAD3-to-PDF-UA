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
    
    <xsl:param name="levels-to-process-before-a-table" select="('series', 'subseries', 'collection', 'fonds', 'subfonds', 'recordgrp', 'subgrp', 'class', 'otherlevel')"/>

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
                
                <xsl:choose>
                    <xsl:when test="ead3:*[matches(local-name(), '^c0|^c1')][@level=$levels-to-process-before-a-table] | ead3:c[@level=$levels-to-process-before-a-table]">
                        <xsl:apply-templates select="ead3:*[matches(local-name(), '^c0|^c1')] | ead3:c" mode="dsc-block"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:call-template name="tableBody"/>
                    </xsl:otherwise>
                </xsl:choose>

                <!-- adding this to grab the last page number
                i don't think this is the preferred method of doing that, so review when needed.  if i use this method, then we'll need to move this to the real last page!
                which could be an index, a control access section, or the container list. -->
                <fo:wrapper id="last-page"/>
            </fo:flow>
        </fo:page-sequence>
    </xsl:template>
    
    <xsl:template match="ead3:*[matches(local-name(), '^c0|^c1')] | ead3:c" mode="dsc-block">
        <xsl:variable name="indent-constant" select="count(ancestor::*) - 3"/> <!-- e.g. c01 = 0, c02 = 1, etc. -->
        <xsl:variable name="cell-margin" select="concat(xs:string($indent-constant * 8), 'pt')"/> <!-- e.g. 0, 8pt for c02, 16pt for c03, etc.-->
        <fo:block margin-left="{$cell-margin}">
            <xsl:apply-templates select="ead3:did/ead3:unittitle"/>
            <!-- still need ot add the other did elements, and select an order -->
            <xsl:apply-templates select="ead3:did" mode="dsc"/>
            <xsl:apply-templates select="ead3:bioghist, ead3:scopecontent
                , ead3:acqinfo, ead3:custodhist, ead3:accessrestrict, ead3:userestrict, ead3:prefercite
                , ead3:processinfo, ead3:altformavail, ead3:relatedmaterial, ead3:separatedmaterial, ead3:accruals, ead3:appraisals
                , ead3:originalsloc, ead3:otherfindingaid, ead3:phystech, ead3:fileplan, ead3:odd, ead3:bibliography, ead3:arrangement, ead3:did/ead3:container" mode="dsc"/>
        </fo:block>
        <xsl:choose>
            <xsl:when test="not(ead3:*[matches(local-name(), '^c0|^c1')] | ead3:c)"/>
            <xsl:when test="ead3:*[matches(local-name(), '^c0|^c1')][@level=$levels-to-process-before-a-table] | ead3:c[@level=$levels-to-process-before-a-table]">
                <xsl:apply-templates select="ead3:*[matches(local-name(), '^c0|^c1')] | ead3:c" mode="dsc-block"/>
            </xsl:when>
            <xsl:otherwise>
               <xsl:call-template name="tableBody">
                   <xsl:with-param name="cell-margin" select="$cell-margin"/>
               </xsl:call-template>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    
    <xsl:template match="ead3:*[matches(local-name(), '^c0|^c1')] | ead3:c" mode="dsc-table">
        <xsl:variable name="indent-constant" select="count(ancestor::*) - 3"/> <!-- e.g. c01 = 0, c02 = 1, etc. -->
        <xsl:variable name="cell-margin" select="concat(xs:string($indent-constant * 8), 'pt')"/> <!-- e.g. 0, 8pt for c02, 16pt for c03, etc.-->
        <fo:table-row>
            <fo:table-cell>
                <!-- do the title and/or date stuff here -->
                <fo:block margin-left="{$cell-margin}">
                    <xsl:apply-templates select="ead3:did/ead3:unittitle"/>
                    <!-- still need ot add the other did elements, and select an order -->
                    <xsl:apply-templates select="ead3:did" mode="dsc"/>
                    <xsl:apply-templates select="ead3:bioghist, ead3:scopecontent
                        , ead3:acqinfo, ead3:custodhist, ead3:accessrestrict, ead3:userestrict, ead3:prefercite
                        , ead3:processinfo, ead3:altformavail, ead3:relatedmaterial, ead3:separatedmaterial, ead3:accruals, ead3:appraisals
                        , ead3:originalsloc, ead3:otherfindingaid, ead3:phystech, ead3:fileplan, ead3:odd, ead3:bibliography, ead3:arrangement" mode="dsc"/>
                </fo:block>
            </fo:table-cell>
            <fo:table-cell>
                <!-- replace with a combine title and date function -->
                <fo:block>
                    <!-- set things up for container groupings here -->
                    <xsl:apply-templates select="ead3:did/ead3:container"/>
                </fo:block>
            </fo:table-cell>
        </fo:table-row>
        <xsl:apply-templates select="ead3:*[matches(local-name(), '^c0|^c1')] | ead3:c" mode="dsc-table"/>
    </xsl:template>
    
    <xsl:template name="tableBody">
        <xsl:param name="cell-margin"/>
        <fo:table inline-progression-dimension="100%" table-layout="fixed">
            <fo:table-column column-number="1" column-width="proportional-column-width(75)"/>
            <fo:table-column column-number="2" column-width="proportional-column-width(25)"/>
            <xsl:call-template name="tableHeaders">
                <xsl:with-param name="cell-margin" select="$cell-margin"/>
            </xsl:call-template>
            <fo:table-body>
                <xsl:apply-templates select="ead3:*[matches(local-name(), '^c0|^c1')] | ead3:c" mode="dsc-table"/>
            </fo:table-body>
        </fo:table>
    </xsl:template>
    
    <xsl:template name="tableHeaders">
        <xsl:param name="cell-margin"/>
        <fo:table-header visibility="hidden"> 
            <fo:table-row visibility="hidden">
                <fo:table-cell padding-left="{if ($cell-margin) then $cell-margin else '0pt'}">
                    <fo:block text-decoration="underline" padding="2pt">
                        Description
                    </fo:block>
                </fo:table-cell>
                <fo:table-cell>
                    <fo:block text-decoration="underline" padding="2pt">
                        Containers
                    </fo:block>
                </fo:table-cell>
            </fo:table-row>
        </fo:table-header>
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