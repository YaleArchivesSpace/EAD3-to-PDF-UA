<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:fo="http://www.w3.org/1999/XSL/Format" xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:fox="http://xmlgraphics.apache.org/fop/extensions"
    xmlns:ead3="http://ead3.archivists.org/schema/" exclude-result-prefixes="xs ead3 fox"
    version="2.0">

    <!-- this file is imported by "ead3-to-pdf-ua.xsl" -->
    
    <!-- 
    table
    bibliography
    chronlist
    list
    deflist
    index
    what else?
    -->
    
    <!-- not used often, but used by the container-grouping and sorting method -->
    <xsl:template match="@*|node()" mode="copy">
        <xsl:copy>
            <xsl:apply-templates select="@*|node()" mode="#current"/>
        </xsl:copy>
    </xsl:template>
   
    <!-- stand-alone block elements go here (not adding values like unitid and unittitle, however, since those will be handled differently
    a lot of these are handled differently as a LIST, however, when at the colleciton level.-->
    <xsl:template match="ead3:unitid | ead3:abstract | ead3:addressline | ead3:langmaterial | ead3:materialspec | ead3:origination | ead3:physdesc[not(@localtype='container_summary')]
        | ead3:physloc | ead3:repository" mode="dsc">
        <fo:block keep-with-previous.within-page="always">
            <xsl:choose>
                <xsl:when test="self::ead3:unitid">
                    <fo:inline font-style="italic">Call Number: </fo:inline>
                </xsl:when>
            </xsl:choose>
            <xsl:apply-templates/>
        </fo:block>
    </xsl:template>
    
    <xsl:template match="ead3:head" mode="dsc"/>

    <xsl:template match="ead3:head">
        <fo:block xsl:use-attribute-sets="h4" id="{if (../@id) then ../@id else generate-id(..)}">
            <xsl:apply-templates/>
        </fo:block>
    </xsl:template>
    
    <xsl:template match="ead3:head" mode="collection-overview">
        <xsl:call-template name="section-start"/>
        <fo:block xsl:use-attribute-sets="h3" id="{if (../@id) then ../@id else generate-id(..)}">
            <xsl:apply-templates/>
        </fo:block>
    </xsl:template>
    
    <xsl:template match="ead3:head" mode="toc">
        <xsl:apply-templates/>
    </xsl:template>
    
    <xsl:template match="ead3:p" mode="#all">
        <fo:block space-after="8pt"><xsl:apply-templates/></fo:block>
    </xsl:template>
    
    <xsl:template match="ead3:blockquote">
        <fo:block margin="4pt 18pt"><xsl:apply-templates/></fo:block>
    </xsl:template>
    
    <xsl:template match="ead3:unitdatestructured" mode="#all">
        <xsl:apply-templates/>
        <xsl:if test="position() ne last()">
            <xsl:text>, </xsl:text>
        </xsl:if>
    </xsl:template>

    <xsl:template match="ead3:daterange" mode="#all">
        <xsl:apply-templates select="ead3:fromdate"/>
        <xsl:if test="ead3:todate">
            <xsl:text>&#x2013;</xsl:text>
        </xsl:if>
        <xsl:apply-templates select="ead3:todate"/>
    </xsl:template>
    
    <!-- ASpace exports a date expression even when one is absent.  it also uses a hypen to separate the date range, rather than an en dash.
        since i don't care if the unit dates have any mixed content, i'm just selecting the text, but replacing the hyphen with an en dash.
        it would be best to move this template to our post-processing process, most likely-->
    <xsl:template match="ead3:unitdate">
        <xsl:value-of select="translate(., '-', '&#x2013;')"/>
        <xsl:if test="position() ne last()">
            <xsl:text>, </xsl:text>
        </xsl:if>
    </xsl:template>
      
    <xsl:template match="ead3:unittype" mode="#all">
        <xsl:text> </xsl:text>
        <!-- add something here to convert to singular extent types, when quantity = 1-->
        <xsl:value-of select="lower-case(.)"/>
    </xsl:template>
    
    <xsl:template match="ead3:physdesc[@localtype='container_summary']">
        <xsl:text> </xsl:text>
        <xsl:choose>
            <xsl:when test="not(starts-with(normalize-space(), '(')) and not(ends-with(normalize-space(), ')'))">
                <xsl:text>(</xsl:text>
                <xsl:apply-templates/>
                <xsl:text>)</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template match="ead3:physfacet">
        <xsl:if test="preceding-sibling::*">
            <xsl:text> : </xsl:text>
        </xsl:if>
        <xsl:apply-templates/>
    </xsl:template>
    
    <xsl:template match="ead3:dimensions">
        <xsl:if test="preceding-sibling::*">
            <xsl:text> ; </xsl:text>
        </xsl:if>
        <xsl:apply-templates/>
    </xsl:template>
    
    <xsl:template match="ead3:title">
        <fo:inline font-style="italic">
            <xsl:apply-templates/>
        </fo:inline>
    </xsl:template>
</xsl:stylesheet>
