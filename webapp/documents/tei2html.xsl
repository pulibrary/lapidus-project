<?xml version="1.0" encoding="utf-8"?>

<!-- Transform new MJP TEI file into simple web page -->

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
		xmlns:xs="http://www.w3.org/2001/XMLSchema"
		xmlns:xlink="http://www.w3.org/1999/xlink"
		xmlns:tei="http://www.tei-c.org/ns/1.0"
		xmlns:local="http://diglib.princeton.edu"
		xmlns:exist="http://exist.sourceforge.net/NS/exist"
		xmlns="http://www.w3.org/1999/xhtml"
		xmlns:html="http://www.w3.org/1999/xhtml"
		exclude-result-prefixes="xs" version="2.0">
  
  <xsl:output
      method="xml"
      doctype-system="about:legacy-compat"
      encoding="UTF-8"
      indent="yes" />
  
  <xsl:key name="surfaces"
	   match="//tei:TEI/tei:facsimile/tei:surface"
	   use="@xml:id"/>
  
  <xsl:variable name="matches" select="//tei:TEI//exist:match"/>

  <xsl:variable name="matches-id">
    <xsl:for-each  select="//tei:TEI//exist:match">
      <item><xsl:value-of select="generate-id(.)"/></item>
    </xsl:for-each>
  </xsl:variable>

<xsl:function name="local:index-of-node" as="xs:integer*" 
              >
  <xsl:param name="nodes" as="node()*"/> 
  <xsl:param name="nodeToFind" as="node()"/> 
 
  <xsl:sequence select=" 
  for $seq in (1 to count($nodes))
  return $seq[$nodes[$seq] is $nodeToFind]
 "/>
   
