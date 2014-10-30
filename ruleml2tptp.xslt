<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:r="http://ruleml.org/spec">

<xsl:output method="text"/>
<xsl:strip-space elements="*"/>

<xsl:variable name="nl" as="xs:string"><xsl:text>
</xsl:text></xsl:variable>

<xsl:template match="r:*">
  <xsl:apply-templates/>
</xsl:template>

<xsl:template match="*/text()">
  <xsl:value-of select="."/>
</xsl:template>

<!-- RuleML = act* -->

<!-- act = (Assert | Retract | Query)* -->
<xsl:template match="r:act">
  <xsl:apply-templates>
    <xsl:with-param name="act-index" select="@index" tunnel="yes"/>
  </xsl:apply-templates>
</xsl:template>

<!-- formula* -->
<xsl:template match="r:Assert">
  <xsl:apply-templates mode="top"/>
</xsl:template>

<!-- Retract -->
<!-- Query -->

<!-- Atom | Equal | Implies | Forall -->
<xsl:template match="r:formula" mode="top">
  <xsl:param name="act-index" required="yes" tunnel="yes"/>

  <xsl:text>fof(</xsl:text>
  <xsl:value-of select="concat('formula_', $act-index, '_', count(preceding-sibling::*[name() = r:formula]) + 1)"/>
  <xsl:text>, axiom, (</xsl:text>
  <xsl:value-of select="$nl"/>
  <xsl:text>    </xsl:text>

  <xsl:apply-templates/>
  
  <xsl:value-of select="$nl"/>
  <xsl:text>)).</xsl:text>
  <xsl:value-of select="$nl"/>
</xsl:template>

<!-- op, arg* -->
<xsl:template match="r:Atom">
  <xsl:apply-templates select="r:op"/>
  <xsl:text>(</xsl:text>
  <xsl:call-template name="sibling-list">
    <xsl:with-param name="element" select="r:arg"/>
  </xsl:call-template>
  <xsl:text>)</xsl:text>
</xsl:template>

<!-- left, right -->
<xsl:template match="r:Equal">
  <xsl:text>(</xsl:text>
  <xsl:apply-templates select="r:left"/>
  <xsl:text> = </xsl:text>
  <xsl:apply-templates select="r:right"/>
  <xsl:text>)</xsl:text>
</xsl:template>

<!-- if, then -->
<xsl:template match="r:Implies">
  <xsl:text>(</xsl:text>
  <xsl:apply-templates select="r:if"/>
  <xsl:text> => </xsl:text>
  <xsl:apply-templates select="r:then"/>
  <xsl:text>)</xsl:text>
</xsl:template>

<!-- declare+, formula_5 -->
<xsl:template match="r:Forall">
  <xsl:text>! [</xsl:text>

  <xsl:call-template name="sibling-list">
    <xsl:with-param name="element" select="r:declare"/>
  </xsl:call-template>

  <xsl:text>] : </xsl:text>

  <xsl:apply-templates select="r:formula"/>
</xsl:template>

<!-- op = Rel -->
<!-- arg = Ind | Data | Var -->
<!-- left = Ind | Data | Var -->
<!-- right = Ind | Data | Var -->
<!-- if = Atom | Equal | And_2 | Or_2 -->
<!-- then = Atom | Equal | And_3 | Or_3 | Exists_2 -->
<!-- declare = Var -->
<!-- formula_5 = formula { Atom | Equal | Implies | Forall } -->
<!-- Rel = text -->
<!-- Ind = text -->
<!-- Data -->
<!-- Var = text -->

<!-- And_2 = And { formula_3* } -->

<xsl:template match = "r:And">
  <xsl:text>(</xsl:text>
  <xsl:call-template name="sibling-list">
    <xsl:with-param name="element" select="r:*"/>
    <xsl:with-param name="separator" select="' &amp; '"/>
  </xsl:call-template>
  <xsl:text>)</xsl:text>
</xsl:template>

<!-- Or_2 = Or { formula_4* } -->

<xsl:template match = "r:Or">
  <xsl:choose>
    <xsl:when test="*">
      <xsl:text>(</xsl:text>
      <xsl:call-template name="sibling-list">
        <xsl:with-param name="element" select="r:*"/>
        <xsl:with-param name="separator" select="' | '"/>
      </xsl:call-template>
      <xsl:text>)</xsl:text>
    </xsl:when>
    <xsl:otherwise>
      <xsl:text>$false</xsl:text>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

<!-- And_3 = And { formula_7* } -->
<!-- Or_3 = Or {} -->

<!-- Exists_2 = Exists { declare+, formula_8 } -->
<xsl:template match="r:Exists">
  <xsl:text>? [</xsl:text>
  <xsl:call-template name="sibling-list">
    <xsl:with-param name="element" select="r:declare"/>
  </xsl:call-template>
  <xsl:text>] : </xsl:text>
  <xsl:apply-templates select="r:formula"/>
</xsl:template>

<!-- formula_3 = formula { Atom | Equal | And_2 | Or_2 } -->
<!-- formula_4 = formula { Atom | Equal | And_2 | Or_2 } -->
<!-- formula_7 = formula { Atom | And_3 | Or_3 | Exists_2 } -->
<!-- formula_8 = formula { Atom | And_3 | Or_3 | Exists_2 } -->

<xsl:template name="sibling-list">
  <xsl:param name="element" required="yes"/>
  <xsl:param name="separator" select="', '" as="xs:string"/>
  <xsl:for-each select="$element">
    <xsl:if test="not(. is $element[1])">
      <xsl:value-of select="$separator"/>
    </xsl:if>
    <xsl:apply-templates select="."/>
  </xsl:for-each>
</xsl:template>

</xsl:stylesheet>
