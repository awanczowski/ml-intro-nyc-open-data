<?xml version="1.0" encoding="UTF-8"?>
<!--
 Copyright 2013 Andrew Wanczowski
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
-->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    exclude-result-prefixes="xs"
    version="2.0">
    
    <xsl:template match="/">
        <xsl:apply-templates select="."/>
    </xsl:template>
    
    <xsl:template match="attribute()|text()">
        <xsl:copy-of select="."/>
    </xsl:template>
    
    <xsl:template match="element()">
        <xsl:choose>
            <xsl:when  test="local-name(.) = ('find','result','facets','facet','graph','axis','point')">
                <xsl:element name="{local-name(.)}" namespace="{namespace-uri(.)}">
                    <xsl:attribute name="type">object</xsl:attribute>
                    <xsl:copy-of select="./@*" />
                    <xsl:apply-templates select="./node()"/>
                </xsl:element>
            </xsl:when>
            <xsl:when  test="local-name(.) = ('results','agencies','complaints','years','axises','months')">
                <xsl:element name="{local-name(.)}" namespace="{namespace-uri(.)}">
                    <xsl:attribute name="type">array</xsl:attribute>
                    <xsl:copy-of select="./@*" />
                    <xsl:apply-templates select="./node()"/>
                </xsl:element>
            </xsl:when>
            <xsl:otherwise>
                <xsl:element name="{local-name(.)}" namespace="{namespace-uri(.)}">
                    <xsl:copy-of select="./@*" />
                    <xsl:apply-templates select="./node()"/>
                </xsl:element>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
</xsl:stylesheet>