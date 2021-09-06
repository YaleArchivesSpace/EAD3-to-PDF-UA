<?xml version="1.0" encoding="UTF-8"?>
<!-- Yale University Library XSLT Stylesheet ::
  Transform ArchivesSpace EAD output to be EAD compliant with Yale's EAD best practice guidelines

  maintained by: mark.custer@yale.edu
  updated to conform with ASpace versions 2.x  
             

  to do:


  1)
  strip any notes that only have a head element, and no text otheriwse.


  2)
  update all repo records in ASpace and remove the "respository_code" parameter from this file.



  figure out how to handle titles that are exported incorrectly in EAD3 from ASpace
  if a note has two title elements, those get exported as a single one.
  find an example!
-->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:ead3="http://ead3.archivists.org/schema/"
  xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
  xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:mdc="http://www.local-functions/mdc"
  exclude-result-prefixes="xsl ead3 mdc xsi"
  version="3.0">

  <xsl:output method="xml" indent="yes" encoding="UTF-8" omit-xml-declaration="no"/>
  
  <xsl:include href="ead3-holdings-notes.xsl"/>

  <!-- will pass false() when using this process to do staff-only PDF previews -->
  <xsl:param name="suppressInternalComponents" select="true()" as="xs:boolean"/>
  
  <xsl:variable name="finding-aid-identifier" select="ead3:ead/ead3:control/ead3:recordid[1]"/>
  <xsl:variable name="holding-repository" select="ead3:ead/ead3:archdesc/ead3:did/ead3:repository[1]"/>

  <xsl:function name="mdc:iso-date-2-display-form" as="xs:string*">
    <xsl:param name="date" as="xs:string"/>
    <xsl:variable name="months"
      select="('January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December')"/>
    <xsl:variable name="date-numbers" select="for $num in tokenize($date, '-') return number($num)"/>    
    <xsl:variable name="year">
      <xsl:value-of select="format-number($date-numbers[1], '#')"/>
    </xsl:variable>
  <xsl:variable name="month">
      <xsl:value-of select="if ($date-numbers[2]) then subsequence($months, $date-numbers[2], 1) else ()"/>
    </xsl:variable>
    <xsl:variable name="day">
      <xsl:value-of select="if ($date-numbers[3]) then format-number($date-numbers[3], '#') else ()"/>
    </xsl:variable>   

    <xsl:sequence select="normalize-space(string-join(($year, $month, $day), ' '))"/>

  </xsl:function>

  <xsl:function name="mdc:top-container-to-number" as="xs:decimal">
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
    <xsl:value-of select="xs:decimal(concat($primary-container-number, '.', $primary-container-modify))"/>
  </xsl:function>


  <!-- Repository Parameter -->
  <xsl:param name="repository">
    <xsl:value-of select="substring-before(normalize-space(/ead3:ead/ead3:control/ead3:recordid), '.')"/>
  </xsl:param>

  <xsl:param name="include-cc0-rights-statement" as="xs:boolean">
    <xsl:value-of select="if ($repository = ('mssa', 'beinecke', 'divinity', 'music', 'oham', 'med', 'arts', 'vrc', 'lwl', 'ycba', 'ypl')) then true() else false()"/>
  </xsl:param>

  <!-- Repository Code.
  make sure that these are all in ASpace, and then remove from here -->
  <xsl:param name="repository_code">
    <xsl:choose>
      <!-- MSSA choice -->
      <xsl:when test="$repository = 'mssa'">
        <xsl:text>US-CtY</xsl:text>
      </xsl:when>
      <!-- BRBL choice -->
      <xsl:when test="$repository = 'beinecke'">
        <xsl:text>US-CtY-BR</xsl:text>
      </xsl:when>
      <!-- Divinity choice -->
      <xsl:when test="$repository = 'divinity'">
        <xsl:text>US-CtY-D</xsl:text>
      </xsl:when>
      <!-- Music choice -->
      <xsl:when test="$repository = 'music'">
        <xsl:text>US-CtY-Mus</xsl:text>
      </xsl:when>
      <!-- Medical choice -->
      <xsl:when test="$repository = 'med'">
        <xsl:text>US-CtY-M</xsl:text>
      </xsl:when>
      <!-- Arts choice -->
      <xsl:when test="$repository = 'arts'">
        <xsl:text>US-CtY-A</xsl:text>
      </xsl:when>
      <!-- VRC choice -->
      <xsl:when test="$repository = 'vrc'">
        <xsl:text>US-CtY-A</xsl:text>
      </xsl:when>
      <!-- YCBA choice -->
      <xsl:when test="$repository = 'ycba'">
        <xsl:text>US-CtY-BA</xsl:text>
      </xsl:when>
      <!-- Walpole choice -->
      <xsl:when test="$repository = 'lwl'">
        <xsl:text>US-CtY-LWL</xsl:text>
      </xsl:when>
      <xsl:otherwise>
        <xsl:text>US-CtY</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:param>

  <xsl:template match="/">
    <xsl:processing-instruction name="xml-model">
      <xsl:text>href="https://raw.githubusercontent.com/YaleArchivesSpace/EAD3-to-PDF-UA/dev/ead3-yale.sch" type="application/xml" schematypens="http://purl.oclc.org/dsdl/schematron"</xsl:text>
    </xsl:processing-instruction>
    <xsl:apply-templates select="@* | node()"/>
  </xsl:template>

  <!-- standard identity template -->
  <xsl:template match="@* | node()" mode="#default copy">
    <xsl:copy>
      <xsl:apply-templates select="@* | node()"/>
    </xsl:copy>
  </xsl:template>

  <!-- if it's listed "unpublished" in ASpace, let's keep it unpublished no matter how the file is serialized into EAD
  (and we'll change the paraemter as needed for previewing PDF files) -->
  <xsl:template match="*[@audience = 'internal'][$suppressInternalComponents = true()]" priority="10"/>

  <xsl:template match="ead3:conventiondeclaration[$include-cc0-rights-statement eq true()]">
    <xsl:copy>
      <xsl:apply-templates select="@* | node()"/>
    </xsl:copy>
    <xsl:call-template name="cc0-rights-statement"/>
  </xsl:template>

  <xsl:template match="ead3:languagedeclaration[$include-cc0-rights-statement eq true()][not(following-sibling::ead3:conventiondeclaration)]">
    <xsl:copy>
      <xsl:apply-templates select="@* | node()"/>
    </xsl:copy>
    <xsl:call-template name="cc0-rights-statement"/>
  </xsl:template>

  <xsl:template match="ead3:maintenanceagency[$include-cc0-rights-statement eq true()][not(following-sibling::ead3:languagedeclaration)][not(following-sibling::ead3:conventiondeclaration)]">
    <xsl:copy>
      <xsl:apply-templates select="@* | node()"/>
    </xsl:copy>
    <xsl:call-template name="cc0-rights-statement"/>
  </xsl:template>

  <xsl:template name="cc0-rights-statement">
    <xsl:element name="rightsdeclaration" namespace="http://ead3.archivists.org/schema/">
      <xsl:element name="abbr" namespace="http://ead3.archivists.org/schema/">
        <xsl:text>CC0</xsl:text>
      </xsl:element>
      <xsl:element name="citation" namespace="http://ead3.archivists.org/schema/">
        <xsl:attribute name="href" select="'https://creativecommons.org/publicdomain/zero/1.0/'"/>
      </xsl:element>
      <xsl:element name="descriptivenote" namespace="http://ead3.archivists.org/schema/">
        <xsl:element name="p" namespace="http://ead3.archivists.org/schema/">
          <xsl:text>Finding aid description and metadata in Archives at Yale are licensed under a CC0 1.0 Universal (CC0 1.0) Public Domain Dedication. This means that anyone may copy, modify, and distribute this descriptive metadata without restriction or permission. The CC0 license is explained in full on the Creative Commons website: </xsl:text>
          <xsl:element name="ref" namespace="http://ead3.archivists.org/schema/">
            <xsl:attribute name="href" select="'https://creativecommons.org/publicdomain/zero/1.0/'"/>
            <xsl:text>CC0 1.0 Universal (CC0 1.0) Public Domain Dedication</xsl:text>
           </xsl:element>
          <xsl:text>. More information is available on our </xsl:text> 
          <xsl:element name="ref" namespace="http://ead3.archivists.org/schema/">
            <xsl:attribute name="href" select="'https://archives.yale.edu/help'"/>
            <xsl:text>Help page</xsl:text>
          </xsl:element>
          <xsl:text>.</xsl:text>
        </xsl:element>
      </xsl:element>
    </xsl:element>
  </xsl:template>

  <!-- in the cases when we've migrated "ref_" id and target values from the AT, we need to preserve those as is;
    ASpace, however, will always prepend "aspace_"-->
  <xsl:template match="@id[starts-with(., 'aspace_ref')]">
    <xsl:attribute name="id">
      <xsl:value-of select="substring-after(., 'aspace_')"/>
    </xsl:attribute>
  </xsl:template>

  <!-- first attempt to deal with duplicate language "notes"
  exploiting the fact that ASpace includes an @id on the note, but not on the language code element
  -->
  <xsl:template match="ead3:archdesc/ead3:did/ead3:langmaterial[not(@id)][../ead3:langmaterial[@id]]"/>

  <!-- 
    For now, we might have... (with no language or script codes)
  <langmaterial>
      <descriptivenote><p>In English and Greek.</p></descriptivenote>
  </langmaterial
  If so, to be valid EAD3, we need to add an empty tag.  Sigh.  
   We could also add language codes by analazying the note, but better to get those code added directly to ASpace.
  -->
  <xsl:template match="ead3:langmaterial[not(ead3:language) and not(ead3:languageset)]">
    <xsl:copy>
      <xsl:apply-templates select="@*"/>
      <xsl:element name="language" namespace="http://ead3.archivists.org/schema/"/>
      <xsl:apply-templates select="node()"/>
    </xsl:copy>
  </xsl:template>
  
  <!-- we might get something like this:
          <physloc>Some files include photographs; negatives for some prints are stored in
            <title localtype="simple" render="italic">
              <part>Restricted Fragile</part>
             </title>
           </physloc>

          That needs to change to:
          <physloc>Some files include photographs; negatives for some prints are stored in
            <emph render="italic">Restricted Fragile</emph>
           </physloc>

    Review the EAD3 schema to abstract this rule, so that we know where else this can happen.
    -->
  <xsl:template match="ead3:physloc/ead3:title">
    <xsl:element name="emph" namespace="http://ead3.archivists.org/schema/">
      <xsl:apply-templates select="@render"/>
      <!-- not good to assume, but our best practice has been to always italicize a title element, even when no @render was specified-->
      <xsl:if test="not(@render)">
        <xsl:attribute name="render" select="'italic'"/>
      </xsl:if>
      <xsl:value-of select="."/>
    </xsl:element>
  </xsl:template>


  <!-- we're hacking our way to better subjects/agents in ASpace.
    one problem with that is that we're adding subfield delimerts like "$t:"
    to ASpace's qualifier field.  Here's where we strip those values out, since they're pointless for the display
    -->
  <xsl:template match="ead3:part/text()">
    <xsl:value-of select="replace(., '\$\w: ', '')"/>
  </xsl:template>
    
 <!-- going with a less extreme strategy for the time being.  
   see the ead3:title/ead3:emph template much further down,
   which replaces these 3 templates ...
   
  <xsl:template match="ead3:title/ead3:emph"/>
  
  <xsl:template match="ead3:part[preceding-sibling::ead3:emph[1]]">
    <xsl:copy>
      <xsl:apply-templates select="preceding-sibling::ead3:emph[1], node()" mode="copy"/>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template match="ead3:part[not(preceding-sibling::*)][not(node())]"/>
  -->



  <!-- in ASpace, we don't want to include links that start with "aspace_".
    Therefore, if the link is to a note or a component of a finding aid that was created
    in ArchivesSpace, not the AT (hence the "ref" part), we need to append
    "aspace_" before the target, since that's what ASpace appends to the @id attributes
    upon export.  Clear as mud, right? :) -->
  <xsl:template match="@target[not(starts-with(., 'ref'))][not(starts-with(., 'aspace_'))]">
    <xsl:attribute name="target">
      <xsl:value-of select="concat('aspace_', .)"/>
    </xsl:attribute>
  </xsl:template>
  <xsl:template match="@target[not(starts-with(., 'ref'))][contains(., 'ref')][starts-with(., 'aspace_')]">
    <xsl:attribute name="target">
      <xsl:value-of select="substring-after(., 'aspace_')"/>
    </xsl:attribute>
  </xsl:template>

  <!--remove any ref/@type attributes -->
  <xsl:template match="ead3:ref/@type"/>
  
  <!-- new stuff to stabilize the value supplied by ASpace for the container id and parent attributes.
  
  right now, ASpace will change the ID and Parent attributes upon every export.  these next two templates will ensure that they don't change every time, unless warranted. -->
  <xsl:template match="ead3:container/@id">
    <xsl:variable name="container-id" select="."/>
    <xsl:variable name="container-position" select="1 + ../../ead3:container[@id eq $container-id]/count(preceding-sibling::ead3:container)"/>
    <xsl:variable name="component-id" select="../../../@id"/>
    <xsl:attribute name="id" select="if ($component-id) then concat($component-id, '_c', $container-position) else generate-id(..)"/>
  </xsl:template>
  <xsl:template match="ead3:container/@parent">
    <xsl:variable name="parent-id" select="."/>
    <xsl:variable name="parent-position" select="1 + ../../ead3:container[@id eq $parent-id]/count(preceding-sibling::ead3:container)"/>
    <xsl:variable name="component-id" select="../../../@id"/>
    <xsl:attribute name="parent" select="if ($component-id)  then concat($component-id, '_c', $parent-position) else generate-id(../preceding-sibling::ead3:container[1][@id])"/>
  </xsl:template>

  <!-- let's make top-container ranges, if the component has nothing but top containers -->
  <xsl:template match="ead3:did[ead3:container[2]][not(ead3:container/@parent)]">
    <xsl:copy>
      <xsl:apply-templates select="@*|node() except ead3:container"/>
      <xsl:variable name="containers-sorted-by-localtype">
        <xsl:for-each-group
          select="ead3:container"
          group-by="if (@localtype eq '') then 'box' else lower-case(@localtype)">
          <xsl:sort select="current-grouping-key()" data-type="text"/>
          <xsl:element name="{current-grouping-key()}">
            <xsl:apply-templates select="current-group()">
              <xsl:sort select="mdc:top-container-to-number(.)"/>
            </xsl:apply-templates>
          </xsl:element>
        </xsl:for-each-group>
      </xsl:variable>
      <!--
      our variable will be structured like so:
        box
          container 1
          container 2
        carton
          container 1
          container 3
        @localtype
          container N
          etc.
        -->
      <xsl:apply-templates select="$containers-sorted-by-localtype/*" mode="container-fun"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="*" mode="container-fun">
    <!--now we've got one more container children, which need to be condensed into ranges -->
      <xsl:apply-templates select="ead3:container[1]" mode="container-fun"/>
  </xsl:template>

  <!--
           but really should be (can handle that in the PDF tranformation bit):
           1-2, 2a-2c, 4-8, 9-11
           1
  -->
  <xsl:template match="ead3:container" mode="container-fun">
    <xsl:param name="first-container-in-range" select="."/>
    <xsl:variable name="current-container" select="."/>
    <xsl:variable name="next-container" select="following-sibling::ead3:container[1]"/>
    <xsl:choose>
      <!-- e.g. end of the line, regardless of ranges (but still might need to output a range) -->
      <xsl:when test="not(following-sibling::ead3:container)">
        <xsl:copy>
          <xsl:apply-templates select="@localtype"/>
          <xsl:attribute name="id" select="generate-id()"/>
          <xsl:value-of select="if ($first-container-in-range eq $current-container)
            then $current-container
            else concat($first-container-in-range, '&#x2013;', $current-container)"/>
        </xsl:copy>
      </xsl:when>
      <!-- e.g. 6, 6a, 6b, 6c, 7 (could also handle a rule here to condense 6a-6c)
      perhaps: when has a remainder plus floor of current = floor of next. -->
      <xsl:when test="mdc:top-container-to-number($current-container) mod 1 gt 0
        and mdc:top-container-to-number($next-container) mod 1 gt 0
        and (floor(mdc:top-container-to-number($current-container)) eq floor(mdc:top-container-to-number($next-container)))">
        <xsl:apply-templates select="$next-container" mode="#current">
          <xsl:with-param name="first-container-in-range" select="$first-container-in-range"/>
          <xsl:with-param name="current-container" select="$next-container"/>
        </xsl:apply-templates>
      </xsl:when>
      <!-- e.g. 1, 2, 3, 4, 5, 6, 8
        when we're at 1 -5, we just want to keep going.
      -->
      <xsl:when test="mdc:top-container-to-number($current-container) + 1 eq mdc:top-container-to-number($next-container)">
            <xsl:apply-templates select="$next-container" mode="#current">
              <xsl:with-param name="first-container-in-range" select="$first-container-in-range"/>
              <xsl:with-param name="current-container" select="$next-container"/>
            </xsl:apply-templates>
      </xsl:when>
      <!-- e.g. in the above example, let's say we get to 6.
      -->
      <xsl:when test="mdc:top-container-to-number($current-container) + 1 ne mdc:top-container-to-number($next-container)">
        <xsl:copy>
          <xsl:apply-templates select="@localtype"/>
          <xsl:attribute name="id" select="generate-id()"/>
          <xsl:value-of select="if ($first-container-in-range eq $current-container)
            then $current-container
            else concat($first-container-in-range, '&#x2013;', $current-container)"/>
        </xsl:copy>
        <xsl:if test="following-sibling::ead3:container">
          <xsl:apply-templates select="$next-container" mode="#current">
            <xsl:with-param name="first-container-in-range" select="$next-container"/>
            <xsl:with-param name="current-container" select="$next-container"/>
          </xsl:apply-templates>
        </xsl:if>
      </xsl:when>
    </xsl:choose>
  </xsl:template>


  <!--aspace exports empty type/localtype attributes on containers that don't have a container type.
    for local purposes, we assume that these containers are "boxes".
  the following template adds our default value of 'box' to this attribute.-->
  <xsl:template match="ead3:container/@localtype[. eq '']" priority="2">
    <xsl:attribute name="localtype">
      <xsl:text>box</xsl:text>
    </xsl:attribute>
  </xsl:template>

  <xsl:template match="ead3:container/@localtype">
    <xsl:attribute name="{local-name()}">
      <xsl:value-of select="lower-case(replace(., '\s', '_'))"/>
    </xsl:attribute>
  </xsl:template>

  <!-- mdc: hack for beinecke.edwards (and any other collections/sections we
    need to model deliverable units within top containers)-->
  <xsl:template match="ead3:container[@localtype = ('parent_barcode', 'parent_box')]"/>
  
  <xsl:template match="ead3:container[@localtype eq 'folder'][following-sibling::ead3:container[1][@localtype eq 'parent_box']]">
    <xsl:copy>
      <xsl:attribute name="localtype" select="'box'"/>
      <xsl:attribute name="id">
        <xsl:apply-templates select="following-sibling::ead3:container[1]/@id"/>
      </xsl:attribute>
      <!-- of course, this wouldn't work very well if we allowed mixed-content for container indicators, but why would we???-->
      <xsl:value-of select="following-sibling::ead3:container[1]"/>
    </xsl:copy>
    <xsl:copy>
      <xsl:apply-templates select="@localtype|@id"/>
      <xsl:attribute name="parent">
        <xsl:apply-templates select="following-sibling::ead3:container[1]/@id"/>
      </xsl:attribute>
      <xsl:apply-templates/>
    </xsl:copy>
  </xsl:template>



  <!-- head fix for data added by the AT migration tool!
  remove this once those values are corrected in ASpace -->
  <xsl:template match="ead3:head[lower-case(normalize-space()) = 'missing title']"/>

  <!-- let's remove those AT database IDs even if we keep internal-only elements around.
  those should be the only unitids exported with an invalid @type attribute, so just remove 'em.
  should also take care of "local_surrogate_call_number"... but will check that out once we have examples in place from MSSA.
  -->
  <xsl:template match="ead3:unitid[@type]" priority="3"/>

  <!-- MDC:  new additions for new data-entry rules in ArchivesSpace !!! -->
  <xsl:template match="ead3:*[@level = 'series']/ead3:did/ead3:unitid[matches(., '^\d+$')]" priority="2">
    <xsl:variable name="roman-numeral">
      <xsl:number value="." format="I"/>
    </xsl:variable>
    <xsl:copy>
      <xsl:apply-templates select="@*"/>
      <xsl:value-of select="concat('Series ', $roman-numeral)"/>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template match="ead3:*[@level = 'subseries']/ead3:did/ead3:unitid[not(matches(normalize-space(.), '^subseries', 'i'))]" priority="2">
    <xsl:copy>
      <xsl:apply-templates select="@*"/>
      <xsl:value-of select="concat('Subseries ', normalize-space(.))"/>
    </xsl:copy>
  </xsl:template>

  <!-- ArchivesSpace Extent subrecords, EAD3 style (which is much easier to handle than EAD2002 style):  let's deal with 'em.

  Here's what we're up against:

      <physdescstructured coverage="whole" physdescstructuredtype="spaceoccupied">
        <quantity>1</quantity>
        <unittype>3.5" computer disks</unittype>
        <physfacet>physical details</physfacet>
        <dimensions>dimensions</dimensions>
      </physdescstructured>
