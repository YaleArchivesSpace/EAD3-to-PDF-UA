<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:fo="http://www.w3.org/1999/XSL/Format" xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:fox="http://xmlgraphics.apache.org/fop/extensions"
  xmlns:ead3="http://ead3.archivists.org/schema/" exclude-result-prefixes="xs ead3 fox"
  version="2.0">

  <!-- this file is imported by "ead3-to-pdf-ua.xsl" -->

  <!-- block elements:
    bibliography
    deflist
    index
    pretty up the lists
    -->

  <!-- not used often, but used by the container-grouping and sorting method -->
  <xsl:template match="@* | node()" mode="copy">
    <xsl:copy>
      <xsl:apply-templates select="@* | node()" mode="#current"/>
    </xsl:copy>
  </xsl:template>

  <!-- first attempt to remove linebreaks and whitespace from elements
    like title, which should only have a part child now, rather than mixed content.
  see https://www.loc.gov/ead/EAD3taglib/index.html#elem-part
  example encoding:
                  <unittitle>
                     <title localtype="simple" render="italic">
                        <part>The Fire in the Flint</part>
                     </title>, galley proofs, corrected (Series II)
                  </unittitle>
  without removing the whitespace text node, then the above would result in:
    The Fire in the Flint , galley...
  -->
  <xsl:template match="text()[../ead3:part]"/>


  <!-- stand-alone block elements go here (not adding values like unittitle, however, since those will be handled differently
    a lot of these are handled differently as a LIST, however, when at the collection level.-->
  <xsl:template
    match="
      ead3:unitid | ead3:abstract | ead3:addressline | ead3:langmaterial | ead3:materialspec | ead3:origination | ead3:physdesc[not(@localtype = 'container_summary')]
      | ead3:physloc | ead3:repository"
    mode="dsc" priority="2">
    <!-- need to add an unpublish bit here, as well, i'd think -->
    <!--  italicize physdesc notes
    removed keep-with-previous.within-page="always"
    -->
    <fo:block>
      <xsl:choose>
        <!-- let's not.  should we consider prepending the title with the unitid?  that's what was done in YFAD. 
        <xsl:when test="self::ead3:unitid">
          <fo:inline>Call Number: </fo:inline>
          <xsl:apply-templates/>
        </xsl:when>
        -->
        <xsl:when test="self::ead3:physdesc">
          <fo:inline font-style="italic">
            <xsl:apply-templates/>
          </fo:inline>
        </xsl:when>
        <xsl:otherwise>
          <xsl:apply-templates/>
        </xsl:otherwise>
      </xsl:choose>
    </fo:block>
  </xsl:template>

  <!-- no need for so many labels, usually -->
  <!-- time to update this due to how some of the "notes" are applied???
    we have a lot of notes that need the header to display, but not the standard ASpace ones -->
  <!-- e.g.   <scopecontent>
                  <head>Interview Location</head>
                  <p>London</p>
               </scopecontent>
   -->
  <!-- and at the lower levels, we could just add this to the beginning of the same block.  
    e.g. "Interview Location: London". -->
  <xsl:template match="ead3:head" mode="dsc"/>

  <!-- currently used in the adminstrative info section of the collection overview -->
  <xsl:template match="ead3:head">
    <fo:block xsl:use-attribute-sets="h4" id="{if (../@id) then ../@id else generate-id(..)}">
      <xsl:apply-templates/>
    </fo:block>
  </xsl:template>

  <xsl:template match="ead3:head | ead3:head01 | ead3:head02 | ead3:head03" mode="table-header">
    <fo:block xsl:use-attribute-sets="table.head">
      <xsl:apply-templates/>
    </fo:block>
  </xsl:template>

  <xsl:template match="ead3:head | ead3:listhead" mode="list-header">
    <fo:list-item space-before="1em">
      <fo:list-item-label>
        <fo:block/>
      </fo:list-item-label>
      <fo:list-item-body end-indent="5mm">
        <fo:block>
          <xsl:apply-templates/>
        </fo:block>
      </fo:list-item-body>
    </fo:list-item>
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

  <xsl:template match="ead3:odd//ead3:p" mode="#all" priority="2">
    <fo:block xsl:use-attribute-sets="paragraph">
      <xsl:apply-templates/>
    </fo:block>
  </xsl:template>

  <xsl:template match="ead3:p" mode="#all">
    <fo:block xsl:use-attribute-sets="paragraph">
      <xsl:apply-templates/>
    </fo:block>
  </xsl:template>

  <xsl:template match="ead3:p" mode="dao" priority="2">
      <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match="ead3:archref | ead3:bibref" mode="#all">
    <fo:block>
      <xsl:apply-templates/>
    </fo:block>
  </xsl:template>


  <!-- the deep-equal stuff in the next two templates allow us to superimpose the dao link with the unittitle
    when the two match -->
  <xsl:template match="ead3:dao[not(@show='embed')][@href]" mode="#all">
    <xsl:choose>
      <xsl:when test="deep-equal(ead3:descriptivenote/ead3:p//text()/normalize-space(), ../ead3:unittitle//text()/normalize-space())"/>
      <xsl:otherwise>
        <fo:block>
          <fo:basic-link external-destination="url('{@href}')" xsl:use-attribute-sets="ref">
            <xsl:apply-templates select="ead3:descriptivenote/ead3:p" mode="dao"/>
          </fo:basic-link>
        </fo:block>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  <xsl:template match="ead3:daoset/ead3:dao[not(@show='embed')][@href]" mode="#all">
    <xsl:choose>
      <xsl:when test="deep-equal(../ead3:descriptivenote/ead3:p//text()/normalize-space(), ../../ead3:unittitle//text()/normalize-space())"/>
      <xsl:otherwise>
        <fo:block>
          <fo:basic-link external-destination="url('{@href}')" xsl:use-attribute-sets="ref">
            <xsl:apply-templates select="../ead3:descriptivenote/ead3:p" mode="dao"/>
          </fo:basic-link>
        </fo:block>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="ead3:unittitle[../ead3:dao[not(@show='embed')]]" mode="#all">
    <xsl:choose>
      <xsl:when test="deep-equal(.//text()/normalize-space(), ../ead3:dao[1]/ead3:descriptivenote/ead3:p//text()/normalize-space())">
        <fo:basic-link external-destination="url('{../ead3:dao[1]/@href}')" xsl:use-attribute-sets="ref">
          <xsl:apply-templates select="../ead3:dao[1]/ead3:descriptivenote/ead3:p" mode="dao"/>
        </fo:basic-link>
      </xsl:when>
      <xsl:otherwise>
        <xsl:apply-templates/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  <xsl:template match="ead3:unittitle[../ead3:daoset/ead3:dao[not(@show='embed')]]" mode="#all">
    <xsl:choose>
      <xsl:when test="deep-equal(.//text()/normalize-space(), ../ead3:daoset[1]/ead3:descriptivenote/ead3:p//text()/normalize-space())">
        <fo:basic-link external-destination="url('{../ead3:daoset[1]/ead3:dao[1]/@href}')" xsl:use-attribute-sets="ref">
          <xsl:apply-templates select="../ead3:daoset[1]/ead3:descriptivenote/ead3:p" mode="dao"/>
        </fo:basic-link>
      </xsl:when>
      <xsl:otherwise>
        <xsl:apply-templates/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="ead3:unitdatestructured" mode="#all">
    <xsl:apply-templates/>
    <xsl:if test="position() ne last()">
      <xsl:text>, </xsl:text>
    </xsl:if>
  </xsl:template>
  
  <xsl:template match="ead3:unitdatestructured[@altrender]" mode="#all" priority="2">
    <xsl:value-of select="normalize-space(@altrender)"/>
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

  <!-- let's lower case the Linear Feet and Linear Foot statements -->
  <xsl:template match="ead3:unittype" mode="#all">
    <xsl:text> </xsl:text>
    <xsl:choose>
      <xsl:when test="starts-with(lower-case(.), 'linear')">
        <xsl:value-of select="lower-case(.)"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:apply-templates/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="ead3:physdescstructured" mode="dsc">
    <fo:inline font-style="italic">
      <xsl:apply-templates/>
    </fo:inline>
  </xsl:template>

  <xsl:template match="ead3:physdesc[@localtype = 'container_summary']" mode="dsc">
    <fo:inline font-style="italic">
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
    </fo:inline>
  </xsl:template>

  <xsl:template match="ead3:physdesc[@localtype = 'container_summary']" mode="collection-overview-table-row">
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

  <!-- this is very Yale specific-->
  <xsl:template match="ead3:physdescstructured[ead3:unittype eq 'duration_HH:MM:SS.mmm']" mode="#all">
    <!-- change this to an inline block group? -->
    <fo:block>
     <xsl:text>duration: </xsl:text>
     <xsl:apply-templates select="* except ead3:unittype"/>
    </fo:block>
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


  <!-- Block <list> Template 
  adding a priority here to ensure a match when it's an internal only note. -->
  <xsl:template match="ead3:list" mode="#all" priority="2">
    <xsl:variable name="numeration-type" select="@numeration"/>
    <fo:list-block>
      <xsl:if test="@audience='internal' and $suppressInternalComponentsInPDF eq false()">
        <xsl:attribute name="border-right-width">1pt</xsl:attribute>
        <xsl:attribute name="border-right-style">solid</xsl:attribute>
        <xsl:attribute name="border-right-color">red</xsl:attribute>
      </xsl:if>
      <xsl:apply-templates select="ead3:head | ead3:listhead" mode="list-header"/>
      <xsl:apply-templates select="ead3:item">
        <xsl:with-param name="numeration-type" select="$numeration-type"/>
      </xsl:apply-templates>
    </fo:list-block>
  </xsl:template>
  
  <xsl:template match="ead3:list[ead3:defitem]" mode="#all" priority="2">
    <fo:list-block start-indent="5mm" provisional-distance-between-starts="40mm">
      <xsl:if test="@audience='internal' and $suppressInternalComponentsInPDF eq false()">
        <xsl:attribute name="border-right-width">1pt</xsl:attribute>
        <xsl:attribute name="border-right-style">solid</xsl:attribute>
        <xsl:attribute name="border-right-color">red</xsl:attribute>
      </xsl:if>
      <xsl:apply-templates select="ead3:head | ead3:listhead" mode="list-header"/>
      <xsl:apply-templates select="ead3:defitem"/>
    </fo:list-block>
  </xsl:template>
  
  <xsl:template match="ead3:defitem">
    <fo:list-item>
      <fo:list-item-label>
        <fo:block>
          <xsl:apply-templates select="ead3:label"/>
        </fo:block>
      </fo:list-item-label>
      <fo:list-item-body start-indent="body-start()" end-indent="5mm">
        <fo:block>
          <xsl:apply-templates select="ead3:item" mode="defitem"/>
        </fo:block>
      </fo:list-item-body>
    </fo:list-item>
  </xsl:template>

  <xsl:template match="ead3:item">
    <!-- valid options in EAD3 (although a few, like Armenian, would require a fair bit of work to support, I think):
      armenian, decimal, decimal-leading-zero, georgian, inherit, lower-alpha, lower-greek,
      lower-latin, lower-roman, upper-alpha, upper-latin, upper-roman
      options available in ASpace:
      null, arabic, lower-alpha, lower-roman, upper-alpha, upper-roman.
      -->
    <xsl:param name="numeration-type"/>
    <fo:list-item>
      <fo:list-item-label>
        <fo:block>
          <xsl:choose>
            <xsl:when test="$numeration-type eq 'arabic'">
              <xsl:number value="position()" format="1"/>
            </xsl:when>
            <xsl:when test="$numeration-type eq 'lower-alpha'">
              <xsl:number value="position()" format="a"/>
            </xsl:when>
            <xsl:when test="$numeration-type eq 'upper-alpha'">
              <xsl:number value="position()" format="A"/>
            </xsl:when>
            <xsl:when test="$numeration-type eq 'lower-roman'">
              <xsl:number value="position()" format="i"/>
            </xsl:when>
            <xsl:when test="$numeration-type eq 'upper-roman'">
              <xsl:number value="position()" format="I"/>
            </xsl:when>
            <!-- uncomment to add a bullet.
              this doesn't work well when other things have been added to the list item.
              e.g. 'I first item', instead of 'first item'
            <xsl:otherwise>
              <xsl:text>&#x2022;</xsl:text>
            </xsl:otherwise>
            -->
          </xsl:choose>
        </fo:block>
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
    <xsl:variable name="columns"
      select="
        if (ead3:listhead) then
          count(ead3:listhead/*)
        else
          if (descendant::ead3:geogname) then
            3
          else
            2"/>
    <fo:table table-layout="fixed" width="100%" space-after.optimum="15pt">
      <xsl:choose>
        <!-- or just add the geogname info to the second column -->
        <xsl:when test="$columns eq 3">
          <fo:table-column column-number="1" column-width="20%"/>
          <fo:table-column column-number="2" column-width="20%"/>
          <fo:table-column column-number="3" column-width="60%"/>
        </xsl:when>
        <xsl:otherwise>
          <fo:table-column column-number="1" column-width="20%"/>
          <fo:table-column column-number="2" column-width="80%"/>
        </xsl:otherwise>
      </xsl:choose>
      <fo:table-header>
        <fo:table-row>
          <xsl:choose>
            <xsl:when test="ead3:head or ead3:listhead">
              <xsl:choose>
                <xsl:when test="ead3:head">
                  <fo:table-cell number-columns-spanned="{if ($columns eq 3) then 3 else 2}">
                    <xsl:apply-templates select="ead3:head" mode="table-header"/>
                  </fo:table-cell>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:for-each select="ead3:listhead/*">
                    <fo:table-cell number-columns-spanned="1">
                      <xsl:apply-templates select="." mode="table-header"/>
                    </fo:table-cell>
                  </xsl:for-each>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:when>
            <xsl:when test="$columns eq 3">
              <fo:table-cell>
                <fo:block>Date</fo:block>
              </fo:table-cell>
              <fo:table-cell>
                <fo:block>Event</fo:block>
              </fo:table-cell>
              <fo:table-cell>
                <fo:block>Location</fo:block>
              </fo:table-cell>
            </xsl:when>
            <xsl:otherwise>
              <fo:table-cell>
                <fo:block>Date</fo:block>
              </fo:table-cell>
              <fo:table-cell>
                <fo:block>Event</fo:block>
              </fo:table-cell>
            </xsl:otherwise>
          </xsl:choose>
        </fo:table-row>
      </fo:table-header>
      <fo:table-body>
        <xsl:apply-templates select="ead3:chronitem">
          <xsl:with-param name="columns" select="$columns"/>
        </xsl:apply-templates>
      </fo:table-body>
    </fo:table>
  </xsl:template>


  <!-- Block <chronitem> Template -->
  <xsl:template match="ead3:chronitem">
    <xsl:param name="columns"/>
    <fo:table-row>
      <fo:table-cell xsl:use-attribute-sets="table.cell">
        <fo:block text-align="start">
          <xsl:apply-templates select="ead3:datesingle | ead3:daterange | ead3:dateset"/>
        </fo:block>
      </fo:table-cell>
      <xsl:if test="$columns eq 3">
        <fo:table-cell xsl:use-attribute-sets="table.cell">
          <fo:block text-align="start">
            <fo:block>
              <xsl:apply-templates select="ead3:geogname | ead3:chronitemset/ead3:geogname"/>
            </fo:block>
          </fo:block>
        </fo:table-cell>
      </xsl:if>
      <fo:table-cell xsl:use-attribute-sets="table.cell">
        <fo:block text-align="start">
          <fo:block>
            <xsl:apply-templates select="ead3:event | ead3:chronitemset/ead3:event"/>
          </fo:block>
        </fo:block>
      </fo:table-cell>
    </fo:table-row>
  </xsl:template>

  <xsl:template match="ead3:chronitemset/ead3:geogname | ead3:chronitemset/ead3:event">
    <fo:block>
      <fo:inline font-family="FontAwesomeRegular" color="#4A4A4A" font-size=".5em">
        <xsl:value-of select="'&#xf111; '"/>
      </fo:inline>
      <xsl:apply-templates/>
    </fo:block>
  </xsl:template>

  <!-- Block <table> Template -->
  <!-- need to revisit these inherited table transformations, but previously i forgot to account for ead3:table/ead3:head, so here -->
  <xsl:template match="ead3:table" mode="#all">
    <!-- probably only impacts one collection (music.mss.0028), but perhaps see about styling this better if/when there's time -->
    <xsl:apply-templates select="ead3:head" mode="table-header"/>
    <fo:table xsl:use-attribute-sets="table">
      <xsl:apply-templates select="ead3:tgroup"/>
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
    <fo:table-header xsl:use-attribute-sets="table.head">
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
    <fo:table-cell xsl:use-attribute-sets="table.cell">
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
      <fo:block xsl:use-attribute-sets="table.cell.block">
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

  <xsl:template match="ead3:lb">
    <fo:block/>
  </xsl:template>

  <!-- dao stuff -->

  <!-- example ASpace encoding:

                     <dao actuate="onrequest"
                             daotype="unknown"
                             href="http://hdl.handle.net/10079/xwdbs31"
                             linktitle="View digital image(s) [Folder 1374]."
                             localtype="image/jpeg"
                             show="new">
                           <descriptivenote>
                              <p>View digital image(s) [Folder 1374].</p>
                           </descriptivenote>
                        </dao>
    -->

  <xsl:template match="ead3:ref[@target]" mode="#all">
    <!-- not, not all of notes get IDs, but this will generally work as long as folks are linking to components.
    should update this later so that all IDs in the XML file wind up as linkable in the PDF -->
    <fo:basic-link internal-destination="{@target}" xsl:use-attribute-sets="ref">
      <xsl:choose>
        <xsl:when test="*|text()">
          <xsl:apply-templates/>
        </xsl:when>
        <xsl:when test="@linktitle">
          <xsl:value-of select="@linktitle"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="@target"/>
        </xsl:otherwise>
      </xsl:choose>
    </fo:basic-link>
  </xsl:template>

  <!-- a ref has a target AND a href for some reason, we're going to use the external link instead.
    but we should add this to the schematron to error out -->
  <xsl:template match="ead3:ref[@href]" priority="2" mode="#all">
    <fo:basic-link external-destination="url({@href})" xsl:use-attribute-sets="ref">
      <xsl:choose>
        <xsl:when test="*|text()">
          <xsl:apply-templates/>
        </xsl:when>
        <xsl:when test="@linktitle">
          <xsl:value-of select="@linktitle"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="@href"/>
        </xsl:otherwise>
      </xsl:choose>
    </fo:basic-link>
  </xsl:template>


  <!--Render elements -->
  <!-- still need to add those font variants, etc. -->
  <xsl:template match="*[@render = 'bold'] | *[@altrender = 'bold']" mode="#all">
    <fo:inline font-weight="bold">
      <xsl:if test="preceding-sibling::*"> &#160;</xsl:if>
      <xsl:apply-templates/>
    </fo:inline>
  </xsl:template>
  <xsl:template match="*[@render = 'bolddoublequote'] | *[@altrender = 'bolddoublequote']" mode="#all">
    <fo:inline font-weight="bold"><xsl:if test="preceding-sibling::*">
      &#160;</xsl:if>"<xsl:apply-templates/>"</fo:inline>
  </xsl:template>
  <xsl:template match="*[@render = 'boldsinglequote'] | *[@altrender = 'boldsinglequote']" mode="#all">
    <fo:inline font-weight="bold"><xsl:if test="preceding-sibling::*">
      &#160;</xsl:if>'<xsl:apply-templates/>'</fo:inline>
  </xsl:template>
  <xsl:template match="*[@render = 'bolditalic'] | *[@altrender = 'bolditalic']" mode="#all">
    <fo:inline font-weight="bold" font-style="italic">
      <xsl:if test="preceding-sibling::*"> &#160;</xsl:if>
      <xsl:apply-templates/>
    </fo:inline>
  </xsl:template>
  <xsl:template match="*[@render = 'boldsmcaps'] | *[@altrender = 'boldsmcaps']" mode="#all">
    <fo:inline font-weight="bold" font-variant="small-caps">
      <xsl:if test="preceding-sibling::*"> &#160;</xsl:if>
      <xsl:apply-templates/>
    </fo:inline>
  </xsl:template>
  <xsl:template match="*[@render = 'boldunderline'] | *[@altrender = 'boldunderline']" mode="#all">
    <fo:inline font-weight="bold" border-bottom="1pt solid #000">
      <xsl:if test="preceding-sibling::*"> &#160;</xsl:if>
      <xsl:apply-templates/>
    </fo:inline>
  </xsl:template>
  <xsl:template match="*[@render = 'doublequote'] | *[@altrender = 'doublequote']" mode="#all">
    <xsl:if test="preceding-sibling::*"> &#160;</xsl:if>"<xsl:apply-templates/>" </xsl:template>
  <xsl:template match="*[@render = 'italic'] | *[@altrender = 'italic']">
    <fo:inline font-style="italic">
      <xsl:if test="preceding-sibling::*"> &#160;</xsl:if>
      <xsl:apply-templates/>
    </fo:inline>
  </xsl:template>
  <xsl:template match="*[@render = 'singlequote'] | *[@altrender = 'singlequote']" mode="#all">
    <xsl:if test="preceding-sibling::*"> &#160;</xsl:if>'<xsl:apply-templates/>' </xsl:template>
  <xsl:template match="*[@render = 'smcaps'] | *[@altrender = 'smcaps']">
    <fo:inline font-variant="small-caps">
      <xsl:if test="preceding-sibling::*"> &#160;</xsl:if>
      <xsl:apply-templates/>
    </fo:inline>
  </xsl:template>
  <xsl:template match="*[@render = 'sub'] | *[@altrender = 'sub']" mode="#all">
    <fo:inline baseline-shift="sub">
      <xsl:apply-templates/>
    </fo:inline>
  </xsl:template>
  <xsl:template match="*[@render = 'super'] | *[@altrender = 'super']" mode="#all">
    <fo:inline baseline-shift="super">
      <xsl:apply-templates/>
    </fo:inline>
  </xsl:template>
  <xsl:template match="*[@render = 'underline'] | *[@altrender = 'underline']" mode="#all">
    <fo:inline text-decoration="underline">
      <xsl:apply-templates/>
    </fo:inline>
  </xsl:template>

  <!-- Formatting elements -->
  <xsl:template match="ead3:blockquote" mode="#all">
    <fo:block margin="4pt 18pt">
      <xsl:apply-templates/>
    </fo:block>
  </xsl:template>

  <xsl:template match="ead3:emph[not(@render)] | ead3:title[not(@render)]" mode="#all">
    <fo:inline font-style="italic">
      <xsl:apply-templates/>
    </fo:inline>
  </xsl:template>


  <!-- highlight unpublished notes 
  this doesn't work right now for lists, since it'll just output a red border 
  around a blob of text, but i can change that later. -->
  <xsl:template match="ead3:*[@audience='internal'][$suppressInternalComponentsInPDF eq false()]" mode="collection-overview dsc">
    <fo:block xsl:use-attribute-sets="unpublished">
      <xsl:apply-templates mode="#current"/>
    </fo:block>
  </xsl:template>
  
  <xsl:template match="ead3:*[@relator]" mode="#all">
    <xsl:apply-templates/>
    <xsl:value-of select="concat(', ', key('relator-code', @relator, $cached-list-of-relators)/lower-case(label))"/>
  </xsl:template>
  
  <xsl:template match="ead3:part[position() gt 1]" mode="#all">
    <xsl:text> -- </xsl:text>
    <xsl:apply-templates/>
  </xsl:template>
  
  <xsl:template match="ead3:langmaterial/ead3:language | ead3:langmaterial/ead3:languageset">
    <xsl:apply-templates/>
    <xsl:if test="following-sibling::ead3:*[local-name() = ('language', 'languageset')]">
      <xsl:text>; </xsl:text>
    </xsl:if>
  </xsl:template>
  
  <xsl:template match="ead3:script">
    <xsl:if test="preceding-sibling::ead3:language[1]">
      <xsl:text> </xsl:text>
    </xsl:if>
    <!-- add a translated value -->
    <xsl:value-of select="concat('(', ., ' script)')"/>
  </xsl:template>

</xsl:stylesheet>
