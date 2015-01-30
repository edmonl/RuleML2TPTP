<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet version="2.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:r="http://ruleml.org/spec">
<xsl:output method="text"/>
<xsl:strip-space elements="*"/>

<!-- line break -->
<xsl:param name="nl" select="'&#xA;'" as="xs:string" required="no"/>

<xsl:template match="comment()" mode="#all">
  <!-- trim lines -->
  <xsl:variable name="step1"
    select="replace(., '(^[ \t]+)|([ \t]+$)', '', 'm')"/>
  <!-- trim first and last lines if they are blank -->
  <xsl:variable name="step2"
    select="replace($step1, '(^\r*\n)|(\r*\n$)', '')"/>
  <!-- insert '% ' -->
  <xsl:variable name="final"
    select="replace($step2, '^([^%])', '% $1', 'm')"/>
  <!-- switch to a new line after the comment -->
  <xsl:value-of select="$nl"/>
  <xsl:value-of select="$final"/>
  <xsl:value-of select="$nl"/>
</xsl:template>

<!-- break the line with indentation -->
<xsl:template name="break-line">
  <xsl:param name="depth" required="yes" as="xs:integer"/>
  <!-- somtime we need to go backwards some spaces from the indention -->
  <xsl:param name="retreat" select="0" required="no" as="xs:integer"/>

  <xsl:variable name="indent" as="xs:string *">
    <xsl:text>  </xsl:text> <!-- two leading spaces -->
    <xsl:for-each select="1 to $depth">
      <xsl:text>  </xsl:text> <!-- two spaces for every depth -->
    </xsl:for-each>
  </xsl:variable>
  <xsl:value-of select="$nl"/>
  <xsl:value-of select="substring(string-join($indent, ''), $retreat + 1)"/>

</xsl:template>

<xsl:template match="r:*">
  <xsl:apply-templates/>
</xsl:template>

<xsl:template match="/">
  <xsl:apply-templates select="r:RuleML | comment()"/>
</xsl:template>

<xsl:template match="r:RuleML">
  <xsl:apply-templates select="r:act | comment()"/>
</xsl:template>

<xsl:template match="r:act">
  <xsl:apply-templates select="r:Assert | r:Query | comment()">
    <xsl:with-param name="act-index" select="@index" tunnel="yes"/>
  </xsl:apply-templates>
</xsl:template>

<xsl:template match="r:Assert">
  <xsl:apply-templates select="r:formula | comment()" mode="fof-formula">
    <xsl:with-param name="formula-type" select="local-name()"/>
  </xsl:apply-templates>
</xsl:template>

<xsl:template match="r:Query">
  <xsl:apply-templates select="r:formula | comment()" mode="fof-formula">
    <xsl:with-param name="formula-type" select="local-name()"/>
  </xsl:apply-templates>
</xsl:template>

<xsl:template match="r:formula" mode="fof-formula">
  <xsl:param name="act-index" required="yes" tunnel="yes" as="xs:integer"/>
  <xsl:param name="formula-type" required="yes" as="xs:string"/>
  <xsl:variable name="depth" select="1" as="xs:integer"/>

  <xsl:apply-templates select="comment()"/>

  <xsl:text>fof(</xsl:text>
  <!-- formula name -->
  <xsl:value-of select="concat('act', $act-index, '_formula', count(preceding-sibling::r:formula) + 1)"/>

  <xsl:text>,</xsl:text>
  <!-- formula role -->
  <xsl:choose>
    <xsl:when test="$formula-type = 'Assert'">
      <xsl:text>axiom</xsl:text>
    </xsl:when>
    <xsl:when test="$formula-type = 'Query'">
      <xsl:text>conjecture</xsl:text>
    </xsl:when>
  </xsl:choose>
  <xsl:text>,</xsl:text>

  <xsl:variable name="content-sequence" as="xs:string*">
    <xsl:apply-templates>
      <xsl:with-param name="depth" select="$depth" tunnel="yes"/>
      <!-- this param indicates if the children can break the line at the very
          beginning -->
      <xsl:with-param name="line-breaking" select="false()" tunnel="yes"/>
    </xsl:apply-templates>
  </xsl:variable>
  <xsl:variable name="content" select="string-join($content-sequence, '')" as="xs:string"/>
  <xsl:variable name="need-extra-parens" select="not(starts-with($content, '( '))" as="xs:boolean"/>

  <xsl:if test="$need-extra-parens">
    <xsl:text>(</xsl:text>
  </xsl:if>
  <xsl:call-template name="break-line">
    <xsl:with-param name="depth" select="$depth"/>
  </xsl:call-template>
  <xsl:value-of select="$content"/>
  <xsl:value-of select="$nl"/>
  <xsl:if test="$need-extra-parens">
    <xsl:text>)</xsl:text>
  </xsl:if>
  <xsl:text>).</xsl:text>
  <xsl:value-of select="$nl"/>
