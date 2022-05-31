public without sharing class SignupObjectImpact {
    public Id objectId { public get; private set; }
    public Id ownerId { public get; private set; }
    public SignupObjectImpactStatus objectImpact { public get; private set; }

    public SignupObjectImpact(Id objectId, Id ownerId, SignupObjectImpactStatus objectImpact) {
        this.objectId = objectId;
        this.ownerId = ownerId;
        this.objectImpact = objectImpact;
    }

    public static List<SignupObjectImpact> asList(Id objectId, Id ownerId, SignupObjectImpactStatus objectImpact) {
        List<SignupObjectImpact> result = new List<SignupObjectImpact>();

        result.add(new SignupObjectImpact(
            objectId,
            ownerId,
            objectImpact
        ));

        return result;
    }
}
