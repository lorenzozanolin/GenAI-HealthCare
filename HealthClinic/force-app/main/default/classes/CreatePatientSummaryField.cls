public with sharing class CreatePatientSummaryField {
    @InvocableMethod(CapabilityType='PromptTemplateType://einstein_gpt__fieldCompletion')

    public static List<Response> getPatientInfos(List<Request> requests) {
        Request input = requests[0];    //Account di input che l'azione Identify Account fornisce al prompt 

        List<AllergyIntolerance> allergies = [
            SELECT Allergy__r.Definition__c, Allergy__r.Type__c
            FROM AllergyIntolerance
            WHERE AllergyIntolerance.PatientId = :input.RelatedEntity.Id
        ];

        List<HealthCondition> clinicalHistory = [
            SELECT ProblemDefinition.Name, ProblemDefinition.Description, Severity, DiagnosticStatus, ClinicalEncounter.StartDate, ClinicalEncounter.EndDate, ClinicalEncounter.Reason__c
            FROM HealthCondition
            WHERE PatientId = :input.RelatedEntity.Id

        ];

        List<Response> responses = new List<Response>();
        Response output = new Response();
        responses.add(output);
    
        output.Prompt += 'Use also the following infos:';
        
        output.Prompt += '\nAllergies: ';
        for (AllergyIntolerance a : allergies) {
            output.Prompt += a.Allergy__r.Definition__c +' '+ a.Allergy__r.Type__c + '\n';
        }
        
        if (allergies.size() == 0) {
            output.Prompt += 'none';
        }

        output.Prompt += '\n Health Conditions with the correspective Clinical Encounter';
        for (HealthCondition con : clinicalHistory) {
            output.Prompt += con.ProblemDefinition.Name + ' ' + con.ProblemDefinition.Description + ' ' + con.DiagnosticStatus + ' ' + con.Severity + ' ' + con.ClinicalEncounter.StartDate + ' ' + con.ClinicalEncounter.EndDate + ' ' + con.ClinicalEncounter.Reason__c + '\n';
        }

        if (clinicalHistory.size() == 0) {
            output.Prompt += 'none';
        }

        return responses;
    }

    public class Request {
        @InvocableVariable(required=true)
        public Account RelatedEntity;
    }
    
    public class Response {
        @InvocableVariable
        public String Prompt;
    }
}