</xsl:template>

<xsl:template match="r:Forall">
  <xsl:call-template name="quantified">
    <xsl:with-param name="quantifier" select="'!'"/>
  </xsl:call-template>
</xsl:template>

<xsl:template match="r:Exists">
  <xsl:call-template name="quantified">
    <xsl:with-param name="quantifier" select="'?'"/>
  </xsl:call-template>
</xsl:template>

<xsl:template name="quantified">
  <xsl:param name="depth" required="yes" as="xs:integer" tunnel="yes"/>
  <xsl:param name="line-breaking" required="yes" as="xs:boolean" tunnel="yes"/>
  <xsl:param name="quantifier" required="yes" as="xs:string"/>
  <xsl:param name="last-quantifier-depth" select="-1" required="no" as="xs:integer" tunnel="yes"/>

  <xsl:variable name="final-depth" as="xs:integer">
    <xsl:choose>
      <xsl:when test="$depth = $last-quantifier-depth + 1">
        <xsl:value-of select="$last-quantifier-depth"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$depth"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <xsl:if test="$line-breaking">
    <xsl:call-template name="break-line">
      <xsl:with-param name="depth" select="$final-depth"/>
    </xsl:call-template>
  </xsl:if>
  <xsl:value-of select="$quantifier"/>
  <xsl:text> [</xsl:text>
  <xsl:call-template name="declare-list"/>
  <xsl:text>] :</xsl:text>

  <xsl:variable name="content-sequence" as="xs:string*">
    <xsl:apply-templates select="r:formula">
      <xsl:with-param name="depth" select="$final-depth + 1" tunnel="yes"/>
      <xsl:with-param name="line-breaking" select="true()" tunnel="yes"/>
      <xsl:with-param name="last-quantifier-depth" select="$final-depth" tunnel="yes"/>
    </xsl:apply-templates>
  </xsl:variable>
  <xsl:variable name="content" select="string-join($content-sequence, '')" as="xs:string"/>
  <xsl:if test="not(starts-with($content, $nl))">
    <xsl:text> </xsl:text>
  </xsl:if>
  <xsl:value-of select="$content"/>

</xsl:template>

<xsl:template match="r:Implies">
  <xsl:param name="depth" required="yes" as="xs:integer" tunnel="yes"/>
  <xsl:param name="line-breaking" required="yes" as="xs:boolean" tunnel="yes"/>

  <xsl:if test="$line-breaking">
    <xsl:call-template name="break-line">
      <xsl:with-param name="depth" select="$depth"/>
    </xsl:call-template>
  </xsl:if>
  <xsl:text>( </xsl:text>

  <xsl:apply-templates select="r:if">
    <xsl:with-param name="depth" select="$depth + 1" tunnel="yes"/>
    <xsl:with-param name="line-breaking" select="false()" tunnel="yes"/>
  </xsl:apply-templates>

  <xsl:call-template name="break-line">
    <xsl:with-param name="depth" select="$depth"/>
    <xsl:with-param name="retreat" select="1"/>
  </xsl:call-template>
  <xsl:text>=> </xsl:text>

  <xsl:apply-templates select="r:then">
    <xsl:with-param name="depth" select="$depth + 1" tunnel="yes"/>
    <xsl:with-param name="line-breaking" select="false()" tunnel="yes"/>
  </xsl:apply-templates>

  <xsl:text> )</xsl:text>

</xsl:template>

<xsl:template match="r:Equal">
  <xsl:apply-templates select="r:left"/>
  <xsl:text> = </xsl:text>
  <xsl:apply-templates select="r:right"/>
</xsl:template>

<xsl:template match="r:And">
  <xsl:call-template name="associated">
    <xsl:with-param name="connective" select="'&amp;'"/>
    <xsl:with-param name="empty-form" select="'$true'"/>
  </xsl:call-template>
</xsl:template>

