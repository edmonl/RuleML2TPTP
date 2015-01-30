package org.ruleml.translation.ruleml2tptp;

import java.nio.charset.StandardCharsets;
import java.io.InputStreamReader;
import javax.xml.transform.Result;
import javax.xml.transform.Source;
import javax.xml.transform.Templates;
import javax.xml.transform.Transformer;
import javax.xml.transform.TransformerConfigurationException;
import javax.xml.transform.TransformerException;
import javax.xml.transform.sax.SAXTransformerFactory;
import javax.xml.transform.sax.SAXResult;
import javax.xml.transform.sax.TransformerHandler;
import javax.xml.transform.stream.StreamSource;

/**
 * @author edmonluan@gmail.com (Meng Luan)
 */
public class Translator {

    private static final String XSLT_NORMALIZER_RES_PATH = "/xslt/101_nafneghornlogeq_normalizer.xslt";
    private static final String XSLT_TRANSLATOR_RES_PATH = "/xslt/ruleml2tptp.xslt";
    private static final String NEWLINE = String.format("%n");

    private SAXTransformerFactory transFactory;
    private Templates normalizerTemplates;
    private Templates translatorTemplates;

    public Translator(SAXTransformerFactory transFactory) {
        if (transFactory == null) {
            throw new IllegalArgumentException();
        }
        this.transFactory = transFactory;
    }

    public synchronized void loadTemplates() {
        try {
            if (normalizerTemplates == null) {
                normalizerTemplates = transFactory.newTemplates(new StreamSource(
                            getClass().getResourceAsStream(XSLT_NORMALIZER_RES_PATH)));
            }
            if (translatorTemplates == null) {
                translatorTemplates = transFactory.newTemplates(new StreamSource(
                            getClass().getResourceAsStream(XSLT_TRANSLATOR_RES_PATH)));
            }
        } catch (TransformerConfigurationException ex) {
            throw new IllegalStateException(ex);
        }
    }

    public void translate(Source src, Result result) throws TransformerException {
        if (src == null || result == null) {
            throw new IllegalArgumentException();
        }
        loadTemplates();
        Transformer transPerformer;
        try {
            transPerformer = normalizerTemplates.newTransformer();
            final TransformerHandler transHandler =
                transFactory.newTransformerHandler(translatorTemplates);
            transHandler.getTransformer().setParameter("nl", NEWLINE);
            transHandler.setResult(result);
            result = new SAXResult(transHandler);
        } catch (TransformerConfigurationException ex) {
            throw new IllegalStateException(ex);
        }
        transPerformer.transform(src, result);
    }

}