</xsl:function>

  <!-- Algorithm from http://wiki.tei-c.org/index.php/Milestone-chunk.xquery -->
  <xsl:function name="local:milestone-chunk" as="node()*">
    <xsl:param name="ms1" as="element()"/>
    <xsl:param name="ms2" as="element()?"/>
    <xsl:param name="node" as="node()"/>
  
    <xsl:variable name="chunk">
    <xsl:choose>
      <xsl:when test="$node/self::*"> <!-- When the node is an element -->
        <xsl:choose>
          <xsl:when test="$node is $ms1">
            <xsl:copy-of select="$node" copy-namespaces="yes"/>
          </xsl:when>
          <xsl:when
            test="some $n in $node/descendant::* satisfies ($n is $ms1 or $n is $ms2)">
           <xsl:element name="{local-name($node)}" namespace="{namespace-uri($node)}">
              
                <xsl:for-each select="$node/node() | $node/@*">
                <xsl:sequence select="local:milestone-chunk($ms1, $ms2, current())" />
              </xsl:for-each>
            </xsl:element>
          </xsl:when>
          <xsl:when test="$node &gt;&gt; $ms1 and $node &lt;&lt; $ms2">
            <xsl:copy-of select="$node" copy-namespaces="yes"/>
          </xsl:when>
        </xsl:choose>
      </xsl:when>
      <xsl:when test="count($node|$node/../@*) = count($node/../@*)"> <!-- When the node is an attribute -->
        <xsl:copy-of select="$node" copy-namespaces="yes"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:choose>
          <xsl:when test="$node &gt;&gt; $ms1 and $node &lt;&lt; $ms2">
            <xsl:copy-of select="$node" copy-namespaces="yes"/>
          </xsl:when>
          <xsl:otherwise/>
        </xsl:choose>
      </xsl:otherwise>
    </xsl:choose>
    </xsl:variable>
    <xsl:sequence select="$chunk"/>
  </xsl:function>
  

  <xsl:template match="/">
    <html lang="en" xmlns="http://www.w3.org/1999/xhtml">
      <head>
	<meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
	<title>sample</title>	
	<style type="text/css">
	  div.result p { font-size: small; }
	  header {background:black; color: white;}
	  span.hi {background:yellow;}
	  p.odd,p.even {margin: 3px;}
	  p.odd { background:whitesmoke; }
	</style>
      </head>
      <body>
	<xsl:apply-templates />
      </body>
    </html>
  </xsl:template>
  
  <xsl:template match="tei:TEI-test">
    <xsl:copy-of select="$matches"/>
  </xsl:template>

  <xsl:template match="tei:TEI">
    <xsl:variable name="textblock">
      <xsl:apply-templates select="tei:text" />
    </xsl:variable>

    <section>
      <xsl:apply-templates select="tei:teiHeader"/>
    </section>
    <section>
      <h3>Matches</h3>
      <ol>
	<xsl:for-each select="$textblock//html:span[@class='hi']">
	  <xsl:variable name="prev" select="current()/preceding::text()[1]" as="xs:string"/>
	  <xsl:variable name="next" select="current()/following::text()[1]" as="xs:string"/>
	  <li>
	    <span class="previous"><xsl:value-of select="substring($prev, string-length($prev) -60)" /></span>
	    <span class="hi"><a href="#{current()/@id}"><xsl:apply-templates/></a></span>
	    <span class="next"><xsl:value-of select="substring($next, 1, 60)" /></span>
	  </li>
	</xsl:for-each>
      </ol>
    </section>
    <section>
      <xsl:sequence select="$textblock" />
    </section>
  </xsl:template>

  <xsl:template match="tei:teiHeader">
    <xsl:apply-templates select="tei:fileDesc/tei:sourceDesc" />
  </xsl:template>

  <xsl:template match="tei:sourceDesc">
    <header>
            <xsl:apply-templates select="tei:biblStruct/tei:monogr"/>
    </header>
    <nav>
      <ul>
	<xsl:for-each select="tei:biblStruct/tei:relatedItem[@type='constituent']">
	  <li><xsl:apply-templates select="current()"/></li>
	</xsl:for-each>
      </ul>
    </nav>
  </xsl:template>

  <xsl:template match="tei:monogr">
    <h1><xsl:apply-templates select="tei:title"/></h1>
  </xsl:template>

  <xsl:template match="tei:relatedItem[@type='constituent']">
    <xsl:variable name="title" select="tei:biblStruct/tei:analytic/tei:title"/>
    <xsl:variable name="byline">
      <xsl:apply-templates select="tei:biblStruct/tei:analytic/tei:respStmt"/>
    </xsl:variable>
    <xsl:variable name="page" select="tokenize(tei:biblStruct/tei:monogr/tei:imprint/tei:biblScope/@corresp, ' ')[1]"/>
    <a href="#{$page}"><xsl:value-of select="concat($title, ' . . . ', $byline)"/></a>
  </xsl:template>

  <xsl:template match="tei:respStmt">
    <xsl:apply-templates select="tei:persName"/>
  </xsl:template>
  
  <xsl:template match="tei:text">
    <table>
      <xsl:apply-templates /> 
    </table>
 
  </xsl:template>

  <xsl:template match="tei:front">
    <xsl:variable name="pbs"  select=".//tei:pb"/>

      <xsl:for-each select="$pbs">
        <xsl:variable name="pb2-pos" select="position() +1" />
  
        <tr>
           <td>
              <xsl:choose>
                <xsl:when test="$pbs[$pb2-pos]">
                  <xsl:apply-templates select="local:milestone-chunk(current(), $pbs[$pb2-pos], ./ancestor::tei:front)" mode="render"/>
                </xsl:when>

                <xsl:otherwise>
                  <xsl:apply-templates select="current()/following-sibling::element()" mode="render"/>
                </xsl:otherwise>
              </xsl:choose>
              
            </td>
          <td>
            <a name="{@facs}"/>
            <img src = "{key('surfaces', @facs)/tei:graphic[@ana='lowres']/@url}" alt="page"/>
          </td>
        </tr>
      </xsl:for-each>
    
  </xsl:template>

  <xsl:template match="tei:body">
    <xsl:variable name="pbs"  select=".//tei:pb"/>
   
      <xsl:for-each select="$pbs">
        <xsl:variable name="pb2-pos" select="position() +1" />
  
        <tr>
           <td>
              <xsl:choose>
                <xsl:when test="$pbs[$pb2-pos]">
                  <xsl:apply-templates select="local:milestone-chunk(current(), $pbs[$pb2-pos], ./ancestor::tei:body)" mode="render"/>
                </xsl:when>

                <xsl:otherwise>
<!--                  <xsl:apply-templates select="current()/following::element()" mode="render"/> -->
                  <xsl:apply-templates select="local:milestone-chunk(current(), current()/following::element()[last()], ./ancestor::tei:body)" mode="render"/>
                </xsl:otherwise>
              </xsl:choose>
              
            </td>
          <td>
            <a name="{@facs}"/>
            <img src = "{key('surfaces', @facs)/tei:graphic[@ana='lowres']/@url}" alt="page"/>
          </td>
        </tr>
      </xsl:for-each>
    
  </xsl:template>
  
  <xsl:template match="tei:text" mode="render">
    <xsl:apply-templates mode="#current"/>
  </xsl:template>
  
  <xsl:template match="tei:p" mode="render">
    <p><xsl:apply-templates mode="#current"/></p>
  </xsl:template>

  <xsl:template match="tei:lb" mode="render">
    <br />
  </xsl:template>

  <xsl:template match="tei:salute" mode="render">
    <p><xsl:apply-templates mode="#current"/></p>
  </xsl:template>

  <xsl:template match="exist:match" mode="render">
    <span class="hi" id="{generate-id()}"><xsl:apply-templates mode="#current"/></span>
  </xsl:template>

  <xsl:template match="exist:match-1" mode="render">
    <span class="hi"><xsl:apply-templates mode="#current"/></span>
  </xsl:template>

  <xsl:template match="exist:match-works" mode="render">
    <xsl:variable name="index" select="index-of($matches, current())[1]"/>
    <span id="{concat('match', $index)}" class="hi"><xsl:apply-templates mode="#current"/></span>
  </xsl:template>

</xsl:stylesheet>