<xsl:template match="r:Or">
  <xsl:call-template name="associated">
    <xsl:with-param name="connective" select="'|'"/>
    <xsl:with-param name="empty-form" select="'$false'"/>
  </xsl:call-template>
</xsl:template>

<xsl:template name="associated">
  <xsl:param name="depth" required="yes" as="xs:integer" tunnel="yes"/>
  <xsl:param name="line-breaking" required="yes" as="xs:boolean" tunnel="yes"/>
  <xsl:param name="connective" required="yes" as="xs:string"/>
  <xsl:param name="empty-form" required="yes" as="xs:string"/>

  <xsl:choose>
    <xsl:when test="r:formula[2]">
      <xsl:if test="$line-breaking">
        <xsl:call-template name="break-line">
          <xsl:with-param name="depth" select="$depth"/>
        </xsl:call-template>
      </xsl:if>
      <xsl:text>( </xsl:text>
      <xsl:for-each select="r:formula">
        <xsl:if test="preceding-sibling::r:formula">
          <xsl:call-template name="break-line">
            <xsl:with-param name="depth" select="$depth"/>
          </xsl:call-template>
          <xsl:value-of select="$connective"/>
          <xsl:text> </xsl:text>
        </xsl:if>
        <xsl:apply-templates>
          <xsl:with-param name="depth" select="$depth + 1" tunnel="yes"/>
          <xsl:with-param name="line-breaking" select="false()" tunnel="yes"/>
        </xsl:apply-templates>
      </xsl:for-each>
      <xsl:text> )</xsl:text>
    </xsl:when>
    <xsl:when test="r:formula">
      <xsl:apply-templates>
        <xsl:with-param name="depth" select="$depth + 1" tunnel="yes"/>
        <xsl:with-param name="line-breaking" select="false()" tunnel="yes"/>
      </xsl:apply-templates>
    </xsl:when>
    <xsl:otherwise>
      <xsl:value-of select="$empty-form"/>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

<xsl:template match="r:Atom">
  <xsl:apply-templates select="r:op"/>
  <!-- sorted args -->
  <xsl:for-each select="r:arg">
    <xsl:choose>
      <xsl:when test="preceding-sibling::r:arg">
        <xsl:text>,</xsl:text>
      </xsl:when>
      <xsl:otherwise>
        <xsl:text>(</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
    <xsl:apply-templates select="r:Ind | r:Var"/>
    <xsl:if test="not(following-sibling::r:arg)">
      <xsl:text>)</xsl:text>
    </xsl:if>
  </xsl:for-each>
</xsl:template>

<!-- variables in the TPTP language start with a uppercase letter -->
<xsl:template match="r:Var">
  <xsl:if test="not(matches(text(), '^[a-z][a-z0-9_]*$', 'i'))">
    <xsl:message terminate="no">
      <xsl:text>Variable '</xsl:text>
      <xsl:value-of select="text()"/>
      <xsl:text>' cannot be converted into the valid format.</xsl:text>
    </xsl:message>
  </xsl:if>
  <xsl:value-of select="concat(upper-case(substring(text(), 1, 1)), substring(text(), 2))"/>
</xsl:template>

<!-- constants and functors in the TPTP language start with a lowercase letter or is single-quoted -->
<xsl:template match="r:Rel | r:Ind">
  <xsl:choose>
    <xsl:when test="matches(text(), '^[a-z][a-z0-9_]*$', 'i')">
      <xsl:value-of select="concat(lower-case(substring(text(), 1, 1)), substring(text(), 2))"/>
    </xsl:when>
    <xsl:otherwise>
      <xsl:if test="not(matches(text(), '^[&#x20;-&#x7E;]+$'))">
        <xsl:message terminate="no">
          <xsl:text>Relator/constant '</xsl:text>
          <xsl:value-of select="text()"/>
          <xsl:text>' cannot be converted into the valid format.</xsl:text>
        </xsl:message>
      </xsl:if>
      <!-- escape \ and ' then single quote -->
      <xsl:value-of select='concat("&apos;",
        replace(replace(text(), "\\", "\\\\"), "&apos;", "\\&apos;"), "&apos;")'/>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

<!-- a comma-separated list of declarations -->
<xsl:template name="declare-list">
  <xsl:for-each select="r:declare">
    <xsl:if test="preceding-sibling::r:declare">
      <xsl:text>,</xsl:text>
    </xsl:if>
    <xsl:apply-templates select="r:Var"/>
  </xsl:for-each>
</xsl:template>

</xsl:stylesheet>
