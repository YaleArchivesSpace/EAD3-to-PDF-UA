<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:fo="http://www.w3.org/1999/XSL/Format"
    xmlns:fox="http://xmlgraphics.apache.org/fop/extensions"
    xmlns:math="http://www.w3.org/2005/xpath-functions/math"
    xmlns:mdc="http://mdc"
    xmlns:ead3="http://ead3.archivists.org/schema/" 
    exclude-result-prefixes="xs math mdc fox"
    version="2.0">
    
    <!-- also need to make sure that the top-level dates display if those are NOT normalized
        -->
    
    <xsl:function name="mdc:container-to-number" as="xs:decimal">
        <xsl:param name="current-container" as="node()*"/>
        <xsl:variable name="primary-container-number" select="if (contains($current-container, '-')) then replace(substring-before($current-container, '-'), '\D', '') else replace($current-container, '\D', '')"/>
        <xsl:variable name="primary-container-modify">
            <xsl:choose>
                <xsl:when test="matches($current-container, '\D')">
                    <xsl:analyze-string select="$current-container" regex="(\D)(\s?)">
                        <xsl:matching-substring>
                            <xsl:value-of select="number(string-to-codepoints(upper-case(regex-group(1))))"/>
                        </xsl:matching-substring>
                    </xsl:analyze-string>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="00"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="id-attribue" select="$current-container/@id"/>
        <xsl:variable name="secondary-container-number">
            <!-- changed this xpath slightly so as to ignore containers that start with a # -->
            <xsl:value-of select="if (contains($current-container/following-sibling::ead3:container[@parent eq $id-attribue][1], '-')) then 
                format-number(number(replace(substring-before($current-container/following-sibling::ead3:container[@parent eq $id-attribue][1], '-'), '\D', '')), '000000')
                else if ($current-container/following-sibling::ead3:container[not(starts-with(., '#'))][@parent eq $id-attribue][1])
                then format-number(number(replace($current-container/following-sibling::ead3:container[@parent eq $id-attribue][1], '\D', '')), '000000')
                else '000000'"/>
        </xsl:variable>
        <!-- could do this recursively, instead, but ASpace can only have container1,2,3 as a group... and i've
            never seen more than that needed, anyway -->
        <xsl:variable name="tertiary-container-number">
            <xsl:value-of select="if (contains($current-container/following-sibling::ead3:container[@parent eq $id-attribue][2], '-')) then 
                format-number(number(replace(substring-before($current-container/following-sibling::ead3:container[@parent eq $id-attribue][1], '-'), '\D', '')), '000000')
                else if ($current-container/following-sibling::ead3:container[not(starts-with(., '#'))][@parent eq $id-attribue][2])
                then format-number(number(replace($current-container/following-sibling::ead3:container[@parent eq $id-attribue][2], '\D', '')), '000000')
                else '000000'"/>
        </xsl:variable>
        <xsl:value-of select="xs:decimal(concat($primary-container-number, '.', $primary-container-modify, $secondary-container-number, $tertiary-container-number))"/>
    </xsl:function>
    
    <!-- header and footer templates (start)-->
    <xsl:template name="header-right">
        <fo:block text-align="right" font-size="9pt">
            <xsl:apply-templates select="$collection-title"/>
            <fo:block/>
            <xsl:apply-templates select="$collection-identifier"/>
        </fo:block>
    </xsl:template>
    <xsl:template name="header-dsc">
        <fo:block text-align="justify">
            <fo:inline-container width="30%">
                <fo:block font-size="9pt">
                    <fo:retrieve-marker retrieve-class-name="continued-header-text"/>
                </fo:block>
            </fo:inline-container>
            <fo:inline-container width="70%">
                <xsl:call-template name="header-right"/>
            </fo:inline-container>
        </fo:block>
    </xsl:template>
    <xsl:template name="footer">
        <fo:block xsl:use-attribute-sets="page-number" text-align="center" padding-top="10pt">
            <xsl:text>Page </xsl:text>
            <fo:page-number/>
            <xsl:text> of </xsl:text>
            <fo:page-number-citation ref-id="last-page"/>
        </fo:block>
    </xsl:template>
    <!-- header and footer templates (end)-->
    
    <!-- archdesc named templates (start)-->
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
    <!-- archdesc named templates (end)-->
    
    <!-- dsc named templates (start)-->
    <xsl:template name="dsc-block-identifier-and-title">
        <xsl:if test="ead3:did/ead3:unitid/normalize-space()">
            <xsl:value-of select="concat(ead3:did/ead3:unitid/normalize-space(), '. ')"/>
        </xsl:if>
        <xsl:apply-templates select="if (ead3:did/ead3:unittitle) then ead3:did/ead3:unittitle 
            else ead3:did/ead3:unitdatestructured | ead3:did/ead3:unitdate" mode="dsc"/>
    </xsl:template>
    
    <!-- still neeed options for when dates and/or containers aren't present in a table -->
    <xsl:template name="tableBody">
        <xsl:param name="cell-margin"/>
        <fo:table inline-progression-dimension="100%" table-layout="fixed" font-size="10pt"
            border-collapse="collapse" keep-with-previous.within-page="always" table-omit-header-at-break="{$dsc-omit-table-header-at-break}">
            <fo:table-column column-number="1" column-width="proportional-column-width(60)"/>
            <fo:table-column column-number="2" column-width="proportional-column-width(15)"/>
            <fo:table-column column-number="3" column-width="proportional-column-width(25)"/>
            <xsl:call-template name="tableHeaders">
                <xsl:with-param name="cell-margin" select="$cell-margin"/>
            </xsl:call-template>
            <fo:table-body>
                <xsl:apply-templates select="ead3:*[matches(local-name(), '^c0|^c1') or local-name()='c']" mode="dsc-table"/>
            </fo:table-body>
        </fo:table>
    </xsl:template>
    
    <xsl:template name="tableHeaders">
        <xsl:param name="cell-margin"/>
        <fo:table-header>
            <fo:table-row>
                <fo:table-cell number-columns-spanned="3">
                    <fo:block font-size="9pt">
                        <fo:retrieve-table-marker retrieve-class-name="continued-text" 
                            retrieve-position-within-table="first-starting" 
                            retrieve-boundary-within-table="table-fragment"/> 
                        &#x00A0;
                    </fo:block>
                </fo:table-cell>
            </fo:table-row>
            <fo:table-row>
                <fo:table-cell number-columns-spanned="3">
                    <fo:block>
                        &#x00A0;
                    </fo:block>
                </fo:table-cell>
            </fo:table-row>
            <fo:table-row>
                <fo:table-cell>
                    <fo:block font-weight="700">Description</fo:block>
                </fo:table-cell>
                <fo:table-cell>
                    <fo:block font-weight="700">Date</fo:block>
                </fo:table-cell>
                <fo:table-cell>
                    <fo:block font-weight="700">Container</fo:block>
                </fo:table-cell>    
            </fo:table-row>
        </fo:table-header>
    </xsl:template>
    
    <xsl:template name="dsc-table-row-border">
        <xsl:param name="last-row"/>
        <xsl:param name="no-children"/>
        <xsl:if test="$last-row or $no-children">
            <xsl:attribute name="border-bottom-style">solid</xsl:attribute>
            <xsl:attribute name="border-bottom-width">0.1mm</xsl:attribute>
        </xsl:if>
        <xsl:choose>
            <xsl:when test="$last-row">
                <!--
                <xsl:attribute name="border-bottom-color">#222222</xsl:attribute>
                -->
                <xsl:attribute name="border-bottom-color">#dddddd</xsl:attribute>
            </xsl:when>
            <xsl:when test="$no-children">
                <xsl:attribute name="border-bottom-color">#dddddd</xsl:attribute>
            </xsl:when>
        </xsl:choose>
    </xsl:template>
    
    <!-- not sure how to handle this yet, but ideally i'd like to include extra blocks of text
        to indicate when the table is continued -->
    <xsl:template name="ancestor-info">
        <!-- allow for longer c01 - c03 headings, and then make it smaller from there -->
        <xsl:param name="longest-length-allowed" select="64"/>
        <xsl:variable name="immediate-ancestor" select="ancestor::ead3:*[ead3:did/ead3:unittitle][ancestor::ead3:dsc][1]"/>
        <xsl:variable name="folder-title-plus-unitid">
            <xsl:choose>
                <!-- if there's just a unitid, use that in place of the title and don't inherit anything.
                            the "inherited" title will still appear as an ancestor title on the label due to the sequence-of-series -->
                <xsl:when test="not(ead3:did/ead3:unittitle[normalize-space()]) and ead3:did/ead3:unitid[normalize-space()][not(@audience='internal')]">
                    <xsl:value-of select="ead3:did/ead3:unitid[not(@audience='internal')][1]"/>
                </xsl:when>
                <!-- if there's no unitid or title, then grab an ancestor title and unitid, since 
                            the component might only have a unitdate.  later, we'll filter this out of the sequence-of-series list of titles. -->
                <xsl:when test="not(ead3:did/ead3:unittitle[normalize-space()])">
                    <xsl:if test="$immediate-ancestor[ead3:did/ead3:unitid]">
                        <xsl:value-of select="concat($immediate-ancestor/ead3:did/ead3:unitid[not(@audience='internal')][1], ' ')"/>
                    </xsl:if>
                    <xsl:value-of select="$immediate-ancestor/ead3:did/ead3:unittitle[1]"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:if test="normalize-space(ead3:did/ead3:unitid[not(@audience='internal')][1])">
                        <xsl:value-of select="normalize-space(ead3:did/ead3:unitid[not(@audience='internal')][1])"/>
                        <xsl:text> </xsl:text>
                    </xsl:if>
                    <xsl:value-of select="normalize-space(ead3:did/ead3:unittitle[1])"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="ancestor-sequence">
            <xsl:sequence select="string-join(
                for $ancestor in ancestor::*[ead3:did][ancestor::ead3:dsc] return 
                if ($ancestor/ead3:did/ead3:unitid/not(ends-with(normalize-space(), '.'))
                and $ancestor/lower-case(@level) eq 'series') 
                then concat($ancestor/ead3:did/ead3:unitid/normalize-space(), '. ', $ancestor/ead3:did/ead3:unittitle/normalize-space())
                else if (ends-with($ancestor/ead3:did/ead3:unitid/normalize-space(), '.'))
                then concat($ancestor/ead3:did/ead3:unitid/normalize-space(), ' ', $ancestor/ead3:did/ead3:unittitle/normalize-space())
                else if ($ancestor/ead3:did/ead3:unitid/normalize-space()) then concat($ancestor/ead3:did/ead3:unitid/normalize-space(), ' ', $ancestor/ead3:did/ead3:unittitle/normalize-space())
                else $ancestor/ead3:did/ead3:unittitle/normalize-space()
                , 'xx*****yz')"/>
        </xsl:variable>
        <xsl:variable name="ancestor-sequence-filtered">
            <xsl:sequence select="string-join(remove($ancestor-sequence
                , if (exists(index-of($ancestor-sequence, $folder-title-plus-unitid))) 
                then index-of($ancestor-sequence, $folder-title-plus-unitid)
                else 0)
                , 'xx*****yz')"/>
        </xsl:variable>
        <xsl:variable name="series-of-series" select="if (contains($ancestor-sequence-filtered, 'xx*****yz'))
            then tokenize($ancestor-sequence-filtered, 'xx\*\*\*\*\*yz') else $ancestor-sequence-filtered"/>
        <xsl:for-each select="$series-of-series[normalize-space()]">
            <fo:inline font-style="italic">
                <xsl:value-of select="if (string-length(.) gt $longest-length-allowed) 
                    then concat(substring(., 1, $longest-length-allowed), ' [...]') 
                    else ."/>
                <xsl:if test="position() ne last()">
                    <xsl:text> > </xsl:text>
                </xsl:if>
                <xsl:if test="position() eq last()">
                    <xsl:text> (Continued)</xsl:text>
                </xsl:if>
            </fo:inline>
        </xsl:for-each>
    </xsl:template>
    
    <xsl:template name="container-layout">
        <xsl:param name="containers-sorted-by-localtype"/>
        <xsl:choose>
            <!-- the middle step, i.e. *, in these cases is the localtype (e.g. box, volume, etc.) -->
            <xsl:when test="count($containers-sorted-by-localtype/*/container-group) gt 1">
                <xsl:for-each select="$containers-sorted-by-localtype/*/container-group">
                    <fo:block>
                        <xsl:apply-templates/>
                    </fo:block> 
                </xsl:for-each>                
            </xsl:when>
            <xsl:otherwise>
                <fo:block>
                    <xsl:apply-templates select="$containers-sorted-by-localtype/*/container-group"/>
                </fo:block> 
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    
    <!-- dsc named templates (end) -->
    
    <xsl:template name="section-start">
        <fo:block keep-with-next.within-page="always">
            <fo:leader leader-pattern="rule"
                rule-thickness="0.75pt"
                leader-length="7.25in"/>
        </fo:block>
    </xsl:template>
      
</xsl:stylesheet>
