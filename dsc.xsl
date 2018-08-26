<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:fo="http://www.w3.org/1999/XSL/Format" xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:fox="http://xmlgraphics.apache.org/fop/extensions"
    xmlns:mdc="http://mdc"
    xmlns:ead3="http://ead3.archivists.org/schema/" exclude-result-prefixes="xs ead3 fox mdc"
    version="2.0">

    <!-- this file is imported by "ead3-to-pdf-ua.xsl" -->
    
    <!-- to do:
        change so that the only thing in tables are files/items with containers ?
        everything else can be handled in blocks.
        
        what if i go back to no tables, floating the dates to the right,
            and just adding containers in a new block? 
        
        other ideas:
            autogenerate a series/subseries overview, with container ranges and first pargraph of scope note?
            
            take the regular DSC out of a table, and put the container information inline.
            
            and add a container-inventory section at the end that's a real table, with box, folder, etc., plus title,
            date, etc., sorted by container numbers.   
     -->
    <xsl:param name="dsc-first-c-levels-to-process-before-a-table" select="('series', 'collection', 'fonds', 'recordgrp')"/>
    <xsl:param name="levels-to-force-a-page-break" select="('series', 'collection', 'fonds', 'recordgrp')"/>
    <xsl:param name="otherlevels-to-force-a-page-break-and-process-before-a-table" select="('accession', 'acquisition')"/>
    
    <!-- not worrying about multiple DSC sections.  ASpace can only export 1 DSC -->
    <xsl:template match="ead3:dsc">
        <xsl:variable name="column-types" select="
            if 
            (ead3:*[matches(local-name(), '^c0|^c1') or local-name()='c'][descendant-or-self::ead3:unitdate or descendant-or-self::ead3:unitdatestructured][descendant-or-self::ead3:container])
            then 'c-d-d'
            else 
            if (ead3:*[matches(local-name(), '^c0|^c1') or local-name()='c'][descendant-or-self::ead3:unitdate or descendant-or-self::ead3:unitdatestructured])
            then 'd-d'
            else 
            if (ead3:*[matches(local-name(), '^c0|^c1') or local-name()='c'][descendant-or-self::ead3:container])
            then 'c-d'
            else 'd'"/>
        <fo:page-sequence master-reference="contents">
            <!-- Page header -->
            <fo:static-content flow-name="xsl-region-before">
                <xsl:call-template name="header-dsc"/>
            </fo:static-content>
            <!-- Page footer-->
            <fo:static-content flow-name="xsl-region-after" role="artifact">
                <xsl:call-template name="footer"/>
            </fo:static-content>
            <!-- Content of page -->
            <fo:flow flow-name="xsl-region-body">
                <xsl:call-template name="section-start"/>
                <fo:block xsl:use-attribute-sets="h3" id="dsc-contents"><xsl:value-of select="$dsc-title"/></fo:block>
                <xsl:choose>
                    <xsl:when test="ead3:*[matches(local-name(), '^c0|^c1') or local-name()='c'][@level=$dsc-first-c-levels-to-process-before-a-table or @otherlevel=$otherlevels-to-force-a-page-break-and-process-before-a-table]">
                        <xsl:apply-templates select="ead3:*[matches(local-name(), '^c0|^c1') or local-name()='c']" mode="dsc-block">
                            <xsl:with-param name="column-types" select="$column-types"/>
                        </xsl:apply-templates>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:call-template name="tableBody">
                            <xsl:with-param name="column-types" select="$column-types"/>
                        </xsl:call-template>
                    </xsl:otherwise>
                </xsl:choose>
                <!-- adding this to grab the last page number-->
                <xsl:if test="$last-page eq 'dsc'">
                    <fo:wrapper id="last-page"/>
                </xsl:if>
            </fo:flow>
        </fo:page-sequence>
    </xsl:template>
    
    <xsl:template match="ead3:*[matches(local-name(), '^c0|^c1') or local-name()='c']" mode="dsc-block">
        <xsl:variable name="depth" select="count(ancestor::*) - 3"/> <!-- e.g. c01 = 0, c02 = 1, etc. -->
        <xsl:variable name="cell-margin" select="concat(xs:string($depth * 6), 'pt')"/> <!-- e.g. 0, 8pt for c02, 16pt for c03, etc.-->
        <xsl:variable name="column-types" select="
            if 
            (ead3:*[matches(local-name(), '^c0|^c1') or local-name()='c'][descendant-or-self::ead3:unitdate or descendant-or-self::ead3:unitdatestructured][descendant-or-self::ead3:container])
            then 'c-d-d'
            else 
            if (ead3:*[matches(local-name(), '^c0|^c1') or local-name()='c'][descendant-or-self::ead3:unitdate or descendant-or-self::ead3:unitdatestructured])
            then 'd-d'
            else 
            if (ead3:*[matches(local-name(), '^c0|^c1') or local-name()='c'][descendant-or-self::ead3:container])
            then 'c-d'
            else 'd'"/>
        <!-- do a second grouping based on the container grouping's primary localtype (i.e. box, volume, reel, etc.)
            then add a custom sort, or just sort those alphabetically -->
        <xsl:variable name="container-groupings">
            <xsl:for-each-group select="ead3:did/ead3:container" group-by="if (@parent) then @parent else @id">
                <xsl:sort select="mdc:container-to-number(.)"/>
                <container-group>
                    <xsl:apply-templates select="current-group()" mode="copy"/>
                </container-group>
            </xsl:for-each-group>
        </xsl:variable>
        <xsl:variable name="containers-sorted-by-localtype">
            <xsl:for-each-group select="$container-groupings/container-group" group-by="ead3:container[1]/@localtype">
                <xsl:sort select="current-grouping-key()" data-type="text"/>
                <!-- i don't use this element for anything right now, but it could be used, if 
                    additional grouping in the presentation was desired -->
                <xsl:element name="{current-grouping-key()}">
                    <xsl:apply-templates select="current-group()" mode="copy"/>
                </xsl:element>
            </xsl:for-each-group>
        </xsl:variable>
        <fo:block margin-left="{$cell-margin}" keep-with-next.within-page="always" id="{if (@id) then @id else generate-id(.)}">
            <xsl:if test="preceding-sibling::ead3:*[@level=$levels-to-force-a-page-break or @otherlevel=$otherlevels-to-force-a-page-break-and-process-before-a-table]">
                <xsl:attribute name="break-before" select="'page'"/>
            </xsl:if>
            <xsl:choose>
                <xsl:when test="parent::ead3:dsc and  (@level = ('series', 'collection', 'recordgrp') or @otherlevel = $otherlevels-to-force-a-page-break-and-process-before-a-table)">
                    <fo:marker marker-class-name="continued-header-text">
                        <fo:inline>
                            <xsl:if test="ead3:did/ead3:unitid/normalize-space()">
                                <xsl:value-of select="concat(ead3:did/ead3:unitid/normalize-space(), '. ')"/>
                            </xsl:if>
                            <xsl:apply-templates select="ead3:did/ead3:unittitle[1]"/>
                        </fo:inline>
                    </fo:marker>
                </xsl:when>
                <xsl:otherwise>
                    <fo:marker marker-class-name="continued-header-text"/>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:choose>
                <xsl:when test="$depth = 0 and (@level = ('series', 'collection', 'recordgrp') or @otherlevel = $otherlevels-to-force-a-page-break-and-process-before-a-table)">
                    <fo:block xsl:use-attribute-sets="h4">
                        <xsl:call-template name="dsc-block-identifier-and-title"/>
                    </fo:block>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:call-template name="dsc-block-identifier-and-title"/>
                </xsl:otherwise>
            </xsl:choose>

            <!-- still need ot add the other did elements, and select an order -->
            <xsl:apply-templates select="ead3:did" mode="dsc"/>
            <xsl:apply-templates select="ead3:bioghist, ead3:scopecontent
                , ead3:acqinfo, ead3:custodhist, ead3:accessrestrict, ead3:userestrict, ead3:prefercite
                , ead3:processinfo, ead3:altformavail, ead3:relatedmaterial, ead3:separatedmaterial, ead3:accruals, ead3:appraisals
                , ead3:originalsloc, ead3:otherfindingaid, ead3:phystech, ead3:fileplan, ead3:odd, ead3:bibliography, ead3:arrangement" mode="dsc"/>
            <!-- still need to add templates here for digital objects.  anything else?  -->
            <xsl:call-template name="container-layout">
                <xsl:with-param name="containers-sorted-by-localtype" select="$containers-sorted-by-localtype"/>
            </xsl:call-template>
        </fo:block>
        <xsl:choose>
            <xsl:when test="not(ead3:*[matches(local-name(), '^c0|^c1') or local-name()='c'])"/>
            <xsl:otherwise>
               <xsl:call-template name="tableBody">
                   <xsl:with-param name="column-types" select="$column-types"/>
               </xsl:call-template>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
     
    <xsl:template match="ead3:*[matches(local-name(), '^c0|^c1') or local-name()='c']" mode="dsc-table">            
        <xsl:param name="first-row" select="if (position() eq 1 and (
                parent::ead3:dsc 
                or parent::*[@level=$dsc-first-c-levels-to-process-before-a-table]
                or parent::*[@otherlevel=$otherlevels-to-force-a-page-break-and-process-before-a-table])
            )
            then true() else false()"/>
        <xsl:param name="no-children" select="if (not(ead3:*[matches(local-name(), '^c0|^c1') or local-name()='c'])) then true() else false()"/>
        <xsl:param name="last-row" select="if (position() eq last() and $no-children) then true() else false()"/>
        <xsl:param name="depth"/> <!-- e.g. c01 = 0, c02 = 1, etc. -->
        <xsl:param name="column-types"/>
        <xsl:variable name="cell-margin" select="concat(xs:string($depth * 8), 'pt')"/> <!-- e.g. 0, 8pt for c02, 16pt for c03, etc.-->
        <xsl:variable name="container-groupings">
            <xsl:for-each-group select="ead3:did/ead3:container" group-by="if (@parent) then @parent else @id">
                <xsl:sort select="mdc:container-to-number(.)"/>
                <container-group>
                    <xsl:apply-templates select="current-group()" mode="copy"/>
                </container-group>
            </xsl:for-each-group>
        </xsl:variable>
        <xsl:variable name="containers-sorted-by-localtype">
            <xsl:for-each-group select="$container-groupings/container-group" group-by="ead3:container[1]/@localtype">
                <xsl:sort select="current-grouping-key()" data-type="text"/>
                <xsl:element name="{current-grouping-key()}">
                    <xsl:apply-templates select="current-group()" mode="copy"/>
                </xsl:element>
            </xsl:for-each-group>
        </xsl:variable>
        <fo:table-row>
            <xsl:call-template name="dsc-table-row-border">
                <xsl:with-param name="last-row" select="$last-row"/>
                <xsl:with-param name="no-children" select="$no-children"/>
            </xsl:call-template>
            <xsl:choose>
                <xsl:when test="$column-types eq 'c-d-d'">
                    <fo:table-cell xsl:use-attribute-sets="dsc-table-cells">
                        <xsl:call-template name="container-layout">
                            <xsl:with-param name="containers-sorted-by-localtype" select="$containers-sorted-by-localtype"/>
                        </xsl:call-template>
                    </fo:table-cell>
                    <fo:table-cell xsl:use-attribute-sets="dsc-table-cells">
                        <fo:block>
                            <xsl:choose>
                                <xsl:when test="$first-row eq true()">
                                    <fo:marker marker-class-name="continued-text"/>
                                </xsl:when>
                                <xsl:otherwise>
                                    <fo:marker marker-class-name="continued-text">
                                        <fo:inline>
                                            <xsl:call-template name="ancestor-info"/>
                                        </fo:inline>
                                    </fo:marker>
                                </xsl:otherwise>
                            </xsl:choose> 
                        </fo:block>
                        <!-- do the title and/or date stuff here -->
                        <fo:block-container margin-left="{$cell-margin}" id="{if (@id) then @id else generate-id(.)}">
                            <fo:block-container>
                                <fo:block>
                                    <xsl:apply-templates select="if (ead3:did/ead3:unittitle/normalize-space()) then ead3:did/ead3:unittitle
                                        else ead3:did/ead3:unitdatestructured | ead3:did/ead3:unitdate"/>
                                    <xsl:apply-templates select="ead3:did/ead3:unitid" mode="dsc"/>
                                </fo:block>
                                <!-- still need to add the other did elements, and select an order -->
                                <fo:block>
                                    <xsl:apply-templates select="ead3:did" mode="dsc"/>
                                </fo:block>
                            </fo:block-container>
                            <fo:block-container>
                                <fo:block>
                                    <xsl:apply-templates select="ead3:bioghist, ead3:scopecontent
                                        , ead3:acqinfo, ead3:custodhist, ead3:accessrestrict, ead3:userestrict, ead3:prefercite
                                        , ead3:processinfo, ead3:altformavail, ead3:relatedmaterial, ead3:separatedmaterial, ead3:accruals, ead3:appraisals
                                        , ead3:originalsloc, ead3:otherfindingaid, ead3:phystech, ead3:fileplan, ead3:odd, ead3:bibliography, ead3:arrangement" mode="dsc"/>
                                </fo:block>
                            </fo:block-container>
                        </fo:block-container>
                    </fo:table-cell>
                    <fo:table-cell xsl:use-attribute-sets="dsc-table-cells">
                        <fo:block>
                            <xsl:apply-templates select="ead3:did/ead3:unitdatestructured | ead3:did/ead3:unitdate" mode="dsc"/>
                        </fo:block>
                    </fo:table-cell>
                </xsl:when>
                <xsl:when test="$column-types eq 'd-d'">
                    <fo:table-cell xsl:use-attribute-sets="dsc-table-cells">
                        <fo:block>
                            <xsl:choose>
                                <xsl:when test="$first-row eq true()">
                                    <fo:marker marker-class-name="continued-text"/>
                                </xsl:when>
                                <xsl:otherwise>
                                    <fo:marker marker-class-name="continued-text">
                                        <fo:inline>
                                            <xsl:call-template name="ancestor-info"/>
                                        </fo:inline>
                                    </fo:marker>
                                </xsl:otherwise>
                            </xsl:choose> 
                        </fo:block>
                        <!-- do the title and/or date stuff here -->
                        <fo:block-container margin-left="{$cell-margin}" id="{if (@id) then @id else generate-id(.)}">
                            <fo:block-container>
                                <fo:block>
                                    <xsl:apply-templates select="if (ead3:did/ead3:unittitle/normalize-space()) then ead3:did/ead3:unittitle
                                        else ead3:did/ead3:unitdatestructured | ead3:did/ead3:unitdate"/>
                                    <xsl:apply-templates select="ead3:did/ead3:unitid" mode="dsc"/>
                                </fo:block>
                                <!-- still need to add the other did elements, and select an order -->
                                <fo:block>
                                    <xsl:apply-templates select="ead3:did" mode="dsc"/>
                                </fo:block>
                            </fo:block-container>
                            <fo:block-container>
                                <fo:block>
                                    <xsl:apply-templates select="ead3:bioghist, ead3:scopecontent
                                        , ead3:acqinfo, ead3:custodhist, ead3:accessrestrict, ead3:userestrict, ead3:prefercite
                                        , ead3:processinfo, ead3:altformavail, ead3:relatedmaterial, ead3:separatedmaterial, ead3:accruals, ead3:appraisals
                                        , ead3:originalsloc, ead3:otherfindingaid, ead3:phystech, ead3:fileplan, ead3:odd, ead3:bibliography, ead3:arrangement" mode="dsc"/>
                                </fo:block>
                            </fo:block-container>
                        </fo:block-container>
                    </fo:table-cell>
                    <fo:table-cell xsl:use-attribute-sets="dsc-table-cells">
                        <fo:block>
                            <xsl:apply-templates select="ead3:did/ead3:unitdatestructured | ead3:did/ead3:unitdate" mode="dsc"/>
                        </fo:block>
                    </fo:table-cell>
                </xsl:when>
                <xsl:when test="$column-types eq 'c-d'">
                    <fo:table-cell xsl:use-attribute-sets="dsc-table-cells">
                        <xsl:call-template name="container-layout">
                            <xsl:with-param name="containers-sorted-by-localtype" select="$containers-sorted-by-localtype"/>
                        </xsl:call-template>
                    </fo:table-cell>
                    <fo:table-cell xsl:use-attribute-sets="dsc-table-cells">
                        <fo:block>
                            <xsl:choose>
                                <xsl:when test="$first-row eq true()">
                                    <fo:marker marker-class-name="continued-text"/>
                                </xsl:when>
                                <xsl:otherwise>
                                    <fo:marker marker-class-name="continued-text">
                                        <fo:inline>
                                            <xsl:call-template name="ancestor-info"/>
                                        </fo:inline>
                                    </fo:marker>
                                </xsl:otherwise>
                            </xsl:choose> 
                        </fo:block>
                        <!-- do the title and/or date stuff here -->
                        <fo:block-container margin-left="{$cell-margin}" id="{if (@id) then @id else generate-id(.)}">
                            <fo:block-container>
                                <fo:block>
                                    <xsl:apply-templates select="if (ead3:did/ead3:unittitle/normalize-space()) then ead3:did/ead3:unittitle
                                        else ead3:did/ead3:unitdatestructured | ead3:did/ead3:unitdate"/>
                                    <xsl:apply-templates select="ead3:did/ead3:unitid" mode="dsc"/>
                                </fo:block>
                                <!-- still need to add the other did elements, and select an order -->
                                <fo:block>
                                    <xsl:apply-templates select="ead3:did" mode="dsc"/>
                                </fo:block>
                            </fo:block-container>
                            <fo:block-container>
                                <fo:block>
                                    <xsl:apply-templates select="ead3:bioghist, ead3:scopecontent
                                        , ead3:acqinfo, ead3:custodhist, ead3:accessrestrict, ead3:userestrict, ead3:prefercite
                                        , ead3:processinfo, ead3:altformavail, ead3:relatedmaterial, ead3:separatedmaterial, ead3:accruals, ead3:appraisals
                                        , ead3:originalsloc, ead3:otherfindingaid, ead3:phystech, ead3:fileplan, ead3:odd, ead3:bibliography, ead3:arrangement" mode="dsc"/>
                                </fo:block>
                            </fo:block-container>
                        </fo:block-container>
                    </fo:table-cell>
                </xsl:when>
                <xsl:otherwise>
                    <fo:table-cell xsl:use-attribute-sets="dsc-table-cells">
                        <fo:block>
                            <xsl:choose>
                                <xsl:when test="$first-row eq true()">
                                    <fo:marker marker-class-name="continued-text"/>
                                </xsl:when>
                                <xsl:otherwise>
                                    <fo:marker marker-class-name="continued-text">
                                        <fo:inline>
                                            <xsl:call-template name="ancestor-info"/>
                                        </fo:inline>
                                    </fo:marker>
                                </xsl:otherwise>
                            </xsl:choose> 
                        </fo:block>
                        <!-- do the title and/or date stuff here -->
                        <fo:block-container margin-left="{$cell-margin}" id="{if (@id) then @id else generate-id(.)}">
                            <fo:block-container>
                                <fo:block>
                                    <xsl:apply-templates select="if (ead3:did/ead3:unittitle/normalize-space()) then ead3:did/ead3:unittitle
                                        else ead3:did/ead3:unitdatestructured | ead3:did/ead3:unitdate"/>
                                    <xsl:apply-templates select="ead3:did/ead3:unitid" mode="dsc"/>
                                </fo:block>
                                <!-- still need to add the other did elements, and select an order -->
                                <fo:block>
                                    <xsl:apply-templates select="ead3:did" mode="dsc"/>
                                </fo:block>
                            </fo:block-container>
                            <fo:block-container>
                                <fo:block>
                                    <xsl:apply-templates select="ead3:bioghist, ead3:scopecontent
                                        , ead3:acqinfo, ead3:custodhist, ead3:accessrestrict, ead3:userestrict, ead3:prefercite
                                        , ead3:processinfo, ead3:altformavail, ead3:relatedmaterial, ead3:separatedmaterial, ead3:accruals, ead3:appraisals
                                        , ead3:originalsloc, ead3:otherfindingaid, ead3:phystech, ead3:fileplan, ead3:odd, ead3:bibliography, ead3:arrangement" mode="dsc"/>
                                </fo:block>
                            </fo:block-container>
                        </fo:block-container>
                    </fo:table-cell>
                </xsl:otherwise>
            </xsl:choose>
        </fo:table-row>
        <xsl:apply-templates select="ead3:*[matches(local-name(), '^c0|^c1') or local-name()='c']" mode="dsc-table">
            <xsl:with-param name="depth" select="$depth + 1"/>
            <xsl:with-param name="column-types" select="$column-types"/>
        </xsl:apply-templates>
    </xsl:template>
    
    <xsl:template match="ead3:did" mode="dsc">
        <xsl:apply-templates select="ead3:abstract, ead3:physdesc, ead3:physdescstructured, 
            ead3:physdescset, ead3:physloc, 
            ead3:langmaterial, ead3:materialspec, ead3:origination, ead3:repository, ead3:dao" mode="#current"/>
    </xsl:template>
    
    <xsl:template match="ead3:container">
        <xsl:variable name="use-fontawesome" as="xs:boolean">
            <xsl:value-of select="if (lower-case(@localtype) = ('box', 'volume', 'item_barcode')) then true() else false()"/>
        </xsl:variable>
        <xsl:choose>
            <xsl:when test="$use-fontawesome eq false()">
                <xsl:value-of select="lower-case(@localtype)"/>
            </xsl:when>
            <xsl:otherwise>
                <fo:inline font-family="FontAwesomeSolid" color="#4A4A4A">
                    <xsl:value-of select="if (lower-case(@localtype) eq 'box') then '&#xf187; '
                        else if (lower-case(@localtype) eq 'folder') then '&#xf07b; '
                        else if (lower-case(@localtype) eq 'volume') then '&#xf02d; '
                        else if (lower-case(@localtype) eq 'item_barcode') then '&#xf02a;'
                        else '&#xf0a0; '"/>
                </fo:inline>
                <xsl:value-of select="if (lower-case(@localtype) eq 'item_barcode') then '' else lower-case(@localtype)"/>
            </xsl:otherwise>
        </xsl:choose>
        <xsl:text> </xsl:text>
        <xsl:apply-templates/>
        <xsl:if test="position() ne last()">
            <xsl:text>, </xsl:text>
        </xsl:if>
    </xsl:template>
    
</xsl:stylesheet>
