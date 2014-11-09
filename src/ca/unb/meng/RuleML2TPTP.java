package ca.unb.meng;

import org.apache.commons.cli.BasicParser;
import org.apache.commons.cli.CommandLine;
import org.apache.commons.cli.CommandLineParser;
import org.apache.commons.cli.HelpFormatter;
import org.apache.commons.cli.Option;
import org.apache.commons.cli.OptionBuilder;
import org.apache.commons.cli.OptionGroup;
import org.apache.commons.cli.Options;
import org.apache.commons.cli.ParseException;

import java.io.Closeable;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.IOException;
import java.io.OutputStream;
import java.io.OutputStreamWriter;
import java.io.Reader;
import java.io.StringReader;
import java.io.StringWriter;
import java.io.Writer;
import java.util.Properties;

import javax.xml.transform.Result;
import javax.xml.transform.Source;
import javax.xml.transform.Templates;
import javax.xml.transform.Transformer;
import javax.xml.transform.TransformerConfigurationException;
import javax.xml.transform.TransformerException;
import javax.xml.transform.TransformerFactory;
import javax.xml.transform.TransformerFactoryConfigurationError;
import javax.xml.transform.sax.SAXResult;
import javax.xml.transform.sax.SAXTransformerFactory;
import javax.xml.transform.sax.TransformerHandler;
import javax.xml.transform.stream.StreamSource;
import javax.xml.transform.stream.StreamResult;

public class RuleML2TPTP {
    private static final String propertiesPath = "/resources/properties";
    private static final String xsltNormalizerPathKey = "xslt.normalizer";
    private static final String xsltTranslatorPathKey = "xslt.translator";
    private static final String xsltProperties = String.format(
          "<?xml version='1.0'?><xsl:stylesheet version='1.0' "
        + "xmlns:xsl='http://www.w3.org/1999/XSL/Transform'>"
        + "<xsl:output method='text'/>"
        + "<xsl:template match='/'>"
        + "<xsl:text>XSLT PROPERTIES%nxsl:version = </xsl:text>"
        + "<xsl:value-of select=\"system-property('xsl:version')\"/>"
        + "<xsl:text>%nxsl:vendor = </xsl:text>"
        + "<xsl:value-of select=\"system-property('xsl:vendor')\"/>"
        + "<xsl:text>%nxsl:vendor-url = </xsl:text>"
        + "<xsl:value-of select=\"system-property('xsl:vendor-url')\"/>"
        + "</xsl:template></xsl:stylesheet>");

    private static final int EC_OPTION = 1;
    private static final int EC_SOURCE = 2;
    private static final int EC_OUTPUT = 3;
    private static final int EC_NORMALIZER = 4;
    private static final int EC_TRANSLATOR = 5;
    private static final int EC_TRANSFORM = 10;
    private static final int EC_FATAL = 127;

    private static SAXTransformerFactory tFactory = null;

    public static void main(String[] args) {
        Options options = buildOptions();
        CommandLine cmd = null;
        try {
            cmd = new BasicParser().parse(options, args);
        } catch (ParseException ex) {
            System.err.println(ex.getMessage());
            System.err.println("Try '-h' for usage.");
            System.exit(EC_OPTION);
        }
        String factoryClassName = cmd.getOptionValue('t');
        try {
            if (factoryClassName == null) {
                tFactory = (SAXTransformerFactory)(SAXTransformerFactory
                        .newInstance());
            } else {
                tFactory = (SAXTransformerFactory)(TransformerFactory
                        .newInstance(factoryClassName,
                            RuleML2TPTP.class.getClassLoader()));
            }
        } catch (TransformerFactoryConfigurationError err) {
            System.err.println("Fatal error: "
                    + "failed to create the XML transformer factory.");
            String msg = err.getMessage();
            if (msg != null) {
                System.err.println(msg);
            }
            Exception ex = err.getException();
            if (ex != null && ex.getMessage() != null) {
                System.err.println(ex.getMessage());
            }
            System.exit(EC_FATAL);
        }
        if (cmd.hasOption('h')) {
            printUsage(options);
            return;
        }
        RuleML2TPTP prog = new RuleML2TPTP();
        try {
            prog.run(cmd);
        } catch (TransformerException ex) {
            String msg = ex.getMessageAndLocation();
            if (msg != null) {
                System.err.println(msg);
            }
        } catch (RuntimeException ex) {
            throw ex;
        } catch (Exception ex) {
            String msg = ex.getMessage();
            if (msg != null) {
                System.err.println(msg);
            }
        } finally {
            prog.closeAll();
        }
        System.exit(prog.getErrorCode());
    }

