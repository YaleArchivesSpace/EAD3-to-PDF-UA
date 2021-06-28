<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:ead="http://ead3.archivists.org/schema/"
    xmlns:mdc="http://mdc/local-functions" xmlns:map="http://www.w3.org/2005/xpath-functions/map"
    exclude-result-prefixes="xs ead mdc map" version="3.0">
    
    <!-- depends on yale.aspace_v2_to_yale_ead3.xsl, right now at least, for $repository variable -->
    
    <xsl:param name="valid-top-container-types" select="('box', 'folder', 'item', 'volume', 'reel', 'file')"/>
    
    <!-- ideally, we could call the ASpace API and get an updated list of "onsite = false" locations and cache that as a map-->
    <xsl:param name="offsite-locations" as="map(xs:string, xs:string)"
        select="
        map {
        '/locations/9': 'LSF',
        '/locations/206': 'LSF BP',
        '/locations/207': '344 W D',
        '/locations/2831': 'IM',
        '/locations/3273': '344 W RR',
        '/locations/3358': '344 W CS',
        '/locations/4050': '344 W TS',
        '/locations/4485': '344 W BPS'
        }"/>
    
    <xsl:param name="acknowledged-indicator-suffixes" as="map(xs:string, xs:decimal)"
        select="
        map {
        'art': .01,
        'broadside': .02,
        'broadside oversize': .03,
        'cold storage': .04,
        'file': .05,
        'file oversize': .06,
        'oversize': .07,
        'record album storage': .08,
        'roll': .09
        }"/>
    
    <xsl:function name="mdc:container-to-number" as="xs:decimal">
        <xsl:param name="current-container" as="node()*"/>
        <xsl:variable name="primary-container-number"
            select="
            if (contains($current-container, '-')) then
            replace(substring-before($current-container, '-'), '\D', '')
            else
            replace($current-container, '\D', '')"/>
        <xsl:variable name="primary-container-modifier">
            <xsl:choose>
                <xsl:when test="matches($current-container, '\D')">
                    <xsl:analyze-string select="$current-container" regex="(\D)(\s?)">
                        <xsl:matching-substring>
                            <xsl:value-of select="number(string-to-codepoints(upper-case(regex-group(1))))"/>
                        </xsl:matching-substring>
                    </xsl:analyze-string>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="0"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:value-of select="xs:decimal(concat($primary-container-number, '.', $primary-container-modifier))"/>
    </xsl:function>
    
    <xsl:function name="mdc:container-to-decimal-for-grouping" as="xs:decimal">
        <xsl:param name="current-container" as="item()"/>
        <xsl:variable name="primary-container"
            select="
            if (contains($current-container, '-')) then
            replace(substring-before($current-container, '-'), '\D', '')
            else
            replace($current-container, '\D', '')"/>
        
        <xsl:variable as="xs:integer" name="primary-container-number" select="if ($primary-container castable as xs:integer) then $primary-container cast as xs:integer else 0"/>
        
        <!-- ignore () or expect them???.  eventually they should not exist in the container indicators, per a policy decision, but we have a way to go to get there. -->
        <xsl:variable name="suffix" select="substring-before(substring-after(lower-case($current-container), '('), ')')"/>
        
        <xsl:variable name="primary-container-modifier">
            <xsl:value-of select="(map:get($acknowledged-indicator-suffixes, $suffix), 0)[1]"/>
        </xsl:variable>
        <xsl:value-of select="xs:decimal($primary-container-number + $primary-container-modifier)"/>
    </xsl:function>
    
    <xsl:function name="mdc:capitalize" as="xs:string?">
        <xsl:param name="name" as="xs:string?"/>
        <xsl:sequence select="concat(upper-case(substring($name,1,1)), substring($name, 2))"/>
    </xsl:function>
    
    <xsl:function name="mdc:container-statement-label" as="xs:string">
        <xsl:param name="element" as="node()"/>
        <xsl:variable name="container-type" select="mdc:capitalize(local-name($element))"/>
        <xsl:variable name="one-child" select="if ($element/ead:container[2]) then false() else true()"/>  
        <xsl:variable name="suffix" select="if ($one-child) then '' else if ($container-type eq 'Box') then 'es' else 's'"/> 
        <xsl:value-of select="concat($container-type, $suffix, ': ')"/>
    </xsl:function>
    
    <xsl:variable name="all-containers">
        <!-- for mssa, would probably need to do this for each series, rather than the collection, right? -->
        <xsl:if test="not($repository = ('mssa', 'ypm'))">
            <container-list>
                <!-- keep an eye on performance, but the preceding predicate will dedupe duplicate container numbers...  e.g 1, 1, 1 become 1 -->
                <xsl:for-each-group select="ead:ead/ead:archdesc/ead:dsc//ead:container[@altrender][not(@altrender = preceding::ead:container/@altrender)]"
                    group-by="if (map:contains($offsite-locations, substring-after(@altrender, ' '))) then 'offsite' else 'onsite'">
                    <!-- add an element for on- vs. off-site -->
                    <xsl:element name="{current-grouping-key()}">
                        <xsl:for-each-group select="current-group()" group-by="if (not(@localtype) or @localtype eq '') then 'box' else lower-case(@localtype)">
                            <!-- add an element for the container type -->
                            <xsl:element name="{current-grouping-key()}">
                                <xsl:for-each select="current-group()">
                                    <xsl:sort select="mdc:container-to-number(.)" data-type="number" order="ascending"/>
                                    <xsl:copy-of select="."/>
                                </xsl:for-each>
                            </xsl:element>
                        </xsl:for-each-group>
                    </xsl:element>              
                </xsl:for-each-group>
            </container-list>
        </xsl:if> 
    </xsl:variable>
    
    <xsl:variable name="all-digital-instances">
        <xsl:copy-of select="//ead:did/ead:daoset | //ead:did/ead:dao"/>
    </xsl:variable>
    
    <xsl:template name="container-summary">
        <xsl:param name="containers"/>
        <xsl:for-each select="$containers/*">
            <!-- rename the local elements, like box, etc., to a paragraph element for valid EAD.  we'll add the element name in front of the paragraph, with mdc:container-statement-label -->
            <xsl:element name="p" namespace="http://ead3.archivists.org/schema/">
                <xsl:value-of select="mdc:container-statement-label(.)"/> 
                <xsl:value-of separator=", ">
                    <xsl:for-each-group select="ead:container" group-adjacent="mdc:container-to-decimal-for-grouping(.) - position()">
                        <xsl:sequence
                            select="
                            if (not(current-group()[2])) then
                            normalize-space()
                            else
                            concat(if (contains(., '(')) then normalize-space(substring-before(., '(')) else normalize-space(), '-', current-group()[last()])"/>
                    </xsl:for-each-group>
                </xsl:value-of>
            </xsl:element>
        </xsl:for-each>
    </xsl:template>
    
    <xsl:template match="ead:controlnote[$all-containers/container-list/*] | ead:controlnote[$all-digital-instances/*]">
        <xsl:copy>
            <xsl:apply-templates select="@*|node()"/>
        </xsl:copy>
        <xsl:call-template name="create-holdings-notes">
            <xsl:with-param name="all-containers" select="$all-containers"/>
        </xsl:call-template>
        <xsl:call-template name="create-digital-note">
            <xsl:with-param name="all-digital-instances" select="$all-digital-instances"/>
        </xsl:call-template>
    </xsl:template>
    
    <xsl:template match="ead:filedesc[not(ead:notestmt)][$all-containers/container-list/*] | ead:filedesc[not(ead:notestmt)][$all-digital-instances/*]">
        <xsl:copy>
            <xsl:apply-templates select="@*|node()"/>
            <xsl:element name="notestmt" namespace="http://ead3.archivists.org/schema/">
                <xsl:call-template name="create-holdings-notes">
                    <xsl:with-param name="all-containers" select="$all-containers"/>
                </xsl:call-template>
                <xsl:call-template name="create-digital-note">
                    <xsl:with-param name="all-digital-instances" select="$all-digital-instances"/>
                </xsl:call-template>
            </xsl:element>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template name="create-holdings-notes">
        <xsl:param name="all-containers"/>
        <xsl:for-each select="$all-containers/container-list/*">
            <xsl:call-template name="holdings-note">
                <xsl:with-param name="type" select="local-name()"/>
            </xsl:call-template>
        </xsl:for-each>
    </xsl:template>
    
    <xsl:template name="holdings-note">
        <xsl:param name="type"/>
        <xsl:element name="controlnote" namespace="http://ead3.archivists.org/schema/">
            <xsl:attribute name="localtype" select="$type"/>
            <xsl:call-template name="container-summary">
                <xsl:with-param name="containers" select="$all-containers/container-list/*[local-name() eq $type]"/>
            </xsl:call-template>       
        </xsl:element>
    </xsl:template>
    
    <!-- clean this up, but you get the idea, right? -->
    <xsl:template name="create-digital-note">
        <xsl:param name="all-digital-instances"/>
        <xsl:variable name="digital-object-count" select="count($all-digital-instances/*)"/>
        <xsl:variable name="digital-files-count" select="sum($all-digital-instances/*/*[@linktitle]/xs:integer(substring-before(@linktitle, ' ')))"/>
        <xsl:variable name="object-text" select="if ($digital-object-count eq 1) then 'digital object.' else 'digital objects.'"/>
        <xsl:variable name="object-file-text" select="if ($digital-object-count eq 1) then 'that object' else 'those objects'"/>
        <xsl:if test="$digital-object-count">
            <xsl:element name="controlnote" namespace="http://ead3.archivists.org/schema/">
                <xsl:attribute name="localtype" select="'digital'"/>
                <xsl:element name="p" namespace="http://ead3.archivists.org/schema/">
                    <xsl:text>This collection contains </xsl:text>
                    <xsl:element name="num" namespace="http://ead3.archivists.org/schema/">
                        <xsl:attribute name="localtype" select="'objects'"/>
                        <xsl:attribute name="altrender" select="$digital-object-count"/>
                        <xsl:value-of select="format-number($digital-object-count, '#,###')"/>
                    </xsl:element>
                    <xsl:value-of select="' published ' || $object-text"/>
                    <xsl:if test="$digital-files-count">
                        <xsl:value-of select="' And ' || $object-file-text || ' are comprised of '"/>
                        <xsl:element name="num" namespace="http://ead3.archivists.org/schema/">
                            <xsl:attribute name="localtype" select="'files'"/>
                            <xsl:attribute name="altrender" select="$digital-files-count"/>
                            <xsl:value-of select="format-number($digital-files-count, '#,###')"/>
                        </xsl:element>
                        <xsl:text> digital files.</xsl:text>
                    </xsl:if>
                </xsl:element>
            </xsl:element>
        </xsl:if>
    </xsl:template>
   
    
</xsl:stylesheet>
