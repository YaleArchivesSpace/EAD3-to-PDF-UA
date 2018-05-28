<?xml version="1.0" encoding="UTF-8"?>
<!-- Yale University Library XSLT Stylesheet :: 
  Transform ArchivesSpace EAD output to be EAD compliant with Yale's EAD best practice guidelines
  
  maintained by: mark.custer@yale.edu
  updated to conform with ASpace versions 2.x
  
  to do:
  adjust how ASpace exports unitdatestructure and unitdate in EAD3 (and report some JIRA issues).
    notes:
      1) if you create a date subrecord and give it an end date, do NOT give it a begin date, and give it a date expression...  
            (the date type will have to be bulk or inclusive, since if you change it to single you lose the "end" option)
        then the ASpace EAD2002 exporter will include the date expression, but not the end date (that's no good, but the problem is with the @normal attribute in EAD2002);
        and the ASpace EAD3 exporter will ONLY include the end date, NOT the date expression.  that's really not good...
        but until ASpace has a way to differentiate between unitdatestructured and unitdate, there's no great solution here.
          ***perhaps the best comprimise would be to always export "unitdate" when a date expression was filled out, ignoring the begin/end values altogether.
      
      2) if you create a date subrecord and give it an end date, do NOT give it a begin date, and leave the date expression field blank...
             the date type will have to be bulk or inclusive, since if you change it to single you lose the "end" option)
        then the ASpace EAD2002 exporter will be reasonable.  example output: <unitdate type="inclusive">-2018-06-03</unitdate>. and that's as best it can do, really, since EAD2002 wouldn't allow  @normal="/2018-06-03"
        and the ASpace EAD3 exporter also will work as expected (the problem with the EAD3 exporter, though, is issue #1 above).
        
     3)  if you create a date subrecord and give it a begin date, do NOT give it an end date, call it "inclusive", and add a date expresion...
        then the ASpace EAD2002 exporter does fine, but it's a bit repetitious since you wind up with normal="1945-04-01/1945-04-01" instead of normal="1945-04-01"
        and the ASpace EAD3 exporter will export the date but ignore the date expression altogether.  that's not good. 
          ...but if if you go back and change the date type to "single", you're golden.   
 
      4)  And there are other problems to deal with for now regarding the EAD3 exporter, such as:
      
          1 ASpace subrecord, which looks like 2 in the export:
          
                     <unitdatestructured unitdatetype="inclusive"> 
                       <daterange>
                           <fromdate standarddate="1934">1934</fromdate> 
                          <todate standarddate="1967">1967</todate> 
                       </daterange> 
                     </unitdatestructured> 
                     <unitdate unitdatetype="inclusive">1934–1967</unitdate>

          1 ASpace subrecord, which looks even more like 2 in the export (since the date expression ends with ", undated")
          
                     <unitdatestructured unitdatetype="inclusive"> 
                      <daterange> 
                        <fromdate standarddate="1942">1942</fromdate> 
                        <todate standarddate="1946">1946</todate> 
                      </daterange> 
                     </unitdatestructured> 
                     <unitdate unitdatetype="inclusive">1942-1946, undated</unitdate>
                     
          3 ASpace date subrecords, which look like 3 in the export, and finally looks are not deceiving:
             
                  <unitdatestructured unitdatetype="inclusive"> 
                      <daterange> 
                        <fromdate standarddate="1963">1963</fromdate> 
                    </daterange> 
                  </unitdatestructured> 
                  <unitdatestructured unitdatetype="inclusive"> 
                    <daterange> 
                      <fromdate standarddate="1968">1968</fromdate>   
                    </daterange>   
                  </unitdatestructured>    
                  <unitdate unitdatetype="inclusive">undated</unitdate>
        
        In the first two cases, it would be best to just process the sibling unitdate element by itself,
        but in the last case we need to process all 3 of the date subrecords.
        
        In other words, we need a way to tell when ASpace has exported a unitdatestructured + unitdate pair via the EAD3 exporter...
        and when those potential "pairs" are not produced from the same ASpace date subrecord.
        
        For now, I attempt to compare all unitdatestructured elements with the unitdate element that follows immmediately, if any.
          to compare, i'll only look at the numeric contents of the unitdate and the unitdatestructured.
          if those match exactly, then I will remove the unitdatestructured.
          if they don't match, then we'll keep everything and process whatever's in the output during the PDF process.
                this isn't perfect ,but as long as folks don't type in month names into date expressions, etc. (since we've said not to, according to your guidelines),
                then it should be good enough.
              
  
  strip any notes that only have a head element, and no text otheriwse.
  
  decide on how to handle EAD3 head elements.
  
  update all repo records in ASpace and remove the "respository_code" parameter from this file.
  
  remove elements that aren't legal in EAD3...  e.g. linebreaks in title elements.
  e.g. 
  <title localtype="simple" render="italic">
                <part>Bumarap:</part>
                <lb/>
                <part>the Story of a Male Virgin</part>
              </title>
    there should only be one <part> element!
  
  figure out how to handle titles that are exported incorrectly in EAD3 from ASpace
  if a note has two title elements, those get exported as a single one!
  ead2002 example:
  
  ead3 example:
 
  
-->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:ead3="http://ead3.archivists.org/schema/"
  xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
  xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:mdc="http://www.local-functions/mdc"
  exclude-result-prefixes="xsl ead3 mdc xsi"
  version="2.0">

  <xsl:output method="xml" indent="yes" encoding="UTF-8" omit-xml-declaration="no"/>

  <!-- will pass false() when using this process to do staff-only PDF previews -->
  <xsl:param name="suppressInternalComponents" select="true()" as="xs:boolean"/>

  <xsl:function name="mdc:iso-date-2-display-form" as="xs:string*">
    <xsl:param name="date" as="xs:string"/>
    <xsl:variable name="months"
      select="('January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December')"/>
    <xsl:analyze-string select="$date" flags="x" regex="(\d{{4}})(\d{{2}})?(\d{{2}})?">
      <xsl:matching-substring>
        <!-- year -->
        <xsl:value-of select="regex-group(1)"/>
        <!-- month (can't add an if,then,else '' statement here without getting an extra space at the end of the result-->
        <xsl:if test="regex-group(2)">
          <xsl:value-of select="subsequence($months, number(regex-group(2)), 1)"/>
        </xsl:if>
        <!-- day -->
        <xsl:if test="regex-group(3)">
          <xsl:number value="regex-group(3)" format="1"/>
        </xsl:if>
        <!-- still need to handle time... but if that's there, then I can just use xs:dateTime !!!! -->
      </xsl:matching-substring>
    </xsl:analyze-string>
  </xsl:function>
  
  <xsl:function name="mdc:remove-this-date" as="xs:boolean">
    <xsl:param name="unitdate" as="node()"/>
    <xsl:variable name="first-date" select="string-join($unitdate//@standarddate, '')"/>
    <xsl:variable name="second-date" select="$unitdate/following-sibling::*[1]/replace(text(), '[^0-9]', '')"/>
    <xsl:value-of select="if ($first-date eq $second-date) then true() else false()"/>
  </xsl:function>

  <!-- still need to decide on how we should handle these default head / label elements -->
  <xsl:include href="http://www.library.yale.edu/facc/xsl/include/yale.ead2002.id_head_values.xsl"/>

  <!-- Repository Parameter -->
  <xsl:param name="repository">
    <xsl:value-of select="substring-before(normalize-space(/ead3:ead/ead3:control/ead3:recordid), '.')"/>
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

  <!-- standard identity template -->
  <xsl:template match="@* | node()">
    <xsl:copy>
      <xsl:apply-templates select="@* | node()"/>
    </xsl:copy>
  </xsl:template>

  <!-- if it's listed "unpublished" in ASpace, let's keep it unpublished no matter how the file is serialized into EAD
  (and we'll change the paraemter as needed for previewing PDF files) -->
  <xsl:template match="*[@audience = 'internal'][$suppressInternalComponents = true()]" priority="5"/>

  <!-- in the cases when we've migrated "ref_" id and target values from the AT, we need to preserve those as is;
    ASpace, however, will always prepend "aspace_"-->
  <xsl:template match="@id[starts-with(., 'aspace_ref')]">
    <xsl:attribute name="id">
      <xsl:value-of select="substring-after(., 'aspace_')"/>
    </xsl:attribute>
  </xsl:template>

  <!-- in ASpace, we don't want to include links that start with "aspace_".  
    Therefore, if the link is to a note or a component of a finding aid that was created 
    in ArchivesSpace, not the AT (hence the "ref" part), we need to append
    "aspace_" before the target, since that's what ASpace appends to the @id attributes
    upon export.  Clear as mud, right? :) -->
  <xsl:template match="@target[not(starts-with(., 'ref'))]">
    <xsl:attribute name="target">
      <xsl:value-of select="concat('aspace_', .)"/>
    </xsl:attribute>
  </xsl:template>
  
  <!--remove any ref/@type attributes -->
  <xsl:template match="ead3:ref/@type"/>

  
  <!--aspace exports empty type/localtype attributes on containers that don't have a container type.
    for local purposes, we assume that these containers are "boxes".
  the following template adds our default value of 'box' to this attribute.-->
  <xsl:template match="ead3:container/@localtype[. eq '']">
    <xsl:attribute name="localtype">
      <xsl:text>box</xsl:text>
    </xsl:attribute>
  </xsl:template>

  <!-- head fix for data added by the AT migration tool!
  remove this once those values are corrected in ASpace -->
  <xsl:template match="ead3:head[lower-case(normalize-space()) = 'missing title']"/>

  <!-- MDC:  new additions for new data-entry rules in ArchivesSpace !!! -->
  <xsl:template match="ead3:*[@level = 'series']/ead3:did/ead3:unitid[matches(., '^\d+$')]">
    <xsl:variable name="roman-numeral">
      <xsl:number value="." format="I"/>
    </xsl:variable>
    <xsl:copy>
      <xsl:apply-templates select="@*"/>
      <xsl:value-of select="concat('Series ', $roman-numeral)"/>
    </xsl:copy>
  </xsl:template>

  <!--optimized for what ASpace can output (up to 2 extents only).  If these templates are not used with AS-produced EAD, they
    will definitely need to change!-->
  <xsl:template match="ead3:extent[1][matches(., '^\d')]">
    <xsl:copy>
      <xsl:apply-templates select="@*"/>
      <!--ASpace doesn't force the extent number to be a number, so we'll need to validate and test this on our own-->
      <xsl:variable name="extent-number" select="number(substring-before(normalize-space(.), ' '))"/>
      <xsl:variable name="extent-type" select="lower-case(substring-after(normalize-space(.), ' '))"/>
      <xsl:value-of select="format-number($extent-number, '#,##0.##')"/>
      <xsl:text> </xsl:text>
      <xsl:choose>
        <!--changes feet to foot for singular extents-->
        <xsl:when test="$extent-number eq 1 and contains($extent-type, ' feet')">
          <xsl:value-of select="replace($extent-type, ' feet', ' foot')"/>
        </xsl:when>
        <!--changes boxes to box for singular extents-->
        <xsl:when test="$extent-number eq 1 and contains($extent-type, ' Boxes')">
          <xsl:value-of select="replace($extent-type, ' Boxes', ' Box')"/>
        </xsl:when>
        <!--changes works to work for the "Works of art" extent type, if this is used-->
        <xsl:when test="$extent-number eq 1 and contains($extent-type, ' Works of art')">
          <xsl:value-of select="replace($extent-type, ' Works', ' Work')"/>
        </xsl:when>
        <!--chops off the trailing 's' for singular extents-->
        <xsl:when test="$extent-number eq 1 and ends-with($extent-type, 's')">
          <xsl:variable name="sl" select="string-length($extent-type)"/>
          <xsl:value-of select="substring($extent-type, 1, $sl - 1)"/>
        </xsl:when>
        <!--chops off the trailing 's' for singular extents that are in AAT form, with a paranthetical qualifer-->
        <xsl:when test="$extent-number eq 1 and ends-with($extent-type, ')')">
          <xsl:value-of select="replace($extent-type, 's \(', ' (')"/>
        </xsl:when>
        <!--any other irregular singluar/plural extent type names???-->

        <!--otherwise, just print out the childless text node as is-->
        <xsl:otherwise>
          <xsl:value-of select="$extent-type"/>
        </xsl:otherwise>

      </xsl:choose>

      <!--provide a separator before the next extent value, if present-->
      <xsl:choose>
        <!-- if there's a second extent, and that value starts with an open parentheis character, then add a space-->
        <xsl:when test="starts-with(following-sibling::ead3:extent[1], '(')">
          <xsl:text> </xsl:text>
        </xsl:when>
        <!--otherwise, if there's a second extent value, add a comma and a space-->
        <xsl:when test="following-sibling::ead3:extent[1]">
          <xsl:text>, </xsl:text>
        </xsl:when>
      </xsl:choose>
    </xsl:copy>
  </xsl:template>

  <!-- this stuff won't work for all of the hand-encoded YCBA files, so those should probably be updated in ASpace.
    Or, just remove these templates for YCBA by adding a repository-based filter-->
  <xsl:template match="ead3:physfacet">
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
  <xsl:template match="ead3:dimensions">
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
      <xsl:element name="head" namespace="urn:isbn:1-931666-22-9">
        <xsl:value-of select="substring-after(ead3:head, ') ')"/>
      </xsl:element>
      <xsl:apply-templates select="ead3:* except ead3:head"/>
      <xsl:apply-templates
        select="../ead3:*[local-name() = $grouping-element-name][matches(ead3:head, '^\d\)')][position() gt 1]/ead3:*[not(local-name() = 'head')]"
      />
    </xsl:copy>
  </xsl:template>
  <xsl:template match="ead3:*[matches(ead3:head, '^\d\)')][position() gt 1]" priority="2"/>

 
  <!-- check with MSSA to see if they still need their "Forms part of:" rule 
    for odd elements with that head element -->
  
  <!-- do we still need this?? -->
  <xsl:template match="ead3:archdesc/ead3:did/ead3:origination[@label = 'source']"/>



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

  <!-- decide later on how we should handle default head / label values for each element-->



<!-- we'll have to update how ASpace deals with languages (and languagesets)
    but for now, since EAD3 language can only contain text, that's all that we'll give it-->
  <xsl:template match="ead3:language">
    <xsl:copy>
      <xsl:apply-templates select="@*"/>
      <xsl:value-of select="."/>
    </xsl:copy>
  </xsl:template>


  <!-- you can't designate an "unordered" list in ASpace, but if no enumeration attriibute is supplied,
    we can (and should) assume it's just an unordered, or "simple" list.-->
  <xsl:template match="ead3:list[@listtype = 'ordered'][not(@numeration)] | ead3:list[@listtype = 'ordered'][@numeration eq '']">
    <xsl:copy>
      <xsl:apply-templates select="@* except @numeration"/>
      <xsl:attribute name="listtype">
        <xsl:text>unordered</xsl:text>
      </xsl:attribute>
      <xsl:apply-templates/>
    </xsl:copy>
  </xsl:template>

  

  <!-- hack to remove the extra paragraph element that ASpace inserts before hard-code table elements 
    (see beinecke.sok, appendix 5, as an example)
  is this still required???
  -->
  <xsl:template match="ead3:p[ead3:table]">
    <xsl:apply-templates/>
  </xsl:template>

  <!-- we want ead3:c elements in the final product, so if enumerated elements are exported by mistake,
    we'll change those here -->
  <xsl:template match="ead3:c01|ead3:c02|ead3:c03|ead3:c04|ead3:c05|ead3:c06|ead3:c07|ead3:c08|ead3:c09|ead3:c10|ead3:c11|ead3:c12">
    <xsl:element name="c" namespace="http://ead3.archivists.org/schema/">
      <xsl:apply-templates select="@*|node()"/>
    </xsl:element>
  </xsl:template>
  
  <!-- we need to check on unitdatestructureds to see if we need to remove those and only process the unitdate that follows.
    here's where we do that (until we can get ASpace updated to align better with EAD3). -->
  <xsl:template match="ead3:unitdatestructured[following-sibling::*[1][local-name() eq 'unitdate']]">
     <xsl:variable name="remove" select="mdc:remove-this-date(.)"/>
     <xsl:if test="$remove eq false()">
       <xsl:copy>
         <xsl:apply-templates select="@*|node()"/>
       </xsl:copy>
     </xsl:if>
  </xsl:template>

</xsl:stylesheet>