<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:fo="http://www.w3.org/1999/XSL/Format" xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:fox="http://xmlgraphics.apache.org/fop/extensions"
    xmlns:ead3="http://ead3.archivists.org/schema/" exclude-result-prefixes="xs ead3 fox"
    version="2.0">

    
    <!-- to do: update so that these two templates aren't so repetive, since the structure should only differ slightly, I think -->

    <!-- this file is imported by "ead3-to-pdf-ua.xsl" -->
    <xsl:template match="ead3:archdesc" mode="control-access-section">
        <fo:page-sequence master-reference="control-access">
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
                <fo:block xsl:use-attribute-sets="h3" id="control-access" span="all">
                    <xsl:value-of select="$control-access-title"/>
                </fo:block>
                <fo:block span="all">
                    <xsl:value-of select="$control-access-context-note"/>
                </fo:block>
                <fo:block>
                    <xsl:apply-templates select="ead3:controlaccess"/>
                </fo:block>
                <!-- adding this to grab the last page number-->
                <xsl:if test="$last-page eq 'controlaccess'">
                    <fo:wrapper id="last-page"/>
                </xsl:if>
            </fo:flow>
        </fo:page-sequence>
    </xsl:template>
    
    <xsl:template match="ead3:controlaccess">
        <!-- even though controlaccess can have children such as head, blockquote, and table
            ASpace cannot support that, so we're only expecting children elements that are actual
            access headings-->
        <xsl:for-each-group select="*" group-by="local-name()">
            <xsl:variable name="current-group-size" select="count(current-group())"/>
            <fo:block margin-top="25pt" margin-left="10pt">
                <fo:block font-weight="700" xsl:use-attribute-sets="h4">
                    <!-- should we change values if there's only one heading?  e.g. Subject instead of Subjects?
                    if so, then we can use the current-group-size variable.  when 1, it's singular.-->
                    <xsl:value-of select="if (current-grouping-key() eq 'corpname')
                        then 
                            if ($current-group-size eq 1) then 'Corporate Body' else 'Corporate Bodies'
                        else if (current-grouping-key() eq 'famname')
                        then 'Families'
                        else if (current-grouping-key() eq 'function')
                        then 'Functions'
                        else if (current-grouping-key() eq 'genreform')
                        then 'Genres / Formats'
                        else if (current-grouping-key() eq 'geogname')
                        then 'Geographic Names'
                        else if (current-grouping-key() eq 'occupation')
                        then 'Occupations'
                        else if (current-grouping-key() = ('persname', 'name'))
                        then 'Names'
                        else if (current-grouping-key() eq 'subject')
                        then 'Subjects'
                        else if (current-grouping-key() eq 'title')
                        then 'Preferred Titles'
                        else ''"/>
                </fo:block>
                <fo:list-block>
                    <xsl:for-each select="current-group()">
                        <xsl:sort select="." data-type="text"/>
                        <xsl:for-each select=".">
                            <fo:list-item>
                                <fo:list-item-label>
                                    <fo:block/>
                                </fo:list-item-label>
                                <fo:list-item-body>
                                    <fo:block>
                                        <xsl:apply-templates/>
                                        <xsl:if test="@relator">
                                            <xsl:text>, </xsl:text>
                                            <xsl:value-of select="key('relator-code', @relator, $cached-list-of-relators)/lower-case(label)"/>
                                        </xsl:if>
                                    </fo:block>
                                </fo:list-item-body>
                            </fo:list-item>
                        </xsl:for-each>
                    </xsl:for-each>
                </fo:list-block>
            </fo:block>
        </xsl:for-each-group>
    </xsl:template>
    
    <xsl:template match="ead3:controlaccess" mode="dsc">
        <xsl:for-each-group select="*" group-by="local-name()">
            <xsl:variable name="current-group-size" select="count(current-group())"/>
            <fo:block margin="10pt">
                <fo:block>
                    <!-- should we change values if there's only one heading?  e.g. Subject instead of Subjects?
                    if so, then we can use the current-group-size variable.  when 1, it's singular.-->
                    <xsl:value-of select="if (current-grouping-key() eq 'corpname')
                        then 
                        if ($current-group-size eq 1) then 'Corporate Body:' else 'Corporate Bodies:'
                        else if (current-grouping-key() eq 'famname')
                        then 'Families:'
                        else if (current-grouping-key() eq 'function')
                        then 'Functions:'
                        else if (current-grouping-key() eq 'genreform')
                        then 'Genres / Formats:'
                        else if (current-grouping-key() eq 'geogname')
                        then 'Geographic Names:'
                        else if (current-grouping-key() eq 'occupation')
                        then 'Occupations:'
                        else if (current-grouping-key() = ('persname', 'name'))
                        then 'Names:'
                        else if (current-grouping-key() eq 'subject')
                        then 'Subjects:'
                        else if (current-grouping-key() eq 'title')
                        then 'Preferred Titles:'
                        else ''"/>
                </fo:block>
                <fo:list-block margin-left="1em">
                    <xsl:for-each select="current-group()">
                        <xsl:sort select="." data-type="text"/>
                        <xsl:for-each select=".">
                            <fo:list-item>
                                <fo:list-item-label>
                                    <fo:block/>
                                </fo:list-item-label>
                                <fo:list-item-body>
                                    <fo:block>
                                        <xsl:apply-templates/>
                                        <xsl:if test="@relator">
                                            <xsl:text>, </xsl:text>
                                            <xsl:value-of select="key('relator-code', @relator, $cached-list-of-relators)/lower-case(label)"/>
                                        </xsl:if>
                                    </fo:block>
                                </fo:list-item-body>
                            </fo:list-item>
                        </xsl:for-each>
                    </xsl:for-each>
                </fo:list-block>
            </fo:block>
        </xsl:for-each-group>
    </xsl:template>

</xsl:stylesheet>