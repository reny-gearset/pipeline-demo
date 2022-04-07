// This is used by a rest controller, so need to suppress this warning
@SuppressWarnings('PMD.AvoidGlobalModifier')
global class LeadInfo {
    global String firstName;
    global String lastName;
    global String email;
    global String telephone;
    global String intercomUrl;
    global Boolean isAcceptingTeamInvite;
    global Boolean isNewUser;
    global String teamInviteTargetTeamId;
    global String ppcSource;
}
