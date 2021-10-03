<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:fo="http://www.w3.org/1999/XSL/Format" xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:fox="http://xmlgraphics.apache.org/fop/extensions"
    xmlns:ead3="http://ead3.archivists.org/schema/" exclude-result-prefixes="xs ead3 fox" version="2.0">
    
    <!-- this file is imported by "ead3-to-pdf-ua.xsl" -->
    
    <xsl:template name="embed-metadata">
        <!-- this is how we add XMP embedded metadata to the file, which is required for a PDF-UA document.
            (need to figure out how to add the data license once that's supported in ASpace's EAD3 1.1 export option.)
            To see the results, go to File -> Properties when the file is opended in Adobe's Acrobat Reader
            -->
        <fo:declarations>
            <x:xmpmeta xmlns:x="adobe:ns:meta/">
                <rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
                    <rdf:Description rdf:about="" xmlns:dc="http://purl.org/dc/elements/1.1/">
                        <!-- Dublin Core properties go here -->
                        <dc:title><xsl:value-of select="$finding-aid-title/normalize-space()"/></dc:title>
                        <dc:creator><xsl:value-of select="$finding-aid-author/normalize-space()"/></dc:creator>
                        <dc:description><xsl:value-of select="$finding-aid-summary/normalize-space()"/></dc:description>
                    </rdf:Description>
                    <rdf:Description rdf:about=""
                        xmlns:xmp="http://ns.adobe.com/xap/1.0/">
                        <!-- XMP properties go here -->
                        <!-- should figure out a way to get the FOP version another way, even if i just add it to a config file -->
                        <xmp:CreatorTool>Apache FOP 2.6</xmp:CreatorTool>
                    </rdf:Description>
                    <rdf:Description rdf:about=""
                        xmlns:pdf="http://ns.adobe.com/pdf/1.3/">
                        <!-- PDF properties go here -->
                        <pdf:Keywords><xsl:value-of select="string-join(($holding-repository/normalize-space(), $collection-identifier/normalize-space()), ', ')"/></pdf:Keywords>
                    </rdf:Description>
                </rdf:RDF>
            </x:xmpmeta>
        </fo:declarations>
    </xsl:template>
    
</xsl:stylesheet>