    private static Options buildOptions() {
        Options options = new Options();
        options.addOption("h", "help", false, "print usage");
        options.addOptionGroup(new OptionGroup()
                .addOption(new Option("nn", "no-normalization",
                        false, "take source as normalized"))
                .addOption(new Option("nt", "no-translation", false,
                        "only normalize source and output")));
        options.addOption(OptionBuilder
                .hasArg()
                .withArgName("class")
                .withDescription("use given factory class")
                .withLongOpt("transformer-factory")
                .create('t'));
        options.addOption(OptionBuilder
                .hasOptionalArg()
                .withArgName("pattern")
                .withDescription("keep comments matching given pattern "
                   + "or any pattern if pattern is omitted or empty")
                .withLongOpt("keep-comments")
                .create('c'));
        options.addOption(OptionBuilder
                .hasArg()
                .withArgName("flags")
                .withDescription("flags following the specification of XPath "
                    + "except for flag v (see NOTES below)")
                .withLongOpt("matching-flags")
                .create('g'));
        options.addOption(OptionBuilder
                .hasArg()
                .withArgName("file")
                .withDescription("use given source file")
                .create('s'));
        options.addOption(OptionBuilder
                .hasArg()
                .withArgName("file")
                .withDescription("use given output file")
                .create('o'));
        return options;
    }

    private static void printUsage(Options options) {
        new HelpFormatter().printHelp("java -jar ruleml2tptp.jar",
                 null, options, String.format("%nNOTES%n"
                    + "If '-s' or '-o' is omitted, the standard input or "
                    + "output will be used accordingly.%n"
                    + "If '-h' is used, "
                    + "no XML transformation will be performed.%n"
                    + "Flag v means the matching behavior is reverted, "
                    + "so comments DO NOT match the given pattern are kept. "
                    ),
                true);
        System.out.println();
        StringWriter noteWriter = new StringWriter();
        try {
            tFactory.newTransformer(
                    new StreamSource(new StringReader(xsltProperties)))
                .transform(new StreamSource(new StringReader(xsltProperties)),
                    new StreamResult(noteWriter));
        } catch (TransformerException ex) {
            System.err.println("Error: failed to get XSLT properties.");
            String msg = ex.getMessageAndLocation();
            if (msg != null) {
                System.err.println(msg);
            }
        }
        String note = noteWriter.toString();
        System.out.println(note);
    }

    private InputStream xsltNormalizer = null;
    private InputStream xsltTranslator = null;
    private Reader sr = null;
    private Writer ow = null;
    private int ec = 0;
    private Properties properties = null;

    public int getErrorCode() {
        return ec;
    }

    public void closeAll() {
        close(xsltNormalizer);
        close(xsltTranslator);
        close(sr);
        close(ow);
    }

    public void run(CommandLine cmd) throws FileNotFoundException, IOException,
           TransformerException, TransformerConfigurationException {
        loadXslt(!cmd.hasOption("nn"), !cmd.hasOption("nt"));
        sr = getSourceReader(cmd.getOptionValue('s'));
        ow = getOutputWriter(cmd.getOptionValue('o'));
        Source source = new StreamSource(sr);
        Result result = new StreamResult(ow);
        try {
            if (xsltTranslator == null) {
                assert xsltNormalizer != null;
                tFactory.newTransformer(new StreamSource(new BufferedReader(
                                new InputStreamReader(xsltNormalizer))))
                    .transform(source, result);
            } else {
                String commentPattern = cmd.getOptionValue('c');
                String matchingFlags = cmd.getOptionValue('g');
                if (matchingFlags == null) {
                    matchingFlags = "";
                }
                boolean keepComments = cmd.hasOption('c')
                    && (matchingFlags.indexOf('v') == -1);
                matchingFlags = matchingFlags.replaceAll("v", "");
                if (xsltNormalizer == null) {
                    Transformer translator = tFactory.newTransformer(
                            new StreamSource(new BufferedReader(
                                    new InputStreamReader(xsltTranslator))));
                    if (commentPattern != null && !commentPattern.isEmpty()) {
                        translator.setParameter(
                                "match-comments", commentPattern);
                    }
                    if (!matchingFlags.isEmpty()) {
                        translator.setParameter(
                                "matching-flags", matchingFlags);
                    }
                    translator.setParameter("keep-comments", keepComments);
                    translator.transform(source, result);
                } else {
                    TransformerHandler th = tFactory.newTransformerHandler(
                            tFactory.newTemplates(new StreamSource(
                                    new BufferedReader(new InputStreamReader(
                                            xsltTranslator)))));
                    th.setResult(result);
                    Transformer translator = th.getTransformer();
                    if (commentPattern != null && !commentPattern.isEmpty()) {
                        translator.setParameter(
                                "match-comments", commentPattern);
                    }
                    if (!matchingFlags.isEmpty()) {
                        translator.setParameter(
                                "matching-flags", matchingFlags);
                    }
                    translator.setParameter("keep-comments", keepComments);
                    tFactory.newTransformer(new StreamSource(new BufferedReader(
                                    new InputStreamReader(xsltNormalizer))))
                        .transform(source, new SAXResult(th));
                }
            }
        } catch (TransformerConfigurationException ex) {
            ec = EC_FATAL;
            throw ex;
        } catch (TransformerException ex) {
            ec = EC_TRANSFORM;
            throw ex;
        }
    }

