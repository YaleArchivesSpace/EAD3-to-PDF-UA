<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:fo="http://www.w3.org/1999/XSL/Format" xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:fox="http://xmlgraphics.apache.org/fop/extensions"
    xmlns:ead3="http://ead3.archivists.org/schema/" exclude-result-prefixes="xs ead3"
    version="2.0">

    <xsl:output method="xml" encoding="UTF-8"/>

    <xsl:include href="embedded-metadata.xsl"/>
    <xsl:include href="attributes.xsl"/>
    <xsl:include href="bookmarks.xsl"/>
    <xsl:include href="common-block-and-inline-elements.xsl"/>
    <xsl:include href="functions-and-named-templates.xsl"/> 
    
    <xsl:include href="cover-page.xsl"/> 
    <xsl:include href="table-of-contents.xsl"/>
    
    <xsl:include href="archdesc.xsl"/>
    <xsl:include href="dsc.xsl"/>
    <xsl:include href="odd-index.xsl"/>
    <xsl:include href="index.xsl"/>
    <xsl:include href="controlaccess.xsl"/>
    
    <!-- to do:
          add Odd (index), Index
          
          fix up block and inline stylings.
          
          test Digital Object links. any way to get thumbnails?
          
          check that the use of "modes" is consistent and makes sense.
          
          decide on what gets added to table of contents and bookmarks. always the same?  skip a c01 really if it's labelled an item?, etc.
          
          create a list of other fonts needed for other languages that will be present (e.g. arabic, cjk languages, etc)
          then add those as secondary font options when/where needed, such as the following example:
           <fo:block font-family="Helvetica, SimSun">Paul 你好</fo:block>
                   
          add red boxes around anything that has audience = internal. (also flag in table of contents / bookmarks?)
		 
		  future dev:
		  - upgrade to FOP 2.3
		  - test out request links, passing last-updated-date info so as to ensure the data that's passed is up-to-date.
		  - add another section (or linked file) that's a flattened container list sorted by box number?  probably better to serve this up as an Excel or CSV file.
		  - update so that this process won't only expect files to be produced by ASpace (e.g. nested control access sections, multiple DSC elements, etc.)
		 
		  refactor, refactor, refactor. 
      -->

    <!--======== Requirements ========-->
    <!-- 
    Apache FOP 2.2 (version 2.1 should also work)
    
    for instructions on how to turn on the built-in accessibility features in FOP, see:
    
    https://xmlgraphics.apache.org/fop/2.2/accessibility.html
    
    This XSL-FO process has been written for EAD3 files that produced by ArchivesSpace, version 2.2.
    Those exports are first processed by another XSLT transformtion, however, to clean up some of the potentially-invalid / 
    problematic EAD that ArchivesSpace can produce.
    -->
    <!--======== End: Requirements ========-->

    <!-- global parameters -->
    <xsl:param name="primary-language-of-finding-aid" select="'en'"/>
    <xsl:param name="primary-font-for-pdf" select="'Yale'"/>
    <xsl:param name="serif-font" select="'Yale'"/>
    <xsl:param name="sans-serif-font" select="'Mallory'"/>
    <xsl:param name="include-audience-equals-internal" select="false()"/>
    <xsl:param name="start-page-1-after-table-of-contents" select="false()"/>
    <xsl:param name="dsc-omit-table-header-at-break" select="false()"/>
    
    <xsl:param name="archdesc-did-title" select="'Collection Overview'"/>
    <xsl:param name="admin-info-title" select="'Administrative Information'"/>
    <xsl:param name="dsc-title" select="'Collection Contents'"/>
    <xsl:param name="control-access-title" select="'Names and Subjects'"/>
    
    <xsl:param name="odd-headings-to-add-at-end" select="'index|appendix'"/>
    
    <xsl:param name="levels-to-include-in-toc" select="('series', 'subseries', 'collection', 'fonds', 'recordgrp', 'subgrp')"/>
    <xsl:param name="otherlevels-to-include-in-toc" select="('accession', 'acquisition')"/>
     
    <!-- document-based variables -->
    <xsl:variable name="finding-aid-title" select="ead3:ead/ead3:control/ead3:filedesc/ead3:titlestmt/ead3:titleproper[1][not(@localtype = 'filing')]"/>
    <xsl:variable name="finding-aid-author" select="ead3:ead/ead3:control/ead3:filedesc/ead3:titlestmt/ead3:author"/>
    <xsl:variable name="finding-aid-summary"
        select="
            if (ead3:ead/ead3:archdesc/ead3:did/ead3:abstract[1])
            then
                ead3:ead/ead3:archdesc/ead3:did/ead3:abstract[1]
            else
                ead3:ead/ead3:archdesc/ead3:scopecontent[1]/ead3:p[1]"/>
    <!--example: <recordid instanceurl="http://hdl.handle.net/10079/fa/beinecke.ndy10">beinecke.ndy10</recordid> -->
    <xsl:variable name="finding-aid-identifier" select="ead3:ead/ead3:control/ead3:recordid[1]"/>
    <xsl:variable name="holding-repository" select="ead3:ead/ead3:archdesc/ead3:did/ead3:repository[1]"/>
    <!-- do i need a variable for the repository code, or can we trust that the repository names won't be edited in ASpace?
    probably shouldn't trust that... so....-->
    <xsl:variable name="repository-code" select="ead3:ead/ead3:control/ead3:recordid[1]/substring-before(., '.')"/>
    <xsl:variable name="collection-title" select="ead3:ead/ead3:archdesc/ead3:did/ead3:unittitle[1]"/>
    <xsl:variable name="collection-identifier" select="ead3:ead/ead3:archdesc/ead3:did/ead3:unitid[not(@audience = 'internal')][1]"/>
    <!-- last page options are controlacces, odd/head contains index, index, dsc, archdesc -->
    <xsl:variable name="last-page" select="if (ead3:ead/ead3:archdesc/ead3:controlaccess) then 'controlaccess'
        else if (ead3:ead/ead3:archdesc/ead3:odd[matches(lower-case(normalize-space(ead3:head)), $odd-headings-to-add-at-end)]) then 'odd-index'
        else if (ead3:ead/ead3:archdesc/ead3:index) then 'index'
        else if (ead3:ead/ead3:archdesc/ead3:dsc[*]) then 'dsc'
        else 'archdesc'"/>

    <!--========== PAGE SETUP =======-->
    <xsl:template match="/">
        <fo:root xml:lang="{$primary-language-of-finding-aid}" font-family="{$primary-font-for-pdf}">
            <fo:layout-master-set>
                <xsl:call-template name="define-page-masters"/>
                <xsl:call-template name="define-page-sequences"/>
            </fo:layout-master-set>
            <!-- Adds embedded metadata, which is required for the title, at least, to ensure compatibility with the PDF-UA standard  -->
            <xsl:call-template name="embed-metadata"/>
            <!-- Builds PDF bookmarks  -->
            <xsl:apply-templates select="ead3:ead/ead3:archdesc" mode="bookmarks"/>
            <!-- see cover-page.xsl -->
            <xsl:apply-templates select="ead3:ead/ead3:control"/>
            <!-- see table-of-contents.xsl -->
            <xsl:apply-templates select="ead3:ead/ead3:archdesc" mode="toc"/>
            <!-- see archdesc.xsl -->
            <xsl:apply-templates select="ead3:ead/ead3:archdesc[*]"/>
            <!-- see dsc.xsl -->
            <xsl:apply-templates select="ead3:ead/ead3:archdesc/ead3:dsc[*]"/>
            
            <!-- see odd-index.xsl -->
            <xsl:apply-templates select="ead3:ead/ead3:archdesc/ead3:odd[matches(lower-case(normalize-space(ead3:head)), $odd-headings-to-add-at-end)][1]"/>
            <!-- see index.xsl -->
            <xsl:apply-templates select="ead3:ead/ead3:archdesc/ead3:index[1]"/>
            
            <!-- see controlaccess.xsl -->
            <xsl:apply-templates select="ead3:ead/ead3:archdesc[ead3:controlaccess/*]" mode="control-access-section"/>
        </fo:root>
    </xsl:template>

    <xsl:template name="define-page-masters">
        <!-- Page master for Cover Page -->
        <fo:simple-page-master master-name="cover" page-height="11in" page-width="8.5in" margin="0.2in">
            <fo:region-body margin="1.5in 0.3in 0.3in 0.3in"/>
            <fo:region-before extent="1.5in"/>
            <fo:region-after extent="0.3in"/>
            <fo:region-start extent="0.3in"/>
            <fo:region-end extent="0.3in"/>
        </fo:simple-page-master>
        <!-- Page master for Table of Contents -->
        <fo:simple-page-master master-name="table-of-contents" page-height="11in" page-width="8.5in" margin="0.2in">
            <fo:region-body margin="0.5in 0.3in 0.3in 0.3in"/>
            <fo:region-before extent="0.5in"/>
            <fo:region-after extent="0.3in"/>
            <fo:region-start extent="0.3in"/>
            <fo:region-end extent="0.3in"/>
        </fo:simple-page-master>
        <!-- Page master for Archdesc -->
        <fo:simple-page-master master-name="archdesc" page-height="11in" page-width="8.5in" margin="0.2in">
            <fo:region-body margin="0.5in 0.3in 0.3in 0.3in"/>
            <fo:region-before extent="0.5in"/>
            <fo:region-after extent="0.3in"/>
            <fo:region-start extent="0.3in"/>
            <fo:region-end extent="0.3in"/>
        </fo:simple-page-master>
        <!-- Page master for DSC -->
        <fo:simple-page-master master-name="contents" page-height="11in" page-width="8.5in" margin="0.2in">
            <fo:region-body margin="0.5in 0.3in 0.3in 0.3in"/>
            <fo:region-before extent="0.5in"/>
            <fo:region-after extent="0.3in"/>
            <fo:region-start extent="0.3in"/>
            <fo:region-end extent="0.3in"/>
        </fo:simple-page-master>
        <!-- Page master for Index -->
        <fo:simple-page-master master-name="index" page-height="11in" page-width="8.5in" margin="0.2in">
            <fo:region-body column-count="2" column-gap=".5in" margin="0.5in 0.3in 0.3in 0.3in"/>
            <fo:region-before extent="0.5in"/>
            <fo:region-after extent="0.3in"/>
            <fo:region-start extent="0.3in"/>
            <fo:region-end extent="0.3in"/>
        </fo:simple-page-master>
        <!-- Page master for Control Accession -->
        <fo:simple-page-master master-name="control-access" page-height="11in" page-width="8.5in" margin="0.2in">
            <fo:region-body column-count="2" column-gap=".5in" margin="0.5in 0.3in 0.3in 0.3in"/>
            <fo:region-before extent="0.5in"/>
            <fo:region-after extent="0.3in"/>
            <fo:region-start extent="0.3in"/>
            <fo:region-end extent="0.3in"/>
        </fo:simple-page-master>
    </xsl:template>

    <xsl:template name="define-page-sequences">
        <!-- any reason (or design choice) to specify recto and verso??? -->
        <fo:page-sequence-master master-name="cover-sequence">
            <fo:single-page-master-reference master-reference="cover"/>
        </fo:page-sequence-master>
        <fo:page-sequence-master master-name="toc-sequence">
            <fo:repeatable-page-master-reference master-reference="table-of-contents"/>
        </fo:page-sequence-master>
        <fo:page-sequence-master master-name="archdesc-sequence">
            <fo:repeatable-page-master-reference master-reference="archdesc"/>
        </fo:page-sequence-master>
        <fo:page-sequence-master master-name="dsc-sequence">
            <fo:repeatable-page-master-reference master-reference="contents"/>
        </fo:page-sequence-master>
        <fo:page-sequence-master master-name="odd-index-sequence">
            <fo:repeatable-page-master-reference master-reference="index"/>
        </fo:page-sequence-master>
        <fo:page-sequence-master master-name="index-sequence">
            <fo:repeatable-page-master-reference master-reference="index"/>
        </fo:page-sequence-master>
        <fo:page-sequence-master master-name="ca-sequence">
            <fo:repeatable-page-master-reference master-reference="control-access"/>
        </fo:page-sequence-master>
        <!-- whatever else that's required for access headings, end-of-file indices, etc. -->
    </xsl:template>
    <!--========== END: PAGE SETUP =======-->
</xsl:stylesheet>
