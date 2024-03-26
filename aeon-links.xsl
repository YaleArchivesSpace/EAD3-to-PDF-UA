<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:fo="http://www.w3.org/1999/XSL/Format" xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:fox="http://xmlgraphics.apache.org/fop/extensions"
    xmlns:mdc="http://mdc"
    xmlns:ead3="http://ead3.archivists.org/schema/" exclude-result-prefixes="xs ead3 fox mdc"
    version="3.0">
    
    
    <xsl:param name="include-Aeon-link" select="false()" as="xs:boolean"/>
    
    <!-- 'container' or 'component' are recognized values. -->
    <xsl:param name="request-link-for-distinct-type" select="'container'" as="xs:string"/>
    
    <xsl:param name="production-or-test-Aeon" select="'test'"/>
    <xsl:param name="request-link-text" select="'REQUEST'" as="xs:string"/>

    
    <!-- using this twice now, so i should likely move this and re-use on the cover-page.xsl file... but for now, since it might not be useful in the PDF requests after all... -->
    <xsl:variable name="export-timestamp" select="'&amp;PDF-timestamp=' || /ead3:ead/ead3:control[1]/ead3:maintenancehistory[1]/ead3:maintenanceevent[1]/ead3:eventdatetime[1]"/>
    
    <xsl:variable name="aeon-site">
        <xsl:variable name="repo-to-site-code">
            <!-- 3-character codes, per request -->
            <xsl:choose>
                <xsl:when test="$repository-code = ('arts', 'vrc')">
                    <xsl:text>ART</xsl:text>
                </xsl:when>
                <xsl:when test="$repository-code = 'beinecke'">
                    <xsl:text>BRBL</xsl:text>
                </xsl:when>
                <xsl:when test="$repository-code = 'divinity'">
                    <xsl:text>DIV</xsl:text>
                </xsl:when>
                <xsl:when test="$repository-code = 'lwl'">
                    <xsl:text>LWL</xsl:text>
                </xsl:when>
                <xsl:when test="$repository-code = 'med'">
                    <xsl:text>MHL</xsl:text>
                </xsl:when>
                <xsl:when test="$repository-code = 'mssa'">
                    <xsl:text>MSS</xsl:text>
                </xsl:when>
                <xsl:when test="$repository-code = ('music', 'oham')">
                    <xsl:text>MUS</xsl:text>
                </xsl:when>
                <xsl:when test="$repository-code = 'ycba'">
                    <xsl:text>BCA</xsl:text>
                </xsl:when>
                <xsl:when test="$repository-code = 'ypm'">
                    <xsl:text>YPM</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text>MSS</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:value-of select="'&amp;Site=' || $repo-to-site-code"/>
    </xsl:variable>
   
    <xsl:variable name="aspace-base-URL" select="if ($production-or-test-Aeon eq 'test') then 'https://testarchivesspace.library.yale.edu/api/' else 'https://archivesspace.library.yale.edu/api/'"/>
        
    <xsl:variable name="aeon-base-URL">
        <xsl:choose>
            <xsl:when test="$repository-code eq 'beinecke' and $production-or-test-Aeon eq 'test'">
                <xsl:value-of select="'https://aeon-test.library.yale.edu/aeon.dll?Action=10&amp;Form=20'"/>
            </xsl:when>
            <xsl:when test="$repository-code eq 'beinecke' and $production-or-test-Aeon eq 'prod'">
                <xsl:value-of select="'https://aeon.library.yale.edu/aeon.dll?Action=10&amp;Form=20'"/>
            </xsl:when>
            <xsl:when test="not($repository-code eq 'beinecke') and $production-or-test-Aeon eq 'test'">
                <xsl:value-of select="'https://aeon-test.library.yale.edu/aeon.dll?Action=10&amp;Form=20'"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="'https://aeon.library.yale.edu/aeon.dll?Action=10&amp;Form=20'"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    
    <xsl:variable name="aeon-document-type">
        <xsl:choose>
            <xsl:when test="$repository-code eq 'beinecke'">
                <xsl:value-of select="'&amp;DocumentType=BRBL'"/>
            </xsl:when>
            <xsl:when test="starts-with(normalize-space(ead3:ead/ead3:control/ead3:recordid[1]), 'mssa.ru')">
                <xsl:value-of select="'&amp;DocumentType=Archives'"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="'&amp;DocumentType=Manuscript'"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    
    <xsl:variable name="aeon-call-number" select="'&amp;CallNumber=' || $collection-identifier"/>
    
    <xsl:variable name="aeon-value">
        <xsl:choose>
            <xsl:when test="$repository-code eq 'beinecke'">
                <xsl:value-of select="'&amp;Value=GenericRequestManuscript'"/>
            </xsl:when>
            <xsl:when test="$office-of-origin-request">
                <xsl:value-of select="'&amp;Value=GenericRequestOrigin'"/>
            </xsl:when>
            <xsl:when test="starts-with(normalize-space(ead3:ead/ead3:control/ead3:recordid[1]), 'mssa.ru')">
                <xsl:value-of select="'&amp;Value=GenericRequestArchive'"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="'&amp;Value=GenericRequestManuscript'"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    
    <xsl:variable name="aeon-collection-title" select="'&amp;ItemTitle=' || $collection-title"/>
    
    <xsl:variable name="aeon-collection-title-custom-field" select="'&amp;Transaction.CustomFields.CollectionTitle=' || $collection-title"/>
    
    <xsl:variable name="aeon-ead-id" select="'&amp;Transaction.CustomFields.RootRecordURI=' || $finding-aid-identifier"/>
    
    <xsl:variable name="aeon-citation" select="'&amp;ItemCitation=' || /ead3:ead/ead3:archdesc/ead3:prefercite/normalize-space(ead3:p[1])"/>

 
    <xsl:variable name="aspace-location-list">
        <xsl:if test="$include-Aeon-link eq true()">
            <xsl:variable name="location-urls" as="item()*">
                <xsl:sequence select="distinct-values(/ead3:ead/ead3:archdesc/ead3:dsc//ead3:container/substring-after(@altrender, ' '))"/>
            </xsl:variable>
            <locations>
                <xsl:for-each select="$location-urls[normalize-space()]">
                    <location url="{.}">
                        <xsl:variable name="location-json" as="map(*)">
                            <xsl:sequence select="unparsed-text($aspace-base-URL || .) => parse-json()"/>
                        </xsl:variable>
                        <xsl:value-of select="$location-json?title => replace('\[\d{5}, ', '[')"/>            
                    </location>
                </xsl:for-each>
            </locations>
        </xsl:if>
    </xsl:variable>
 
    <xsl:template name="add-aeon-link">
                 
        <xsl:variable name="container-id" select="if (contains(@altrender, ' ')) then tokenize(substring-before(., ' '), '/')[last()] else tokenize(@altrender, '/')[last()]"/>
     
        <xsl:variable name="location-url" select="substring-after(@altrender, ' ')"/>
              
        <xsl:variable name="aeon-item-volume"  select="'&amp;ItemVolume=' || concat(upper-case(substring(@localtype,1,1)), substring(@localtype,2)) || ' ' || normalize-space(.)"/>
        
        <xsl:variable name="aeon-restricted" select="'&amp;Transaction.CustomFields.TopContainerRestriction=' || (if (../@ancestor-access-restrictions) then 'Y' else 'N')"/>
        
        <xsl:variable name="aeon-reference-number" select="if (@containerid) then '&amp;ReferenceNumber=' || @containerid else ''"/>
        
        <xsl:variable name="aeon-sub-location" select="if (@encodinganalog) then '&amp;SubLocation=' || @encodinganalog else ''"/>
        
        <xsl:variable name="aeon-location-uri" select="if (normalize-space($location-url)) then '&amp;Transaction.CustomFields.LocationURI=' || $location-url else ''"/>
        
        <xsl:variable name="aeon-location">
            <xsl:if test="normalize-space($location-url)">
                <xsl:value-of select="'&amp;Location=' || $aspace-location-list/locations/location[@url = $location-url]"/>
            </xsl:if>
        </xsl:variable>
        
        <xsl:variable name="aeon-access-restriction-types" select="if (normalize-space(../@ancestor-access-restrictions)) then ('&amp;RestrictionCode=' || string-join(../@ancestor-access-restrictions, ';')) else ''"/>
        
        <xsl:variable name="aeon-series-id" select="if (normalize-space(../@series)) then ('&amp;Transaction.CustomFields.ItemSeries=' || ../@series) else ''"/>
        
        <xsl:variable name="aeon-folder" select="if ($request-link-for-distinct-type eq 'component'
                and following::ead3:container[@parent][1])
            then '&amp;Transaction.CustomFields.ItemFolder='
            || upper-case(substring(following::ead3:container[@parent][1]/@localtype,1,1))
            || substring(following::ead3:container[@parent][1]/@localtype,2)
            || ' '
            || following::ead3:container[@parent][1]
            || ': '
            || substring(../@component-title, 1, 25)
            || (if (string-length(../@component-title) eq 26) then '...' else ())
            else ()"/>
        
        <xsl:variable name="aeon-request-uri" select="if ($request-link-for-distinct-type eq 'component') 
            (: yes, right now, we're always pointing folks to the production staff URL.  that's because the 'test' aspect is in regards to test Aeon, not test ASpace. :)
            then '&amp;EADNumber=https://archivesspace.library.yale.edu/resources/' || tokenize($resource-url, '/')[last()] || '#tree::archival_object_' || tokenize(../@component-url, '/')[last()]
            else '&amp;EADNumber=https://archivesspace.library.yale.edu/top_containers/' || $container-id"
        />

  
        <xsl:variable name="link" select="$aeon-base-URL || $aeon-value || $aeon-site || $aeon-document-type || '&amp;SystemID=PDF' || $aeon-call-number || $aeon-citation || $aeon-ead-id || $aeon-access-restriction-types || $aeon-collection-title || $aeon-collection-title-custom-field || $aeon-item-volume || $aeon-location || $aeon-location-uri || $aeon-reference-number
            || $aeon-request-uri || $aeon-restricted || $aeon-series-id || $aeon-sub-location || $aeon-folder || $export-timestamp"/>

        <!-- test and see if i need to use encode-for-uri -->
            <fo:block xsl:use-attribute-sets="request.block">
                <fo:basic-link external-destination="{$link}" xsl:use-attribute-sets="ref">
                    <xsl:value-of select="if ($request-link-for-distinct-type eq 'component' and following::ead3:container[@parent][1])
                        then string-join(($request-link-text, upper-case(following::ead3:container[@parent][1]/@localtype), following::ead3:container[@parent][1]), ' ')
                        else string-join(($request-link-text, upper-case(@localtype), .), ' ')"/>  
                </fo:basic-link>
            </fo:block>

    </xsl:template>
  
</xsl:stylesheet>
