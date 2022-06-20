@SuppressWarnings('PMD.ExcessiveParameterList')
public with sharing class Logger {
    private final string context;

    public Logger(final string context) {
        this.context = context;
    }

    public void info(string message) {
        emit(message, 'info', null, null, null, null);
    }

    public void info(string message, Object param) {
        emit(message, 'info', param, null, null, null);
    }

    public void info(string message, Object param1, Object param2) {
        emit(message, 'info', param1, param2, null, null);
    }

    public void info(string message, Object param1, Object param2, Object param3) {
        emit(message, 'info', param1, param2, param3, null);
    }

    public void info(string message, Object param1, Object param2, Object param3, Object param4) {
        emit(message, 'info', param1, param2, param3, param4);
    }

    public void emit(String message, String level, Object param1, Object param2, Object param3, Object param4) {
        String currentUserEmail = UserInfo.getUserEmail();

        this.emitToEventBus(currentUserEmail, message, level, param1, param2, param3, param4);

        this.emitToSystemDebug(currentUserEmail, message, level, param1, param2, param3, param4);
    }

    public void emitToEventBus(String currentUserEmail, String message, String level, Object param1, Object param2, Object param3, Object param4) {
        LogEvent__e evt = new LogEvent__e();
        evt.Context__c = this.context;
        evt.Level__c = level;
        evt.User_email__c = currentUserEmail;
        evt.Log_Message_Parameter_1__c = '' + param1;
        evt.Log_Message_Parameter_2__c = '' + param2;
        evt.Log_Message_Parameter_3__c = '' + param3;
        evt.Log_Message_Parameter_4__c = '' + param4;
        evt.MessageFormat__c = message;
        evt.Timestamp__c = getTimestamp();

        EventBus.publish(evt);
    }

    public void emitToSystemDebug(String currentUserEmail, String message, String level, Object param1, Object param2, Object param3, Object param4) {
        List<Object> params = new List<Object>();
        params.add(param1);
        params.add(param2);
        params.add(param3);
        params.add(param4);

        final String messageWithParms = String.format(message, params);

        final String logMessage = getTimestamp() + ' : ' + this.context + ' : ' + level + ' : ' + currentUserEmail + ' : ' + messageWithParms;

        System.debug(logMessage);
    }

    public string getTimestamp() {
        return System.now().formatGmt('HH:mm:ss.SSS');
    }
}
