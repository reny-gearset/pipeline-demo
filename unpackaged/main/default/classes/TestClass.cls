@isTest
public class TestClass {
    // a new comment
    @isTest
    public static void testFoo() {
        System.assert(false);
        /* this used to be false */ System.assert(true);// but may be changed later
    }
}
