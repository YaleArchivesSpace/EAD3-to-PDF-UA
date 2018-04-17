<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:fo="http://www.w3.org/1999/XSL/Format" xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:fox="http://xmlgraphics.apache.org/fop/extensions"
    xmlns:ead3="http://ead3.archivists.org/schema/" exclude-result-prefixes="xs ead3 fox"
    version="2.0">

    <!-- this file is imported by "ead3-to-pdf-ua.xsl" -->

    <xsl:template match="ead3:archdesc">
        <fo:page-sequence master-reference="archdesc">
            <xsl:if test="$start-page-1-after-table-of-contents eq true()">
                <xsl:attribute name="initital-page-number" select="1"/>
            </xsl:if>
            <!-- Page header -->
            <fo:static-content flow-name="xsl-region-before">
                <fo:block/>
            </fo:static-content>
            <!-- Page footer-->
            <fo:static-content flow-name="xsl-region-after" role="artifact">
                <fo:block xsl:use-attribute-sets="page-number" text-align="center">
                    <xsl:text>Page </xsl:text>
                    <fo:page-number/>
                    <xsl:text> of </xsl:text>
                    <fo:page-number-citation ref-id="last-page"/>
                </fo:block>
            </fo:static-content>
            <!-- Content of page -->
            <fo:flow flow-name="xsl-region-body">
                <xsl:call-template name="section-start"/>
                <fo:block xsl:use-attribute-sets="h3" id="contents">
                    <xsl:value-of select="$archdesc-did-title"/>
                </fo:block>
                <!-- change mode name and re-purpose for all levels ? -->
                <xsl:apply-templates select="ead3:did" mode="collection-overview"/>
                <xsl:if test="ead3:acqinfo, ead3:custodhist, ead3:accessrestrict, ead3:userestrict, ead3:prefercite
                    , ead3:processinfo, ead3:altformavail, ead3:relatedmaterial, ead3:separatedmaterial, ead3:accruals, ead3:appraisals
                    , ead3:originalsloc, ead3:otherfindingaid, ead3:phystech, ead3:fileplan">
                    <xsl:call-template name="section-start"/>
                    <fo:block xsl:use-attribute-sets="h3" id="admin-info"><xsl:value-of select="$admin-info-title"/></fo:block>
                </xsl:if>
                <fo:block margin-left="0.2in" margin-top="0.1in">
                    <xsl:apply-templates select="ead3:acqinfo, ead3:custodhist, ead3:accessrestrict, ead3:userestrict, ead3:prefercite
                        , ead3:processinfo, ead3:altformavail, ead3:relatedmaterial, ead3:separatedmaterial, ead3:accruals, ead3:appraisals
                        , ead3:originalsloc, ead3:otherfindingaid, ead3:phystech, ead3:fileplan"/>
                </fo:block>
                <xsl:apply-templates select="ead3:bioghist, ead3:scopecontent
                    , ead3:odd[not(contains(lower-case(ead3:head), 'index'))]
                    , ead3:bibliography, ead3:arrangement" mode="collection-overview"/>
                
                <!-- display after container list
                odd (if "index" in head)
                index
                controlaccess (or put this in it's own section, prior to the container list???)
                -->
                <!-- adding this to grab the last page number-->
                <xsl:if test="$last-page eq 'archdesc'">
                    <fo:wrapper id="last-page"/>
                </xsl:if>
            </fo:flow>
        </fo:page-sequence>
    </xsl:template>
    
    <xsl:template match="ead3:did" mode="collection-overview">
        <fo:list-block xsl:use-attribute-sets="collection-overview-list">
            <xsl:call-template name="holding-repository"/>
            <!-- should i group, up front, when the elements should be grouped into the same row?
                e.g. 2 origination elements
                -->
            <xsl:apply-templates select="ead3:unitid[not(@audience='internal')][1]
                , ead3:origination[1]
                , ead3:unittitle[1]
                , ead3:unitdatestructured[not(@unidatetype='bulk')][1]
                , ead3:unitdatestructured[@unitdatetype='bulk'][1]
                , ead3:physdescstructured
                , ead3:langmaterial" mode="collection-overview-table-row"/>
            <xsl:call-template name="finding-aid-summary"/>
            <xsl:apply-templates select="ead3:physloc
                , ead3:materialspec" mode="collection-overview-table-row"/>
            <xsl:if test="$finding-aid-identifier/@instanceurl/normalize-space()">
                <xsl:call-template name="finding-aid-link"/>
            </xsl:if>
        </fo:list-block>
    </xsl:template>
    
    <xsl:template match="ead3:unitid | ead3:origination | ead3:unittitle | ead3:physdesctructured | ead3:langmaterial | ead3:physloc | ead3:materialspec" mode="collection-overview-table-row">
        <fo:list-item xsl:use-attribute-sets="collection-overview-list-item">
            <fo:list-item-label xsl:use-attribute-sets="collection-overview-list-label">
                <xsl:call-template name="select-header"/>  
            </fo:list-item-label>
            <fo:list-item-body xsl:use-attribute-sets="collection-overview-list-body">
                <fo:block>
                    <xsl:apply-templates/>
                </fo:block>
            </fo:list-item-body>      
        </fo:list-item>
    </xsl:template>
    
    <xsl:template match="ead3:physdescstructured" mode="collection-overview-table-row">
        <fo:list-item xsl:use-attribute-sets="collection-overview-list-item">
            <fo:list-item-label xsl:use-attribute-sets="collection-overview-list-label">
                <xsl:call-template name="select-header"/>
            </fo:list-item-label>
            <fo:list-item-body xsl:use-attribute-sets="collection-overview-list-body">
                <fo:block>
                    <xsl:apply-templates select="ead3:quantity
                        , ead3:unittype
                        , following-sibling::*[1][self::ead3:physdesc/@localtype='container_summary']
                        , ead3:physfacet
                        , ead3:dimensions"/>
                </fo:block>
            </fo:list-item-body>
        </fo:list-item>
    </xsl:template>
    
    <!-- it would be great to combine the next two templates, but i'd have to change how the "for-each" section works, which i need to keep right now
        so that the dates can be sorted -->
    <xsl:template match="ead3:unitdatestructured[not(@unitdatetype='bulk')][1]" mode="collection-overview-table-row">
        <fo:list-item xsl:use-attribute-sets="collection-overview-list-item">
            <fo:list-item-label xsl:use-attribute-sets="collection-overview-list-label">
                <xsl:call-template name="select-header"/>
            </fo:list-item-label>
            <fo:list-item-body xsl:use-attribute-sets="collection-overview-list-body">
                <!-- this is a mess right now.  EAD3 doesn't make it any easier, either
                    especially the way that ASpace creates it right now.-->
                <fo:block>
                    <xsl:for-each select="../ead3:unitdatestructured[not(@unitdatetype='bulk')]">
                        <xsl:sort select="if (ead3:daterange//@standarddate) then (ead3:daterange//@standarddate)[1]
                            else ead3:datesingle/@standarddate[1]" data-type="number"/>
                        <xsl:choose>
                            <xsl:when test="following-sibling::ead3:*[1][local-name()='unitdate']">
                                <xsl:apply-templates select="following-sibling::ead3:*[1]"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:apply-templates/>
                            </xsl:otherwise>
                        </xsl:choose>
                        <xsl:if test="position() != last()">
                            <xsl:text>, </xsl:text>
                        </xsl:if>
                    </xsl:for-each>
                </fo:block>
            </fo:list-item-body>
        </fo:list-item>
    </xsl:template>
    
    <xsl:template match="ead3:unitdatestructured[@unitdatetype='bulk'][1]" mode="collection-overview-table-row">
        <fo:list-item xsl:use-attribute-sets="collection-overview-list-item">
            <fo:list-item-label xsl:use-attribute-sets="collection-overview-list-label">
                <xsl:call-template name="select-header"/>
            </fo:list-item-label>
            <fo:list-item-body xsl:use-attribute-sets="collection-overview-list-body">
                <fo:block>
                    <xsl:for-each select="../ead3:unitdatestructured[@unitdatetype='bulk']">                
                        <xsl:sort select="if (ead3:daterange//@standarddate) then (ead3:daterange//@standarddate)[1]
                            else ead3:datesingle/@standarddate[1]" data-type="number"/>
                        <xsl:choose>
                            <xsl:when test="following-sibling::ead3:*[1][local-name()='unitdate']">
                                <xsl:apply-templates select="following-sibling::ead3:*[1]"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:apply-templates/>
                            </xsl:otherwise>
                        </xsl:choose>
                        <xsl:if test="position() != last()">
                            <xsl:text>, </xsl:text>
                        </xsl:if>
                    </xsl:for-each>
                </fo:block>
            </fo:list-item-body>
        </fo:list-item>
    </xsl:template>

    <xsl:template name="holding-repository">
        <fo:list-item xsl:use-attribute-sets="collection-overview-list-item">
            <fo:list-item-label xsl:use-attribute-sets="collection-overview-list-label">
                <fo:block>
                    <xsl:text>Repository: </xsl:text>
                </fo:block>
            </fo:list-item-label>
            <fo:list-item-body xsl:use-attribute-sets="collection-overview-list-body">
                <fo:block>
                    <xsl:value-of select="$holding-repository/normalize-space()"/>
                </fo:block>
                <xsl:apply-templates select="ancestor::ead3:ead/ead3:control/ead3:filedesc/ead3:publicationstmt/ead3:address"/>
            </fo:list-item-body>
        </fo:list-item>
    </xsl:template>
    
    <xsl:template name="finding-aid-summary">
        <fo:list-item xsl:use-attribute-sets="collection-overview-list-item">
            <fo:list-item-label xsl:use-attribute-sets="collection-overview-list-label">
                <fo:block>
                    <xsl:text>Summary: </xsl:text>
                </fo:block>
            </fo:list-item-label>
            <fo:list-item-body xsl:use-attribute-sets="collection-overview-list-body">
                <fo:block>
                    <xsl:apply-templates select="$finding-aid-summary"/>
                </fo:block>
            </fo:list-item-body>
        </fo:list-item>
    </xsl:template>
    
    <xsl:template name="finding-aid-link">
        <fo:list-item xsl:use-attribute-sets="collection-overview-list-item">
            <fo:list-item-label xsl:use-attribute-sets="collection-overview-list-label">
                <fo:block>
                    <xsl:text>Online Finding Aid: </xsl:text>
                </fo:block>
            </fo:list-item-label>
            <fo:list-item-body xsl:use-attribute-sets="collection-overview-list-body">
                <fo:block>
                    <xsl:text>To cite or bookmark this finding aid, please use the following link: </xsl:text>
                    <fo:basic-link xsl:use-attribute-sets="ref" external-destination="{$finding-aid-identifier/@instanceurl/normalize-space()}"
                        fox:alt-text="Permanent finding aid link">
                        <xsl:value-of select="$finding-aid-identifier/@instanceurl/normalize-space()"/>
                    </fo:basic-link>
                </fo:block>
            </fo:list-item-body>
        </fo:list-item>
    </xsl:template>
    
    <xsl:template name="select-header">
        <!-- i'd like to add a map here instead but i think that we'd need to upgrade saxon he to do that -->
        <fo:block>
            <xsl:choose>
                <xsl:when test="self::ead3:unitid">
                    <xsl:text>Call Number: </xsl:text>
                </xsl:when>
                <xsl:when test="self::ead3:origination">
                    <xsl:text>Creator: </xsl:text>
                </xsl:when>
                <xsl:when test="self::ead3:unittitle">
                    <xsl:text>Title: </xsl:text>
                </xsl:when>
                <xsl:when test="self::ead3:unitdatestructured[not(@unitdatetype='bulk')]">
                    <xsl:text>Dates: </xsl:text>
                </xsl:when>
                <xsl:when test="self::ead3:unitdatestructured[@unitdatetype='bulk']">
                    <xsl:text>Bulk Dates: </xsl:text>
                </xsl:when>
                <xsl:when test="self::ead3:physdescstructured">
                    <xsl:text>Physical Description: </xsl:text>
                </xsl:when>
                <xsl:when test="self::ead3:langmaterial">
                    <xsl:text>Language: </xsl:text>
                </xsl:when>
                <xsl:when test="self::ead3:physloc">
                    <xsl:text>Location: </xsl:text>
                </xsl:when>
                <xsl:when test="self::ead3:materialspec">
                    <xsl:text>Technical: </xsl:text>
                </xsl:when>
            </xsl:choose>
        </fo:block>
    </xsl:template>
    
</xsl:stylesheet>