**immediately following physdesc with "container_summary" is part of the above, so take that into account for the display
      <physdesc localtype="container_summary">container summary</physdesc>

     though we can have whole/part statements, for now we just take them as they are in the PDF output.

**also, no distinction for the other physdesc notes.
      <physdesc id="aspace_c01a106a4cf1b9787c933ec0ae449fba">physical description</physdesc>
      <physdesc id="aspace_87278ac037e106a92efd44152b242089">physical facet</physdesc>
      <physdesc id="aspace_ed6aa58891d81e358bce0571bc4c823a">dimensions</physdesc>

So, all that we need to do here
1) is singularize the unittype values when the quantity = 1.
2) remove any quantity/unittype values when the quantity is 0 OR unittype = 'see container summary', and replace with a generic physdesc element in case physfacet and dimensions were recorded.
3) [also consider formatting the numbers?  e.g. if 1000 is entered, display as 1,000.  need feedback about this.
  for now, we'll display whatever is entered since ASpace does not actually store this field as a number.]
  -->

  <xsl:template match="ead3:physdescstructured[normalize-space(ead3:quantity) eq '1']/ead3:unittype">
    <xsl:copy>
      <xsl:apply-templates select="@*"/>
      <xsl:choose>
        <!--changes feet to foot for singular extents-->
        <xsl:when test="matches(., 'feet', 'i')">
          <xsl:value-of select="replace(., 'eet', 'oot')"/>
        </xsl:when>
        <!--changes boxes to box for singular extents-->
        <xsl:when test="matches(., 'boxes', 'i')">
          <xsl:value-of select="replace(., 'oxes', 'ox')"/>
        </xsl:when>
        <!--changes works to work for the "Works of art" extent type, if this is used-->
        <xsl:when test="matches(., 'works of art', 'i')">
          <xsl:value-of select="replace(., 'orks', 'ork')"/>
        </xsl:when>
        <!--chops off the trailing 's' for singular extents-->
        <xsl:when test="ends-with(., 's')">
          <xsl:variable name="sl" select="string-length(.)"/>
          <xsl:value-of select="substring(., 1, $sl - 1)"/>
        </xsl:when>
        <!--chops off the trailing 's' for singular extents that are in AAT form, with a paranthetical qualifier-->
        <xsl:when test="ends-with(., ')')">
          <xsl:value-of select="replace(., 's \(', ' (')"/>
        </xsl:when>
        <!--any other irregular singluar/plural extent type names???-->

        <!--otherwise, just go with what we've got -->
        <xsl:otherwise>
          <xsl:apply-templates/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="ead3:physdescstructured[normalize-space(ead3:quantity) eq '0']
    | ead3:physdescstructured[lower-case(normalize-space(ead3:unittype)) eq 'see container summary']">
    <xsl:element name="physdesc" namespace="http://ead3.archivists.org/schema/">
      <xsl:value-of select="ead3:physfacet"/>
      <xsl:if test="ead3:physfacet/normalize-space()">
          <xsl:text> ; </xsl:text>
       </xsl:if>
      <xsl:value-of select="ead3:dimensions"/>
    </xsl:element>
  </xsl:template>


  <!-- this stuff won't work for all of the hand-encoded YCBA files, so those should probably be updated in ASpace.
    Or, just remove these templates for YCBA by adding a repository-based filter-->
  <xsl:template match="ead3:physfacet[$repository != ('ycba')]">
    <xsl:copy>
      <xsl:apply-templates select="@*"/>
      <xsl:choose>
        <xsl:when test="preceding-sibling::ead3:extent">
          <xsl:text> : </xsl:text>
          <xsl:apply-templates/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:apply-templates/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:copy>
  </xsl:template>
  <xsl:template match="ead3:dimensions[$repository != ('ycba')]">
    <xsl:copy>
      <xsl:apply-templates select="@*"/>
      <xsl:choose>
        <xsl:when test="preceding-sibling::ead3:extent | preceding-sibling::ead3:physfacet">
          <xsl:text> ; </xsl:text>
          <xsl:apply-templates/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:apply-templates/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:copy>
  </xsl:template>



  <!-- silly hack to deal with the fact that ASpace won't allow notes over 65k.
    might want to try this with for-each-group instead.
    remove when no longer necessary-->
  <xsl:template match="ead3:*[matches(ead3:head, '^\d\)')][1]" priority="2">
    <xsl:variable name="grouping-element-name" select="local-name()"/>
    <xsl:copy>
      <xsl:apply-templates select="@*"/>
      <xsl:element name="head" namespace="http://ead3.archivists.org/schema/">
        <xsl:value-of select="substring-after(ead3:head, ') ')"/>
      </xsl:element>
      <xsl:apply-templates select="ead3:* except ead3:head"/>
      <xsl:apply-templates select="../ead3:*[local-name() = $grouping-element-name][matches(ead3:head, '^\d\)')][position() gt 1]/ead3:*[not(local-name() = 'head')]"/>
    </xsl:copy>
  </xsl:template>
  <xsl:template match="ead3:*[matches(ead3:head, '^\d\)')][position() gt 1]" priority="2"/>


  <!-- check with MSSA to see if they still need their "Forms part of:" rule
    for odd elements with that head element -->

  <!-- do we still need this?? -->
  <!-- no.  we're now going to keep the sources as is and display them in a control access section under a specific heading-->
  <!-- <xsl:template match="ead3:archdesc/ead3:did/ead3:origination[@label = 'source']"/> -->
  <!-- but we now need to remove empty controlaccess elements, since we've changed the aspace behavior of DUPLICATING every source in the EAD output.  for shame, aspace -->
  <!-- normally we wouldn't delete an element like this, but since EAD requires the element to have children elements, we don't need to worry about any attributes, etc. -->
  <!-- this also holds true for an empty controlacess element, which won't have any element matches, so we can eliminate both instances of empty controlaccess sections with the same xpath -->
  <xsl:template match="ead3:controlaccess[every $x in * satisfies $x[@audience='internal']]"/>


  <xsl:template match="ead3:physdesc">
    <xsl:copy>
      <xsl:apply-templates select="@*"/>
      <xsl:choose>
        <!-- hack for "0 See container summary" statements
        when ASpace removes this requuirement, we can remove this hack-->
        <xsl:when test="ead3:extent[1][starts-with(normalize-space(lower-case(.)), '0 ')]">
          <xsl:apply-templates select="ead3:extent[2]"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:apply-templates/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:copy>
  </xsl:template>


<!-- we'll have to update how ASpace deals with languages (and languagesets)
    but for now, since EAD3 language can only contain text, that's all that we'll give it-->
  <xsl:template match="ead3:language">
    <xsl:copy>
      <xsl:apply-templates select="@*"/>
      <xsl:value-of select="."/>
    </xsl:copy>
  </xsl:template>

  <!--EAD3 doesn't allow launguge elements within launguage elements, so we'll just take the text of any lanuage element instead.
  Need to follow up with ASpace to see if it will support languageset and descriptivenote elements.
  -->
  <xsl:template match="ead3:language/ead3:language">
    <xsl:value-of select="."/>
  </xsl:template>


  <!-- you can't designate an "unordered" list in ASpace, but if no enumeration attriibute is supplied,
    we can (and should) assume it's just an unordered list.-->
  <xsl:template match="ead3:list[@listtype = 'ordered'][not(@numeration)] | ead3:list[@listtype = 'ordered'][@numeration eq '']">
    <xsl:copy>
      <xsl:apply-templates select="@* except @numeration"/>
      <xsl:attribute name="listtype">
        <xsl:text>unordered</xsl:text>
      </xsl:attribute>
      <xsl:apply-templates/>
    </xsl:copy>
  </xsl:template>



  <!-- hack to remove the extra paragraph element that ASpace inserts before hard-coded table elements
    (see beinecke.sok, appendix 5, as an example)
  is this still required???
  -->
  <xsl:template match="ead3:p[ead3:table]">
    <xsl:apply-templates/>
  </xsl:template>

  <!-- a very wacky hack to fix the dao title comparisons for the 2 kissinger finding aids, which include a date string as part of the dao title
    after the last comma (which we strip out below) -->
  <xsl:template match="ead3:dao/ead3:descriptivenote/ead3:p/text()[last()][$finding-aid-identifier = ('mssa.ms.2004', 'mssa.ms.1980')]" priority="2">
    <xsl:variable name="tokens" select="tokenize(string-join(normalize-space(.), ' '), ', ')"/>
    <xsl:value-of select="$tokens[position() &lt; last()]" separator=", "/>
  </xsl:template>

  <!-- REMOVE THIS TEMPLATE ONCE THIS BUG IS FIXED IN ASPACE'S EAD3 EXPORT OPTION -->
  <xsl:template match="@linktitle">
    <xsl:attribute name="{local-name()}">
      <xsl:value-of select="replace(replace(replace(., '&amp;quot;', '&quot;'), '&amp;lt;', '&lt;'), '&amp;gt;', '&gt;')"/>
    </xsl:attribute>
  </xsl:template>

  <!-- for now, we're going to remove any thumbnail only style links.  adding a priority here, in case the embedded link is from preservica or kaltura.
    REMOVING this, since we're now going to inlcoude daoset in the output.
    UPDATE... and add daoset here somewhere, since we could group on dao/@altrender now.
  <xsl:template match="ead3:dao[@show='embed']" priority="2"/>
  -->
  <!-- also taking out staff-only dao links until we figure out what to do with those -->
  <!-- should revisit since these could (and shoulb) be marked as unpublished if we don't want to display them -->
  <!-- UPDATE...   only remove these if they are unpublished.  if they shouldn't be published, unpublish them.
  <xsl:template match="ead3:dao[contains(@href, 'preservica')]"/>
  <xsl:template match="ead3:dao[contains(@href, 'kaltura')]"/>
  -->

  <!-- we want ead3:c elements in the final product, so if enumerated elements are exported by mistake,
    we'll change those here -->
  <xsl:template match="ead3:c01|ead3:c02|ead3:c03|ead3:c04|ead3:c05|ead3:c06|ead3:c07|ead3:c08|ead3:c09|ead3:c10|ead3:c11|ead3:c12">
    <xsl:element name="c" namespace="http://ead3.archivists.org/schema/">
      <xsl:apply-templates select="@*|node()"/>
    </xsl:element>
  </xsl:template>
  
  <!-- let's keep this hack around until we actually get the plugin updates into PROD.
    and, once those are there, this template won't match anything any longer -->
  <xsl:template match="ead3:unitdatestructured[ead3:unitdate]" priority="2">
    <xsl:copy>
      <xsl:apply-templates select="@* except @altrender"/>
      <xsl:attribute name="altrender">
        <xsl:value-of select="ead3:unitdate"/>
      </xsl:attribute>
      <xsl:apply-templates select="ead3:daterange | ead3:dateset | ead3:datesingle"/>
    </xsl:copy>
  </xsl:template>
 

  <!-- ptr to ref
  this assumes that the ptr is directed to a component.
  adjust after investigating the data, but eventually we can remove this feature since we'll be converting our ptr elements to ref elements.
  -->
  <xsl:template match="ead3:ptr[@target]">
    <xsl:element name="ref" namespace="http://ead3.archivists.org/schema/">
      <xsl:attribute name="target" select="@target"/>
      <xsl:call-template name="get-target-info">
        <xsl:with-param name="id-to-find" select="if (starts-with(@target, 'aspace_')) then @target else concat('aspace_', @target)"/>
      </xsl:call-template>
    </xsl:element>
  </xsl:template>

  <xsl:template name="get-target-info">
    <xsl:param name="id-to-find"/>
    <xsl:apply-templates select="//*[@id = $id-to-find]/ead3:did/ead3:unittitle/(*|text())"/>
  </xsl:template>

  <xsl:template match="ead3:ptr[@href]" priority="2">
    <xsl:element name="ref" namespace="http://ead3.archivists.org/schema/">
      <xsl:value-of select="@href"/>
    </xsl:element>
  </xsl:template>
  
  <!-- note:  
    persname/@role (and likely quite a few others) should be changed to something else...  like @localtype?
    -->
  <xsl:template match="@role">
    <xsl:attribute name="linkrole">
      <xsl:value-of select="."/>
    </xsl:attribute>
  </xsl:template>
  
  <!-- should re-join split title part elements, but for now
    it's probably safest to just replace "lb" elements with a textual space
 
  e.g.
     <title localtype="simple" render="italic">
                <part>Bumarap:</part>
                <lb/>
                <part>the Story of a Male Virgin</part>
     </title>
  there should only be one <part> element.
  should be simple/safe to group adjacent elements
  but i'm not sure if ASpace could ever export multiple part elements and we'd actually need to keep those separate.
  because of that, let's go with a stupid space.
  but we could just remove this rule once we delete those "lb"s from the database!
  -->
  <xsl:template match="ead3:title/ead3:lb">
    <xsl:element name="part" namespace="http://ead3.archivists.org/schema/">
      <xsl:text xml:space="preserve"> </xsl:text>
    </xsl:element>
  </xsl:template>
  
  <!-- 
    another example problem:
    
                <title localtype="simple" render="italic">
                  <emph render="italic">By-laws of the Hudson River Spathic Iron Ore Company</emph>
                  <part/>
                </title>
                
                <title localtype="simple" render="italic"><part>The Baron's</part><lb></lb><part>War</part></title>
                
     should check the logic of the render attributes and clean up data in the database,
     but for now, let's just wrap any "emph" elements within a title within a part element and be done with.
     the empty part shouldn't cause any harm, and that's just inserted by the ASpace EAD3 exporter since it doesn't know how to handle the "emph" element.
     that said, we should be able to safely strip any empty part elements.
    -->
  <xsl:template match="ead3:corpname/ead3:emph | ead3:famname/ead3:emph
    | ead3:function/ead3:emph | ead3:genreform/ead3:emph 
    | ead3:geogname/ead3:emph | ead3:name/ead3:emph 
    | ead3:occupation/ead3:emph | ead3:persname/ead3:emph 
    | ead3:subject/ead3:emph | ead3:title/ead3:emph">
    <xsl:element name="part" namespace="http://ead3.archivists.org/schema/">
      <xsl:copy>
        <xsl:apply-templates select="@* | node()"/>
      </xsl:copy>
    </xsl:element>
  </xsl:template>
  
  <xsl:template match="ead3:part[not(node())]"/>
  
  <!-- what else do we need to account for here due to issues with database values and translation values in ASpace?
    add this list to a map and just use a single template to handle it.-->
  <xsl:template match="@source[. = 'Library of Congress Subject Headings']">
    <xsl:attribute name="source" select="'lcsh'"/>
  </xsl:template>
  <xsl:template match="@source[. = 'Art and Architecture Thesaurus']">
    <xsl:attribute name="source" select="'aat'"/>
  </xsl:template>
  
  <xsl:template match="ead3:datesingle | ead3:fromdate | ead3:todate">
    <xsl:copy>
      <xsl:apply-templates select="@*"/>
      <xsl:choose>
        <xsl:when test="contains(., '-') and not(parent::ead3:chronitem)">
          <!-- should update this function to be more robust, but just didn't anticipate datesingle having year ranges, like 1800-1820-->
          <xsl:value-of select="mdc:iso-date-2-display-form(.)"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:apply-templates/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:copy>
  </xsl:template>

</xsl:stylesheet>
