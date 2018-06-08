<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:fo="http://www.w3.org/1999/XSL/Format" xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:fox="http://xmlgraphics.apache.org/fop/extensions"
  xmlns:ead3="http://ead3.archivists.org/schema/" exclude-result-prefixes="xs ead3 fox"
  version="2.0">

  <!-- this file is imported by "ead3-to-pdf-ua.xsl" -->

  <!-- block elements:
    bibliography
    chronlist
    deflist
    index
    what else?
    -->

  <!-- not used often, but used by the container-grouping and sorting method -->
  <xsl:template match="@* | node()" mode="copy">
    <xsl:copy>
      <xsl:apply-templates select="@* | node()" mode="#current"/>
    </xsl:copy>
  </xsl:template>

  <!-- stand-alone block elements go here (not adding values like unitid and unittitle, however, since those will be handled differently
    a lot of these are handled differently as a LIST, however, when at the colleciton level.-->
  <xsl:template
    match="
      ead3:unitid | ead3:abstract | ead3:addressline | ead3:langmaterial | ead3:materialspec | ead3:origination | ead3:physdesc[not(@localtype = 'container_summary')]
      | ead3:physloc | ead3:repository"
    mode="dsc">
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

  <!-- currently used in the adminstrative info section of the collection overview -->
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
    <fo:block space-after="8pt">
      <xsl:apply-templates/>
    </fo:block>
  </xsl:template>

  <xsl:template match="ead3:blockquote" mode="#all">
    <fo:block margin="4pt 18pt">
      <xsl:apply-templates/>
    </fo:block>
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
  <xsl:template match="ead3:unitdate" mode="#all">
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

  <xsl:template match="ead3:physdesc[@localtype = 'container_summary']" mode="#all">
    <xsl:text> </xsl:text>
    <xsl:choose>
      <xsl:when
        test="not(starts-with(normalize-space(), '(')) and not(ends-with(normalize-space(), ')'))">
        <xsl:text>(</xsl:text>
        <xsl:apply-templates/>
        <xsl:text>)</xsl:text>
      </xsl:when>
      <xsl:otherwise>
        <xsl:apply-templates/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="ead3:physfacet" mode="#all">
    <xsl:if test="preceding-sibling::*">
      <xsl:text> : </xsl:text>
    </xsl:if>
    <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match="ead3:dimensions" mode="#all">
    <xsl:if test="preceding-sibling::*">
      <xsl:text> ; </xsl:text>
    </xsl:if>
    <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match="ead3:title" mode="#all">
    <fo:inline font-style="italic">
      <xsl:apply-templates/>
    </fo:inline>
  </xsl:template>


  <!-- Block <list> Template -->
  <xsl:template match="ead3:list">
    <xsl:variable name="numeration-type" select="@numeration"/>
    <!-- valid options in EAD3 (although a few, like Armenian, would require a fair bit of work to support, I think):
      armenian, decimal, decimal-leading-zero, georgian, inherit, lower-alpha, lower-greek, 
      lower-latin, lower-roman, upper-alpha, upper-latin, upper-roman
      -->
    <fo:list-block start-indent="5mm" provisional-distance-between-starts="35mm">
      <xsl:apply-templates select="ead3:head | ead3:listhead"/>
      <xsl:apply-templates select="ead3:item | ead3:defitem">
        <xsl:with-param name="numeration-type"/>
      </xsl:apply-templates>
    </fo:list-block>
  </xsl:template>

  <xsl:template match="ead3:item">
    <xsl:param name="numeration-type"/>
    <fo:list-item space-after="1em">
      <fo:list-item-label>
        <xsl:choose>
          <xsl:when test="$numeration-type"></xsl:when>
        </xsl:choose>
      </fo:list-item-label>
      <fo:list-item-body start-indent="body-start()" end-indent="5mm">
        <fo:block>
          <xsl:apply-templates/>
        </fo:block>
      </fo:list-item-body>
    </fo:list-item>
  </xsl:template>

  <!-- Block <chronlist> Template -->
  <xsl:template match="ead3:chronlist" mode="#all">
    <fo:table table-layout="fixed" width="100%" space-after.optimum="15pt">
      <!-- need a test still to determine if we're going to create a
        2 column table (dates, events), or a 
        3 column table (dates, events, geographic locations)...
        or handle those geographic locations another way.
      -->
      <fo:table-column column-width="3cm"/>
      <fo:table-column column-width="10cm"/>
      <fo:table-column column-width="3cm"/>
      <xsl:if test="ead3:head or ead3:listhead">
        <fo:table-header>
          <fo:table-row>
            <xsl:choose>
              <xsl:when test="ead3:head">
                <fo:table-cell number-columns-spanned="3">
                  <xsl:apply-templates select="ead3:head"/>
                </fo:table-cell>
              </xsl:when>
              <xsl:otherwise>
                <xsl:for-each select="ead3:listhead/*">
                  <fo:table-cell number-columns-spanned="1">
                    <xsl:apply-templates/>
                  </fo:table-cell>
                </xsl:for-each>
              </xsl:otherwise>
            </xsl:choose>
          </fo:table-row>
        </fo:table-header>
      </xsl:if>
      <fo:table-body>
        <xsl:apply-templates select="ead3:chronitem"/>
      </fo:table-body>
    </fo:table>
  </xsl:template>
  

  <!-- Block <chronitem> Template -->
  <xsl:template match="ead3:chronitem">
    <!--chronitemset, daterange, dateset, datesingle, event, geogname -->
    <fo:table-row>
      <fo:table-cell>
        <fo:block space-before.optimum="10pt" text-align="start">
          <xsl:apply-templates select="ead3:datesingle | ead3:daterange | ead3:dateset"/>
        </fo:block>
      </fo:table-cell>
      <fo:table-cell>
        <fo:block space-before.optimum="10pt" text-align="start"/>
      </fo:table-cell>
      <fo:table-cell>
        <fo:block space-before.optimum="10pt" text-align="start">
          <xsl:for-each select="ead3:eventgrp/ead3:event">
            <fo:block>
              <xsl:apply-templates/>
            </fo:block>
          </xsl:for-each>
          <xsl:for-each select="ead3:event">
            <fo:block>
              <xsl:apply-templates/>
            </fo:block>
          </xsl:for-each>
        </fo:block>
      </fo:table-cell>
    </fo:table-row>
  </xsl:template>

  <!-- Block <table> Template -->
  <xsl:template match="ead3:table">
    <fo:table use-attribute-sets="table">
      <xsl:apply-templates/>
    </fo:table>
  </xsl:template>

  <!-- Block <tgroup> Template -->
  <xsl:template match="ead3:tgroup">
    <xsl:call-template name="table-column">
      <xsl:with-param name="cols">
        <xsl:value-of select="@cols"/>
      </xsl:with-param>
      <xsl:with-param name="width_percent">
        <xsl:value-of select="100 div @cols"/>
      </xsl:with-param>
    </xsl:call-template>
    <xsl:apply-templates/>
  </xsl:template>

  <!-- Template called by Block <tgroup> Template-->
  <!-- Inserts <fo:table-column>s necessary to set columns widths. -->
  <xsl:template name="table-column">
    <xsl:param name="cols"/>
    <xsl:param name="width_percent"/>
    <xsl:if test="$cols > 0">
      <fo:table-column>
        <xsl:attribute name="column-width">
          <xsl:value-of select="$width_percent"/>
          <xsl:text>%</xsl:text>
        </xsl:attribute>
      </fo:table-column>
      <xsl:call-template name="table-column">
        <xsl:with-param name="cols">
          <xsl:value-of select="$cols - 1"/>
        </xsl:with-param>
        <xsl:with-param name="width_percent">
          <xsl:value-of select="$width_percent"/>
        </xsl:with-param>
      </xsl:call-template>
    </xsl:if>
  </xsl:template>

  <!-- Block <thead> Template -->
  <xsl:template match="ead3:thead">
    <fo:table-header use-attribute-sets="table.head">
      <xsl:apply-templates/>
    </fo:table-header>
  </xsl:template>

  <!-- Block <tbody> Template -->
  <xsl:template match="ead3:tbody">
    <fo:table-body>
      <xsl:apply-templates/>
    </fo:table-body>
  </xsl:template>

  <!-- Block <row> Template -->
  <xsl:template match="ead3:row">
    <fo:table-row>
      <xsl:apply-templates select="ead3:entry"/>
    </fo:table-row>
  </xsl:template>

  <!-- Block <entry> Template -->
  <xsl:template match="ead3:entry">
    <fo:table-cell use-attribute-sets="table.cell">
      <xsl:if test="@align">
        <xsl:attribute name="text-align">
          <xsl:choose>
            <xsl:when test="@align = 'left'">
              <xsl:text>start</xsl:text>
            </xsl:when>
            <xsl:when test="@align = 'right'">
              <xsl:text>end</xsl:text>
            </xsl:when>
            <xsl:when test="@align = 'center'">
              <xsl:text>center</xsl:text>
            </xsl:when>
            <xsl:when test="@align = 'justify'">
              <xsl:text>justify</xsl:text>
            </xsl:when>
            <xsl:when test="@align = 'char'">
              <xsl:text>start</xsl:text>
            </xsl:when>
          </xsl:choose>
        </xsl:attribute>
      </xsl:if>
      <xsl:if
        test="@valign | parent::ead3:row/@valign | parent::ead3:row/parent::ead3:tbody/@valign | parent::ead3:row/parent::ead3:thead/@valign">
        <xsl:attribute name="display-align">
          <xsl:choose>
            <xsl:when test="@valign">
              <xsl:call-template name="valign.choose"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:choose>
                <xsl:when test="parent::ead3:row/@valign">
                  <xsl:for-each select="parent::ead3:row">
                    <xsl:call-template name="valign.choose"/>
                  </xsl:for-each>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:choose>
                    <xsl:when test="parent::ead3:row/parent::ead3:tbody/@valign">
                      <xsl:for-each select="parent::ead3:row/parent::ead3:tbody">
                        <xsl:call-template name="valign.choose"/>
                      </xsl:for-each>
                    </xsl:when>
                    <xsl:otherwise>
                      <xsl:for-each select="parent::ead3:row/parent::ead3:thead">
                        <xsl:call-template name="valign.choose"/>
                      </xsl:for-each>
                    </xsl:otherwise>
                  </xsl:choose>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:attribute>
      </xsl:if>
      <fo:block use-attribute-sets="table.cell.block">
        <xsl:apply-templates/>
      </fo:block>
    </fo:table-cell>
  </xsl:template>

  <!-- Template that is called to assign a display-align attribute value. -->
  <xsl:template name="valign.choose">
    <xsl:choose>
      <xsl:when test="@valign = 'top'">
        <xsl:text>before</xsl:text>
      </xsl:when>
      <xsl:when test="@valign = 'middle'">
        <xsl:text>center</xsl:text>
      </xsl:when>
      <xsl:when test="@valign = 'bottom'">
        <xsl:text>after</xsl:text>
      </xsl:when>
    </xsl:choose>
  </xsl:template>

</xsl:stylesheet>
