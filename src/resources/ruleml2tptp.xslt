<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet version="2.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:r="http://ruleml.org/spec">

<xsl:output method="text"/>
<!-- We have to do the format ourselves. -->
<xsl:strip-space elements="*"/>

<!-- Line break.  -->
<xsl:variable name="nl" as="xs:string"><xsl:text>
</xsl:text></xsl:variable>

<!-- The root. -->
<xsl:template match="/">
  <xsl:apply-templates select="r:RuleML"/>
</xsl:template>

<!-- Universal templates for trivial nodes. -->
<xsl:template match="r:*">
  <xsl:apply-templates/>
</xsl:template>

<!-- Variables start with a uppercase letter. -->
<xsl:template match="r:Var">
  <xsl:if test="not(matches(text(), '^[a-z][a-z0-9_]*$', 'i'))">
    <xsl:message terminate="no">
      <xsl:text>The format of variable '</xsl:text>
      <xsl:value-of select="text()"/>
      <xsl:text>' is not valid in the target syntax.</xsl:text>
    </xsl:message>
  </xsl:if>
  <xsl:value-of select="concat(upper-case(substring(text(), 1, 1)), substring(text(), 2))"/>
</xsl:template>

<!-- Constants and functors start with a lowercase letter or is single quoted. -->
<xsl:template match="r:Rel | r:Ind">
  <xsl:choose>
    <xsl:when test="matches(text(), '^[a-z][a-z0-9_]*$', 'i')">
      <xsl:value-of select="concat(lower-case(substring(text(), 1, 1)), substring(text(), 2))"/>
    </xsl:when>
    <xsl:otherwise>
      <xsl:if test="not(matches(text(), '^[#x20-#x7E]+$'))">
        <xsl:message terminate="no">
          <xsl:text>The format of functor/constant '</xsl:text>
          <xsl:value-of select="text()"/>
          <xsl:text>' is not valid in the target syntax.</xsl:text>
        </xsl:message>
      </xsl:if>
      <xsl:value-of select='concat(&quot;&apos;&quot;,
        replace(replace(text(), "\", "\\"), "&apos;", "\&apos;"), &quot;&apos;&quot;)'/>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

<!-- Data is warned of and ignored because the target syntax only accepts
     visible characters rathe than "any type". -->
<xsl:template match="r:Data">
    <xsl:message terminate="no">
      <xsl:text>The target syntax only accepts visible characters in functors/constants. </xsl:text>
      <xsl:text>Use tag 'Ind' instead of 'Data'. </xsl:text>
    </xsl:message>
</xsl:template>

<!-- RuleML = act* -->
<xsl:template match="r:RuleML">
  <xsl:apply-templates select="r:act"/>
</xsl:template>

<!-- Retract is ignored. -->
<!-- act = Assert | Query -->
<xsl:template match="r:act">
  <xsl:apply-templates select="r:Assert | r:Query">
    <xsl:with-param name="act-index" select="@index" tunnel="yes"/>
  </xsl:apply-templates>
</xsl:template>

<!-- Assert = formula* -->
<xsl:template match="r:Assert">
  <xsl:apply-templates select="r:formula" mode="top">
    <xsl:with-param name="formula-source" select="lower-case(local-name())"
      as="xs:string"/>
  </xsl:apply-templates>
</xsl:template>

<!-- Query = formula* -->
<xsl:template match="r:Query">
  <xsl:apply-templates select="r:formula" mode="top">
    <xsl:with-param name="formula-source" select="lower-case(local-name())"
      as="xs:string"/>
  </xsl:apply-templates>
</xsl:template>

<!-- formula = Atom | Equal | Implies | Forall | And | Or | Exists -->
<xsl:template match="r:formula" mode="top">
  <xsl:param name="act-index" required="yes" tunnel="yes"/>
  <xsl:param name="formula-source" required="yes" as="xs:string"/>

  <xsl:text>fof(</xsl:text>
  <!-- Formula name. -->
  <xsl:value-of select="concat($formula-source, '_in_act', $act-index, '_formula',
                        count(preceding-sibling::r:formula) + 1)"/>

  <xsl:text>, </xsl:text>
  <!-- Formula role. -->
  <xsl:choose>
    <xsl:when test="$formula-source = 'assert'">
      <xsl:text>axiom</xsl:text>
    </xsl:when>
    <xsl:when test="$formula-source = 'query'">
      <xsl:text>conjecture</xsl:text>
    </xsl:when>
    <xsl:otherwise>
      <xsl:message terminate="yes">Assert: this should never happen.</xsl:message>
    </xsl:otherwise>
  </xsl:choose>

  <xsl:text>, (</xsl:text>
  <xsl:value-of select="$nl"/>
  <!-- Indentation. -->
  <xsl:text>    </xsl:text>

  <xsl:apply-templates/>
  
  <xsl:value-of select="$nl"/>
  <xsl:text>)).</xsl:text>
  <xsl:value-of select="$nl"/>
</xsl:template>

<!-- Atom = op, arg* -->
<xsl:template match="r:Atom">
  <xsl:apply-templates select="r:op"/>
  <xsl:text>(</xsl:text>
  <xsl:for-each select="r:arg">
    <xsl:sort select="@index" order="ascending" data-type="number"/>
    <xsl:if test="preceding-sibling::r:arg">
      <xsl:text>, </xsl:text>
    </xsl:if>
    <xsl:apply-templates/>
  </xsl:for-each>
  <xsl:text>)</xsl:text>
</xsl:template>

<!-- Equal = left, right -->
<xsl:template match="r:Equal">
  <xsl:text>( </xsl:text>
  <xsl:apply-templates select="r:left"/>
  <xsl:text> = </xsl:text>
  <xsl:apply-templates select="r:right"/>
  <xsl:text> )</xsl:text>
</xsl:template>

<!-- Implies = if, then -->
<xsl:template match="r:Implies">
  <xsl:text>( </xsl:text>
  <xsl:apply-templates select="r:if"/>
  <xsl:text> => </xsl:text>
  <xsl:apply-templates select="r:then"/>
  <xsl:text> )</xsl:text>
</xsl:template>

<!-- Forall = declare+, formula -->
<xsl:template match="r:Forall">
  <xsl:text>! [</xsl:text>
  <xsl:call-template name="declare-list"/>
  <xsl:text>] : </xsl:text>
  <xsl:apply-templates select="r:formula"/>
</xsl:template>

<!-- And = formula* -->
<xsl:template match = "r:And">
  <xsl:choose>
    <xsl:when test="r:formula">
      <xsl:text>( </xsl:text>
      <xsl:for-each select="r:formula">
        <xsl:if test="preceding-sibling::r:formula">
          <xsl:text> &amp; </xsl:text>
        </xsl:if>
        <xsl:apply-templates/>
      </xsl:for-each>
      <xsl:text> )</xsl:text>
    </xsl:when>
    <xsl:otherwise>
      <xsl:text>$true</xsl:text>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

<!-- Or = formula* -->
<xsl:template match = "r:Or">
  <xsl:choose>
    <xsl:when test="r:formula">
      <xsl:text>( </xsl:text>
      <xsl:for-each select="r:formula">
        <xsl:if test="preceding-sibling::r:formula">
          <xsl:text> | </xsl:text>
        </xsl:if>
        <xsl:apply-templates/>
      </xsl:for-each>
      <xsl:text> )</xsl:text>
    </xsl:when>
    <xsl:otherwise>
      <xsl:text>$false</xsl:text>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

<!-- Exists = declare+, formula -->
<xsl:template match="r:Exists">
  <xsl:text>? [</xsl:text>
  <xsl:call-template name="declare-list"/>
  <xsl:text>] : </xsl:text>
  <xsl:apply-templates select="r:formula"/>
</xsl:template>

<!-- A comma separated list of declarations. -->
<xsl:template name="declare-list">
  <xsl:for-each select="r:declare">
    <xsl:if test="preceding-sibling::r:declare">
      <xsl:text>, </xsl:text>
    </xsl:if>
    <xsl:apply-templates/>
  </xsl:for-each>
</xsl:template>

</xsl:stylesheet>
