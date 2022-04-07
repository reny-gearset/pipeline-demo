public with sharing class LogFactory {
    public static Logger create(Type t) {
        return new Logger(t.getName());
    }
}
