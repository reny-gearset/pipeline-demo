import { createElement } from 'lwc';
import { registerApexTestWireAdapter } from '@salesforce/sfdx-lwc-jest';
import teamLoginDetailsComponent from 'c/teamLoginDetailsComponent';
import getTeamMemberLoginStats from '@salesforce/apex/TeamRoutes.getTeamMemberLoginStats';

const getTeamMemberLoginStatsAdapter = registerApexTestWireAdapter(getTeamMemberLoginStats);

describe('teamLoginDetailsComponent', () => {
    it('should render error message if getTeamMemberLoginStats errors', async () => {
        const element = createElement('c-team-login-details-component', {
            is: teamLoginDetailsComponent
        });
        document.body.appendChild(element);
    
        getTeamMemberLoginStatsAdapter.error();    
        await Promise.resolve();

        const errorElement = element.shadowRoot.querySelector('div');
        expect(errorElement.textContent).toBe('Failed to retrieve team login details');
    })
});
