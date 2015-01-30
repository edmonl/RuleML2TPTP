package org.ruleml.translation.ruleml2tptp;

import org.kohsuke.args4j.Argument;
import org.kohsuke.args4j.CmdLineException;
import org.kohsuke.args4j.CmdLineParser;
import org.kohsuke.args4j.Option;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.StringReader;
import java.io.StringWriter;
import java.util.List;
import javax.xml.transform.TransformerException;
import javax.xml.transform.TransformerFactoryConfigurationError;
import javax.xml.transform.sax.SAXTransformerFactory;
import javax.xml.transform.stream.StreamSource;
import javax.xml.transform.stream.StreamResult;

/**
 * @author edmonluan@gmail.com (Meng Luan)
 */
public class Main {

    private static final String dummyXML = "<?xml version='1.0'?><blank/>";
    private static final String xsltProperties = String.format(
          "<?xml version='1.0'?>"
        + "<xsl:stylesheet version='1.0' xmlns:xsl='http://www.w3.org/1999/XSL/Transform'>"
        + "  <xsl:output method='text'/>"
        + "  <xsl:template match='/'>"
        + "    <xsl:text> xsl:version = </xsl:text>"
        + "    <xsl:value-of select=\"system-property('xsl:version')\"/>"
        + "    <xsl:text>%n xsl:vendor = </xsl:text>"
        + "    <xsl:value-of select=\"system-property('xsl:vendor')\"/>"
        + "    <xsl:text>%n xsl:vendor-url = </xsl:text>"
        + "    <xsl:value-of select=\"system-property('xsl:vendor-url')\"/>"
        + "  </xsl:template>"
        + "</xsl:stylesheet>");

    @Option(name="-h",aliases={"-?","-help"},help=true,usage="print this message")
    private boolean help;

    @Option(name="-o",aliases={"-output"},metaVar="<path>",usage="use given output path (the standard output or the current working directory by default)")
    private File output;

    @Option(name="-f",aliases={"-transformer-factory"},metaVar="<class>",usage="use given factory class")
    private String transFactoryClass;

    @Option(name="-r",aliases={"-recursive"},usage="traverse the directory tree for input files")
    private boolean recursive;

    @Argument
    private List<String> input;

    private static final int EC_GENERAL = 1;
    private static final int EC_TRANSFORM = 2;

    public static void main(String args[]) {
        final Main appMain = new Main();
        CmdLineParser parser = new CmdLineParser(appMain);
        try {
            parser.parseArgument(args);
        } catch (CmdLineException ex) {
            System.err.println(ex.getLocalizedMessage() + ".");
            System.err.println("Try option \"-h\" for usage.");
            System.err.println();
            System.exit(EC_GENERAL);
        }
        SAXTransformerFactory transFactory;
        try {
            if (appMain.transFactoryClass == null) {
                transFactory = (SAXTransformerFactory) (SAXTransformerFactory.newInstance());
            } else {
                transFactory = (SAXTransformerFactory) (SAXTransformerFactory.newInstance(
                            appMain.transFactoryClass, Main.class.getClassLoader()));
            }
        } catch (TransformerFactoryConfigurationError err) {
            throw new IllegalStateException(err);
        }
        if (appMain.help) {
            System.out.println("Usage: [options] <input-file> ...");
            System.out.println("Options:");
            parser.printUsage(System.out);
            StringWriter noteWriter = new StringWriter();
            try {
                transFactory.newTransformer(new StreamSource(new StringReader(xsltProperties)))
                    .transform(new StreamSource(new StringReader(dummyXML)), new StreamResult(noteWriter));
            } catch (TransformerException ex) {
                throw new IllegalStateException(ex);
            }
            System.out.println("XSLT Properties:");
            System.out.println(noteWriter.toString());
            System.out.println();
            return;
        }
        appMain.run(transFactory);
    }

    private void run(SAXTransformerFactory transFactory) {
        final Translator translator = new Translator(transFactory);
        translator.loadTemplates();
        try {
            translator.translate(new StreamSource(new FileInputStream(input.get(0))),
                    new StreamResult(output));
        } catch (TransformerException ex) {
            System.err.println(ex.getMessageAndLocation());
            System.err.println();
            System.exit(EC_TRANSFORM);
        } catch (FileNotFoundException ex) {
            System.err.println(ex.getLocalizedMessage());
            System.err.println();
            System.exit(EC_TRANSFORM);
        }
    }

}
