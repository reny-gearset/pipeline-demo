trigger AccountTrigger on Account (before insert, before update) {
    AccountValidateGearsetTeam.validateGearsetTeam(Trigger.new);
}