    private void loadXslt(boolean doNormalization,
            boolean doTranslation) throws FileNotFoundException,
            IOException, TransformerConfigurationException {
        assert doNormalization || doTranslation;
        if (doNormalization) {
            try {
                xsltNormalizer = loadXslt(xsltNormalizerPathKey);
            } catch (FileNotFoundException ex) {
                ec = EC_NORMALIZER;
                throw ex;
            }
        }
        if (doTranslation) {
            try {
                xsltTranslator = loadXslt(xsltTranslatorPathKey);
            } catch (FileNotFoundException ex) {
                ec = EC_TRANSLATOR;
                throw ex;
            }
        }
    }

    private InputStream loadXslt(String key) throws FileNotFoundException,
            IOException, TransformerConfigurationException {
        InputStream result = null;
        String path = System.getProperty(key);
        if (path != null) {
            try {
                result = new FileInputStream(path);
            } catch (FileNotFoundException ex) {
                System.err.println("Failed to read " + key + ": " + path);
                ec = EC_FATAL;
                throw ex;
            }
        }
        if (result == null) {
            loadProperties();
            path = properties.getProperty(key);
            if (path != null) {
                result = getClass().getResourceAsStream(path);
            }
            if (result == null) {
                System.err.println("Fatal error: failed to find " + key + ".");
                ec = EC_FATAL;
                throw new TransformerConfigurationException();
            }
        }
        return result;
    }

    private void loadProperties() throws IOException,
            TransformerConfigurationException {
        if (properties != null) {
            return;
        }
        properties = new Properties();
        InputStream res = getClass().getResourceAsStream(propertiesPath);
        if (res == null) {
            System.err.println(
                    "Fatal error: failed to load application properties.");
            ec = EC_FATAL;
            throw new TransformerConfigurationException();
        }
        try (Reader pr = new BufferedReader(new InputStreamReader(res))) {
            properties.load(pr);
        } catch (IOException ex) {
            System.err.println(
                    "Fatal error: failed to load application properties.");
            ec = EC_FATAL;
            throw ex;
        }
    }

    private Reader getSourceReader(
            String filename) throws FileNotFoundException {
        InputStream in = null;
        if (filename == null) {
            in = System.in;
        } else {
            try {
                in = new FileInputStream(filename);
            } catch (FileNotFoundException ex) {
                System.err.println("Failed to read the source file: "
                        + filename);
                ec = EC_SOURCE;
                throw ex;
            }
        }
        return new BufferedReader(new InputStreamReader(in));
    }

    private Writer getOutputWriter(
            String filename) throws FileNotFoundException {
        OutputStream out = null;
        if (filename == null) {
            out = System.out;
        } else {
            try {
                out = new FileOutputStream(filename);
            } catch (FileNotFoundException ex) {
                System.err.println("Failed to write the output file: "
                        + filename);
                ec = EC_OUTPUT;
                throw ex;
            }
        }
        return new BufferedWriter(new OutputStreamWriter(out));
    }

    private void close(Closeable c) {
        if (c == null) {
            return;
        }
        try {
            c.close();
        } catch (IOException ex) {
            System.err.println(ex.getMessage());
        }
    }
}
