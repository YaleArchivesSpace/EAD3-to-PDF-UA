<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:fo="http://www.w3.org/1999/XSL/Format" xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:fox="http://xmlgraphics.apache.org/fop/extensions"
    xmlns:ead3="http://ead3.archivists.org/schema/" exclude-result-prefixes="xs ead3 fox"
    version="2.0">

    <!-- this file is imported by "ead3-to-pdf-ua.xsl" -->
    
    <!-- to do:  should this be a list, instead?
    the table markup is quite bloated. -->

    <xsl:template match="ead3:archdesc" mode="toc">
        <fo:page-sequence master-reference="table-of-contents">
            <!-- Page header -->
            <fo:static-content flow-name="xsl-region-before">
                <fo:block/>
            </fo:static-content>
            <!-- Page footer-->
            <fo:static-content flow-name="xsl-region-after">
                <fo:block/>
            </fo:static-content>
            <!-- Content of page -->
            <fo:flow flow-name="xsl-region-body">
                <xsl:call-template name="section-start"/>
                <fo:block xsl:use-attribute-sets="h3" id="toc">Table of Contents</fo:block>
                <fo:block xsl:use-attribute-sets="toc-block">
                    <xsl:apply-templates select="ead3:did" mode="toc"/>
                    <xsl:if test="ead3:acqinfo, ead3:custodhist, ead3:accessrestrict, ead3:userestrict, ead3:prefercite
                        , ead3:processinfo, ead3:altformavail, ead3:relatedmaterial, ead3:separatedmaterial, ead3:accruals, ead3:appraisals
                        , ead3:originalsloc, ead3:otherfindingaid, ead3:phystech, ead3:fileplan">
                        <fo:block text-align-last="justify">
                            <fo:basic-link internal-destination="admin-info">
                                <xsl:value-of select="$admin-info-title"/>
                                <xsl:text> </xsl:text><fo:leader leader-pattern="dots"/><xsl:text> </xsl:text>
                                <fo:page-number-citation ref-id="admin-info"/>
                            </fo:basic-link>
                        </fo:block>
                        <xsl:apply-templates select="ead3:acqinfo, ead3:custodhist, ead3:accessrestrict, ead3:userestrict, ead3:prefercite
                            , ead3:processinfo, ead3:altformavail, ead3:relatedmaterial, ead3:separatedmaterial, ead3:accruals, ead3:appraisals
                            , ead3:originalsloc, ead3:otherfindingaid, ead3:phystech, ead3:fileplan" mode="toc">
                            <xsl:with-param name="margin-left" select="'10pt'"/>
                        </xsl:apply-templates>
                    </xsl:if>
                    <xsl:apply-templates select="ead3:bioghist, ead3:scopecontent
                        , ead3:odd[not(contains(lower-case(ead3:head), 'index'))]
                        , ead3:bibliography, ead3:arrangement" mode="toc"/>
                    <xsl:apply-templates select="ead3:dsc" mode="toc"/>
                    <xsl:apply-templates select="ead3:odd[contains(lower-case(ead3:head), 'index')]
                        , ead3:index
                        , ead3:controlaccess" mode="toc"/>
                </fo:block>
            </fo:flow>
        </fo:page-sequence>
    </xsl:template>
    
    <xsl:template match="ead3:did" mode="toc">
        <fo:block text-align-last="justify">
            <fo:basic-link internal-destination="contents">
                <xsl:value-of select="$archdesc-did-title"/>
                <xsl:text> </xsl:text><fo:leader leader-pattern="dots"/><xsl:text> </xsl:text>
                <fo:page-number-citation ref-id="contents"/>
            </fo:basic-link>
        </fo:block>
    </xsl:template>
    
    <xsl:template match="ead3:*" mode="toc">
        <xsl:param name="margin-left"/>
        <xsl:variable name="id-for-link" select="if (@id) then @id else generate-id(.)"/>
        <fo:block text-align-last="justify">
            <xsl:if test="$margin-left">
                <xsl:attribute name="margin-left" select="$margin-left"/>
            </xsl:if>
            <fo:basic-link internal-destination="{$id-for-link}">
                <xsl:apply-templates select="ead3:head" mode="#current"/>
                <xsl:text> </xsl:text><fo:leader leader-pattern="dots"/><xsl:text> </xsl:text>
                <fo:page-number-citation ref-id="{$id-for-link}"/>
            </fo:basic-link>
        </fo:block>
    </xsl:template>
    
    <xsl:template match="ead3:dsc" mode="toc">
        <fo:block text-align-last="justify">
            <fo:basic-link internal-destination="dsc-contents">
                <xsl:value-of select="$dsc-title"/>
                <xsl:text> </xsl:text><fo:leader leader-pattern="dots"/><xsl:text> </xsl:text>
                <fo:page-number-citation ref-id="dsc-contents"/>
            </fo:basic-link>
        </fo:block>
        <xsl:apply-templates select="ead3:*[local-name()=('c01', 'c')][@level=$levels-to-include-in-toc or @otherlevel=$otherlevels-to-include-in-toc]"
            mode="#current"/>
    </xsl:template>
    
    <xsl:template match="ead3:*[matches(local-name(), '^c0|^c1') or local-name()='c'][@level=$levels-to-include-in-toc or @otherlevel=$otherlevels-to-include-in-toc]" mode="toc">
        <xsl:variable name="id-for-link" select="if (@id) then @id else generate-id(.)"/>
        <!-- should change this into a function, since I re-use it, but haven't done that yet!-->
        <xsl:variable name="depth" select="count(ancestor::*) - 2"/> 
        <xsl:variable name="margin-left" select="concat(xs:string($depth * 10), 'pt')"/>       
        <fo:block text-align-last="justify" margin-left="{$margin-left}">
            <fo:basic-link internal-destination="{$id-for-link}">
                <xsl:if test="ead3:did/ead3:unitid/normalize-space()">
                    <xsl:value-of select="concat(ead3:did/ead3:unitid/normalize-space(), '. ')"/>
                </xsl:if>
                <xsl:apply-templates select="ead3:did/ead3:unittitle"/>
                <xsl:text> </xsl:text><fo:leader leader-pattern="dots"/><xsl:text> </xsl:text>
                <fo:page-number-citation ref-id="{$id-for-link}"/>
            </fo:basic-link>
        </fo:block>
        <xsl:apply-templates select="ead3:*[matches(local-name(), '^c0|^c1') or local-name()='c'][@level=$levels-to-include-in-toc or @otherlevel=$otherlevels-to-include-in-toc]" mode="#current"/>
    </xsl:template>
    
    <xsl:template match="ead3:controlaccess" mode="toc">
        <fo:block text-align-last="justify">
            <fo:basic-link internal-destination="control-access">
                <xsl:value-of select="$control-access-title"/>
                <xsl:text> </xsl:text><fo:leader leader-pattern="dots"/><xsl:text> </xsl:text>
                <fo:page-number-citation ref-id="control-access"/>
            </fo:basic-link>
        </fo:block>
    </xsl:template>
    
</xsl:stylesheet>