export interface PersonLike {
    readonly FirstName: string | undefined;
    readonly LastName: string | undefined;
    readonly Email: string | undefined;
    readonly Phone: string | undefined;
    readonly IntercomUrl: string | undefined;
}

export function sanitisePerson(person: PersonLike): PersonLike {
    let email = person.Email?.split(/[,\n]/)[0].trim();
    const phone = person.Phone?.split(/[,\n]/)[0].trim();
    const intercomUrl = person.IntercomUrl?.split(/[,\n]/)[0].trim();

    // seems there are a lot of random whitespace in a few records, easy fix
    let firstName = person.FirstName?.split('\n')[0].trim();
    let lastName = person.LastName?.split('\n')[0].trim();

    // salesforce requires a last name
    if (!lastName) {
        // seems like some people have first name and last name in the first name field
        if (firstName?.includes(' ')) {
            const splitNames = firstName.split(' ');
            if (splitNames.length > 2) {
                console.log('Person has no first / last name, so shoving what we have into the last name');
                lastName = firstName;
                firstName = undefined;
            } else {
                console.log(`Splitting first and last name of ${person.FirstName}`);
                firstName = splitNames[0];
                lastName = splitNames[1];
            }
        } else {
            // no hope for this contact, but I think we'd rather keep it, so put the full name into the last name field
            lastName = firstName;
            firstName = undefined;
        }
    }

    // salesforce requires valid-ish email addresses
    const emailRegex = /[^@:]+@[-a-zA-Z0-9_]+\.[-a-zA-Z0-9_\.]+/;
    email = email?.match(emailRegex)?.[0];
    if (!email || !email.match(emailRegex)) {
        if (lastName?.match(emailRegex)) {
            console.log('First name is an email somehow, so using that instead');
            email = lastName.match(emailRegex)?.[0]!;
        } else {
            console.log(`Person ${person.FirstName} ${person.LastName} has an invalid email ${email}.`);
        }
    }

    return {
        FirstName: firstName,
        LastName: lastName,
        Phone: phone,
        Email: email,
        IntercomUrl: intercomUrl,
    };
}
