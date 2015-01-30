package org.ruleml.translation.ruleml2tptp;

import static junitx.framework.FileAssert.*;
import static org.junit.Assert.*;

import java.net.URISyntaxException;
import java.nio.charset.StandardCharsets;
import java.io.BufferedReader;
import java.io.File;
import java.io.InputStreamReader;
import java.io.IOException;
import java.io.StringWriter;
import javax.xml.transform.Result;
import javax.xml.transform.Source;
import javax.xml.transform.TransformerException;
import javax.xml.transform.sax.SAXTransformerFactory;
import javax.xml.transform.stream.StreamResult;
import javax.xml.transform.stream.StreamSource;
import org.junit.Test;
import org.junit.BeforeClass;
import org.junit.runners.Parameterized;
import org.junit.runners.Parameterized.Parameters;
import org.junit.runner.RunWith;

/**
 * @author edmonluan@gmail.com (Meng Luan)
 */
@RunWith(Parameterized.class)
public class TranslatorTest
{

    private static Translator translator;

    @BeforeClass
    public static void setUpClass() {
        translator = new Translator((SAXTransformerFactory) (SAXTransformerFactory.newInstance()));
        translator.loadTemplates();
    }

    @Parameters(name="{index}: {0}")
    public static Object[] baseNames() {
        return new Object[] {
            "Atom",
            "Implies",
            "Forall",
            "Exists",
            "Equal",
            "And",
            "Or"
        };
    }

    private String baseName;

    public TranslatorTest(String baseName) {
        this.baseName = baseName;
    }

    @Test
    public void test() throws IOException, TransformerException, URISyntaxException {
        final File input = new File(getClass().getResource("/TranslatorTest/" + baseName + "Test.ruleml").toURI());
        final File result = File.createTempFile("TranslatorTest_" + baseName + "Test_", ".tptp.tmp");
        translator.translate(new StreamSource(input), new StreamResult(result));
        final File expected = new File(getClass().getResource("/TranslatorTest/" + baseName + "Test.tptp").toURI());
        final String resultFilePath = result.getCanonicalPath();
        assertEquals("Result file: " + resultFilePath, expected, result);
        assertTrue("Failed to delete " + resultFilePath, result.delete());
    }

}
