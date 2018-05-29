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
    
    
    <!-- block elements from previous EAD2002 stylesheets
    with the needless xsl:elements removed (and now need to remove those icky for-each elements... probably should've started from scratch...  still might) -->
      <!-- Block <list> Template -->
  <xsl:template match="ead3:list">   
    <fo:list-block>
      <xsl:if test="ead3:head">
        <!--THE HEAD-->
        <fo:list-item>
          <fo:list-item-label end-indent="label-end()">
            <fo:block />
          </fo:list-item-label>
          <fo:list-item-body start-indent="body-start()">
            <fo:block use-attribute-sets="listhead">
              <xsl:apply-templates select="ead3:head"/>
            </fo:block>
          </fo:list-item-body>
        </fo:list-item>
      </xsl:if>
      <xsl:if test="ead3:listhead">
        <!--THE LISTHEAD-->
        <fo:list-item>
          <fo:list-item-label end-indent="label-end()">
            <fo:block use-attribute-sets="listhead">
              <xsl:apply-templates select="ead3:listhead/ead3:head01"/>
            </fo:block>
          </fo:list-item-label>
          <fo:list-item-body start-indent="body-start()">
            <fo:block use-attribute-sets="listhead">
              <xsl:apply-templates select="ead3:listhead/ead3:head02"/>
            </fo:block>
          </fo:list-item-body>
        </fo:list-item>
      </xsl:if>
      <xsl:for-each select="ead3:item|ead3:defitem/ead3:item">
        <fo:list-item use-attribute-sets="list.item">
          <xsl:if test="ancestor::ead3:list[1][ancestor::ead3:list] and position()=1">
            <xsl:attribute name="space-before.optimum">
              <xsl:text>5pt</xsl:text>
            </xsl:attribute>
          </xsl:if>
          <xsl:if test="@id">
            <xsl:attribute name="id">
              <xsl:value-of select="@id"/>
            </xsl:attribute>
          </xsl:if>
          <fo:list-item-label end-indent="label-end()">
            <fo:block>
              <xsl:choose>
                <xsl:when test="@listtype='unordered'"/>
                <xsl:when test="@listtype='deflist'"/>
                <xsl:when test="@listtype='ordered'">
                    <!-- values:
                armenian, decimal, decimal-leading-zero, georgian, inherit, 
                lower-alpha, lower-greek, lower-latin, lower-roman, upper-alpha, 
                upper-latin, upper-roman
                -->
                  <xsl:choose>
                    <xsl:when test="ancestor::ead3:list[1][@numeration='arabic']">
                      <xsl:number format="1" /><xsl:text>)</xsl:text>
                    </xsl:when>
                    <xsl:when test="ancestor::ead3:list[1][@numeration='upperalpha']">
                      <xsl:number format="A" /><xsl:text>)</xsl:text>
                    </xsl:when>
                    <xsl:when test="ancestor::ead3:list[1][@numeration='loweralpha']">
                      <xsl:number format="a" /><xsl:text>)</xsl:text>
                    </xsl:when>
                    <xsl:when test="ancestor::ead3:list[1][@numeration='upperroman']">
                      <xsl:number format="I" /><xsl:text>)</xsl:text>
                    </xsl:when>
                    <xsl:when test="ancestor::ead3:list[1][@numeration='lowerroman']">
                      <xsl:number format="i" /><xsl:text>)</xsl:text>
                    </xsl:when>
                    <xsl:otherwise/>
                  </xsl:choose>
                </xsl:when>
              </xsl:choose>
            </fo:block>
          </fo:list-item-label>
          <!-- thing itself-->
          <fo:list-item-body start-indent="body-start()">
            <!--<fo:block space-after="6pt">-->
            <fo:block>
              <xsl:if test="parent::ead3:defitem/ead3:label">
                <fo:wrapper>
                  <xsl:attribute name="font-weight">
                    <xsl:text>bold</xsl:text>
                  </xsl:attribute>
                  <xsl:value-of select="parent::ead3:defitem/ead3:label" /><xsl:text>   </xsl:text>
                </fo:wrapper>
              </xsl:if>
              <xsl:apply-templates/>
            </fo:block>
            <xsl:if test="ead3:list">
              <xsl:apply-templates select="ead3:list"/>
            </xsl:if>
          </fo:list-item-body>
        </fo:list-item>
      </xsl:for-each>
    </fo:list-block>
  </xsl:template>
  
  <!-- Block <chronlist> Template -->
  <xsl:template match="ead3:chronlist">
      <fo:block>
          <xsl:apply-templates select="ead3:head"/>
      </fo:block>
 
    <fo:table table-layout="fixed" width="100%" space-after.optimum="15pt">
      <fo:table-column column-width="3cm" />
      <fo:table-column column-width="1cm" />
      <fo:table-column column-width="13cm" />
      <fo:table-body>
        <xsl:apply-templates select="ead3:chronitem"/>
      </fo:table-body>>
    </fo:table>
  </xsl:template>
  
  <!-- Block <chronitem> Template -->
  <xsl:template match="ead3:chronitem">
      <fo:table-row>
        <fo:table-cell>
          <fo:block space-before.optimum="10pt" text-align="start">
            <xsl:choose>
              <xsl:when test="ead3:date">
                <xsl:apply-templates select="ead3:date"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:text>no date</xsl:text>
              </xsl:otherwise>
            </xsl:choose>
          </fo:block>
        </fo:table-cell>
        <fo:table-cell>
          <fo:block space-before.optimum="10pt" text-align="start" />
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
          <xsl:value-of select="$width_percent"/><xsl:text>%</xsl:text>
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
            <xsl:when test="@align='left'">
              <xsl:text>start</xsl:text>
            </xsl:when>
            <xsl:when test="@align='right'">
              <xsl:text>end</xsl:text>
            </xsl:when>
            <xsl:when test="@align='center'">
              <xsl:text>center</xsl:text>
            </xsl:when>
            <xsl:when test="@align='justify'">
              <xsl:text>justify</xsl:text>
            </xsl:when>
            <xsl:when test="@align='char'">
              <xsl:text>start</xsl:text>
            </xsl:when>
          </xsl:choose>
        </xsl:attribute>
      </xsl:if>
      <xsl:if test="@valign|parent::ead3:row/@valign|parent::ead3:row/parent::ead3:tbody/@valign|parent::ead3:row/parent::ead3:thead/@valign">
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
      <xsl:when test="@valign='top'">
        <xsl:text>before</xsl:text>
      </xsl:when>
      <xsl:when test="@valign='middle'">
        <xsl:text>center</xsl:text>
      </xsl:when>
      <xsl:when test="@valign='bottom'">
        <xsl:text>after</xsl:text>
      </xsl:when>
    </xsl:choose>
  </xsl:template>
    
</xsl:stylesheet>
