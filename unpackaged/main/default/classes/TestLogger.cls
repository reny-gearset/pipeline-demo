@isTest
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
public class TestLogger {
    
    @isTest
    public static void canLogInfoWithoutParams() {
        Logger sut = new Logger(TestLogger.class.getName());
        sut.info('Message');
    }

    @isTest
    public static void canLogInfoWithOneStringParam() {
        Logger sut = new Logger(TestLogger.class.getName());
        sut.info('Message {0}', 'parameter');
    }

    @isTest
    public static void canLogInfoWithTwoStringParams() {
        Logger sut = new Logger(TestLogger.class.getName());
        sut.info('Message {0} {1}', 'parameter 1', 'parameter 2');
    }

    @isTest
    public static void canLogInfoWithThreeStringParams() {
        Logger sut = new Logger(TestLogger.class.getName());
        sut.info('Message {0} {1} {2}', 'parameter 1', 'parameter 2', 'parameter 3');
    }

    @isTest
    public static void canLogInfoWithFourStringParams() {
        Logger sut = new Logger(TestLogger.class.getName());
        sut.info('Message {0} {1} {2} {3}', 'parameter 1', 'parameter 2', 'parameter 3', 'parameter 4');
    }

    @isTest
    public static void canLogInfoWithThreeIntegerParams() {
        Logger sut = new Logger(TestLogger.class.getName());
        sut.info('Message {0} {1} {2}', 1, 2, 3);
    }

    @isTest
    public static void canLogInfoWithAnSObject() {
        Logger sut = new Logger(TestLogger.class.getName());
        sut.info('Message {0}', new Lead(
            Email = 'kevin@gearset.com'
        ));
    }
}
