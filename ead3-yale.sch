<?xml version="1.0" encoding="UTF-8"?>
<sch:schema xmlns:sch="http://purl.oclc.org/dsdl/schematron" queryBinding="xslt2"
    xmlns:sqf="http://www.schematron-quickfix.com/validator/process">
    <sch:ns uri="http://ead3.archivists.org/schema/" prefix="ead3"/>
    
    <!-- to do... add tests for container types (e.g. item_barcode vs. Item Barcode)
        etc. 
        -->
    
    <sch:pattern>
        <sch:rule context="ead3:archdesc">
            <sch:assert test="@level eq 'collection'">You must change this level attribute to "collection" in ArchivesSpace. "<value-of select="@level"/>" is not a valid value at this level of description at YUL.</sch:assert>
            <sch:assert test="ead3:accessrestrict">You must supply a resource-level access restriction statement to be DACS compliant.</sch:assert>
            <!-- what other notes should we test for in every finding aid???? -->
        </sch:rule>
    </sch:pattern>
    
    <sch:pattern>
        <sch:rule context="ead3:recordid">
            <sch:assert test="matches(.,'(^mssa\.((ms|ru|hvt)\.[0-9]{4}[A-Z]?|pubs\.[0-9a-z]*))$|
                (^divinity\.([0-9a-zA-Z]+(\.[0-9]{1})?|bib\.[0-9]*))$|
                (^beinecke\.[0-9a-zA-Z]{2,16}(\.[0-9]{1})?)$|
                (^music\.(mss|misc)\.[0-9]{4}(\.[0-9]{1})?)$|
                (^oham\.[a-zA-Z]{2,9})$|
                (^arts\.(aob|dra|art|bkp)\.[0-9]{4}(\.[0-9]{1})?)$|
                (^vrc\.[0-9]{4}(\.[0-9]{1})?)$|
                (^med\.(ms|pam)\.[0-9]{4}(\.[0-9]{1})?)$|
                (^ycba\.(mss|ar)\.[0-9]{4}(\.[0-9]{1})?)$|
                (^ycba\.\ia\.[SA][0-9]{3})$|
                (^ypm\.[a-z]{2,7}\.[0-9]{6})$|
                (^lwl\.[a-z]{2,7}\.[0-9]{1,6})$|
                (^yul\.[0-9a-zA-Z\.]{2,16})$| 
                (^HVT\-[0-9]{4})$'
                , 'x')">The EAD ID value for this collection, "<sch:value-of select="."/>," does not adhere to our local best practices.  You must correct this issue before the file will export properly.</sch:assert>
        </sch:rule>
    </sch:pattern>
    
    <sch:pattern>
        <sch:rule context="ead3:publicationstmt">
            <sch:assert test="ead3:date">This finding aid is missing a publication date. Please supply one.</sch:assert>
        </sch:rule>
    </sch:pattern>
    
    <sch:pattern>
        <sch:rule context="ead3:titlestmt">
            <sch:assert test="ead3:titleproper">You must supply a title for the finding aid in ArchivesSpace.</sch:assert>
        </sch:rule>
    </sch:pattern>
    
    <sch:pattern>
        <sch:rule context="ead3:archdesc/ead3:did">
            <sch:assert test="ead3:unitdatestructured//@standarddate">You must supply standardized dates at the resource level.</sch:assert>
        </sch:rule>
    </sch:pattern>
    
    <sch:pattern>
        <!-- add in function test for check digit -->
        <sch:let name="repo_code" value="tokenize(normalize-space(/ead3:ead/ead3:archdesc/@altrender),'/')[3]"/>
        <sch:rule context="ead3:container/@containerid[not($repo_code eq '3')]">
            <sch:assert test="matches(., '^\d{14}')">Please verify that your barcode values are correct. They should be 14 digits long.</sch:assert>
        </sch:rule>
        <sch:rule context="ead3:container/@containerid[$repo_code eq '3']">
            <sch:assert test="matches(., '^\d{9}')">Please verify that your barcode values are correct. They should be 9 digits long</sch:assert>
        </sch:rule>
    </sch:pattern>
    
    <sch:pattern>
        <!-- at terminal component nodes, we need to make sure the component either has a container...
            an ancestor with a container...
            an approved cross-reference note...
            a digital object...
            or an access restriction that indicates the material cannot be requested
                or is borndigital in nature, and so, doesn't require a container (or a published digital object)
                ...phew. -->
        <sch:let name="local-access-restriction-types-that-do-not-require-containers"
            value="('NoRequest', 'BornDigital')"/>
        <sch:rule context="ead3:c[not(ead3:c)]">
            <sch:assert test="ead3:did/ead3:container
                or ancestor::ead3:c/ead3:did/ead3:container
                or descendant::*[matches(normalize-space(.), '^stored in:|^in:|^see:', 'i')]
                or tokenize(ead3:accessrestrict/@localtype) = $local-access-restriction-types-that-do-not-require-containers
                or tokenize(ancestor::ead3:c[ead3:accessrestrict/@localtype]/ead3:accessrestrict/@localtype) = $local-access-restriction-types-that-do-not-require-containers
                or ead3:did//ead3:dao">
                Hold up. This terminal component appears to be missing a container, a properly formatted cross-reference note, a published digital object, or a local access restriction type that would indicate
                that this level of description does not require a container. Sound about right?
            </sch:assert>
        </sch:rule>
        
        <sch:rule context="ead3:c">
            <sch:assert test="@level=('series', 'subseries', 'file', 'item', 'otherlevel', 'recordgrp', 'subgrp')">
                Please update your level attribute. "<sch:value-of select="@level"/>" is not a valid option. The valid options for Yale's best practices are:
                series, subseries, file, item, otherlevel, recordgrp, or subgrp.
            </sch:assert>
        </sch:rule>
        
    </sch:pattern>
    
    <sch:pattern>
        <!-- add in a value list here once agreed upon in YAMS -->
        <sch:rule context="ead3:c[@level eq 'otherlevel']">
            <sch:assert test="@otherlevel">If the value of a level attribute is "otherlevel', then you must specify the value of the otherlevel attribute</sch:assert>
        </sch:rule>
    </sch:pattern>
    
    <sch:pattern>
        <sch:rule context="ead3:head">
            <sch:report test="lower-case(.) = 'typecollection'">
                Please verity that this finding aid does not contain a note that should remain unpublished.
                The note, "<sch:value-of select=".."/>," contains a head element that usually indicates 
                that this note is a staff-only Preservica note.
            </sch:report>
            <sch:report test="contains(lower-case(.), 'samma')">
                Please verity that this finding aid does not contain a note that should remain unpublished.
                The note, "<sch:value-of select=".."/>," contains a head element that includes the word "Samma", 
                which typically indicate that the note is meant to be internal-only.
            </sch:report>
        </sch:rule>
    </sch:pattern>
    
</sch:schema>