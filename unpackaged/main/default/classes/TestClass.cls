@isTest
public class TestClass {
    // a new comment
    @isTest
    public static void testFoo() {
        System.assert(true);
        /* this used to be false */ System.assert(false);// but may be changed later
    }
}
